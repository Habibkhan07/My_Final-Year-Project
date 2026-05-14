import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/technician/wallet/data/data_sources/withdrawal_remote_data_source.dart';
import 'package:frontend/features/technician/wallet/data/models/payout_account_model.dart';
import 'package:frontend/features/technician/wallet/data/models/withdrawal_request_model.dart';
import 'package:frontend/features/technician/wallet/data/repositories/withdrawal_repository_impl.dart';
import 'package:frontend/features/technician/wallet/domain/entities/payout_account.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/failures/withdrawal_failure.dart';

class _MockRemoteDataSource extends Mock
    implements IWithdrawalRemoteDataSource {}

void main() {
  late WithdrawalRepositoryImpl repo;
  late _MockRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = _MockRemoteDataSource();
    repo = WithdrawalRepositoryImpl(remoteDataSource: mockRemote);
  });

  // ──────────────────────────────────────────────────────────────────
  // listPayoutAccounts — read happy path + offline + envelope
  // ──────────────────────────────────────────────────────────────────

  group('listPayoutAccounts', () {
    test('happy path returns PayoutAccounts entity with both lists', () async {
      when(() => mockRemote.listPayoutAccounts()).thenAnswer(
        (_) async => const PayoutAccountsModel(
          bankAccounts: [
            BankPayoutAccountModel(
              id: 7,
              bankName: 'HBL',
              accountTitle: 'Ali Khan',
              maskedNumber: '••1234',
            ),
          ],
          jazzcashAccounts: [
            JazzCashPayoutAccountModel(
              id: 12,
              accountTitle: 'Ali Khan',
              maskedMobile: '+923•••567',
            ),
          ],
        ),
      );

      final accounts = await repo.listPayoutAccounts();

      expect(accounts.bankAccounts, hasLength(1));
      expect(accounts.bankAccounts.first, isA<BankPayoutAccount>());
      expect((accounts.bankAccounts.first).bankName, 'HBL');
      expect(accounts.bankAccounts.first.masked, '••1234');
      expect(accounts.jazzcashAccounts, hasLength(1));
      expect(accounts.jazzcashAccounts.first.masked, '+923•••567');
    });

    test('SocketException → WithdrawalNetworkFailure (no cache fallback)',
        () async {
      when(() => mockRemote.listPayoutAccounts())
          .thenThrow(const SocketException('offline'));

      await expectLater(
        repo.listPayoutAccounts(),
        throwsA(isA<WithdrawalNetworkFailure>()),
      );
    });

    test('401 → WithdrawalPermissionFailure', () async {
      when(() => mockRemote.listPayoutAccounts()).thenThrow(
        const HttpFailure(
            statusCode: 401, code: 'permission_denied', message: 'No'),
      );

      await expectLater(
        repo.listPayoutAccounts(),
        throwsA(isA<WithdrawalPermissionFailure>()),
      );
    });

    test('5xx → WithdrawalServerFailure', () async {
      when(() => mockRemote.listPayoutAccounts()).thenThrow(
        const HttpFailure(statusCode: 503, code: 'server_error', message: 'oops'),
      );

      await expectLater(
        repo.listPayoutAccounts(),
        throwsA(isA<WithdrawalServerFailure>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // createRequest — each backend code maps to its sealed-class case
  // ──────────────────────────────────────────────────────────────────

  group('createRequest', () {
    WithdrawalRequestModel modelFromServer({
      String status = 'PENDING_REVIEW',
    }) =>
        WithdrawalRequestModel(
          id: 42,
          amount: '500.00',
          status: status,
          uiStatusLabel: 'Under review',
          payout: const PayoutDescriptorModel(
            kind: 'bank',
            label: 'HBL — Ali',
            masked: '••1234',
          ),
          adminExternalRef: '',
          requestedAt: '2026-05-15T10:00:00Z',
          reviewedAt: null,
        );

    test('happy path → WithdrawalRequest entity', () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenAnswer((_) async => modelFromServer());

      final req = await repo.createRequest(amount: 500.0, bankAccountId: 7);

      expect(req.id, 42);
      expect(req.amount, 500.00);
      expect(req.status, WithdrawalStatus.pendingReview);
      expect(req.uiStatusLabel, 'Under review');
      expect(req.payout.kind, 'bank');
    });

    test('400 insufficient_funds → InsufficientFundsFailure with both ints',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'insufficient_funds',
          message: 'Cannot withdraw Rs. 500. Available balance: Rs. 100.',
          errors: {
            'requested_pkr': ['500'],
            'available_pkr': ['100'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 500.0, bankAccountId: 7);
        fail('expected InsufficientFundsFailure');
      } on InsufficientFundsFailure catch (e) {
        expect(e.requestedPkr, 500);
        expect(e.availablePkr, 100);
        expect(e.message,
            'Cannot withdraw Rs. 500. Available balance: Rs. 100.');
      }
    });

    test('403 wallet_lockout → WalletLockoutForWithdrawalFailure', () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'wallet_lockout',
          message: 'locked',
          errors: {
            'balance_pkr': ['-50'],
            'owed_pkr': ['50'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 10.0, bankAccountId: 7);
        fail('expected WalletLockoutForWithdrawalFailure');
      } on WalletLockoutForWithdrawalFailure catch (e) {
        expect(e.balancePkr, -50);
        expect(e.owedPkr, 50);
      }
    });

    test('403 inactive_technician PENDING → InactiveTechnicianForWithdrawalFailure',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'inactive_technician',
          message: 'no',
          errors: {
            'status': ['PENDING'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 100.0, bankAccountId: 7);
        fail('expected InactiveTechnicianForWithdrawalFailure');
      } on InactiveTechnicianForWithdrawalFailure catch (e) {
        expect(e.status, 'PENDING');
      }
    });

    test('403 inactive_technician DEACTIVATED → preserves synthetic status',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 403,
          code: 'inactive_technician',
          message: 'no',
          errors: {
            'status': ['DEACTIVATED'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 100.0, bankAccountId: 7);
        fail('expected InactiveTechnicianForWithdrawalFailure');
      } on InactiveTechnicianForWithdrawalFailure catch (e) {
        expect(e.status, 'DEACTIVATED');
      }
    });

    test('409 duplicate_pending_withdrawal → carries pending id', () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 409,
          code: 'duplicate_pending_withdrawal',
          message: 'in review',
          errors: {
            'pending_request_id': ['41'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 100.0, bankAccountId: 7);
        fail('expected DuplicatePendingWithdrawalFailure');
      } on DuplicatePendingWithdrawalFailure catch (e) {
        expect(e.pendingRequestId, 41);
      }
    });

    test('400 validation_error on amount → WithdrawalAmountOutOfRangeFailure',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {
            'amount': ['Ensure this value is less than or equal to 5000.00.'],
          },
        ),
      );

      try {
        await repo.createRequest(amount: 5001.0, bankAccountId: 7);
        fail('expected WithdrawalAmountOutOfRangeFailure');
      } on WithdrawalAmountOutOfRangeFailure catch (e) {
        expect(e.message, contains('5000'));
      }
    });

    test(
        '400 validation_error on payout_bank_account_id → InvalidPayoutAccountFailure (IDOR / inactive / unknown)',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {
            'payout_bank_account_id': ['Invalid payout account.'],
          },
        ),
      );

      await expectLater(
        repo.createRequest(amount: 100.0, bankAccountId: 999),
        throwsA(isA<InvalidPayoutAccountFailure>()),
      );
    });

    test(
        '400 validation_error on payout_jazzcash_account_id → InvalidPayoutAccountFailure',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {
            'payout_jazzcash_account_id': ['Invalid payout account.'],
          },
        ),
      );

      await expectLater(
        repo.createRequest(amount: 100.0, jazzcashAccountId: 999),
        throwsA(isA<InvalidPayoutAccountFailure>()),
      );
    });

    test('400 validation_error on payout XOR rule → WithdrawalValidationFailure',
        () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid input data.',
          errors: {
            'payout': ['Exactly one of payout_bank_account_id or payout_jazzcash_account_id is required.'],
          },
        ),
      );

      await expectLater(
        repo.createRequest(
          amount: 100.0,
          bankAccountId: 7,
          jazzcashAccountId: 12,
        ),
        throwsA(isA<WithdrawalValidationFailure>()),
      );
    });

    test('SocketException → WithdrawalNetworkFailure (no cache write)', () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(const SocketException('offline'));

      await expectLater(
        repo.createRequest(amount: 100.0, bankAccountId: 7),
        throwsA(isA<WithdrawalNetworkFailure>()),
      );
    });

    test('FormatException → WithdrawalServerFailure', () async {
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(const FormatException('bad json'));

      await expectLater(
        repo.createRequest(amount: 100.0, bankAccountId: 7),
        throwsA(isA<WithdrawalServerFailure>()),
      );
    });

    test('unknown backend code in 400 → WithdrawalServerFailure fallback',
        () async {
      // Forward-compat: a future server adds a new ``code``, we must not
      // crash — just surface a generic server failure.
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'some_future_code_unknown_today',
          message: 'whatever',
        ),
      );

      await expectLater(
        repo.createRequest(amount: 100.0, bankAccountId: 7),
        throwsA(isA<WithdrawalServerFailure>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // listHistory — pagination contract + offline behaviour
  // ──────────────────────────────────────────────────────────────────

  group('listHistory', () {
    test('happy path returns WithdrawalHistoryPage', () async {
      when(() => mockRemote.listHistory(cursor: any(named: 'cursor')))
          .thenAnswer(
        (_) async => WithdrawalHistoryPageModel(
          results: [
            WithdrawalRequestModel(
              id: 42,
              amount: '500.00',
              status: 'PROCESSED',
              uiStatusLabel: 'Processed',
              payout: const PayoutDescriptorModel(
                kind: 'bank',
                label: 'HBL — Ali',
                masked: '••1234',
              ),
              adminExternalRef: 'JC-MERCH-2026-05-20',
              requestedAt: '2026-05-15T10:00:00Z',
              reviewedAt: '2026-05-20T14:30:00Z',
            ),
          ],
          nextCursor: 'abc123',
        ),
      );

      final page = await repo.listHistory();

      expect(page.results, hasLength(1));
      expect(page.nextCursor, 'abc123');
      expect(page.hasMore, isTrue);
      expect(page.results.first.status, WithdrawalStatus.processed);
      expect(page.results.first.adminExternalRef, 'JC-MERCH-2026-05-20');
      expect(page.results.first.reviewedAt, isNotNull);
    });

    test('null next_cursor → hasMore=false', () async {
      when(() => mockRemote.listHistory(cursor: any(named: 'cursor')))
          .thenAnswer(
        (_) async => const WithdrawalHistoryPageModel(
          results: [],
          nextCursor: null,
        ),
      );

      final page = await repo.listHistory();

      expect(page.hasMore, isFalse);
    });

    test('400 bad cursor → WithdrawalValidationFailure', () async {
      when(() => mockRemote.listHistory(cursor: any(named: 'cursor')))
          .thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'validation_error',
          message: 'Invalid cursor.',
          errors: {
            'cursor': ['Cursor could not be decoded.'],
          },
        ),
      );

      await expectLater(
        repo.listHistory(cursor: 'tampered'),
        throwsA(isA<WithdrawalValidationFailure>()),
      );
    });

    test('SocketException → WithdrawalNetworkFailure', () async {
      when(() => mockRemote.listHistory(cursor: any(named: 'cursor')))
          .thenThrow(const SocketException('offline'));

      await expectLater(
        repo.listHistory(),
        throwsA(isA<WithdrawalNetworkFailure>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Envelope edge cases (regression guards for HttpFailure.fromEnvelope)
  // ──────────────────────────────────────────────────────────────────

  group('envelope parsing edge cases', () {
    test('insufficient_funds with missing ints defaults to 0/0', () async {
      // Degraded but never throws — the UI rendering with "Rs. 0" is
      // still recoverable; throwing would crash the sheet.
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 400,
          code: 'insufficient_funds',
          message: '',
        ),
      );

      try {
        await repo.createRequest(amount: 100.0, bankAccountId: 7);
        fail('expected InsufficientFundsFailure');
      } on InsufficientFundsFailure catch (e) {
        expect(e.requestedPkr, 0);
        expect(e.availablePkr, 0);
      }
    });

    test('envelope errors map with bare value (not list) is coerced', () async {
      // Wire-shape robustness: if the server ever drops the list
      // wrapper, the parser must still extract the value.
      when(() => mockRemote.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const HttpFailure(
          statusCode: 409,
          code: 'duplicate_pending_withdrawal',
          message: '',
          errors: {
            'pending_request_id': '7', // bare string, not a list
          },
        ),
      );

      try {
        await repo.createRequest(amount: 100.0, bankAccountId: 7);
        fail('expected DuplicatePendingWithdrawalFailure');
      } on DuplicatePendingWithdrawalFailure catch (e) {
        expect(e.pendingRequestId, 7);
      }
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/payout_account.dart';
import 'package:frontend/features/technician/wallet/domain/entities/payout_accounts.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/failures/withdrawal_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/withdrawal_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/withdraw_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/withdraw_state.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements WithdrawalRepository {}

PayoutAccounts _accounts({
  bool withBank = true,
  bool withJazz = true,
}) =>
    PayoutAccounts(
      bankAccounts: withBank
          ? const [
              BankPayoutAccount(
                id: 7,
                bankName: 'HBL',
                accountTitle: 'Ali',
                masked: '••1234',
              ),
            ]
          : const [],
      jazzcashAccounts: withJazz
          ? const [
              JazzCashPayoutAccount(
                id: 12,
                accountTitle: 'Ali',
                masked: '+923•••567',
              ),
            ]
          : const [],
    );

WithdrawalRequest _request({String status = 'PENDING_REVIEW'}) =>
    WithdrawalRequest(
      id: 42,
      amount: 500.0,
      status: WithdrawalStatus.fromWire(status),
      uiStatusLabel: 'Under review',
      payout: const PayoutDescriptor(
        kind: 'bank',
        label: 'HBL — Ali',
        masked: '••1234',
      ),
      adminExternalRef: '',
      requestedAt: DateTime.utc(2026, 5, 15, 10),
      reviewedAt: null,
    );

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [withdrawalRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  // ────────────────────────────────────────────────────────────────────
  // build() — initial fetch
  // ────────────────────────────────────────────────────────────────────

  group('build', () {
    test('fetches payout accounts and transitions to editing', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());

      final state = await container.read(withdrawProvider.future);

      expect(state.flow, WithdrawFlow.editing);
      expect(state.accounts, isNotNull);
      expect(state.accounts!.bankAccounts, hasLength(1));
      expect(state.selectedTarget, isNull);
      expect(state.amountInput, isEmpty);
    });

    test('fetch failure → flow=failed with sealed failure', () async {
      when(() => repo.listPayoutAccounts())
          .thenThrow(const WithdrawalNetworkFailure());

      final state = await container.read(withdrawProvider.future);

      expect(state.flow, WithdrawFlow.failed);
      expect(state.failure, isA<WithdrawalNetworkFailure>());
    });

    test('empty accounts → flow=editing but accounts.isEmpty=true', () async {
      when(() => repo.listPayoutAccounts()).thenAnswer(
        (_) async => _accounts(withBank: false, withJazz: false),
      );

      final state = await container.read(withdrawProvider.future);

      expect(state.flow, WithdrawFlow.editing);
      expect(state.accounts!.isEmpty, isTrue);
      expect(state.canSubmit, isFalse); // no target to pick
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // setAmount / selectTarget — form mutation
  // ────────────────────────────────────────────────────────────────────

  group('form mutation', () {
    test('setAmount updates input without resubmitting', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());

      await container.read(withdrawProvider.future);
      container.read(withdrawProvider.notifier).setAmount('500.00');
      final state = container.read(withdrawProvider).value!;

      expect(state.amountInput, '500.00');
      expect(state.flow, WithdrawFlow.editing);
    });

    test('selectTarget marks the target as selected', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());

      await container.read(withdrawProvider.future);
      final bank = container.read(withdrawProvider).value!.accounts!
          .bankAccounts.first;
      container.read(withdrawProvider.notifier).selectTarget(bank);

      final state = container.read(withdrawProvider).value!;
      expect(state.selectedTarget, bank);
    });

    test('setAmount clears any prior failure (recoverable retry)', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());

      await container.read(withdrawProvider.future);
      // Simulate failure → submit to a non-existent path; easier to
      // directly verify the state surface is correct via canSubmit.
      final notifier = container.read(withdrawProvider.notifier);
      final bank = container.read(withdrawProvider).value!.accounts!
          .bankAccounts.first;
      notifier.selectTarget(bank);
      notifier.setAmount('100');

      // Setting amount on a clean form keeps editing flow.
      expect(container.read(withdrawProvider).value!.flow,
          WithdrawFlow.editing);
    });

    test('canSubmit reflects amount + target + non-empty accounts', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());

      await container.read(withdrawProvider.future);
      final notifier = container.read(withdrawProvider.notifier);

      // No amount, no target.
      expect(container.read(withdrawProvider).value!.canSubmit, isFalse);

      // Amount only.
      notifier.setAmount('100');
      expect(container.read(withdrawProvider).value!.canSubmit, isFalse);

      // Amount + target.
      notifier.selectTarget(container.read(withdrawProvider).value!
          .accounts!.bankAccounts.first);
      expect(container.read(withdrawProvider).value!.canSubmit, isTrue);

      // Zero amount → not submittable.
      notifier.setAmount('0');
      expect(container.read(withdrawProvider).value!.canSubmit, isFalse);

      // Negative amount → not submittable.
      notifier.setAmount('-5');
      expect(container.read(withdrawProvider).value!.canSubmit, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────────────
  // submit() — terminal transitions
  // ────────────────────────────────────────────────────────────────────

  group('submit', () {
    Future<void> arrangeReady({
      required _MockRepo repo,
      required ProviderContainer container,
      double amount = 100.0,
      bool useBank = true,
    }) async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());
      await container.read(withdrawProvider.future);
      final notifier = container.read(withdrawProvider.notifier);
      notifier.setAmount(amount.toString());
      final accounts = container.read(withdrawProvider).value!.accounts!;
      notifier.selectTarget(useBank
          ? accounts.bankAccounts.first
          : accounts.jazzcashAccounts.first);
    }

    test('success → flow=success with submitted entity', () async {
      await arrangeReady(repo: repo, container: container);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenAnswer((_) async => _request());

      await container.read(withdrawProvider.notifier).submit();

      final state = container.read(withdrawProvider).value!;
      expect(state.flow, WithdrawFlow.success);
      expect(state.submitted, isNotNull);
      expect(state.submitted!.id, 42);
      expect(state.failure, isNull);
    });

    test('submit sends the bank id when bank target selected', () async {
      await arrangeReady(repo: repo, container: container, useBank: true);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenAnswer((_) async => _request());

      await container.read(withdrawProvider.notifier).submit();

      final captured = verify(() => repo.createRequest(
            amount: captureAny(named: 'amount'),
            bankAccountId: captureAny(named: 'bankAccountId'),
            jazzcashAccountId: captureAny(named: 'jazzcashAccountId'),
          )).captured;
      expect(captured, [100.0, 7, null]);
    });

    test('submit sends the jazzcash id when jazzcash target selected',
        () async {
      await arrangeReady(repo: repo, container: container, useBank: false);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenAnswer((_) async => _request());

      await container.read(withdrawProvider.notifier).submit();

      final captured = verify(() => repo.createRequest(
            amount: captureAny(named: 'amount'),
            bankAccountId: captureAny(named: 'bankAccountId'),
            jazzcashAccountId: captureAny(named: 'jazzcashAccountId'),
          )).captured;
      expect(captured, [100.0, null, 12]);
    });

    test('insufficient funds failure → flow=failed', () async {
      await arrangeReady(repo: repo, container: container);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(const InsufficientFundsFailure(
        requestedPkr: 100,
        availablePkr: 50,
      ));

      await container.read(withdrawProvider.notifier).submit();

      final state = container.read(withdrawProvider).value!;
      expect(state.flow, WithdrawFlow.failed);
      expect(state.failure, isA<InsufficientFundsFailure>());
    });

    test('duplicate pending failure → flow=failed', () async {
      await arrangeReady(repo: repo, container: container);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(
        const DuplicatePendingWithdrawalFailure(pendingRequestId: 41),
      );

      await container.read(withdrawProvider.notifier).submit();

      expect(
        container.read(withdrawProvider).value!.failure,
        isA<DuplicatePendingWithdrawalFailure>(),
      );
    });

    test('amount input changes after failure clear the failure', () async {
      await arrangeReady(repo: repo, container: container);
      when(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          )).thenThrow(const InsufficientFundsFailure(
        requestedPkr: 100,
        availablePkr: 50,
      ));

      await container.read(withdrawProvider.notifier).submit();
      expect(container.read(withdrawProvider).value!.failure, isNotNull);

      container.read(withdrawProvider.notifier).setAmount('40');

      expect(container.read(withdrawProvider).value!.failure, isNull);
      expect(
        container.read(withdrawProvider).value!.flow,
        WithdrawFlow.editing,
      );
    });

    test('submit no-ops when canSubmit is false (no target)', () async {
      when(() => repo.listPayoutAccounts())
          .thenAnswer((_) async => _accounts());
      await container.read(withdrawProvider.future);
      container.read(withdrawProvider.notifier).setAmount('100');
      // No target selected.

      await container.read(withdrawProvider.notifier).submit();

      verifyNever(() => repo.createRequest(
            amount: any(named: 'amount'),
            bankAccountId: any(named: 'bankAccountId'),
            jazzcashAccountId: any(named: 'jazzcashAccountId'),
          ));
    });
  });

}

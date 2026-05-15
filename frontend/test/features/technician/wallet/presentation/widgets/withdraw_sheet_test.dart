import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/payout_account.dart';
import 'package:frontend/features/technician/wallet/domain/entities/payout_accounts.dart';
import 'package:frontend/features/technician/wallet/domain/entities/wallet_state.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/failures/withdrawal_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/withdrawal_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/withdraw_sheet.dart';

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockWithdrawalRepo extends Mock implements WithdrawalRepository {}

PayoutAccounts _accounts({bool bank = true, bool jazz = true}) =>
    PayoutAccounts(
      bankAccounts: bank
          ? const [
              BankPayoutAccount(
                id: 7,
                bankName: 'HBL',
                accountTitle: 'Ali',
                masked: '••1234',
              ),
            ]
          : const [],
      jazzcashAccounts: jazz
          ? const [
              JazzCashPayoutAccount(
                id: 12,
                accountTitle: 'Ali',
                masked: '+923•••567',
              ),
            ]
          : const [],
    );

void main() {
  late _MockWalletRepo walletRepo;
  late _MockWithdrawalRepo withdrawalRepo;

  setUp(() {
    walletRepo = _MockWalletRepo();
    withdrawalRepo = _MockWithdrawalRepo();
    when(() => walletRepo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: 1000.0,
        asOf: DateTime.utc(2026, 5, 15),
      ),
    );
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletRepositoryProvider.overrideWithValue(walletRepo),
          withdrawalRepositoryProvider.overrideWithValue(withdrawalRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WithdrawSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ────────────────────────────────────────────────────────────────────
  // Sheet structure
  // ────────────────────────────────────────────────────────────────────

  testWidgets('renders header + amount input + picker', (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());

    await pumpSheet(tester);

    expect(find.text('Withdraw funds'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Payout to'), findsOneWidget);
    expect(find.text('HBL — Ali'), findsOneWidget);
    expect(find.text('JazzCash — Ali'), findsOneWidget);
  });

  testWidgets('available balance caption is rendered', (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());

    await pumpSheet(tester);

    expect(find.textContaining('Available: Rs.'), findsOneWidget);
  });

  testWidgets('empty accounts renders empty-state body', (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts()).thenAnswer(
      (_) async => _accounts(bank: false, jazz: false),
    );

    await pumpSheet(tester);

    expect(find.text('No payout account on file'), findsOneWidget);
    expect(find.text('Request withdrawal'), findsNothing);
  });

  // ────────────────────────────────────────────────────────────────────
  // Submit button enable / disable
  // ────────────────────────────────────────────────────────────────────

  testWidgets('submit button disabled until amount + target are set',
      (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());

    await pumpSheet(tester);

    // Initially disabled.
    ElevatedButton btn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Request withdrawal'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNull);

    // Enter amount only — still disabled (no target).
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    btn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Request withdrawal'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNull);

    // Tap a payout target — now enabled.
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    btn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Request withdrawal'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNotNull);
  });

  // ────────────────────────────────────────────────────────────────────
  // Success state
  // ────────────────────────────────────────────────────────────────────

  testWidgets('success body renders after submit', (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());
    when(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        )).thenAnswer((_) async => WithdrawalRequest(
          id: 42,
          amount: 500.0,
          status: WithdrawalStatus.pendingReview,
          uiStatusLabel: 'Under review',
          payout: const PayoutDescriptor(
            kind: 'bank',
            label: 'HBL — Ali',
            masked: '••1234',
          ),
          adminExternalRef: '',
          requestedAt: DateTime.utc(2026, 5, 15),
          reviewedAt: null,
        ));

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    await tester.tap(find.text('Request withdrawal'));
    await tester.pumpAndSettle();

    expect(find.text('Request submitted'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.textContaining('Rs. 500'), findsOneWidget);
  });

  // ────────────────────────────────────────────────────────────────────
  // Failure surface (sealed pattern-match)
  // ────────────────────────────────────────────────────────────────────

  testWidgets('insufficient_funds failure renders friendly inline banner',
      (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());
    when(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        )).thenThrow(const InsufficientFundsFailure(
      requestedPkr: 500,
      availablePkr: 100,
    ));

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    await tester.tap(find.text('Request withdrawal'));
    await tester.pumpAndSettle();

    // Composed copy from the sealed pattern-match in _failureCopy:
    // "You tried to withdraw Rs. 500 but only Rs. 100 is available."
    // Match the whole sentence to disambiguate from the amount field /
    // available-balance caption that also contain "Rs. ...".
    expect(
      find.textContaining('You tried to withdraw Rs. 500'),
      findsOneWidget,
    );
    expect(
      find.textContaining('only Rs. 100 is available'),
      findsOneWidget,
    );
  });

  testWidgets('duplicate pending failure renders the right banner',
      (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());
    when(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        )).thenThrow(
      const DuplicatePendingWithdrawalFailure(pendingRequestId: 41),
    );

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    await tester.tap(find.text('Request withdrawal'));
    await tester.pumpAndSettle();

    expect(find.textContaining('under review'), findsOneWidget);
  });

  testWidgets('inactive_technician DEACTIVATED gets the right copy',
      (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());
    when(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        )).thenThrow(const InactiveTechnicianForWithdrawalFailure(
      status: 'DEACTIVATED',
    ));

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    await tester.tap(find.text('Request withdrawal'));
    await tester.pumpAndSettle();

    expect(find.textContaining('deactivated'), findsOneWidget);
  });

  testWidgets('inactive_technician REJECTED renders the rejected-app copy',
      (tester) async {
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());
    when(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        )).thenThrow(
      const InactiveTechnicianForWithdrawalFailure(status: 'REJECTED'),
    );

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '500');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();
    await tester.tap(find.text('Request withdrawal'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('application was rejected'),
      findsOneWidget,
    );
  });

  testWidgets(
      'client-side: amount > balance disables submit and shows banner',
      (tester) async {
    // Wallet balance = 1000 (from setUp default). Request 5000 → pre-empt.
    when(() => withdrawalRepo.listPayoutAccounts())
        .thenAnswer((_) async => _accounts());

    await pumpSheet(tester);
    await tester.enterText(find.byType(TextField), '5000');
    await tester.pump();
    await tester.tap(find.text('HBL — Ali'));
    await tester.pump();

    // Banner is rendered.
    expect(
      find.textContaining('Amount exceeds available balance'),
      findsOneWidget,
    );
    // Submit button is disabled — onPressed == null.
    final btn = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Request withdrawal'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(btn.onPressed, isNull);
    // Server is never asked.
    verifyNever(() => withdrawalRepo.createRequest(
          amount: any(named: 'amount'),
          bankAccountId: any(named: 'bankAccountId'),
          jazzcashAccountId: any(named: 'jazzcashAccountId'),
        ));
  });
}

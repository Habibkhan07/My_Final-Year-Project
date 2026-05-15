import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_state.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_history_page.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/withdrawal_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/withdraw_button.dart';

class _MockWalletRepo extends Mock implements WalletRepository {}

class _MockWithdrawalRepo extends Mock implements WithdrawalRepository {}

WithdrawalRequest _pendingRow() => WithdrawalRequest(
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

  Future<void> pumpButton(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletRepositoryProvider.overrideWithValue(walletRepo),
          withdrawalRepositoryProvider.overrideWithValue(withdrawalRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WithdrawButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  OutlinedButton findOutlined(WidgetTester tester, String label) =>
      tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text(label),
          matching: find.byType(OutlinedButton),
        ),
      );

  testWidgets('no pending + not locked → enabled with default label',
      (tester) async {
    when(() => withdrawalRepo.listHistory(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const WithdrawalHistoryPage(
              results: [],
              nextCursor: null,
            ));

    await pumpButton(tester);

    expect(find.text('Withdraw'), findsOneWidget);
    expect(findOutlined(tester, 'Withdraw').onPressed, isNotNull);
  });

  testWidgets('locked-out wallet disables the button with locked label',
      (tester) async {
    when(() => walletRepo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: -50.0,
        asOf: DateTime.utc(2026, 5, 15),
      ),
    );
    when(() => withdrawalRepo.listHistory(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => const WithdrawalHistoryPage(
              results: [],
              nextCursor: null,
            ));

    await pumpButton(tester);

    expect(find.text('Withdraw (locked)'), findsOneWidget);
    expect(findOutlined(tester, 'Withdraw (locked)').onPressed, isNull);
  });

  testWidgets('pending request disables the button with pending label',
      (tester) async {
    when(() => withdrawalRepo.listHistory(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => WithdrawalHistoryPage(
              results: [_pendingRow()],
              nextCursor: null,
            ));

    await pumpButton(tester);

    expect(find.text('Withdraw (request pending)'), findsOneWidget);
    expect(
      findOutlined(tester, 'Withdraw (request pending)').onPressed,
      isNull,
    );
    // pendingWithdrawalProvider piggybacks on listHistory.
    verify(() => withdrawalRepo.listHistory(cursor: any(named: 'cursor')))
        .called(1);
  });

  testWidgets('lockout takes precedence over pending in the label',
      (tester) async {
    when(() => walletRepo.getBalance()).thenAnswer(
      (_) async => WalletState.fromBalance(
        balance: -50.0,
        asOf: DateTime.utc(2026, 5, 15),
      ),
    );
    when(() => withdrawalRepo.listHistory(cursor: any(named: 'cursor')))
        .thenAnswer((_) async => WithdrawalHistoryPage(
              results: [_pendingRow()],
              nextCursor: null,
            ));

    await pumpButton(tester);

    expect(find.text('Withdraw (locked)'), findsOneWidget);
  });
}

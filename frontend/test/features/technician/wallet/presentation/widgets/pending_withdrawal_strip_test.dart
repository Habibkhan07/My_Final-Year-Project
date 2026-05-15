import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_history_page.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_request.dart';
import 'package:frontend/features/technician/wallet/domain/entities/withdrawal_status.dart';
import 'package:frontend/features/technician/wallet/domain/failures/withdrawal_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/withdrawal_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/pending_withdrawal_strip.dart';

class _MockRepo extends Mock implements WithdrawalRepository {}

WithdrawalRequest _row({
  WithdrawalStatus status = WithdrawalStatus.pendingReview,
  double amount = 500.0,
}) =>
    WithdrawalRequest(
      id: 42,
      amount: amount,
      status: status,
      uiStatusLabel: status == WithdrawalStatus.approved
          ? 'Approved (processing)'
          : 'Under review',
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
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  // Minimal GoRouter so the strip's ``context.push('/withdrawals/history')``
  // doesn't blow up during tap. The history-screen replacement is just a
  // marker we look for in the navigation test.
  GoRouter buildRouter() => GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: PendingWithdrawalStrip()),
          ),
          GoRoute(
            path: '/withdrawals/history',
            builder: (_, _) =>
                const Scaffold(body: Text('history-marker')),
          ),
        ],
      );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [withdrawalRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: buildRouter()),
        // intentionally using the helper to keep the test isolated.
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no pending row → renders nothing', (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => const WithdrawalHistoryPage(
        results: [],
        nextCursor: null,
      ),
    );

    await pump(tester);

    expect(find.text('Withdrawal under review'), findsNothing);
    expect(find.text('Withdrawal approved — processing'), findsNothing);
    expect(find.textContaining('Could not load withdrawal status'),
        findsNothing);
  });

  testWidgets('PENDING_REVIEW row → review label + amount + payout',
      (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(amount: 500.5)],
        nextCursor: null,
      ),
    );

    await pump(tester);

    expect(find.text('Withdrawal under review'), findsOneWidget);
    // formatRs renders the paisa precision.
    expect(find.textContaining('Rs. 500.50 → HBL — Ali'), findsOneWidget);
  });

  testWidgets('APPROVED row → "approved — processing" label',
      (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row(status: WithdrawalStatus.approved)],
        nextCursor: null,
      ),
    );

    await pump(tester);

    expect(find.text('Withdrawal approved — processing'), findsOneWidget);
  });

  testWidgets('fetch error → shows the "could not load" hint',
      (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor')))
        .thenThrow(const WithdrawalNetworkFailure());

    await pump(tester);

    expect(
      find.textContaining('Could not load withdrawal status'),
      findsOneWidget,
    );
  });

  testWidgets('tap on the pending row navigates to history',
      (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor'))).thenAnswer(
      (_) async => WithdrawalHistoryPage(
        results: [_row()],
        nextCursor: null,
      ),
    );

    await pump(tester);
    await tester.tap(find.text('Withdrawal under review'));
    await tester.pumpAndSettle();

    expect(find.text('history-marker'), findsOneWidget);
  });

  testWidgets('tap on the error hint also navigates to history',
      (tester) async {
    when(() => repo.listHistory(cursor: any(named: 'cursor')))
        .thenThrow(const WithdrawalNetworkFailure());

    await pump(tester);
    await tester.tap(
      find.textContaining('Could not load withdrawal status'),
    );
    await tester.pumpAndSettle();

    expect(find.text('history-marker'), findsOneWidget);
  });
}

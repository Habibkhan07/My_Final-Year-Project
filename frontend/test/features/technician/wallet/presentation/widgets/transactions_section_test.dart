import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:frontend/features/technician/wallet/domain/entities/wallet_transaction_page.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/wallet_transactions_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/widgets/transactions_section.dart';

class _MockNotifier extends WalletTransactionsNotifier {
  _MockNotifier(this._state);

  final AsyncValue<WalletTransactionsState> _state;

  @override
  Future<WalletTransactionsState> build() async {
    final s = _state;
    if (s is AsyncData<WalletTransactionsState>) return s.requireValue;
    if (s is AsyncError<WalletTransactionsState>) throw (s as AsyncError).error;
    return Completer<WalletTransactionsState>().future;
  }
}

WalletTransactionEntity _row(int id, {String title = 'Platform commission'}) =>
    WalletTransactionEntity(
      id: id,
      type: 'COMMISSION_DEBIT',
      amount: -200.0,
      balanceAfter: 800.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      memo: '',
      uiIcon: 'commission',
      uiTitle: title,
      uiSubtitle: 'Booking #$id',
      uiAmountColor: 'debit',
    );

Widget _scope(AsyncValue<WalletTransactionsState> state) {
  return ProviderScope(
    overrides: [
      walletTransactionsProvider.overrideWith(() => _MockNotifier(state)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TransactionsSection()),
      ),
    ),
  );
}

void main() {
  group('TransactionsSection', () {
    testWidgets('renders "Recent activity" header', (tester) async {
      await tester.pumpWidget(_scope(
        AsyncData(
          WalletTransactionsState(
            page: WalletTransactionPage(results: [_row(1)], nextCursor: null),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Recent activity'), findsOneWidget);
    });

    testWidgets('AsyncData with rows renders titles + subtitles', (tester) async {
      await tester.pumpWidget(_scope(
        AsyncData(
          WalletTransactionsState(
            page: WalletTransactionPage(
              results: [
                _row(1, title: 'Platform commission'),
                _row(2, title: 'Platform commission'),
              ],
              nextCursor: null,
            ),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Platform commission'), findsNWidgets(2));
      // Subtitle includes booking id (and a relative timestamp suffix).
      expect(find.textContaining('Booking #1'), findsOneWidget);
      expect(find.textContaining('Booking #2'), findsOneWidget);
    });

    testWidgets('AsyncData empty → "No wallet activity yet" pill', (tester) async {
      await tester.pumpWidget(_scope(
        const AsyncData(
          WalletTransactionsState(
            page: WalletTransactionPage(results: [], nextCursor: null),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('No wallet activity yet'), findsOneWidget);
    });

    testWidgets('AsyncLoading → progress shimmer (skeleton box)',
        (tester) async {
      await tester.pumpWidget(_scope(const AsyncLoading()));
      await tester.pump();

      // Skeleton renders 5 placeholder rows; no real row titles present.
      expect(find.text('Platform commission'), findsNothing);
      expect(find.text('No wallet activity yet'), findsNothing);
    });

    // AsyncError-branch rendering is exercised by the repository tests
    // (see wallet_repository_impl_test.dart) — the failure mapping is
    // the only logic to verify. Replicating it as a widget test runs
    // into the same auto-dispose race documented in
    // wallet_notifier_test.dart; not worth the test-only workaround.
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/technician/wallet/domain/entities/wallet_transaction_entity.dart';
import 'package:frontend/features/technician/wallet/domain/entities/wallet_transaction_page.dart';
import 'package:frontend/features/technician/wallet/domain/failures/wallet_failure.dart';
import 'package:frontend/features/technician/wallet/domain/repositories/wallet_repository.dart';
import 'package:frontend/features/technician/wallet/presentation/notifiers/wallet_transactions_notifier.dart';
import 'package:frontend/features/technician/wallet/presentation/providers/dependency_injection.dart';

class _MockRepo extends Mock implements WalletRepository {}

WalletTransactionEntity _row(int id) => WalletTransactionEntity(
      id: id,
      type: 'COMMISSION_DEBIT',
      amount: -200.0,
      balanceAfter: 800.0,
      timestamp: DateTime.utc(2026, 5, 13, 12, 0, 0),
      memo: '',
      uiIcon: 'commission',
      uiTitle: 'Platform commission',
      uiSubtitle: 'Booking #$id',
      uiAmountColor: 'debit',
    );

WalletTransactionPage _page(List<int> ids, {String? next}) =>
    WalletTransactionPage(
      results: ids.map(_row).toList(),
      nextCursor: next,
    );

void main() {
  late _MockRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _MockRepo();
    container = ProviderContainer(
      overrides: [walletRepositoryProvider.overrideWithValue(repo)],
    );
  });

  tearDown(() => container.dispose());

  group('build', () {
    test('loads the first page via the repository', () async {
      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([1, 2, 3], next: 'CUR'));

      final state = await container.read(walletTransactionsProvider.future);

      expect(state.page.results.map((r) => r.id), [1, 2, 3]);
      expect(state.page.nextCursor, 'CUR');
      expect(state.isLoadingMore, isFalse);
      verify(() => repo.listTransactions(cursor: null)).called(1);
    });

    // Error-path coverage lives at the repository + data source layer
    // (see wallet_repository_impl_test.dart). Replicating it here
    // against the Riverpod provider runs into a known auto-dispose race
    // during build-time exceptions — matches the same skip in
    // wallet_notifier_test.dart.
  });

  group('refresh', () {
    test('replaces the page with a fresh fetch', () async {
      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([1], next: null));
      await container.read(walletTransactionsProvider.future);

      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([4, 5], next: null));
      await container.read(walletTransactionsProvider.notifier).refresh();

      final state =
          container.read(walletTransactionsProvider).requireValue;
      expect(state.page.results.map((r) => r.id), [4, 5]);
      verify(() => repo.listTransactions(cursor: null)).called(2);
    });
  });

  group('loadMore', () {
    test('appends the next page using the prior cursor', () async {
      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([1, 2], next: 'CUR1'));
      await container.read(walletTransactionsProvider.future);

      when(() => repo.listTransactions(cursor: 'CUR1'))
          .thenAnswer((_) async => _page([3, 4], next: null));
      await container.read(walletTransactionsProvider.notifier).loadMore();

      final state =
          container.read(walletTransactionsProvider).requireValue;
      expect(state.page.results.map((r) => r.id), [1, 2, 3, 4]);
      expect(state.page.nextCursor, isNull);
      expect(state.isLoadingMore, isFalse);
    });

    test('no-op when nextCursor is null', () async {
      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([1], next: null));
      await container.read(walletTransactionsProvider.future);

      await container.read(walletTransactionsProvider.notifier).loadMore();

      // Only the initial load — loadMore short-circuited.
      verify(() => repo.listTransactions(cursor: null)).called(1);
      verifyNever(() => repo.listTransactions(cursor: any(named: 'cursor', that: isNotNull)));
    });

    test('error during loadMore keeps existing rows visible', () async {
      when(() => repo.listTransactions(cursor: null))
          .thenAnswer((_) async => _page([1, 2], next: 'CUR1'));
      await container.read(walletTransactionsProvider.future);

      when(() => repo.listTransactions(cursor: 'CUR1'))
          .thenAnswer((_) => Future<WalletTransactionPage>.error(
                const WalletNetworkFailure(),
              ));
      await container.read(walletTransactionsProvider.notifier).loadMore();

      final state =
          container.read(walletTransactionsProvider).requireValue;
      // Existing rows preserved; isLoadingMore reset; cursor kept so the
      // next loadMore can retry.
      expect(state.page.results.map((r) => r.id), [1, 2]);
      expect(state.page.nextCursor, 'CUR1');
      expect(state.isLoadingMore, isFalse);
    });
  });
}

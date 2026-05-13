import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/wallet_transaction_page.dart';
import '../providers/dependency_injection.dart';

part 'wallet_transactions_notifier.g.dart';

/// Composite state for the transaction-history list.
///
/// ``isLoadingMore`` is tracked alongside ``page`` so the screen can show
/// a footer spinner on ``loadMore()`` without flipping the whole notifier
/// back to ``AsyncLoading`` (which would unmount the existing rows).
class WalletTransactionsState {
  final WalletTransactionPage page;
  final bool isLoadingMore;

  const WalletTransactionsState({
    required this.page,
    this.isLoadingMore = false,
  });

  WalletTransactionsState copyWith({
    WalletTransactionPage? page,
    bool? isLoadingMore,
  }) =>
      WalletTransactionsState(
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// State holder for the WalletScreen's transaction list section.
///
/// keepAlive: false — disposed with the leaf wallet screen. On next
/// open, ``build`` re-fetches page 1; the dashboard pill stays warm
/// independently for balance refreshes.
@riverpod
class WalletTransactionsNotifier extends _$WalletTransactionsNotifier {
  @override
  Future<WalletTransactionsState> build() async {
    final repo = ref.read(walletRepositoryProvider);
    final page = await repo.listTransactions();
    return WalletTransactionsState(page: page);
  }

  /// Pull-to-refresh — re-fetches page 1, replacing any in-memory pages.
  ///
  /// AsyncValue.guard keeps the prior page visible during the refetch
  /// (no skeleton flash) and routes any failure back into AsyncError.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(walletRepositoryProvider);
      final page = await repo.listTransactions();
      return WalletTransactionsState(page: page);
    });
  }

  /// Append the next page if one is available and we aren't already
  /// fetching it. Re-entry guard prevents a fast scroll from kicking
  /// off the same request twice.
  Future<void> loadMore() async {
    final current = state;
    if (current is! AsyncData<WalletTransactionsState>) return;
    final value = current.requireValue;
    if (value.isLoadingMore) return;
    final cursor = value.page.nextCursor;
    if (cursor == null) return;

    state = AsyncData(value.copyWith(isLoadingMore: true));

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(walletRepositoryProvider);
      return await repo.listTransactions(cursor: cursor);
    });

    if (result is AsyncError) {
      // Surface the error but keep existing rows so the user can scroll
      // back; the screen renders an inline "couldn't load more" footer.
      state = AsyncData(value.copyWith(isLoadingMore: false));
      return;
    }

    final nextPage = (result as AsyncData<WalletTransactionPage>).requireValue;
    state = AsyncData(
      WalletTransactionsState(
        page: value.page.append(nextPage),
        isLoadingMore: false,
      ),
    );
  }
}

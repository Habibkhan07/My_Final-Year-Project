import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/withdrawal_history_page.dart';
import '../providers/dependency_injection.dart';

part 'withdrawal_history_notifier.g.dart';

/// Composite state for the withdrawal-history list.
///
/// ``isLoadingMore`` is tracked alongside ``page`` so the screen can
/// show a footer spinner during ``loadMore`` without flipping the
/// whole notifier back to ``AsyncLoading`` (which would unmount the
/// existing rows).
class WithdrawalHistoryState {
  final WithdrawalHistoryPage page;
  final bool isLoadingMore;

  const WithdrawalHistoryState({
    required this.page,
    this.isLoadingMore = false,
  });

  WithdrawalHistoryState copyWith({
    WithdrawalHistoryPage? page,
    bool? isLoadingMore,
  }) =>
      WithdrawalHistoryState(
        page: page ?? this.page,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// State holder for [WithdrawalHistoryScreen].
///
/// Mirrors [WalletTransactionsNotifier] in shape — same cursor-paginated
/// load-more semantics, same "preserve existing rows on loadMore
/// failure" UX. The distinct notifier exists because the underlying
/// repository contract differs (withdrawal history is a separate
/// endpoint with its own sealed-failure family).
///
/// ``keepAlive: false`` — the history screen is a leaf route, not a
/// tab. Re-entry re-fetches page 1.
@riverpod
class WithdrawalHistoryNotifier extends _$WithdrawalHistoryNotifier {
  @override
  Future<WithdrawalHistoryState> build() async {
    final repo = ref.read(withdrawalRepositoryProvider);
    final page = await repo.listHistory();
    return WithdrawalHistoryState(page: page);
  }

  /// Pull-to-refresh — re-fetches page 1, replacing the in-memory pages.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() async {
      final repo = ref.read(withdrawalRepositoryProvider);
      final page = await repo.listHistory();
      return WithdrawalHistoryState(page: page);
    });
  }

  /// Append the next page if one is available and we aren't already
  /// fetching it. Re-entry guard prevents a fast scroll from kicking
  /// off the same request twice.
  Future<void> loadMore() async {
    final current = state;
    if (current is! AsyncData<WithdrawalHistoryState>) return;
    final value = current.requireValue;
    if (value.isLoadingMore) return;
    final cursor = value.page.nextCursor;
    if (cursor == null) return;

    state = AsyncData(value.copyWith(isLoadingMore: true));

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(withdrawalRepositoryProvider);
      return await repo.listHistory(cursor: cursor);
    });

    if (result is AsyncError) {
      // Preserve existing rows so the user can scroll back; the screen
      // surfaces an inline "couldn't load more" footer.
      state = AsyncData(value.copyWith(isLoadingMore: false));
      return;
    }

    final nextPage =
        (result as AsyncData<WithdrawalHistoryPage>).requireValue;
    state = AsyncData(
      WithdrawalHistoryState(
        page: value.page.append(nextPage),
        isLoadingMore: false,
      ),
    );
  }
}

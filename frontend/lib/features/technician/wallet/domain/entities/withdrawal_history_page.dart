import 'withdrawal_request.dart';

/// One cursor-paginated page of withdrawal-request history.
///
/// Returned by ``WithdrawalRepository.listHistory(cursor: ...)``.
/// Mirrors the shape of [WalletTransactionPage] so the history
/// notifier can reuse the same "fetch first page, then loadMore on
/// scroll" pattern. ``nextCursor`` is null on the last page.
class WithdrawalHistoryPage {
  final List<WithdrawalRequest> results;
  final String? nextCursor;

  const WithdrawalHistoryPage({
    required this.results,
    required this.nextCursor,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  /// Concatenate this page with the next one fetched via [nextCursor].
  ///
  /// Used by ``WithdrawalHistoryNotifier.loadMore`` to extend the list
  /// without re-creating the existing rows. The merged page carries
  /// the LATER page's cursor (so the next ``loadMore`` continues past
  /// the new tail) and the union of the two ``results`` lists in
  /// newest-first order — the server already returned them sorted.
  WithdrawalHistoryPage append(WithdrawalHistoryPage next) =>
      WithdrawalHistoryPage(
        results: [...results, ...next.results],
        nextCursor: next.nextCursor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WithdrawalHistoryPage &&
          _listEquals(results, other.results) &&
          nextCursor == other.nextCursor;

  @override
  int get hashCode => Object.hash(Object.hashAll(results), nextCursor);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

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

import 'wallet_transaction_entity.dart';

/// One cursor-paginated page of the tech's wallet ledger.
///
/// ``nextCursor`` is opaque — the frontend round-trips whatever string
/// the backend handed back without inspecting its contents. A ``null``
/// cursor means the consumer has reached the end of the timeline.
class WalletTransactionPage {
  final List<WalletTransactionEntity> results;
  final String? nextCursor;

  const WalletTransactionPage({required this.results, required this.nextCursor});

  bool get hasMore => nextCursor != null;
  bool get isEmpty => results.isEmpty;

  /// Append the next page onto the current one, keeping newest-first order.
  ///
  /// Used by the notifier's [loadMore]. Page-boundary dedup isn't needed
  /// because the backend cursor's strict ``(timestamp, id)`` ordering
  /// guarantees the next page starts after the last row of the current.
  WalletTransactionPage append(WalletTransactionPage next) =>
      WalletTransactionPage(
        results: [...results, ...next.results],
        nextCursor: next.nextCursor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransactionPage &&
          _listEquals(results, other.results) &&
          nextCursor == other.nextCursor;

  @override
  int get hashCode => Object.hash(Object.hashAll(results), nextCursor);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

import '../entities/wallet_state.dart';
import '../entities/wallet_transaction_page.dart';

/// Repository contract for the wallet feature.
///
/// Backed by ``GET /api/technicians/wallet/`` (balance) and
/// ``GET /api/technicians/wallet/transactions/`` (cursor-paginated
/// ledger). Throws subclasses of [WalletFailure] on failure — see
/// ``wallet_repository_impl.dart`` for the HTTP-to-domain mapping.
abstract class WalletRepository {
  /// Fetch the tech's current wallet snapshot.
  ///
  /// Throws:
  /// * [WalletPermissionFailure] — backend returned 401/403.
  /// * [WalletNetworkFailure] — device offline (no cache fallback per Fix #9).
  /// * [WalletServerFailure] — backend 5xx or unparseable response.
  Future<WalletState> getBalance();

  /// Fetch one cursor-paginated page of the wallet transaction history.
  ///
  /// Pass [cursor] = null (or omit) for the first page; pass the
  /// previous page's ``nextCursor`` to continue.
  ///
  /// Throws:
  /// * [WalletPermissionFailure] — backend returned 401/403.
  /// * [WalletNetworkFailure] — device offline (no cache fallback —
  ///   transactions list intentionally never serves stale data).
  /// * [WalletServerFailure] — backend 5xx, bad cursor (400), or
  ///   unparseable response.
  Future<WalletTransactionPage> listTransactions({String? cursor});
}

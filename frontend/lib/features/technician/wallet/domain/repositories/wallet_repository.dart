import '../entities/wallet_state.dart';

/// Repository contract for the wallet feature.
///
/// Backed by ``GET /api/technicians/wallet/``. Throws subclasses of
/// [WalletFailure] on failure — see ``wallet_repository_impl.dart`` for
/// the HTTP-to-domain mapping.
abstract class WalletRepository {
  /// Fetch the tech's current wallet snapshot.
  ///
  /// Throws:
  /// * [WalletPermissionFailure] — backend returned 401/403.
  /// * [WalletNetworkFailure] — device offline (no cache fallback per Fix #9).
  /// * [WalletServerFailure] — backend 5xx or unparseable response.
  Future<WalletState> getBalance();
}

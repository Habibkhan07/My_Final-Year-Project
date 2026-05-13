import '../entities/topup_session.dart';
import '../entities/topup_status.dart';
import '../entities/wallet_state.dart';
import '../entities/wallet_transaction_page.dart';

/// Repository contract for the wallet feature.
///
/// Backed by:
/// * ``GET /api/technicians/wallet/``                 — balance snapshot
/// * ``GET /api/technicians/wallet/transactions/``    — cursor-paginated ledger
/// * ``POST /api/technicians/wallet/topups/``         — start top-up
/// * ``GET /api/technicians/wallet/topups/<id>/``     — poll top-up status
///
/// Throws subclasses of [WalletFailure] for read methods and
/// [TopupFailure] for the top-up flow methods — see
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

  /// Start a JazzCash Hosted Checkout top-up. Returns the bridge URL
  /// the Flutter app should open in a webview.
  ///
  /// [amountRs] is whole rupees, validated server-side
  /// (Rs.100..25,000). Out-of-range values throw [TopupInvalidAmount].
  ///
  /// Throws subclasses of [TopupFailure]:
  /// * [TopupInvalidAmount]       — amount out of range (400).
  /// * [TopupPermissionFailure]   — not a tech / token expired (401/403).
  /// * [TopupGatewayUnavailable]  — gateway misconfigured (503).
  /// * [TopupNetworkFailure]      — device offline.
  /// * [TopupServerFailure]       — backend 5xx / unparseable response.
  Future<TopupSession> startTopup({required int amountRs});

  /// Poll a topup's current status. Used by the [TopupNotifier] while
  /// the webview is open to detect when the gateway has settled.
  ///
  /// Throws subclasses of [TopupFailure]:
  /// * [TopupPermissionFailure]   — 401/403 or IDOR (404).
  /// * [TopupNetworkFailure]      — device offline.
  /// * [TopupServerFailure]       — backend 5xx / unparseable response.
  Future<TopupStatus> pollTopupStatus({required int topupId});
}

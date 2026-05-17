import '../entities/technician_dashboard_entity.dart';

/// Wire shape returned by [TechnicianDashboardRepository.setOnline] —
/// the post-commit `is_online` flag plus the fresh wallet balance,
/// so the notifier can patch both fields without a separate dashboard
/// refetch.
typedef OnlineToggleResult = ({bool isOnline, double walletBalance});

abstract class TechnicianDashboardRepository {
  /// Fetches the technician's dashboard data.
  ///
  /// Throws [DashboardNetworkFailure] if no internet and no cache.
  /// Throws [DashboardServerFailure] if backend error.
  /// Throws [DashboardPermissionFailure] if user is not a technician.
  /// Throws [DashboardParsingFailure] if JSON contract mismatch.
  Future<TechnicianDashboardEntity> getDashboard();

  /// Flips the caller's `is_online` flag to [desired].
  ///
  /// Going OFFLINE (desired=false) is always allowed. Going ONLINE
  /// (desired=true) requires a non-negative wallet balance — refusal
  /// surfaces as [DashboardWalletLockedFailure] with the signed balance
  /// + owed amount payload so the UI can compose remediation copy
  /// without client-side math.
  ///
  /// Throws [DashboardWalletLockedFailure] on 403 `wallet_lockout`.
  /// Throws [DashboardPermissionFailure] on 403 for non-tech or non-APPROVED.
  /// Throws [DashboardNetworkFailure] on socket loss.
  /// Throws [DashboardServerFailure] on any other backend error.
  Future<OnlineToggleResult> setOnline(bool desired);
}

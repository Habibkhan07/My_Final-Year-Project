import '../entities/technician_dashboard_entity.dart';

abstract class TechnicianDashboardRepository {
  /// Fetches the technician's dashboard data.
  ///
  /// Throws [DashboardNetworkFailure] if no internet and no cache.
  /// Throws [DashboardServerFailure] if backend error.
  /// Throws [DashboardPermissionFailure] if user is not a technician.
  /// Throws [DashboardParsingFailure] if JSON contract mismatch.
  Future<TechnicianDashboardEntity> getDashboard();
}

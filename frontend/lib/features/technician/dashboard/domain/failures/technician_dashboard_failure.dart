/// Sealed class representing all possible failures when loading the Technician Dashboard.
sealed class TechnicianDashboardFailure implements Exception {
  final String message;
  const TechnicianDashboardFailure(this.message);
}

/// Thrown when the device has no active internet connection and no cache.
class DashboardNetworkFailure extends TechnicianDashboardFailure {
  const DashboardNetworkFailure([super.message = "No internet connection. Please check your settings."]);
}

/// Thrown when the backend returns a 500 error or is unreachable.
class DashboardServerFailure extends TechnicianDashboardFailure {
  const DashboardServerFailure(super.message);
}

/// Thrown when the backend returns a 403 (e.g. user is not a technician).
class DashboardPermissionFailure extends TechnicianDashboardFailure {
  const DashboardPermissionFailure([super.message = "You do not have permission to access the technician dashboard."]);
}

/// Thrown when the backend returns unexpected JSON structures that fail to parse.
class DashboardParsingFailure extends TechnicianDashboardFailure {
  const DashboardParsingFailure([super.message = "Failed to parse dashboard data."]);
}

/// Sealed class representing all possible failures when loading the Technician Dashboard.
sealed class TechnicianDashboardFailure implements Exception {
  final String message;
  const TechnicianDashboardFailure(this.message);
}

/// Thrown when the device has no active internet connection and no cache.
class DashboardNetworkFailure extends TechnicianDashboardFailure {
  const DashboardNetworkFailure([
    super.message = "No internet connection. Please check your settings.",
  ]);
}

/// Thrown when the backend returns a 500 error or is unreachable.
class DashboardServerFailure extends TechnicianDashboardFailure {
  const DashboardServerFailure(super.message);
}

/// Thrown when the backend returns a 403 (e.g. user is not a technician).
class DashboardPermissionFailure extends TechnicianDashboardFailure {
  const DashboardPermissionFailure([
    super.message =
        "You do not have permission to access the technician dashboard.",
  ]);
}

/// Thrown when the backend returns unexpected JSON structures that fail to parse.
class DashboardParsingFailure extends TechnicianDashboardFailure {
  const DashboardParsingFailure([
    super.message = "Failed to parse dashboard data.",
  ]);
}

/// Thrown by [TechnicianDashboardRepository.setOnline] when the tech taps
/// online while their wallet balance is strictly negative. Mirrors the
/// backend's 403 `wallet_lockout` envelope (the same one returned by
/// `accept_job_booking` — single shared FE handler).
///
/// Carries the signed balance and the owed-amount so the UI can compose
/// short remediation copy ("Top up Rs. 101 to come online") without
/// client-side math. Both values are PKR integers.
///
/// Going OFFLINE while locked is always allowed and NEVER raises this.
class DashboardWalletLockedFailure extends TechnicianDashboardFailure {
  final int balancePkr;
  final int owedPkr;

  const DashboardWalletLockedFailure({
    required this.balancePkr,
    required this.owedPkr,
  }) : super('Wallet locked due to negative balance.');
}

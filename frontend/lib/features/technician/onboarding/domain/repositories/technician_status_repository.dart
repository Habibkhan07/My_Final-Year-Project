import '../entities/technician_status.dart';

/// Read-only contract for fetching the logged-in user's technician
/// application status.
///
/// Throws [TechStatusUnauthorized] if the auth token is missing/expired,
/// [TechStatusNetworkFailure] if the device is offline,
/// [TechStatusServerFailure] for any other unexpected error.
abstract class TechnicianStatusRepository {
  Future<TechnicianStatus> getMyStatus();
}

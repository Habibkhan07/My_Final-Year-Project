import '../entities/work_location_entity.dart';

/// Read/write contract for the technician's single work location.
///
/// Both methods throw a [WorkLocationFailure] subclass on failure; nothing
/// HTTP-shaped escapes this boundary (CLAUDE.md error-propagation rule).
abstract class IWorkLocationRepository {
  /// Reads the caller's current work location.
  ///
  /// Returns [WorkLocationEntity] with [isSet]=false when the user has no
  /// technician profile or has not yet picked a location.
  ///
  /// Throws:
  /// - [WorkLocationNetworkFailure] on no internet.
  /// - [WorkLocationUnauthorizedFailure] on 401.
  /// - [WorkLocationServerFailure] on 5xx / unexpected.
  /// - [WorkLocationParsingFailure] on bad JSON.
  Future<WorkLocationEntity> getWorkLocation();

  /// Persists the caller's work location and travel radius.
  ///
  /// Throws:
  /// - [WorkLocationValidationFailure] on backend-rejected coords/radius.
  /// - [WorkLocationProfileMissingFailure] on 404 (pure customer).
  /// - [WorkLocationUnauthorizedFailure] on 401.
  /// - [WorkLocationNetworkFailure] on no internet.
  /// - [WorkLocationServerFailure] on 5xx / unexpected.
  /// - [WorkLocationParsingFailure] on bad JSON.
  Future<WorkLocationEntity> saveWorkLocation({
    required double latitude,
    required double longitude,
    int? maxTravelRadiusKm,
    String? workAddressLabel,
  });
}

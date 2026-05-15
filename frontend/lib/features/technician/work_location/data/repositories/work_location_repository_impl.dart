import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/work_location_entity.dart';
import '../../domain/failures/work_location_failure.dart';
import '../../domain/repositories/i_work_location_repository.dart';
import '../data_sources/work_location_remote_data_source.dart';

/// Standard 4-step error pipeline (CLAUDE.md): wire failure -> HttpFailure ->
/// sealed [WorkLocationFailure] subtype -> UI pattern-match.
///
/// No offline cache: the picker requires map tiles which require connectivity,
/// and the dashboard already caches ``has_work_location`` for the banner.
/// Adding a parallel local DS here would buy nothing demo-relevant.
class WorkLocationRepositoryImpl implements IWorkLocationRepository {
  final IWorkLocationRemoteDataSource remote;

  const WorkLocationRepositoryImpl(this.remote);

  @override
  Future<WorkLocationEntity> getWorkLocation() async {
    try {
      final model = await remote.getWorkLocation();
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const WorkLocationNetworkFailure();
    } on FormatException {
      throw const WorkLocationParsingFailure();
    } catch (e) {
      throw WorkLocationServerFailure('Unexpected error: $e');
    }
  }

  @override
  Future<WorkLocationEntity> saveWorkLocation({
    required double latitude,
    required double longitude,
    int? maxTravelRadiusKm,
    String? workAddressLabel,
  }) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        // Always include label key — sending null clears it server-side.
        'work_address_label': workAddressLabel,
      };
      if (maxTravelRadiusKm != null) {
        body['max_travel_radius_km'] = maxTravelRadiusKm;
      }
      final model = await remote.patchWorkLocation(body);
      return model.toEntity();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const WorkLocationNetworkFailure();
    } on FormatException {
      throw const WorkLocationParsingFailure();
    } catch (e) {
      throw WorkLocationServerFailure('Unexpected error: $e');
    }
  }

  WorkLocationFailure _mapFailure(HttpFailure e) {
    if (e.statusCode == 401) {
      return const WorkLocationUnauthorizedFailure();
    }
    if (e.statusCode == 404) {
      return const WorkLocationProfileMissingFailure();
    }
    if (e.statusCode >= 400 && e.statusCode < 500) {
      // Surface the first field error if the backend named one — keeps the
      // toast actionable ("latitude: This field is required") instead of a
      // generic "validation error". Falls back to the envelope message.
      if (e.errors.isNotEmpty) {
        final field = e.errors.keys.first;
        final raw = e.errors[field];
        final first = raw is List && raw.isNotEmpty
            ? raw.first.toString()
            : raw.toString();
        return WorkLocationValidationFailure('$field: $first');
      }
      return WorkLocationValidationFailure(e.message);
    }
    return WorkLocationServerFailure(e.message);
  }
}

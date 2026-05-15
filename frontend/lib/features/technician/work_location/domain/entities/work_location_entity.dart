import 'package:freezed_annotation/freezed_annotation.dart';

part 'work_location_entity.freezed.dart';

/// Contract: Fed by GET / PATCH /api/technicians/me/work-location/.
///
/// One technician owns exactly one work location, persisted on
/// ``TechnicianProfile.{base_latitude, base_longitude, max_travel_radius_km,
/// work_address_label}``. The matchmaker's bounding-box filter reads the lat/lng
/// directly, so [isSet] doubles as "is this tech discoverable on the customer
/// side."
///
/// [latitude] / [longitude] are nullable because pure customers and
/// newly-onboarded techs both have no row to read. The picker screen falls back
/// to device GPS when [isSet] is false.
@freezed
abstract class WorkLocationEntity with _$WorkLocationEntity {
  const factory WorkLocationEntity({
    required bool isSet,
    required int maxTravelRadiusKm,
    double? latitude,
    double? longitude,
    String? workAddressLabel,
  }) = _WorkLocationEntity;
}

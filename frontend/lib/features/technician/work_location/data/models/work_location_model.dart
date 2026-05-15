import '../../domain/entities/work_location_entity.dart';

/// JSON <-> Dart mapping for GET / PATCH /api/technicians/me/work-location/.
///
/// ``has_profile`` is metadata used only by the router; not surfaced on the
/// domain entity. The picker screen never needs to distinguish "pure customer"
/// from "tech with no location set" — it routes the same way for both. The
/// dashboard route already screens pure customers out via the auth shell.
class WorkLocationModel {
  final bool isSet;
  final int maxTravelRadiusKm;
  final double? latitude;
  final double? longitude;
  final String? workAddressLabel;

  const WorkLocationModel({
    required this.isSet,
    required this.maxTravelRadiusKm,
    this.latitude,
    this.longitude,
    this.workAddressLabel,
  });

  factory WorkLocationModel.fromJson(Map<String, dynamic> json) =>
      WorkLocationModel(
        isSet: json['is_set'] as bool? ?? false,
        maxTravelRadiusKm: (json['max_travel_radius_km'] as num?)?.toInt() ?? 10,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        workAddressLabel: json['work_address_label'] as String?,
      );

  WorkLocationEntity toEntity() => WorkLocationEntity(
        isSet: isSet,
        maxTravelRadiusKm: maxTravelRadiusKm,
        latitude: latitude,
        longitude: longitude,
        workAddressLabel: workAddressLabel,
      );
}

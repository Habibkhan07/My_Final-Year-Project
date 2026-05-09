// DTO for the `POST /api/bookings/<id>/tech-location/` request body.
// Wire shape (verified against
// `backend/bookings/api/tech_location/serializers.py:7`):
//   { "lat": float in [-90, 90],
//     "lng": float in [-180, 180],
//     "accuracy_meters": float >= 0  (optional),
//     "heading": float in [0, 360]   (optional) }
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tech_location_request_model.freezed.dart';
part 'tech_location_request_model.g.dart';

@freezed
abstract class TechLocationRequestModel with _$TechLocationRequestModel {
  const factory TechLocationRequestModel({
    required double lat,
    required double lng,
    @JsonKey(name: 'accuracy_meters') double? accuracyMeters,
    double? heading,
  }) = _TechLocationRequestModel;

  factory TechLocationRequestModel.fromJson(Map<String, dynamic> json) =>
      _$TechLocationRequestModelFromJson(json);
}

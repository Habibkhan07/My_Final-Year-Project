// DTO for the `tech_gps` stream payload. Backend wire shape (verified
// against `backend/bookings/api/tech_location/views.py:182`):
//   { "lat": float, "lng": float,
//     "accuracy_meters": float | null,
//     "heading": float | null,
//     "booking_id": int }
//
// The dispatcher passes only `frame['payload']` to handlers, so this
// model parses the payload object — NOT the full stream envelope.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tech_gps_frame_model.freezed.dart';
part 'tech_gps_frame_model.g.dart';

// MODEL-1 (Batch I): defensive `num.toDouble()` coercion at the
// wire boundary. Without these converters, a JSON integer in a
// `double`-typed field (e.g. `lat: 31` from a hand-crafted test
// payload, a misconfigured client, or a debugging tool) crashes
// `_$TechGpsFrameModelFromJson` with a TypeError. The notifier
// catches it and silently drops the frame, so the failure is
// invisible. Coerce here so the integer wire shape is accepted.
double _doubleFromJson(Object? value) =>
    value is num ? value.toDouble() : value as double;
double? _nullableDoubleFromJson(Object? value) {
  if (value == null) return null;
  return value is num ? value.toDouble() : value as double;
}

@freezed
abstract class TechGpsFrameModel with _$TechGpsFrameModel {
  const factory TechGpsFrameModel({
    @JsonKey(name: 'booking_id') required int bookingId,
    @JsonKey(fromJson: _doubleFromJson) required double lat,
    @JsonKey(fromJson: _doubleFromJson) required double lng,
    @JsonKey(name: 'accuracy_meters', fromJson: _nullableDoubleFromJson)
    double? accuracyMeters,
    @JsonKey(fromJson: _nullableDoubleFromJson) double? heading,
  }) = _TechGpsFrameModel;

  factory TechGpsFrameModel.fromJson(Map<String, dynamic> json) =>
      _$TechGpsFrameModelFromJson(json);
}

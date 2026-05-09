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

@freezed
abstract class TechGpsFrameModel with _$TechGpsFrameModel {
  const factory TechGpsFrameModel({
    @JsonKey(name: 'booking_id') required int bookingId,
    required double lat,
    required double lng,
    @JsonKey(name: 'accuracy_meters') double? accuracyMeters,
    double? heading,
  }) = _TechGpsFrameModel;

  factory TechGpsFrameModel.fromJson(Map<String, dynamic> json) =>
      _$TechGpsFrameModelFromJson(json);
}

// Mapper: TechGpsFrameModel (wire DTO) → TechGpsFrame (domain).
//
// The mapper is a pure function for testability. Stamping arrival time
// at the boundary between transport and domain centralises the choice
// in one place — if we ever rewire the dispatcher to pass envelope
// timestamps through, only this file changes.
//
// Audit H5 (S-2): the mapper validates payload bounds. Streams bypass
// the envelope-layer recipient/expiry filters in `SystemEventNotifier`,
// so this mapper is the only place a malformed `tech_gps` payload (e.g.
// a bug on the server side, a man-in-the-middle attempt, or wire
// corruption) gets stopped before it reaches the map widget. Returning
// `null` signals "drop this frame"; the consumer handles it in the
// same path as a JSON-decode failure.
import '../../domain/entities/tech_gps_frame.dart';
import '../models/tech_gps_frame_model.dart';

class TechGpsFrameMapper {
  /// Converts a parsed wire DTO into the domain entity, stamping
  /// arrival time with `DateTime.now()` (the moment the handler
  /// invokes the mapper). [now] is injectable for deterministic tests.
  ///
  /// Returns `null` when the payload fails geographic-bounds validation.
  /// Caller treats this identically to a `fromJson` parse failure
  /// (drop the frame, no state mutation).
  static TechGpsFrame? toDomain(
    TechGpsFrameModel model, {
    DateTime Function()? now,
  }) {
    if (!_isValidLat(model.lat) || !_isValidLng(model.lng)) return null;
    if (!_isValidHeading(model.heading)) return null;

    final stamp = (now ?? DateTime.now)();
    return TechGpsFrame(
      bookingId: model.bookingId,
      latitude: model.lat,
      longitude: model.lng,
      accuracyMeters: model.accuracyMeters,
      heading: model.heading,
      frameArrivedAt: stamp,
    );
  }

  static bool _isValidLat(double lat) =>
      !lat.isNaN && lat >= -90.0 && lat <= 90.0;
  static bool _isValidLng(double lng) =>
      !lng.isNaN && lng >= -180.0 && lng <= 180.0;
  // Heading is optional. When present, geolocator/backend convention is
  // [0, 360) degrees. Allow null; reject NaN and out-of-range.
  static bool _isValidHeading(double? heading) {
    if (heading == null) return true;
    if (heading.isNaN) return false;
    return heading >= 0.0 && heading < 360.0;
  }
}

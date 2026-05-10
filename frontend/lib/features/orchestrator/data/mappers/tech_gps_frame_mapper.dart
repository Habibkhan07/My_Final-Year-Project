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

    // MAP-2 (Batch I): Geolocator on Android occasionally emits 360.0
    // for due-north (instead of normalising to 0.0). Pre-fix the
    // strict-less validator dropped these frames entirely, causing a
    // momentary marker freeze when the tech faced north. Accept the
    // closed interval [0, 360] in the validator and normalise 360 → 0
    // here so widget-side rotation is unambiguous.
    final heading = model.heading;
    final normalisedHeading = heading == null
        ? null
        : (heading == 360.0 ? 0.0 : heading);

    final stamp = (now ?? DateTime.now)();
    return TechGpsFrame(
      bookingId: model.bookingId,
      latitude: model.lat,
      longitude: model.lng,
      accuracyMeters: model.accuracyMeters,
      heading: normalisedHeading,
      frameArrivedAt: stamp,
    );
  }

  // MAP-1 (Batch I): use `isFinite` (rejects NaN AND ±infinity)
  // rather than `isNaN` alone. Pre-fix `+infinity > 90.0` was true
  // (so rejected) but `-infinity < -90.0` was true and rejected by
  // accident; the intent-vs-code coupling was load-bearing. Make the
  // intent explicit so a future bounds-relax doesn't silently let
  // infinity through.
  static bool _isValidLat(double lat) =>
      lat.isFinite && lat >= -90.0 && lat <= 90.0;
  static bool _isValidLng(double lng) =>
      lng.isFinite && lng >= -180.0 && lng <= 180.0;
  // Heading is optional. When present, geolocator/backend convention is
  // [0, 360] degrees. Allow null; reject NaN/infinity and out-of-range.
  // MAP-2 (Batch I): closed interval — 360.0 is normalised to 0.0 in
  // toDomain so it should pass the validator here.
  static bool _isValidHeading(double? heading) {
    if (heading == null) return true;
    if (!heading.isFinite) return false;
    return heading >= 0.0 && heading <= 360.0;
  }
}

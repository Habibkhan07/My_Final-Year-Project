// Mapper: TechGpsFrameModel (wire DTO) → TechGpsFrame (domain).
//
// The mapper is a pure function for testability. Stamping arrival time
// at the boundary between transport and domain centralises the choice
// in one place — if we ever rewire the dispatcher to pass envelope
// timestamps through, only this file changes.
import '../../domain/entities/tech_gps_frame.dart';
import '../models/tech_gps_frame_model.dart';

class TechGpsFrameMapper {
  /// Converts a parsed wire DTO into the domain entity, stamping
  /// arrival time with `DateTime.now()` (the moment the handler
  /// invokes the mapper). [now] is injectable for deterministic tests.
  static TechGpsFrame toDomain(
    TechGpsFrameModel model, {
    DateTime Function()? now,
  }) {
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
}

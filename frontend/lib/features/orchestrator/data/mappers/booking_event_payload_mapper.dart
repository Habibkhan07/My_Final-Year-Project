import '../../../../core/realtime/domain/entities/system_event_entity.dart';
import '../../../../core/realtime/domain/entities/system_event_type.dart';

/// Lightweight extractors for the orchestrator-relevant event payloads.
///
/// Per CLAUDE.md "Per-event feature wiring" — payload models live with
/// the consumer, never in `core/realtime`. The orchestrator screen
/// notifiers call these helpers to filter by job_id / read child id.
class BookingEventPayloadMapper {
  const BookingEventPayloadMapper._();

  /// Extract `job_id` from the event payload. Returns null when the
  /// payload is malformed or doesn't carry a job_id (defensive — a
  /// missing key shouldn't crash the listener; the event is dropped).
  static int? extractJobId(SystemEventEntity event) {
    final raw = event.payload['job_id'];
    if (raw is int) return raw;
    // JSON parsers may surface integer values as `double` depending on
    // representation (`42.0` vs `42`); accept both. Mirrors the same
    // coercion in customer/bookings/data/mappers/booking_event_patch_mapper.
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Extract `child_booking_id` from a `booking_rescheduled` event.
  /// Returns null when the event type is wrong or the key is missing.
  /// The rescheduled-notifier uses this to pushReplacement to the
  /// child booking's orchestrator screen.
  static int? extractChildBookingId(SystemEventEntity event) {
    if (event.eventType != SystemEventType.bookingRescheduled) return null;
    final raw = event.payload['child_booking_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}

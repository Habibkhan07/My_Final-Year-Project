// Contract: fed by the `job_new_request` realtime event.
// Wire spec: `backend/bookings/api/BOOKINGS_API.md` §1.2.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'booking_type.dart';

part 'job_new_request.freezed.dart';

/// A single dispatched job request awaiting the technician's accept/decline.
///
/// Constructed by `JobNewRequestMapper.fromSystemEvent` from a
/// `SystemEventEntity` whose `eventType == SystemEventType.jobNewRequest`.
/// Domain values are typed (no wire-strings); the mapper handles wire→typed
/// translation and the §2.5 backwards-compat defaults.
///
/// Field notes:
///
///   * [payoutRupees] — backend sends an integer-string for parse-fidelity
///     (e.g. `"1200"`); the mapper parses to int once. Widgets format the
///     locale-aware display string.
///
///   * [payoutContext] — Dumb-UI prose the server picks; widgets render it
///     verbatim under the headline payout. Nullable for replayed pre-rollout
///     `EventLog` rows (§2.5); when null, widgets hide the line.
///
///   * [scheduledStart] — UTC. Widgets call `.toLocal()` for display.
///
///   * [expiresAt] — anchored on the event's server [timestamp] (envelope-level)
///     plus `expires_in_seconds`. Receipt-time would skew slightly *later* than
///     the server SLA on slow delivery; anchoring on the server timestamp keeps
///     the technician's countdown in sync with the SLA-timeout Celery task.
@freezed
abstract class JobNewRequest with _$JobNewRequest {
  const factory JobNewRequest({
    required int jobId,
    required String serviceName,
    required BookingType bookingType,
    required int payoutRupees,
    required String? payoutContext,
    required DateTime scheduledStart,
    required DateTime expiresAt,
  }) = _JobNewRequest;
}

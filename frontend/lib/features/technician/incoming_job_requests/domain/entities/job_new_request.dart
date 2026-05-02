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
///
///   * [slaWindow] — the original SLA span (`expires_in_seconds` from the wire
///     payload, rendered as a [Duration]). Required for the countdown ring's
///     color bands (proportion remaining = `(expiresAt - now) / slaWindow`),
///     which need to work for both 60-second ASAP and 15-minute scheduled
///     offers without a hardcoded reference span. Distinct from
///     `expiresAt - scheduledStart` because the SLA window is the technician's
///     decision window, not the time until the booking starts.
///
///   * [locationLabel] — pre-composed locality (e.g. `"Gulberg, Lahore"`)
///     sourced server-side from `CustomerAddress.locality_label`. Null when
///     the booking's address has no structured locality (legacy / pre-rollout
///     row, or address detached via SET_NULL). Widgets render the row only
///     when non-null — no placeholder text. Full street address is never on
///     the wire pre-accept (privacy + anti-poach).
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
    required Duration slaWindow,
    required String? locationLabel,
  }) = _JobNewRequest;
}

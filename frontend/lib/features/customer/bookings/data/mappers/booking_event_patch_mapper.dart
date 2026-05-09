// Realtime list-patch mapper.
//
// Implements **Option (ii)** of the realtime list-patch design (see
// architecture discussion in CUSTOMER_BOOKINGS_API.md §1.6 + §1.7):
// when a `job_accepted` or `booking_rejected` event arrives over the
// WS, the list notifier patches the existing item **client-side**
// using the same status → ui table the server uses, instead of round-
// tripping a detail fetch.
//
// **Why this duplication is acceptable.** The status → ui table is
// small (5 statuses × 3 fields, plus the REJECTED reason discriminator)
// and the wire payload already carries everything the new ui block
// needs (`technician_display_name`, `reason`). Round-tripping a detail
// fetch on every event would cost a network call per status flip —
// worthless for a transition whose outcome is fully determined.
//
// **Drift policy.** The canonical table lives at
// `backend/bookings/selectors/customer_bookings_selector._resolve_ui_block`.
// When copy or tone changes there, this file MUST change in lockstep.
// The CUSTOMER_BOOKINGS_API.md §1.7 entry is the human-readable
// authority both sides defer to.
//
// **Forward-compat.** New event types that mutate booking state
// (`quote_generated`, `quote_approved`, `job_completed`, etc.) will
// add additional `apply…` static methods here. The ui block for those
// states becomes the place we add their rows to the table.
import '../../../../../core/realtime/domain/entities/system_event_entity.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/booking_ui_tone.dart';
import '../../domain/entities/customer_booking.dart';

class BookingEventPatchMapper {
  BookingEventPatchMapper._();

  /// `payload.job_id` — the booking id on which the event acts.
  /// Returns null when the field is missing or non-int.
  static int? jobIdFromPayload(SystemEventEntity event) {
    final raw = event.payload['job_id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Apply the `job_accepted` transition to an existing card.
  ///
  /// Wire payload fields used:
  ///   * `technician_display_name` — overrides the local display name
  ///     (the booking might have been created with a stale name; the
  ///     event carries the freshest value at accept time).
  ///   * `service_name` — falls through to the existing service name
  ///     when missing (older payloads or a partial replay).
  static CustomerBooking applyJobAccepted(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    final payload = event.payload;
    final newName =
        (payload['technician_display_name'] as String?) ??
        current.technician.displayName;

    return current.copyWith(
      status: BookingStatus.confirmed,
      technician: current.technician.copyWith(displayName: newName),
      ui: BookingUi(
        badgeText: 'Confirmed',
        badgeTone: BookingUiTone.positive,
        headline: 'Confirmed with $newName',
      ),
    );
  }

  /// Apply the `booking_rejected` transition to an existing card. The
  /// `reason` payload field discriminates `technician_declined` from
  /// `sla_timeout` for the headline + badge copy.
  ///
  /// Wire payload fields used:
  ///   * `reason` — `"technician_declined"` (or unknown) → "Unavailable"
  ///     copy; `"sla_timeout"` → "Timed out" copy.
  ///   * `technician_id` is also on the payload but unused here — the
  ///     existing `technician` block stays put; it's the same tech
  ///     either way.
  static CustomerBooking applyBookingRejected(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    final payload = event.payload;
    final reason = payload['reason'] as String?;
    final techName = current.technician.displayName;

    BookingUi nextUi;
    if (reason == 'sla_timeout') {
      nextUi = BookingUi(
        badgeText: 'Timed out',
        badgeTone: BookingUiTone.negative,
        headline: "$techName didn't respond in time",
      );
    } else {
      // technician_declined OR unknown / missing → same copy. Mirrors
      // the server's _resolve_ui_block fallback policy.
      nextUi = BookingUi(
        badgeText: 'Unavailable',
        badgeTone: BookingUiTone.negative,
        headline: "$techName couldn't take this",
      );
    }

    return current.copyWith(status: BookingStatus.rejected, ui: nextUi);
  }

  // ─── Booking-orchestrator v1 transitions (sprint session 3) ─────────────
  //
  // These mirror the orchestrator's status → ui table on the list-card
  // surface. The detail screen renders far richer copy via its own
  // `ui` block; here we only need the badge + one-line headline.
  // Drift policy: when backend's `customer_bookings_selector._resolve_ui_block`
  // changes copy for the new statuses, update here in lockstep.

  /// `booking_cancelled` — applies to `cancel_by_customer`,
  /// `cancel_by_tech`, and the parent leg of a reschedule. The list
  /// row goes to CANCELLED with neutral tone.
  static CustomerBooking applyBookingCancelled(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    return current.copyWith(
      status: BookingStatus.cancelled,
      ui: const BookingUi(
        badgeText: 'Cancelled',
        badgeTone: BookingUiTone.neutral,
        headline: 'This booking was cancelled',
      ),
    );
  }

  /// `booking_no_show` — `actor` payload field discriminates which side
  /// failed to show; copy reflects the perspective.
  static CustomerBooking applyBookingNoShow(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    final actor = event.payload['actor']?.toString();
    final headline = actor == 'customer'
        ? 'Marked as no-show'
        : "${current.technician.displayName} did not show";
    return current.copyWith(
      status: BookingStatus.noShow,
      ui: BookingUi(
        badgeText: 'No-show',
        badgeTone: BookingUiTone.negative,
        headline: headline,
      ),
    );
  }

  /// `quote_declined` — booking transitions to `COMPLETED_INSPECTION_ONLY`.
  /// Customer paid the inspection fee; no further work is being done.
  static CustomerBooking applyQuoteDeclined(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    return current.copyWith(
      status: BookingStatus.completedInspectionOnly,
      ui: const BookingUi(
        badgeText: 'Inspection only',
        badgeTone: BookingUiTone.neutral,
        headline: 'You declined the quote',
      ),
    );
  }

  /// `job_completed` — terminal happy-path. Cash is collected, work
  /// is done. The `final_amount` payload field could surface in the
  /// headline if we wanted; for v1 we keep the copy generic so the
  /// header stays consistent across the bookings list.
  static CustomerBooking applyJobCompleted(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    final techName = current.technician.displayName;
    return current.copyWith(
      status: BookingStatus.completed,
      ui: BookingUi(
        badgeText: 'Completed',
        badgeTone: BookingUiTone.positive,
        headline: '$techName finished the job',
      ),
    );
  }

  /// `booking_rescheduled` — the original booking goes to CANCELLED;
  /// the child appears via list refresh on next pull. We surface the
  /// reschedule lineage in the headline so the customer recognises why
  /// the row is no longer active.
  static CustomerBooking applyBookingRescheduled(
    CustomerBooking current,
    SystemEventEntity event,
  ) {
    return current.copyWith(
      status: BookingStatus.cancelled,
      ui: const BookingUi(
        badgeText: 'Rescheduled',
        badgeTone: BookingUiTone.neutral,
        headline: 'Moved to a new time slot',
      ),
    );
  }
}

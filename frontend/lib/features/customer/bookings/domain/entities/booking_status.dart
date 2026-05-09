/// Status of a [CustomerBooking] AND the orchestrator screen's booking.
///
/// Wire values come from the backend's `JobBooking.STATUS_*` enum (see
/// `backend/bookings/models.py`). The mapper translates wire strings to
/// this enum at the data-layer boundary; domain code never sees the
/// raw string.
///
/// Booking-orchestrator v1 (sprint session 3) adds 8 lifecycle statuses:
/// `enRoute`, `arrived`, `inspecting`, `quoted`, `inProgress`,
/// `completedInspectionOnly`, `noShow`, `disputed`. These are post-CONFIRMED
/// states the orchestrator screen drives the user through. The bookings
/// list keeps the same enum — list rows render the new statuses via the
/// server's `ui` block, no list-side branching needed.
///
/// `pending` is a legacy value preserved for choices compatibility — no
/// current code path persists it (migration 0007 removed the only
/// transition). It is kept here so an unexpected legacy row deserializes
/// cleanly instead of falling into [BookingStatus.unknown].
///
/// `unknown` is the safety net for forward-compat: a status string the
/// backend ships in a future release maps here so existing clients
/// don't crash. The status → ui table always returns *something* for an
/// unknown row, so the card still renders.
enum BookingStatus {
  awaiting,
  confirmed,
  enRoute,
  arrived,
  inspecting,
  quoted,
  inProgress,
  completed,
  completedInspectionOnly,
  cancelled,
  rejected,
  noShow,
  disputed,
  pending,
  unknown;

  static const Map<String, BookingStatus> _wireLookup = {
    'AWAITING': BookingStatus.awaiting,
    'CONFIRMED': BookingStatus.confirmed,
    'EN_ROUTE': BookingStatus.enRoute,
    'ARRIVED': BookingStatus.arrived,
    'INSPECTING': BookingStatus.inspecting,
    'QUOTED': BookingStatus.quoted,
    'IN_PROGRESS': BookingStatus.inProgress,
    'COMPLETED': BookingStatus.completed,
    'COMPLETED_INSPECTION_ONLY': BookingStatus.completedInspectionOnly,
    'CANCELLED': BookingStatus.cancelled,
    'REJECTED': BookingStatus.rejected,
    'NO_SHOW': BookingStatus.noShow,
    'DISPUTED': BookingStatus.disputed,
    'PENDING': BookingStatus.pending,
  };

  static BookingStatus fromWire(String? raw) {
    if (raw == null) return BookingStatus.unknown;
    return _wireLookup[raw.toUpperCase()] ?? BookingStatus.unknown;
  }

  /// Wire string for outbound use (e.g. status csv filter on requests).
  String get wireValue {
    switch (this) {
      case BookingStatus.awaiting:
        return 'AWAITING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.enRoute:
        return 'EN_ROUTE';
      case BookingStatus.arrived:
        return 'ARRIVED';
      case BookingStatus.inspecting:
        return 'INSPECTING';
      case BookingStatus.quoted:
        return 'QUOTED';
      case BookingStatus.inProgress:
        return 'IN_PROGRESS';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.completedInspectionOnly:
        return 'COMPLETED_INSPECTION_ONLY';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.rejected:
        return 'REJECTED';
      case BookingStatus.noShow:
        return 'NO_SHOW';
      case BookingStatus.disputed:
        return 'DISPUTED';
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.unknown:
        return '';
    }
  }
}

/// Status of a [CustomerBooking].
///
/// Wire values come from the backend's `JobBooking.STATUS_*` enum (see
/// `backend/bookings/models.py`). The mapper translates wire strings to
/// this enum at the data-layer boundary; domain code never sees the
/// raw string.
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
  completed,
  cancelled,
  rejected,
  pending,
  unknown;

  static const Map<String, BookingStatus> _wireLookup = {
    'AWAITING': BookingStatus.awaiting,
    'CONFIRMED': BookingStatus.confirmed,
    'COMPLETED': BookingStatus.completed,
    'CANCELLED': BookingStatus.cancelled,
    'REJECTED': BookingStatus.rejected,
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
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.rejected:
        return 'REJECTED';
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.unknown:
        return '';
    }
  }
}

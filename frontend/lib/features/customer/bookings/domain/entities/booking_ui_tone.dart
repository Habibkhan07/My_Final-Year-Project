/// Semantic tone of a booking card's status pill.
///
/// The card widget switches on this enum to pick a design token —
/// never on the raw [BookingStatus]. This is the boundary the dumb-UI
/// principle draws: server says "negative", client picks the red token
/// from the theme. New states the backend invents ship without a
/// client release because the tone vocabulary stays small.
///
/// Wire values: see `CUSTOMER_BOOKINGS_API.md` §1.7. Mirrored in
/// `customer_bookings_selector._resolve_ui_block` on the backend.
enum BookingUiTone {
  positive,
  warning,
  negative,
  neutral,
  info,
  unknown;

  static const Map<String, BookingUiTone> _wireLookup = {
    'positive': BookingUiTone.positive,
    'warning': BookingUiTone.warning,
    'negative': BookingUiTone.negative,
    'neutral': BookingUiTone.neutral,
    'info': BookingUiTone.info,
  };

  static BookingUiTone fromWire(String? raw) {
    if (raw == null) return BookingUiTone.unknown;
    return _wireLookup[raw.toLowerCase()] ?? BookingUiTone.unknown;
  }
}

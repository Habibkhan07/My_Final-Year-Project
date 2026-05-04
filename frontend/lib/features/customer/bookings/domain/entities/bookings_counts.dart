// Contract: fed by `GET /api/bookings/counts/`.
// Wire spec: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §2.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookings_counts.freezed.dart';

/// Segmented-control badge counts. Two cheap COUNT(*) on the server.
///
/// `upcoming + past` is NOT necessarily equal to the customer's total
/// bookings — the `past` count includes "still CONFIRMED but
/// scheduled_end is in the past" rows that effectively aged out without
/// a formal completion event. This deliberate asymmetry aligns with
/// the user's mental model of each tab.
@freezed
abstract class BookingsCounts with _$BookingsCounts {
  const factory BookingsCounts({
    required int upcoming,
    required int past,
    required DateTime serverTime,
  }) = _BookingsCounts;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_cash_collection.freezed.dart';

/// Cash-collection state for the booking. Populated when the technician
/// taps "Cash collected" on the IN_PROGRESS screen — `mark_complete_with_cash`
/// stamps amount + at and the booking flips to COMPLETED.
///
/// Method is currently always `'cash'` (sprint v1; v2 may add JazzCash for
/// gig-economy direct charge per future flag). The orchestrator screen
/// surfaces the amount on the completion summary card.
@freezed
abstract class BookingCashCollection with _$BookingCashCollection {
  const factory BookingCashCollection({
    int? amount,
    DateTime? at,
    @Default('cash') String method,
  }) = _BookingCashCollection;
}

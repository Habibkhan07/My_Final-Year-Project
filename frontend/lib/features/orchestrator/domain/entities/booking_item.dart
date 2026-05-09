import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_item.freezed.dart';

/// A line item the customer accepted on quote-approval — snapshotted from
/// the approved quote's [BookingQuoteLineItem] so historical bookings
/// survive sub-service catalog changes (rename, deletion, price updates).
///
/// `priceCharged` and `lineTotal` come off the wire as Decimal-strings;
/// the mapper coerces to integer rupees.
@freezed
abstract class BookingItem with _$BookingItem {
  const factory BookingItem({
    required int id,
    required int subServiceId,
    required String subServiceName,
    required int quantity,
    required int priceCharged,
    required int lineTotal,
    int? sourcedQuoteId,
  }) = _BookingItem;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_quote.freezed.dart';

/// A single revision of the technician's quote. Multiple may exist for a
/// booking (revision dance: customer requests revision → prior SUBMITTED
/// becomes SUPERSEDED, fresh one is SUBMITTED). The orchestrator screen
/// shows the active quote (latest SUBMITTED, falling back to most recent).
///
/// `totalAmount` and `pricedAt` come off the wire as Decimal-strings
/// (`"1500.00"`); the data mapper coerces to integer rupees once at the
/// boundary. Pakistan market has no paisa — no precision lost.
@freezed
abstract class BookingQuote with _$BookingQuote {
  const factory BookingQuote({
    required int id,
    required int bookingId,
    required int revisionNumber,
    required BookingQuoteStatus status,
    required int totalAmount,
    required bool isUpsell,
    required List<BookingQuoteLineItem> lineItems,
    DateTime? submittedAt,
  }) = _BookingQuote;
}

@freezed
abstract class BookingQuoteLineItem with _$BookingQuoteLineItem {
  const factory BookingQuoteLineItem({
    required int id,
    required int subServiceId,
    required String subServiceName,
    required int quantity,
    required int pricedAt,
    required int lineTotal,
  }) = _BookingQuoteLineItem;
}

enum BookingQuoteStatus {
  draft,
  submitted,
  approved,
  declined,
  superseded,
  unknown;

  static BookingQuoteStatus fromWire(String? raw) => switch (raw) {
    'DRAFT' => BookingQuoteStatus.draft,
    'SUBMITTED' => BookingQuoteStatus.submitted,
    'APPROVED' => BookingQuoteStatus.approved,
    'DECLINED' => BookingQuoteStatus.declined,
    'SUPERSEDED' => BookingQuoteStatus.superseded,
    _ => BookingQuoteStatus.unknown,
  };
}

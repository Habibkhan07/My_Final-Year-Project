// Wire models for `Quote` + `QuoteLineItem`.
// Source of truth: `backend/bookings/api/BOOKINGS_API.md` §5.
//
// `total_amount`, `priced_at`, `line_total` are wire-strings (Decimals)
// here — the mapper coerces to integer rupees. Keeping the DTO faithful
// means cache round-trips don't lose / re-format precision.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_quote_model.freezed.dart';
part 'booking_quote_model.g.dart';

@freezed
abstract class BookingQuoteModel with _$BookingQuoteModel {
  const factory BookingQuoteModel({
    required int id,
    @JsonKey(name: 'booking_id') required int bookingId,
    @JsonKey(name: 'revision_number') required int revisionNumber,
    required String status,
    @JsonKey(name: 'total_amount') required String totalAmount,
    @JsonKey(name: 'is_upsell') required bool isUpsell,
    @JsonKey(name: 'line_items') required List<BookingQuoteLineItemModel> lineItems,
    @JsonKey(name: 'submitted_at') String? submittedAt,
  }) = _BookingQuoteModel;

  factory BookingQuoteModel.fromJson(Map<String, dynamic> json) =>
      _$BookingQuoteModelFromJson(json);
}

@freezed
abstract class BookingQuoteLineItemModel with _$BookingQuoteLineItemModel {
  const factory BookingQuoteLineItemModel({
    required int id,
    @JsonKey(name: 'sub_service_id') required int subServiceId,
    @JsonKey(name: 'sub_service_name') required String subServiceName,
    required int quantity,
    @JsonKey(name: 'priced_at') required String pricedAt,
    @JsonKey(name: 'line_total') required String lineTotal,
  }) = _BookingQuoteLineItemModel;

  factory BookingQuoteLineItemModel.fromJson(Map<String, dynamic> json) =>
      _$BookingQuoteLineItemModelFromJson(json);
}

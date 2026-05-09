// Wire model for accepted `BookingItem` (snapshot of approved quote line).
// Source of truth: `backend/bookings/api/BOOKINGS_API.md` §6.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_item_model.freezed.dart';
part 'booking_item_model.g.dart';

@freezed
abstract class BookingItemModel with _$BookingItemModel {
  const factory BookingItemModel({
    required int id,
    @JsonKey(name: 'sub_service_id') required int subServiceId,
    @JsonKey(name: 'sub_service_name') required String subServiceName,
    required int quantity,
    @JsonKey(name: 'price_charged') required String priceCharged,
    @JsonKey(name: 'line_total') required String lineTotal,
    @JsonKey(name: 'sourced_quote_id') int? sourcedQuoteId,
  }) = _BookingItemModel;

  factory BookingItemModel.fromJson(Map<String, dynamic> json) =>
      _$BookingItemModelFromJson(json);
}

// Wire envelope for `GET /api/bookings/`.
// Source of truth: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §1.4.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'customer_booking_model.dart';

part 'bookings_list_response_model.freezed.dart';
part 'bookings_list_response_model.g.dart';

@freezed
abstract class BookingsListResponseModel with _$BookingsListResponseModel {
  const factory BookingsListResponseModel({
    required List<CustomerBookingModel> items,
    @JsonKey(name: 'next_cursor') required String? nextCursor,
    @JsonKey(name: 'has_more') required bool hasMore,
    @JsonKey(name: 'server_time') required String serverTime,
  }) = _BookingsListResponseModel;

  factory BookingsListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$BookingsListResponseModelFromJson(json);
}

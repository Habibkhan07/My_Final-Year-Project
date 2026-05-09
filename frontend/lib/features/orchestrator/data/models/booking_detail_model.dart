// Wire model for the orchestrator detail response.
// Source of truth: `backend/bookings/api/BOOKINGS_API.md` §8 +
// `backend/bookings/api/booking_detail/serializers.py`.
//
// All Decimal-fields (`base_price`, `inspection_fee`, etc.) come off
// the wire as strings (`"500.00"`); the mapper coerces to integer
// rupees. Datetimes are ISO-8601 strings here, parsed in the mapper.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'booking_item_model.dart';
import 'booking_quote_model.dart';
import 'booking_ui_block_model.dart';

part 'booking_detail_model.freezed.dart';
part 'booking_detail_model.g.dart';

@freezed
abstract class BookingDetailModel with _$BookingDetailModel {
  const factory BookingDetailModel({
    required int id,
    required String status,
    required BookingDetailServiceModel service,
    @JsonKey(name: 'sub_service') BookingDetailSubServiceModel? subService,
    required BookingDetailTechnicianModel technician,
    required BookingDetailCustomerModel customer,
    BookingDetailAddressModel? address,
    @JsonKey(name: 'address_snapshot') required String addressSnapshot,
    @JsonKey(name: 'scheduled_start') required String scheduledStart,
    @JsonKey(name: 'scheduled_end') required String scheduledEnd,
    @JsonKey(name: 'phase_timestamps')
    required BookingDetailPhaseTimestampsModel phaseTimestamps,
    required BookingDetailPricingModel pricing,
    @JsonKey(name: 'cash_collection')
    required BookingDetailCashCollectionModel cashCollection,
    @JsonKey(name: 'parent_booking_id') int? parentBookingId,
    @JsonKey(name: 'child_booking_id') int? childBookingId,
    @JsonKey(name: 'cancel_reason') String? cancelReason,
    @JsonKey(name: 'no_show_actor') String? noShowActor,
    @JsonKey(name: 'active_quote') BookingQuoteModel? activeQuote,
    @JsonKey(name: 'booking_items')
    @Default(<BookingItemModel>[])
    List<BookingItemModel> bookingItems,
    @JsonKey(name: 'open_tickets_count') @Default(0) int openTicketsCount,
    required BookingUiBlockModel ui,
    @JsonKey(name: 'available_transitions')
    @Default(<String>[])
    List<String> availableTransitions,
  }) = _BookingDetailModel;

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailModelFromJson(json);
}

@freezed
abstract class BookingDetailServiceModel with _$BookingDetailServiceModel {
  const factory BookingDetailServiceModel({
    required int id,
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _BookingDetailServiceModel;

  factory BookingDetailServiceModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailServiceModelFromJson(json);
}

@freezed
abstract class BookingDetailSubServiceModel
    with _$BookingDetailSubServiceModel {
  const factory BookingDetailSubServiceModel({
    required int id,
    required String name,
    @JsonKey(name: 'is_fixed_price') required bool isFixedPrice,
    // Decimal on the wire (e.g. "500.00"). Mapper coerces to int rupees.
    @JsonKey(name: 'base_price') required String basePrice,
    @JsonKey(name: 'max_price') String? maxPrice,
  }) = _BookingDetailSubServiceModel;

  factory BookingDetailSubServiceModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailSubServiceModelFromJson(json);
}

@freezed
abstract class BookingDetailTechnicianModel
    with _$BookingDetailTechnicianModel {
  const factory BookingDetailTechnicianModel({
    required int id,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'profile_picture_url') String? profilePictureUrl,
  }) = _BookingDetailTechnicianModel;

  factory BookingDetailTechnicianModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailTechnicianModelFromJson(json);
}

@freezed
abstract class BookingDetailCustomerModel with _$BookingDetailCustomerModel {
  const factory BookingDetailCustomerModel({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'phone_no') required String phoneNo,
  }) = _BookingDetailCustomerModel;

  factory BookingDetailCustomerModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailCustomerModelFromJson(json);
}

@freezed
abstract class BookingDetailAddressModel with _$BookingDetailAddressModel {
  const factory BookingDetailAddressModel({
    required String label,
    // Lat/lng are Decimal-strings on the wire (`"31.520400"`). Parsed
    // to double in the mapper.
    required String latitude,
    required String longitude,
    @JsonKey(name: 'address_text') required String addressText,
  }) = _BookingDetailAddressModel;

  factory BookingDetailAddressModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailAddressModelFromJson(json);
}

@freezed
abstract class BookingDetailPhaseTimestampsModel
    with _$BookingDetailPhaseTimestampsModel {
  const factory BookingDetailPhaseTimestampsModel({
    @JsonKey(name: 'accepted_at') String? acceptedAt,
    @JsonKey(name: 'en_route_started_at') String? enRouteStartedAt,
    @JsonKey(name: 'arrived_at') String? arrivedAt,
    @JsonKey(name: 'inspection_started_at') String? inspectionStartedAt,
    @JsonKey(name: 'quote_first_submitted_at') String? quoteFirstSubmittedAt,
    @JsonKey(name: 'work_started_at') String? workStartedAt,
    @JsonKey(name: 'completed_at') String? completedAt,
  }) = _BookingDetailPhaseTimestampsModel;

  factory BookingDetailPhaseTimestampsModel.fromJson(
    Map<String, dynamic> json,
  ) => _$BookingDetailPhaseTimestampsModelFromJson(json);
}

@freezed
abstract class BookingDetailPricingModel with _$BookingDetailPricingModel {
  const factory BookingDetailPricingModel({
    @JsonKey(name: 'inspection_fee') String? inspectionFee,
    @JsonKey(name: 'base_services_total') String? baseServicesTotal,
    @JsonKey(name: 'discount_applied') String? discountApplied,
    @JsonKey(name: 'final_cash_to_collect') String? finalCashToCollect,
    @JsonKey(name: 'promo_code_snapshot') String? promoCodeSnapshot,
    @JsonKey(name: 'promo_discount_snapshot') String? promoDiscountSnapshot,
  }) = _BookingDetailPricingModel;

  factory BookingDetailPricingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingDetailPricingModelFromJson(json);
}

@freezed
abstract class BookingDetailCashCollectionModel
    with _$BookingDetailCashCollectionModel {
  const factory BookingDetailCashCollectionModel({
    String? amount,
    String? at,
    @Default('cash') String method,
  }) = _BookingDetailCashCollectionModel;

  factory BookingDetailCashCollectionModel.fromJson(
    Map<String, dynamic> json,
  ) => _$BookingDetailCashCollectionModelFromJson(json);
}

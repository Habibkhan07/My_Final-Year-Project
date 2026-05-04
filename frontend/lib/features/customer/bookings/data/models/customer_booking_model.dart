// Wire model for a single booking row in the list response.
// Source of truth: `backend/bookings/api/CUSTOMER_BOOKINGS_API.md` §1.4.
//
// Faithful to the wire — no domain types, no defaults applied here. The
// mapper (`customer_booking_mapper.dart`) translates wire strings to
// typed domain values + applies fallbacks for nullable fields. Keeping
// this model dumb means the local cache round-trips through the same
// JSON shape the network returns.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer_booking_model.freezed.dart';
part 'customer_booking_model.g.dart';

@freezed
abstract class CustomerBookingModel with _$CustomerBookingModel {
  const factory CustomerBookingModel({
    required int id,
    required String status,
    required BookingServiceModel service,
    required BookingTechnicianModel technician,
    @JsonKey(name: 'address_label') required String? addressLabel,
    @JsonKey(name: 'scheduled_start') required String scheduledStart,
    @JsonKey(name: 'scheduled_end') required String scheduledEnd,
    @JsonKey(name: 'created_at') required String createdAt,
    required BookingPriceModel price,
    required BookingUiModel ui,
  }) = _CustomerBookingModel;

  factory CustomerBookingModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerBookingModelFromJson(json);
}

@freezed
abstract class BookingServiceModel with _$BookingServiceModel {
  const factory BookingServiceModel({
    required String name,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _BookingServiceModel;

  factory BookingServiceModel.fromJson(Map<String, dynamic> json) =>
      _$BookingServiceModelFromJson(json);
}

@freezed
abstract class BookingTechnicianModel with _$BookingTechnicianModel {
  const factory BookingTechnicianModel({
    required int id,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'profile_picture_url') required String? profilePictureUrl,
  }) = _BookingTechnicianModel;

  factory BookingTechnicianModel.fromJson(Map<String, dynamic> json) =>
      _$BookingTechnicianModelFromJson(json);
}

@freezed
abstract class BookingPriceModel with _$BookingPriceModel {
  const factory BookingPriceModel({
    required int amount,
    required String context,
    @JsonKey(name: 'ui_label') required String uiLabel,
  }) = _BookingPriceModel;

  factory BookingPriceModel.fromJson(Map<String, dynamic> json) =>
      _$BookingPriceModelFromJson(json);
}

@freezed
abstract class BookingUiModel with _$BookingUiModel {
  const factory BookingUiModel({
    @JsonKey(name: 'badge_text') required String badgeText,
    @JsonKey(name: 'badge_tone') required String badgeTone,
    required String headline,
  }) = _BookingUiModel;

  factory BookingUiModel.fromJson(Map<String, dynamic> json) =>
      _$BookingUiModelFromJson(json);
}

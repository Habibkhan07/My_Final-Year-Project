/// Data models for the Booking feature.
///
/// All models are co-located in one file because they share the same
/// part declarations and are only used together in the booking data layer.
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/booking_entities.dart';

part 'booking_models.freezed.dart';
part 'booking_models.g.dart';

// ---------------------------------------------------------------------------
// Technician Profile Detail (GET /api/customers/technician-profile/{id}/)
// ---------------------------------------------------------------------------

@freezed
abstract class TechnicianSkillModel with _$TechnicianSkillModel {
  const factory TechnicianSkillModel({
    required String name,
    // Nullable: backend sends null when SubService.icon_name is unset in Admin.
    @JsonKey(name: 'icon_name') required String? iconName,
  }) = _TechnicianSkillModel;

  factory TechnicianSkillModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianSkillModelFromJson(json);

  const TechnicianSkillModel._();

  TechnicianSkillEntity toEntity() =>
      TechnicianSkillEntity(name: name, iconName: iconName);
}

@freezed
abstract class TechnicianReviewModel with _$TechnicianReviewModel {
  const factory TechnicianReviewModel({
    @JsonKey(name: 'reviewer_name') required String reviewerName,
    required int rating,
    required String text,
  }) = _TechnicianReviewModel;

  factory TechnicianReviewModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianReviewModelFromJson(json);

  const TechnicianReviewModel._();

  TechnicianReviewEntity toEntity() => TechnicianReviewEntity(
    reviewerName: reviewerName,
    rating: rating,
    text: text,
  );
}

@freezed
abstract class TechnicianProfileModel with _$TechnicianProfileModel {
  const factory TechnicianProfileModel({
    required int id,
    @JsonKey(name: 'full_name') required String fullName,
    required String city,
    @JsonKey(name: 'profile_picture') required String? profilePicture,
    @JsonKey(name: 'rating_average') required double ratingAverage,
    @JsonKey(name: 'review_count') required int reviewCount,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'bayesian_score') double? bayesianScore,
    @JsonKey(name: 'is_active') required bool isActive,
    @JsonKey(name: 'ui_rating_text') required String uiRatingText,
    @JsonKey(name: 'primary_price') required String primaryPrice,
    @JsonKey(name: 'primary_price_raw') required String primaryPriceRaw,
    @JsonKey(name: 'price_context') required String priceContext,
    @JsonKey(name: 'promo_tag') String? promoTag,
    required List<TechnicianSkillModel> skills,
    @JsonKey(name: 'recent_reviews')
    required List<TechnicianReviewModel> recentReviews,
  }) = _TechnicianProfileModel;

  factory TechnicianProfileModel.fromJson(Map<String, dynamic> json) =>
      _$TechnicianProfileModelFromJson(json);

  const TechnicianProfileModel._();

  TechnicianProfileEntity toEntity() => TechnicianProfileEntity(
    id: id,
    fullName: fullName,
    city: city,
    profilePicture: profilePicture,
    ratingAverage: ratingAverage,
    reviewCount: reviewCount,
    distanceKm: distanceKm,
    bayesianScore: bayesianScore,
    isActive: isActive,
    uiRatingText: uiRatingText,
    primaryPrice: primaryPrice,
    primaryPriceRaw: primaryPriceRaw,
    priceContext: priceContext,
    promoTag: promoTag,
    skills: skills.map((s) => s.toEntity()).toList(),
    recentReviews: recentReviews.map((r) => r.toEntity()).toList(),
  );
}

// ---------------------------------------------------------------------------
// Availability (GET /api/customers/technicians/{id}/availability/)
// ---------------------------------------------------------------------------

/// Maps a single availability slot from the backend JSON array.
@freezed
abstract class AvailabilitySlotModel with _$AvailabilitySlotModel {
  const factory AvailabilitySlotModel({
    @JsonKey(name: 'time_string') required String timeString,

    /// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
    @JsonKey(name: 'iso_start') required String isoStart,

    /// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
    @JsonKey(name: 'iso_end') required String isoEnd,

    required String period,
  }) = _AvailabilitySlotModel;

  factory AvailabilitySlotModel.fromJson(Map<String, dynamic> json) =>
      _$AvailabilitySlotModelFromJson(json);

  const AvailabilitySlotModel._();

  AvailabilitySlotEntity toEntity() => AvailabilitySlotEntity(
    timeString: timeString,
    isoStart: isoStart,
    isoEnd: isoEnd,
    period: period,
  );
}

// ---------------------------------------------------------------------------
// Instant Book — Request (POST /api/bookings/instant-book/)
// ---------------------------------------------------------------------------

/// Outgoing POST body. Use [toJson] to build the request payload.
///
/// `includeIfNull: false` keeps optional FKs (`sub_service_id`, `promotion_id`)
/// off the wire when null, matching the backend's four-scenario contract
/// (Scenario A/B/C/D in BOOKINGS_API.md).
///
/// `price_amount` is no longer on the wire — the server derives the figure
/// from the resolved catalog references + technician skill row and stamps
/// it onto the booking.
@freezed
abstract class InstantBookingRequestModel with _$InstantBookingRequestModel {
  const factory InstantBookingRequestModel({
    @JsonKey(name: 'technician_id') required int technicianId,
    @JsonKey(name: 'address_id') required int addressId,

    /// Parent service the customer was browsing. Threaded from the discovery
    /// URL (search match, gig tile, category tile, promo banner).
    @JsonKey(name: 'service_id') required int serviceId,

    /// Specific sub-service for fixed-price gigs (Scenario A) or labor matches
    /// from search (Scenario B). Omit for parent-category / inspection.
    @JsonKey(name: 'sub_service_id', includeIfNull: false) int? subServiceId,

    /// Set only when the customer arrived via a promo banner. Forbidden with
    /// a fixed-price [subServiceId] — the server rejects that combo, and the
    /// presentation layer also blocks it defensively to save a round trip.
    @JsonKey(name: 'promotion_id', includeIfNull: false) int? promotionId,

    /// Pass [AvailabilitySlotEntity.isoStart] directly — no conversion.
    @JsonKey(name: 'scheduled_start') required String scheduledStart,

    /// Pass [AvailabilitySlotEntity.isoEnd] directly — no conversion.
    @JsonKey(name: 'scheduled_end') required String scheduledEnd,
  }) = _InstantBookingRequestModel;

  factory InstantBookingRequestModel.fromJson(Map<String, dynamic> json) =>
      _$InstantBookingRequestModelFromJson(json);
}

// ---------------------------------------------------------------------------
// Instant Book — Response (POST /api/bookings/instant-book/ → 201)
// ---------------------------------------------------------------------------

/// Incoming response: {"booking_id": 123}
@freezed
abstract class InstantBookingResponseModel with _$InstantBookingResponseModel {
  const factory InstantBookingResponseModel({
    @JsonKey(name: 'booking_id') required int bookingId,
  }) = _InstantBookingResponseModel;

  factory InstantBookingResponseModel.fromJson(Map<String, dynamic> json) =>
      _$InstantBookingResponseModelFromJson(json);

  const InstantBookingResponseModel._();

  CreatedBookingEntity toEntity() => CreatedBookingEntity(bookingId: bookingId);
}

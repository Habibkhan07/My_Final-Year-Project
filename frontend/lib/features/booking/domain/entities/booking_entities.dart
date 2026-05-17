/// Domain entities for the Booking feature.
///
/// Fed by:
///   - [TechnicianProfileEntity]: GET /api/customers/technician-profile/{id}/
///   - [AvailabilitySlotEntity]: GET /api/customers/technicians/{id}/availability/
///   - [CreatedBookingEntity]:   POST /api/bookings/instant-book/
///   - [SavedAddressEntity]:     GET /api/customers/addresses/
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_entities.freezed.dart';

@freezed
abstract class TechnicianSkillEntity with _$TechnicianSkillEntity {
  const factory TechnicianSkillEntity({
    required String name,
    // Nullable: SubService.icon_name is null=True in the DB; backend sends null
    // when icon is not set in Django Admin. Flutter maps non-null values to
    // assets/icons/{iconName}.svg via IconAssets.path().
    required String? iconName,
  }) = _TechnicianSkillEntity;
}

@freezed
abstract class TechnicianReviewEntity with _$TechnicianReviewEntity {
  const factory TechnicianReviewEntity({
    required String reviewerName,
    required int rating,
    required String text,
  }) = _TechnicianReviewEntity;
}

@freezed
abstract class TechnicianProfileEntity with _$TechnicianProfileEntity {
  const factory TechnicianProfileEntity({
    required int id,
    required String fullName,
    required String city,
    required String? profilePicture,
    required double ratingAverage,
    required int reviewCount,
    required double? distanceKm,
    required double? bayesianScore,
    required bool isActive,

    // Dumb UI Pricing and Texts
    required String uiRatingText,
    required String primaryPrice,
    required String primaryPriceRaw,
    required String priceContext,
    required String? promoTag,

    required List<TechnicianSkillEntity> skills,
    required List<TechnicianReviewEntity> recentReviews,
  }) = _TechnicianProfileEntity;
}

/// A single available time slot returned by the availability endpoint.
///
/// [isoStart] and [isoEnd] are stored as raw strings because they are passed
/// verbatim back to POST /api/bookings/instant-book/ — no timezone conversion needed.
@freezed
abstract class AvailabilitySlotEntity with _$AvailabilitySlotEntity {
  const factory AvailabilitySlotEntity({
    /// Human-readable label for the slot picker UI (e.g. "9:00 AM").
    required String timeString,

    /// ISO 8601 PKT-aware start time. Pass directly to [scheduledStart].
    required String isoStart,

    /// ISO 8601 PKT-aware end time. Pass directly to [scheduledEnd].
    required String isoEnd,

    /// "AM" or "PM" — used to group slots into sections in the picker.
    required String period,
  }) = _AvailabilitySlotEntity;
}

/// The response from a successful instant booking creation.
///
/// [bookingId] must be cached in Tier 3 (SharedPreferences) immediately after
/// receipt so the Active Job Screen can be restored on crash recovery.
@freezed
abstract class CreatedBookingEntity with _$CreatedBookingEntity {
  const factory CreatedBookingEntity({required int bookingId}) =
      _CreatedBookingEntity;
}

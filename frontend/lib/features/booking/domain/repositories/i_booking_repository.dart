import '../entities/booking_entities.dart';

/// Contract for all booking-related data operations.
///
/// Both the customer-facing (create booking) and technician-facing (manage
/// bookings) use cases depend on this interface — never on the implementation.
abstract class IBookingRepository {
  /// Fetches the technician profile details for the customer view.
  ///
  /// [id] — TechnicianProfile pk.
  /// [lat], [lng] — Customer's location for distance calculation.
  /// [serviceId] — Parent category being browsed (contextual pricing).
  /// [subServiceId] — Specific gig tapped (contextual pricing).
  /// [promotionId] — Active promo banner.
  ///
  /// Throws [BookingFailure] on network or server errors.
  Future<TechnicianProfileEntity> getTechnicianProfile({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  });

  /// Fetches available time slots for a technician on a given date.
  ///
  /// [technicianId] — TechnicianProfile pk.
  /// [date]         — Calendar date in "YYYY-MM-DD" format.
  /// [serviceId]    — Optional: drives job duration via Service.default_duration_minutes.
  /// [subServiceId] — Optional: takes precedence over [serviceId] for duration.
  ///
  /// Returns an empty list (not an error) when the technician has no schedule
  /// for that day or is fully booked.
  ///
  /// Throws [BookingFailure] on network or server errors.
  Future<List<AvailabilitySlotEntity>> getAvailability({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  });

  /// Creates a confirmed instant booking.
  ///
  /// [scheduledStart] and [scheduledEnd] must be the [AvailabilitySlotEntity.isoStart]
  /// and [AvailabilitySlotEntity.isoEnd] values — pass them through verbatim.
  ///
  /// [serviceId] is the parent category the customer was browsing — required.
  /// [subServiceId] is the specific gig (omit for parent-category / inspection bookings).
  /// [promotionId] is set only when the customer arrived via a promo banner.
  /// Pairing [promotionId] with a fixed-price [subServiceId] is rejected by the
  /// server's promo firewall — callers should block that combo locally too.
  ///
  /// Throws [BookingFailure] on any failure. The caller is responsible for
  /// caching [CreatedBookingEntity.bookingId] in Tier 3 for crash recovery.
  Future<CreatedBookingEntity> createInstantBooking({
    required int technicianId,
    required int addressId,
    required int serviceId,
    int? subServiceId,
    int? promotionId,
    required String scheduledStart,
    required String scheduledEnd,
    required String priceAmount,
  });

}

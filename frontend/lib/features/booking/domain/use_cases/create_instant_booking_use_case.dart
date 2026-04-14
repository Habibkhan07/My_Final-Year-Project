import '../entities/booking_entities.dart';
import '../repositories/i_booking_repository.dart';

/// Creates a confirmed instant booking after the customer selects a slot.
///
/// The caller (Notifier) must cache [CreatedBookingEntity.bookingId] in Tier 3
/// immediately after a successful result for crash recovery.
///
/// Throws [BookingFailure] on any failure.
class CreateInstantBookingUseCase {
  final IBookingRepository repository;

  CreateInstantBookingUseCase(this.repository);

  Future<CreatedBookingEntity> call({
    required int technicianId,
    required int addressId,
    required String scheduledStart,
    required String scheduledEnd,
    required String priceAmount,
    String priceContext = '',
  }) {
    return repository.createInstantBooking(
      technicianId: technicianId,
      addressId: addressId,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      priceAmount: priceAmount,
      priceContext: priceContext,
    );
  }
}

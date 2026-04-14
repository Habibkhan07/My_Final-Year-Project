import '../entities/booking_entities.dart';
import '../repositories/i_booking_repository.dart';

/// Fetches available time slots for a technician on a given date.
///
/// Thin delegate — all error mapping is in [IBookingRepository].
/// Throws [BookingFailure] on any failure.
class GetAvailabilityUseCase {
  final IBookingRepository repository;

  GetAvailabilityUseCase(this.repository);

  Future<List<AvailabilitySlotEntity>> call({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) {
    return repository.getAvailability(
      technicianId: technicianId,
      date: date,
      serviceId: serviceId,
      subServiceId: subServiceId,
    );
  }
}

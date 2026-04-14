import '../entities/booking_entities.dart';
import '../repositories/i_booking_repository.dart';

/// Fetches the technician profile details for the customer view.
///
/// Thin delegate — all error mapping is in [IBookingRepository].
/// Throws [BookingFailure] on any failure.
class GetTechnicianProfileUseCase {
  final IBookingRepository repository;

  GetTechnicianProfileUseCase(this.repository);

  Future<TechnicianProfileEntity> call({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) {
    return repository.getTechnicianProfile(
      id: id,
      lat: lat,
      lng: lng,
      serviceId: serviceId,
      subServiceId: subServiceId,
      promotionId: promotionId,
    );
  }
}

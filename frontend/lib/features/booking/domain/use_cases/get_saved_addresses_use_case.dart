import '../entities/booking_entities.dart';
import '../repositories/i_booking_repository.dart';

/// Fetches the authenticated customer's saved addresses.
///
/// Thin delegate — all error mapping is in [IBookingRepository].
/// Throws [BookingFailure] on any failure.
class GetSavedAddressesUseCase {
  final IBookingRepository repository;

  GetSavedAddressesUseCase(this.repository);

  Future<List<SavedAddressEntity>> call() {
    return repository.getSavedAddresses();
  }
}

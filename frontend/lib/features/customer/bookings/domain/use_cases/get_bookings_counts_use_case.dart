import '../entities/bookings_counts.dart';
import '../repositories/customer_bookings_repository.dart';

/// Single-method use case wrapping [ICustomerBookingsRepository.getCounts].
class GetBookingsCountsUseCase {
  final ICustomerBookingsRepository _repository;

  const GetBookingsCountsUseCase(this._repository);

  Future<BookingsCounts> call() => _repository.getCounts();
}

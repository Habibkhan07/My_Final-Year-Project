import '../entities/booking_segment.dart';
import '../entities/booking_status.dart';
import '../entities/bookings_page.dart';
import '../repositories/customer_bookings_repository.dart';

/// Single-method use case wrapping [ICustomerBookingsRepository.getBookings].
///
/// Exists for layering symmetry with the rest of the feature — the
/// notifier reads the use case rather than the repository directly so
/// CLAUDE.md's Clean Architecture rules stay consistent across features.
/// No additional logic lives here today; if a future filter needs to be
/// derived from app-wide state (e.g., a "show only my favorite techs"
/// toggle), this is the right place.
class GetCustomerBookingsUseCase {
  final ICustomerBookingsRepository _repository;

  const GetCustomerBookingsUseCase(this._repository);

  Future<BookingsPage> call({
    required BookingSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) =>
      _repository.getBookings(
        segment: segment,
        statusFilter: statusFilter,
        cursor: cursor,
        pageSize: pageSize,
      );
}

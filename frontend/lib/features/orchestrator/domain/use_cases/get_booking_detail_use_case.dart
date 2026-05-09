import '../entities/booking_detail.dart';
import '../repositories/booking_detail_repository.dart';

/// Thin wrapper around the repository. Exists for symmetry with the rest
/// of the codebase's clean-architecture layering and to give the screen
/// a single use-case dependency rather than raw repository access.
class GetBookingDetailUseCase {
  final IBookingDetailRepository _repository;

  const GetBookingDetailUseCase(this._repository);

  Future<BookingDetail> call(int bookingId) =>
      _repository.getBookingDetail(bookingId);
}

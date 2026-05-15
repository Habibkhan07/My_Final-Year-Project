import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../entities/scheduled_job_segment.dart';
import '../entities/scheduled_jobs_page.dart';
import '../repositories/scheduled_jobs_repository.dart';

/// Single-method use case wrapping [IScheduledJobsRepository.getScheduledJobs].
///
/// Exists for layering symmetry — the notifier reads the use case
/// rather than the repository directly so CLAUDE.md's Clean Architecture
/// rules stay consistent across features.
class GetScheduledJobsUseCase {
  final IScheduledJobsRepository _repository;

  const GetScheduledJobsUseCase(this._repository);

  Future<ScheduledJobsPage> call({
    required ScheduledJobSegment segment,
    List<BookingStatus>? statusFilter,
    String? cursor,
    int pageSize = 20,
  }) => _repository.getScheduledJobs(
    segment: segment,
    statusFilter: statusFilter,
    cursor: cursor,
    pageSize: pageSize,
  );
}

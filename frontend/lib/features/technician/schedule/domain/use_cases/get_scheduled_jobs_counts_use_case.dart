import '../entities/scheduled_jobs_counts.dart';
import '../repositories/scheduled_jobs_repository.dart';

/// Single-method use case wrapping [IScheduledJobsRepository.getCounts].
class GetScheduledJobsCountsUseCase {
  final IScheduledJobsRepository _repository;

  const GetScheduledJobsCountsUseCase(this._repository);

  Future<ScheduledJobsCounts> call() => _repository.getCounts();
}

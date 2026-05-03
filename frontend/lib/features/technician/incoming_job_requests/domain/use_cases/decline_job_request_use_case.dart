import '../repositories/incoming_job_repository.dart';

/// Declines a dispatched job offer on behalf of the authenticated technician.
///
/// Mirror of [AcceptJobRequestUseCase] — see that class for the rationale
/// behind the per-action use-case split.
///
/// Throws [IncomingJobFailure] subtypes — see [IIncomingJobRepository].
class DeclineJobRequestUseCase {
  final IIncomingJobRepository _repository;

  const DeclineJobRequestUseCase(this._repository);

  Future<void> call(int jobId) => _repository.declineJobRequest(jobId);
}

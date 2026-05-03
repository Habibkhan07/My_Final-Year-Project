import '../repositories/incoming_job_repository.dart';

/// Accepts a dispatched job offer on behalf of the authenticated technician.
///
/// Thin wrapper over the repository — kept as a distinct type so the
/// notifier depends on the use case (single-purpose object) rather than
/// the broader repository interface (multi-purpose). When the action set
/// grows (e.g. an "I'm on the way" milestone), the new use case slots in
/// next to this one without forcing the notifier to import the full
/// repository surface.
///
/// Throws [IncomingJobFailure] subtypes — see [IIncomingJobRepository].
class AcceptJobRequestUseCase {
  final IIncomingJobRepository _repository;

  const AcceptJobRequestUseCase(this._repository);

  Future<void> call(int jobId) => _repository.acceptJobRequest(jobId);
}

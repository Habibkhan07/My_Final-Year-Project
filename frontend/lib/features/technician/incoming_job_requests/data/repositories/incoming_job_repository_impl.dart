import 'dart:io';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/failures/incoming_job_failure.dart';
import '../../domain/repositories/incoming_job_repository.dart';
import '../datasources/incoming_job_remote_data_source.dart';

/// Maps the standard HTTP error envelope to the typed [IncomingJobFailure]
/// hierarchy — step 2 of the 4-step error pipeline (CLAUDE.md). Both
/// accept and decline route through [_execute] so the failure switch lives
/// in exactly one place; a future divergence in their wire contracts
/// should bring its own mapper rather than fork this one.
class IncomingJobRepositoryImpl implements IIncomingJobRepository {
  final IIncomingJobRemoteDataSource _remote;

  IncomingJobRepositoryImpl(this._remote);

  @override
  Future<void> acceptJobRequest(int jobId) =>
      _execute(() => _remote.acceptJobRequest(jobId));

  @override
  Future<void> declineJobRequest(int jobId) =>
      _execute(() => _remote.declineJobRequest(jobId));

  /// Wraps a remote call with the standard exception-translation pipeline:
  ///
  ///   1. [HttpFailure] → typed sealed [IncomingJobFailure] via [_mapFailure].
  ///   2. [SocketException] → [IncomingJobNetworkFailure] (offline path).
  ///   3. anything else → [UnknownIncomingJobFailure] (catch-all).
  Future<void> _execute(Future<void> Function() call) async {
    try {
      await call();
    } on HttpFailure catch (e) {
      throw _mapFailure(e);
    } on SocketException {
      throw const IncomingJobNetworkFailure();
    } on IncomingJobFailure {
      // A nested layer (e.g. a future interceptor) may have already mapped
      // — let it propagate verbatim instead of double-wrapping it as
      // UnknownIncomingJobFailure.
      rethrow;
    } catch (e) {
      throw UnknownIncomingJobFailure(e.toString());
    }
  }

  /// Wire-code → typed-failure switch.
  ///
  /// The 404 collapse is intentional: the backend deliberately returns
  /// `404 not_found` for both "booking missing" and "booking not assigned
  /// to this technician" to avoid an enumeration leak. Both cases map to
  /// the same UX outcome — the offer is gone, remove it from the queue.
  IncomingJobFailure _mapFailure(HttpFailure failure) {
    if (failure.statusCode == 409 &&
        failure.code == 'booking_no_longer_available') {
      // The 409 envelope echoes the live row state in
      // `errors.current_status` (a list per the standard envelope shape).
      // Defensively cope with either a list or a bare string.
      final raw = failure.errors['current_status'];
      String? currentStatus;
      if (raw is List && raw.isNotEmpty) {
        currentStatus = raw.first.toString();
      } else if (raw is String) {
        currentStatus = raw;
      }
      return OfferNoLongerAvailable(
        currentStatus: currentStatus,
        message: failure.message.isNotEmpty
            ? failure.message
            : 'This job is no longer available.',
      );
    }
    if (failure.statusCode == 404) {
      // IDOR-safe: missing OR wrong-owner. UX outcome is identical.
      return const OfferNoLongerAvailable();
    }
    if (failure.statusCode >= 500) {
      return const IncomingJobServerFailure();
    }
    return UnknownIncomingJobFailure(failure.message);
  }
}

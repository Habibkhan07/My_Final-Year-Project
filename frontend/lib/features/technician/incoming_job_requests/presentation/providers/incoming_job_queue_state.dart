// State for the incoming job request queue. Held in
// `IncomingJobQueueNotifier`; consumed by `IncomingJobRequestScreen`.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/job_new_request.dart';

part 'incoming_job_queue_state.freezed.dart';

/// Pending job requests the technician hasn't accepted or declined yet.
///
/// `queue` order is FIFO arrival — the oldest pending request is at index 0.
/// The widget layer is free to sort by `expiresAt` for display, but the
/// underlying queue is append-only this sprint (eviction sweep is deferred —
/// see `INCOMING_JOB_REQUESTS_FEATURE.md`).
@freezed
abstract class IncomingJobQueueState with _$IncomingJobQueueState {
  const factory IncomingJobQueueState({
    @Default(<JobNewRequest>[]) List<JobNewRequest> queue,
  }) = _IncomingJobQueueState;
}

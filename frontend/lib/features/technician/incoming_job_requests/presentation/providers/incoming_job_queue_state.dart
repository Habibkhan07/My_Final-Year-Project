// State for the incoming job request queue. Held in
// `IncomingJobQueueNotifier`; consumed by `IncomingJobRequestScreen`.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/job_new_request.dart';

part 'incoming_job_queue_state.freezed.dart';

/// Pending job requests the technician hasn't accepted or declined yet.
///
/// `queue` order is head-sticky priority (head = `queue.first`); see
/// the notifier's class doc for the full ordering contract.
///
/// `inFlightJobIds` tracks offers whose accept/decline HTTP request is
/// currently in flight. The host gates two things on this set:
///   * Accept/Decline button taps are no-ops while the offer is in
///     flight (prevents double-tap from queuing a second HTTP call).
///   * The local SLA expiry callback (`_handleExpire`) is suppressed
///     for in-flight offers so the card does not pop out from under
///     the user mid-request — the server's response is the only thing
///     that resolves the offer once a tap has landed.
@freezed
abstract class IncomingJobQueueState with _$IncomingJobQueueState {
  const factory IncomingJobQueueState({
    @Default(<JobNewRequest>[]) List<JobNewRequest> queue,
    @Default(<int>{}) Set<int> inFlightJobIds,
  }) = _IncomingJobQueueState;
}

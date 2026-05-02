// Per-event subscriber for `job_new_request`.
//
// Architectural pattern: see CLAUDE.md → "Per-event feature wiring". This
// notifier is the only thing in the codebase that knows how `SystemEventEntity`
// envelopes become `JobNewRequest` domain entries. `core/realtime` stays
// audience-agnostic; the screen reads typed state from this provider rather
// than parsing GoRouter `extra`.
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../data/mappers/job_new_request_mapper.dart';
import '../../domain/entities/job_new_request.dart';
import 'incoming_job_queue_state.dart';

part 'incoming_job_queue_notifier.g.dart';

/// Holds every `job_new_request` event observed since wake-up.
///
/// `keepAlive: true` is load-bearing: the notifier MUST be subscribed to
/// `systemEventProvider` BEFORE any event arrives. The `AppLifecycleOrchestrator`
/// performs an eager `ref.read(...)` in `bootAfterAuth` for exactly this reason —
/// otherwise an event landing during the WS connect cascade would be missed
/// because `ref.listen` only fires on transitions that occur after subscription.
///
/// Dedup belt-and-suspenders: `SystemEventNotifier` already dedupes by event id
/// (so the same broadcast arriving via WS + FCM is filtered upstream); the
/// per-`jobId` guard here covers the unlikely case of a re-broadcast with a
/// fresh event id for the same booking.
@Riverpod(keepAlive: true)
class IncomingJobQueueNotifier extends _$IncomingJobQueueNotifier {
  static const _logName =
      'features.technician.incoming_job_requests.queue';

  @override
  IncomingJobQueueState build() {
    ref.listen(systemEventProvider, (previous, next) {
      final event = next.latestEvent;
      if (event == null) return;
      // Same id-equality guard the orchestrator uses — `SystemEventState`
      // mutates on dedup-map prunes too, and we only want to react to the
      // arrival of a NEW event, not to housekeeping rebuilds.
      if (previous?.latestEvent?.id == event.id) return;
      if (event.eventType != SystemEventType.jobNewRequest) return;

      final request = JobNewRequestMapper.fromSystemEvent(event);
      if (request == null) return; // mapper logged the reason

      if (state.queue.any((j) => j.jobId == request.jobId)) {
        log(
          'Duplicate job_new_request for jobId=${request.jobId}; skipping.',
          name: _logName,
        );
        return;
      }

      state = state.copyWith(queue: [...state.queue, request]);
    });

    return const IncomingJobQueueState();
  }

  /// Removes a request from the queue. Called by the screen when the
  /// technician dismisses, declines, or accepts a request. Accept/decline
  /// remote calls land in a separate sprint — until then, this is the only
  /// way an entry leaves the queue.
  void removeRequest(int jobId) {
    final next = state.queue.where((j) => j.jobId != jobId).toList();
    if (next.length == state.queue.length) return;
    state = state.copyWith(queue: next);
  }

  /// **Preview-only.** Injects a fully-formed [JobNewRequest] into the queue,
  /// bypassing the wire mapper. Used by `lib/preview/incoming_job_preview.dart`
  /// to demo the sheet without standing up the full backend → WS → mapper
  /// pipeline. Mirrors the dedup behavior of the real ingest path so seeding
  /// the same `jobId` twice is a no-op.
  ///
  /// Do NOT call this from production code — it does not represent a real
  /// realtime event and will not produce ACK/sync side effects. Real events
  /// flow through `ref.listen(systemEventProvider, ...)` above.
  void debugSeedRequest(JobNewRequest request) {
    if (state.queue.any((j) => j.jobId == request.jobId)) return;
    state = state.copyWith(queue: [...state.queue, request]);
  }
}

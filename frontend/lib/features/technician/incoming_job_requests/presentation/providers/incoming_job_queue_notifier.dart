// Per-event subscriber for `job_new_request`.
//
// Architectural pattern: see CLAUDE.md → "Per-event feature wiring". This
// notifier is the only thing in the codebase that knows how `SystemEventEntity`
// envelopes become `JobNewRequest` domain entries. `core/realtime` stays
// audience-agnostic; the screen reads typed state from this provider rather
// than parsing GoRouter `extra`.
//
// **Queue ordering — head-sticky priority.**
//
// `state.queue` is a list whose contract is:
//
//   * `queue.first` is the HEAD — the offer the technician is currently
//     looking at. Once an offer becomes the head it CANNOT be displaced by
//     a newer, more-urgent arrival. This is load-bearing for the swipe
//     widget — a swap mid-decision would mean the user's finger lands on a
//     different offer than the one they intended to accept, which is the
//     dominant footgun the serialized one-offer pivot exists to prevent.
//
//   * `queue.skip(1)` is the TAIL. Order in the tail is not maintained on
//     every event arrival (newcomers are appended) because the only time
//     the tail's order matters is when the head resolves and the next head
//     must be picked. At that moment, [removeRequest] re-sorts the tail by
//     current urgency (`remaining / slaWindow` ascending) before promoting
//     the most-urgent to the new head.
//
// **Why fraction-of-SLA, not absolute remaining seconds.** A 60-second
// remaining out of a 5-minute SLA window is more urgent (20% left) than a
// 60-second remaining out of a 60-minute SLA window (1.7% left? — wait,
// actually that's *less* urgent in the second case). The point is: an
// absolute-seconds comparison would mis-rank an ASAP offer with a tight
// SLA against a long-scheduled offer with a wide SLA. The fraction is the
// honest urgency metric across heterogeneous SLA windows. With the
// backend's 5-minute floor (see flag.md), all SLAs are at least 5 min,
// but the fraction comparison still matters when SLAs differ within the
// queue.
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/domain/entities/system_event_type.dart';
import '../../../../../core/realtime/presentation/notifiers/system_event_notifier.dart';
import '../../data/mappers/job_new_request_mapper.dart';
import '../../domain/entities/job_new_request.dart';
import '../../domain/failures/incoming_job_failure.dart';
import '../state/job_action_result.dart';
import 'dependency_injection.dart';
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

      // Head-sticky append: if the queue was empty this becomes the head;
      // otherwise the head at queue[0] stays and this joins the tail. The
      // tail is not pre-sorted on arrival because [removeRequest] does the
      // sort lazily at the only moment it matters — when the head resolves
      // and the next head is picked.
      state = state.copyWith(queue: [...state.queue, request]);
    });

    return const IncomingJobQueueState();
  }

  /// Removes a request from the queue. Called when the technician accepts,
  /// declines, or lets the offer expire.
  ///
  /// If the removed request is the HEAD, the next head is selected by
  /// re-sorting the tail by current urgency (smallest `remaining/slaWindow`
  /// first) and promoting the most-urgent. If the removed request is in the
  /// tail, the head stays put and the tail loses one entry.
  ///
  /// Unknown jobId → silent no-op (matches the prior contract; defensive
  /// against double-remove from accept-then-expire-races).
  void removeRequest(int jobId) {
    final queue = state.queue;
    if (queue.isEmpty) return;

    if (queue.first.jobId == jobId) {
      // Head removal — drop any already-expired tail entries first, then
      // promote the most-urgent of what remains. Without the filter, an
      // expired tail entry would have fraction = 0 (most urgent under the
      // ascending sort) and briefly promote to head before the swipe
      // widget's onExpire callback popped it again — a visible flicker.
      final now = DateTime.now();
      final alive = queue
          .skip(1)
          .where((j) => j.expiresAt.isAfter(now))
          .toList();
      if (alive.isEmpty) {
        state = state.copyWith(queue: const []);
        return;
      }
      alive.sort(
        (a, b) => _urgencyFraction(a, now).compareTo(_urgencyFraction(b, now)),
      );
      state = state.copyWith(queue: alive);
      return;
    }

    // Non-head removal — just filter.
    final filtered = queue.where((j) => j.jobId != jobId).toList();
    if (filtered.length == queue.length) return;
    state = state.copyWith(queue: filtered);
  }

  /// Accept the offer with [jobId] via the remote endpoint.
  ///
  /// Concurrency contract:
  ///   * Adds [jobId] to `inFlightJobIds` for the duration of the request.
  ///   * A second concurrent call for the same [jobId] short-circuits with
  ///     [JobActionAlreadyInFlight] and does NOT dispatch a second HTTP call.
  ///     The host gates button taps on the same set, so this guard is
  ///     defense-in-depth.
  ///   * On [JobActionSuccess] / [JobActionConflict], the offer is removed
  ///     from the local queue (the server is the source of truth — the
  ///     offer is gone either way).
  ///   * On retryable failures ([JobActionNetworkFailure] /
  ///     [JobActionUnexpectedFailure]), the offer stays in the queue.
  ///
  /// The `try/finally` clears the in-flight entry even on unexpected
  /// throws — the host renders button-enabled state from the in-flight set,
  /// so a leaked entry would lock the offer permanently.
  Future<JobActionResult> accept(int jobId) =>
      _runAction(jobId, ref.read(acceptJobRequestUseCaseProvider).call);

  /// Decline the offer with [jobId]. Same contract as [accept] — the
  /// server's idempotent same-tech retry on REJECTED also covers the
  /// SLA-fired-first race (end state matches intent → success, no
  /// removal-from-queue surprise).
  Future<JobActionResult> decline(int jobId) =>
      _runAction(jobId, ref.read(declineJobRequestUseCaseProvider).call);

  Future<JobActionResult> _runAction(
    int jobId,
    Future<void> Function(int) call,
  ) async {
    if (state.inFlightJobIds.contains(jobId)) {
      return const JobActionAlreadyInFlight();
    }
    state = state.copyWith(
      inFlightJobIds: {...state.inFlightJobIds, jobId},
    );

    try {
      await call(jobId);
      _removeJobAndClearInFlight(jobId);
      return const JobActionSuccess();
    } on OfferNoLongerAvailable catch (e) {
      _removeJobAndClearInFlight(jobId);
      return JobActionConflict(e);
    } on IncomingJobNetworkFailure catch (e) {
      _clearInFlight(jobId);
      return JobActionNetworkFailure(e);
    } on IncomingJobFailure catch (e) {
      _clearInFlight(jobId);
      return JobActionUnexpectedFailure(e);
    } catch (e) {
      // Any non-IncomingJobFailure throw — should be rare since the
      // repository wraps everything, but defend against an interceptor
      // that throws an untyped exception.
      _clearInFlight(jobId);
      return JobActionUnexpectedFailure(
        UnknownIncomingJobFailure(e.toString()),
      );
    }
  }

  /// Removes [jobId] from the queue (using the same head-promotion logic
  /// as [removeRequest]) and clears the in-flight entry in a single state
  /// mutation so a Riverpod listener never observes "removed but still
  /// in-flight" or "still queued but no longer in-flight".
  void _removeJobAndClearInFlight(int jobId) {
    final nextInFlight = {...state.inFlightJobIds}..remove(jobId);
    final queue = state.queue;
    if (queue.isEmpty) {
      state = state.copyWith(inFlightJobIds: nextInFlight);
      return;
    }

    if (queue.first.jobId == jobId) {
      final now = DateTime.now();
      final alive = queue
          .skip(1)
          .where((j) => j.expiresAt.isAfter(now))
          .toList();
      if (alive.isEmpty) {
        state = state.copyWith(
          queue: const [],
          inFlightJobIds: nextInFlight,
        );
        return;
      }
      alive.sort(
        (a, b) => _urgencyFraction(a, now).compareTo(_urgencyFraction(b, now)),
      );
      state = state.copyWith(queue: alive, inFlightJobIds: nextInFlight);
      return;
    }

    final filtered = queue.where((j) => j.jobId != jobId).toList();
    state = state.copyWith(
      queue: filtered.length == queue.length ? queue : filtered,
      inFlightJobIds: nextInFlight,
    );
  }

  void _clearInFlight(int jobId) {
    if (!state.inFlightJobIds.contains(jobId)) return;
    final next = {...state.inFlightJobIds}..remove(jobId);
    state = state.copyWith(inFlightJobIds: next);
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

  /// Urgency metric — smaller is more urgent. The fraction of the SLA window
  /// still remaining: 0.0 at expiry, 1.0 at fresh dispatch. A non-positive
  /// `slaWindow` (which the backend's 5-min floor prevents) returns 0.0
  /// (most-urgent) defensively rather than silently degrading to "least
  /// urgent" via a divide-by-zero NaN.
  static double _urgencyFraction(JobNewRequest r, DateTime now) {
    final span = r.slaWindow.inMilliseconds;
    if (span <= 0) return 0.0;
    final remainingMs = r.expiresAt.difference(now).inMilliseconds;
    if (remainingMs <= 0) return 0.0;
    final f = remainingMs / span;
    return f.clamp(0.0, 1.0);
  }
}

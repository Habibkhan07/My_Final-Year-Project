import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

/// Builds a `SystemEventEntity` for the `job_new_request` event type with a
/// fixed-past timestamp. Used by tests that don't care about urgency
/// (insertion / dedup / filter).
SystemEventEntity _event({
  required String id,
  required int jobId,
  String rawType = 'job_new_request',
  DateTime? timestamp,
  int expiresInSeconds = 60,
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: rawType,
    targetRoleStr: 'technician',
    timestamp: timestamp ?? DateTime.utc(2026, 4, 27, 20, 14, 42),
    payload: <String, dynamic>{
      'job_id': jobId,
      'service_name': 'AC Deep Wash',
      'booking_type': 'FIXED_GIG',
      'scheduled_start_iso': '2026-04-08T05:00:00Z',
      'payout': '1200',
      'payout_context': 'Fixed-price gig — full payout',
      'expires_in_seconds': expiresInSeconds,
    },
  );
}

/// Builds a `SystemEventEntity` whose `expiresAt` lands in the future
/// relative to the test's current wall clock — needed for any test that
/// asserts about urgency (`remaining / slaWindow`). Pass `agedBy` to make
/// the offer "older" (already-elapsed time since dispatch); the
/// `expiresInSeconds` minus that age is the remaining at test time.
SystemEventEntity _liveEvent({
  required String id,
  required int jobId,
  required int expiresInSeconds,
  Duration agedBy = Duration.zero,
}) {
  final now = DateTime.now().toUtc();
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: 'job_new_request',
    targetRoleStr: 'technician',
    timestamp: now.subtract(agedBy),
    payload: <String, dynamic>{
      'job_id': jobId,
      'service_name': 'AC Deep Wash',
      'booking_type': 'FIXED_GIG',
      'scheduled_start_iso': '2026-04-08T05:00:00Z',
      'payout': '1200',
      'payout_context': 'Fixed-price gig — full payout',
      'expires_in_seconds': expiresInSeconds,
    },
  );
}

ProviderContainer _buildContainer(EventLocalDataSource local) {
  final container = ProviderContainer(
    overrides: [
      eventLocalDataSourceProvider.overrideWithValue(local),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockLocal local;

  setUp(() {
    local = _MockLocal();
    when(() => local.getLastSyncTimestamp()).thenReturn(null);
  });

  group('IncomingJobQueueNotifier — basic ingest', () {
    test('initial state has an empty queue', () {
      final container = _buildContainer(local);

      final state = container.read(incomingJobQueueProvider);

      expect(state.queue, isEmpty);
    });

    test(
      'wakes via ref.read and appends a jobNewRequest event to the queue',
      () {
        final container = _buildContainer(local);
        // Wake-up — mirrors what AppLifecycleOrchestrator.bootAfterAuth does.
        container.read(incomingJobQueueProvider);

        container.read(systemEventProvider.notifier).processEvent(
              _event(id: 'e1', jobId: 1),
            );

        final queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 1);
        expect(queue.single.jobId, 1);
      },
    );

    test('events of other types do not enter the queue', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);

      container.read(systemEventProvider.notifier).processEvent(
            _event(id: 'e1', jobId: 99, rawType: 'payment_received'),
          );

      expect(container.read(incomingJobQueueProvider).queue, isEmpty);
    });

    test(
      'same jobId across two distinct event ids → defensive dedup keeps one',
      () {
        // SystemEventNotifier already dedupes by event id; this test exercises
        // the per-jobId belt-and-suspenders guard inside the queue notifier
        // for a hypothetical re-broadcast with a regenerated event id.
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container.read(systemEventProvider.notifier).processEvent(
              _event(
                id: 'e1',
                jobId: 7,
                timestamp: DateTime.utc(2026, 4, 27, 20, 14, 42),
              ),
            );
        container.read(systemEventProvider.notifier).processEvent(
              _event(
                id: 'e2',
                jobId: 7,
                timestamp: DateTime.utc(2026, 4, 27, 20, 14, 43),
              ),
            );

        final queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 1);
        expect(queue.single.jobId, 7);
      },
    );

    test(
      'malformed payload (non-numeric payout) is silently dropped — '
      'queue stays empty, no throw into the dispatcher',
      () {
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        final bad = SystemEventEntity.fromComponents(
          id: 'e1',
          rawType: 'job_new_request',
          targetRoleStr: 'technician',
          timestamp: DateTime.utc(2026, 4, 27, 20, 14, 42),
          payload: const <String, dynamic>{
            'job_id': 1,
            'service_name': 'AC Deep Wash',
            'booking_type': 'FIXED_GIG',
            'scheduled_start_iso': '2026-04-08T05:00:00Z',
            'payout': 'twelve hundred',
            'payout_context': 'Fixed-price gig — full payout',
            'expires_in_seconds': 60,
          },
        );

        expect(
          () => container
              .read(systemEventProvider.notifier)
              .processEvent(bad),
          returnsNormally,
        );
        expect(container.read(incomingJobQueueProvider).queue, isEmpty);
      },
    );
  });

  group('IncomingJobQueueNotifier — head-sticky priority ordering', () {
    test(
      'first arrival becomes the head; second arrival joins the tail in '
      'arrival order',
      () {
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container.read(systemEventProvider.notifier).processEvent(
              _event(
                id: 'e1',
                jobId: 1,
                timestamp: DateTime.utc(2026, 4, 27, 20, 14, 42),
              ),
            );
        container.read(systemEventProvider.notifier).processEvent(
              _event(
                id: 'e2',
                jobId: 2,
                timestamp: DateTime.utc(2026, 4, 27, 20, 14, 43),
              ),
            );

        final queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 2);
        expect(queue[0].jobId, 1, reason: 'head');
        expect(queue[1].jobId, 2, reason: 'tail (arrival order)');
      },
    );

    test(
      'a more-urgent newcomer does NOT displace the head — the head is '
      'sticky until it resolves',
      () {
        // jobId=1: 5-minute SLA, fresh (300s remaining).
        // jobId=2: 1-minute SLA, fresh (60s remaining) — much more urgent.
        // Head must remain jobId=1 because head-stickiness is the whole
        // point of the serialized one-offer model: a swap mid-decision is
        // exactly the footgun this contract prevents.
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1, expiresInSeconds: 300));
        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e2', jobId: 2, expiresInSeconds: 60));

        final queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 2);
        expect(queue.first.jobId, 1,
            reason: 'head must NOT swap to the more-urgent newcomer');
      },
    );

    test(
      'on head removal, the most-urgent tail entry is promoted to the new '
      'head (not FIFO)',
      () {
        // Three events whose timestamps must increase (the SystemEventNotifier
        // rejects same-type events arriving with a stale timestamp), and
        // whose urgencies differ enough to demonstrate priority promotion is
        // NOT FIFO arrival order:
        //
        //   * jobId=1 (head, will be removed): agedBy=100s, slaWindow=200s.
        //     fraction = (200-100)/200 = 0.50.
        //   * jobId=2 (tail, less urgent): agedBy=30s, slaWindow=600s.
        //     fraction = (600-30)/600 ≈ 0.95.
        //   * jobId=3 (tail, more urgent): agedBy=5s, slaWindow=10s.
        //     fraction = (10-5)/10 = 0.50.
        //
        // Even though jobId=3 arrived AFTER jobId=2, its smaller slaWindow
        // means a much larger proportion of its window has elapsed —
        // jobId=3 is more urgent and must promote ahead of jobId=2.
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container.read(systemEventProvider.notifier).processEvent(_liveEvent(
              id: 'e1',
              jobId: 1,
              expiresInSeconds: 200,
              agedBy: const Duration(seconds: 100),
            ));
        container.read(systemEventProvider.notifier).processEvent(_liveEvent(
              id: 'e2',
              jobId: 2,
              expiresInSeconds: 600,
              agedBy: const Duration(seconds: 30),
            ));
        container.read(systemEventProvider.notifier).processEvent(_liveEvent(
              id: 'e3',
              jobId: 3,
              expiresInSeconds: 10,
              agedBy: const Duration(seconds: 5),
            ));

        // Before removal — head is jobId=1, tail in arrival order.
        var queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 3,
            reason: 'all three events must pass the order guard');
        expect(queue.first.jobId, 1);

        // Remove the head → most-urgent of [job2, job3] gets promoted.
        // jobId=3's fraction ≈ 0.50, jobId=2's fraction ≈ 0.95.
        // jobId=3 is more urgent, so it becomes the new head.
        container.read(incomingJobQueueProvider.notifier).removeRequest(1);

        queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 2);
        expect(queue.first.jobId, 3,
            reason: 'most-urgent of tail must promote to head, '
                'NOT FIFO arrival order');
        expect(queue[1].jobId, 2);
      },
    );

    test(
      'on head removal of a single-entry queue, the queue empties cleanly',
      () {
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1, expiresInSeconds: 300));

        expect(container.read(incomingJobQueueProvider).queue.length, 1);

        container.read(incomingJobQueueProvider.notifier).removeRequest(1);

        expect(container.read(incomingJobQueueProvider).queue, isEmpty);
      },
    );

    test(
      'removing a non-head entry leaves the head in place and the rest of '
      'the tail unchanged',
      () {
        final container = _buildContainer(local);
        container.read(incomingJobQueueProvider);

        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e1', jobId: 1, expiresInSeconds: 300));
        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e2', jobId: 2, expiresInSeconds: 300));
        container
            .read(systemEventProvider.notifier)
            .processEvent(_liveEvent(id: 'e3', jobId: 3, expiresInSeconds: 300));

        // Remove the middle entry (not the head, not the last).
        container.read(incomingJobQueueProvider.notifier).removeRequest(2);

        final queue = container.read(incomingJobQueueProvider).queue;
        expect(queue.length, 2);
        expect(queue[0].jobId, 1, reason: 'head unchanged');
        expect(queue[1].jobId, 3, reason: 'remaining tail entry preserved');
      },
    );

    test('removeRequest with unknown jobId is a no-op', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);

      container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1, expiresInSeconds: 300));

      container
          .read(incomingJobQueueProvider.notifier)
          .removeRequest(999);

      final queue = container.read(incomingJobQueueProvider).queue;
      expect(queue.length, 1);
      expect(queue.single.jobId, 1);
    });

    test('removeRequest on an empty queue is a no-op', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);

      // No throw, no state change.
      container.read(incomingJobQueueProvider.notifier).removeRequest(1);

      expect(container.read(incomingJobQueueProvider).queue, isEmpty);
    });
  });

  group('IncomingJobQueueNotifier — debugSeedRequest', () {
    test('seeding an empty queue places the seed at the head', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);
      final notifier =
          container.read(incomingJobQueueProvider.notifier);

      // Build a domain entity directly via the wire mapper to avoid hand-
      // rolling JobNewRequest in tests (the entity's required field set
      // is not test-friendly).
      container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 1, expiresInSeconds: 300));
      // Pop the head to clear the queue, then re-seed via debugSeedRequest.
      final seed = container.read(incomingJobQueueProvider).queue.single;
      notifier.removeRequest(seed.jobId);
      expect(container.read(incomingJobQueueProvider).queue, isEmpty);

      notifier.debugSeedRequest(seed);

      expect(container.read(incomingJobQueueProvider).queue.length, 1);
      expect(
          container.read(incomingJobQueueProvider).queue.single.jobId, 1);
    });

    test('seeding a duplicate jobId is a no-op (mirrors real-event dedup)',
        () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);
      final notifier =
          container.read(incomingJobQueueProvider.notifier);

      container
          .read(systemEventProvider.notifier)
          .processEvent(_liveEvent(id: 'e1', jobId: 5, expiresInSeconds: 300));
      final seed = container.read(incomingJobQueueProvider).queue.single;

      notifier.debugSeedRequest(seed);

      expect(container.read(incomingJobQueueProvider).queue.length, 1);
    });
  });
}

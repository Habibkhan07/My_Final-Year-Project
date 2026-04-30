import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

/// Builds a `SystemEventEntity` for the `job_new_request` event type.
///
/// The notifier filters by `eventType == jobNewRequest`; flipping `rawType`
/// drives the negative path (e.g. `payment_received` should not enter the
/// queue).
SystemEventEntity _event({
  required String id,
  required int jobId,
  String rawType = 'job_new_request',
  DateTime? timestamp,
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
      'expires_in_seconds': 60,
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

  group('IncomingJobQueueNotifier', () {
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

    test('two distinct job_new_request events queue in FIFO arrival order',
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
      expect(queue[0].jobId, 1);
      expect(queue[1].jobId, 2);
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

    test('removeRequest drops the matching jobId', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);

      container.read(systemEventProvider.notifier).processEvent(
            _event(id: 'e1', jobId: 1),
          );
      container.read(systemEventProvider.notifier).processEvent(
            _event(
              id: 'e2',
              jobId: 2,
              timestamp: DateTime.utc(2026, 4, 27, 20, 14, 43),
            ),
          );

      container
          .read(incomingJobQueueProvider.notifier)
          .removeRequest(1);

      final queue = container.read(incomingJobQueueProvider).queue;
      expect(queue.length, 1);
      expect(queue.single.jobId, 2);
    });

    test('removeRequest with unknown jobId is a no-op', () {
      final container = _buildContainer(local);
      container.read(incomingJobQueueProvider);

      container.read(systemEventProvider.notifier).processEvent(
            _event(id: 'e1', jobId: 1),
          );

      container
          .read(incomingJobQueueProvider.notifier)
          .removeRequest(999);

      final queue = container.read(incomingJobQueueProvider).queue;
      expect(queue.length, 1);
      expect(queue.single.jobId, 1);
    });

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
}

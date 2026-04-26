import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/data/repositories/event_repository.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/domain/failures/event_failures.dart';
import 'package:frontend/core/realtime/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements EventRepository {}

class _MockLocal extends Mock implements EventLocalDataSource {}

SystemEventEntity _entity({
  required String id,
  String rawType = 'job_dispatched',
  required DateTime timestamp,
  String role = 'technician',
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: rawType,
    targetRoleStr: role,
    timestamp: timestamp,
    payload: const <String, dynamic>{},
  );
}

ProviderContainer _container({
  required EventRepository repo,
  required EventLocalDataSource local,
}) {
  final container = ProviderContainer(
    overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      eventLocalDataSourceProvider.overrideWithValue(local),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockRepo repo;
  late _MockLocal local;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    repo = _MockRepo();
    local = _MockLocal();

    when(() => local.getLastSyncTimestamp()).thenReturn(null);
    when(() => local.getPendingAcks()).thenReturn(const <String>[]);
    when(() => repo.syncMissedEvents(any()))
        .thenAnswer((_) async => <SystemEventEntity>[]);
    when(() => repo.fetchUnacknowledgedCritical())
        .thenAnswer((_) async => <SystemEventEntity>[]);
    when(() => repo.acknowledgeEvents(any())).thenAnswer((_) async {});
  });

  // ─── syncMissedEvents — cursor selection ───────────────────────────────

  group('syncMissedEvents — cursor selection', () {
    test('E1 — cold start (system cursor null) → repo called with ISO of now-24h',
        () async {
      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      verify(() => repo.syncMissedEvents(any(that: predicate<String>((iso) {
            final actual = DateTime.parse(iso);
            final target =
                DateTime.now().toUtc().subtract(const Duration(hours: 24));
            return actual.difference(target).abs() <
                const Duration(seconds: 5);
          })))).called(1);
    });

    test(
        'E2 — warm start (cursor C present) → repo called with C.toUtc().toIso8601String()',
        () async {
      // Seed the SystemEventNotifier cursor via persisted local timestamp.
      when(() => local.getLastSyncTimestamp())
          .thenReturn('2026-04-24T12:00:00Z');
      final container = _container(repo: repo, local: local);
      // Materialize systemEventProvider so build() seeds the cursor.
      container.read(systemEventProvider);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      verify(() => repo.syncMissedEvents('2026-04-24T12:00:00.000Z')).called(1);
    });
  });

  // ─── chronological feed ────────────────────────────────────────────────

  group('syncMissedEvents — chronological feed', () {
    test('E3 — out-of-order repo response → processEvent fed in chronological order',
        () async {
      final t1 = DateTime.utc(2026, 4, 25, 10);
      final t2 = DateTime.utc(2026, 4, 25, 11);
      final t3 = DateTime.utc(2026, 4, 25, 12);
      final e1 = _entity(id: 'm1', timestamp: t1);
      final e2 = _entity(id: 'm2', timestamp: t2);
      final e3 = _entity(id: 'm3', timestamp: t3);
      when(() => repo.syncMissedEvents(any()))
          .thenAnswer((_) async => [e2, e1, e3]);

      final container = _container(repo: repo, local: local);
      final processed = <String?>[];
      container.listen<SystemEventState>(
        systemEventProvider,
        (prev, next) {
          if (prev?.latestEvent?.id != next.latestEvent?.id) {
            processed.add(next.latestEvent?.id);
          }
        },
      );
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      expect(processed, ['m1', 'm2', 'm3']);
    });
  });

  // ─── cascade ordering ──────────────────────────────────────────────────

  group('syncMissedEvents — cascade ordering', () {
    test('E4 — happy path: missed → critical → pending-acks → acknowledge',
        () async {
      final m1 = _entity(id: 'm1', timestamp: DateTime.utc(2026, 4, 25, 10));
      final m2 = _entity(id: 'm2', timestamp: DateTime.utc(2026, 4, 25, 11));
      final c1 = _entity(
        id: 'c1',
        rawType: 'dispute_opened',
        timestamp: DateTime.utc(2026, 4, 25, 12),
      );
      when(() => repo.syncMissedEvents(any())).thenAnswer((_) async => [m1, m2]);
      when(() => repo.fetchUnacknowledgedCritical())
          .thenAnswer((_) async => [c1]);
      when(() => local.getPendingAcks()).thenReturn(const ['a', 'b']);

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      verifyInOrder([
        () => repo.syncMissedEvents(any()),
        () => repo.fetchUnacknowledgedCritical(),
        () => local.getPendingAcks(),
        () => repo.acknowledgeEvents(any()),
      ]);
      expect(
        container.read(systemEventProvider).processedEventIds.length,
        3,
      );
    });

    test(
        'E5 — empty cascade: both repo calls still fire; acknowledge skipped when '
        'no pending IDs', () async {
      when(() => repo.syncMissedEvents(any())).thenAnswer((_) async => []);
      when(() => repo.fetchUnacknowledgedCritical())
          .thenAnswer((_) async => []);
      when(() => local.getPendingAcks()).thenReturn(const <String>[]);

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      verify(() => repo.syncMissedEvents(any())).called(1);
      verify(() => repo.fetchUnacknowledgedCritical()).called(1);
      verifyNever(() => repo.acknowledgeEvents(any()));
    });

    test(
        'E6 — repo.syncMissedEvents throws → cascade aborts; no critical sync, '
        'no ack flush', () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncNetworkFailure());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncMissedEvents();

      verifyNever(() => repo.fetchUnacknowledgedCritical());
      verifyNever(() => local.getPendingAcks());
      verifyNever(() => repo.acknowledgeEvents(any()));
    });
  });

  // ─── 401 callback ──────────────────────────────────────────────────────

  group('syncMissedEvents — 401 callback', () {
    test('E7 — repo throws EventSyncUnauthorized → onUnauthorized fires once',
        () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncUnauthorized());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await notifier.syncMissedEvents();

      expect(hits, 1);
    });

    test('E8 — repo throws EventSyncNetworkFailure → onUnauthorized NOT called',
        () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncNetworkFailure());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await notifier.syncMissedEvents();

      expect(hits, 0);
    });

    test('E9 — repo throws EventSyncServerFailure → onUnauthorized NOT called',
        () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncServerFailure('boom'));

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await notifier.syncMissedEvents();

      expect(hits, 0);
    });

    test(
        'E10 — onUnauthorized null + 401 → no exception, callback simply not invoked '
        '(NPE-safety guard)', () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncUnauthorized());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      // onUnauthorized intentionally left null — proves the `?.call()` guard.

      await expectLater(
        notifier.syncMissedEvents(),
        completes,
      );
    });

    test('E11 — two sequential 401s → callback fires twice', () async {
      when(() => repo.syncMissedEvents(any()))
          .thenThrow(const EventSyncUnauthorized());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await notifier.syncMissedEvents();
      await notifier.syncMissedEvents();

      expect(hits, 2);
    });
  });

  // ─── unexpected error ──────────────────────────────────────────────────

  group('syncMissedEvents — unexpected error', () {
    test(
        'E12 — repo throws non-EventSyncFailure Exception → caught in unexpected '
        'branch; no rethrow', () async {
      when(() => repo.syncMissedEvents(any())).thenThrow(Exception('boom'));

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await expectLater(notifier.syncMissedEvents(), completes);
      expect(hits, 0);
    });
  });

  // ─── syncUnacknowledgedCritical (decision-D parity) ────────────────────

  group('syncUnacknowledgedCritical — direct invocation', () {
    test('E13 — happy path: events fed into systemEventNotifier', () async {
      final c1 = _entity(id: 'c1', timestamp: DateTime.utc(2026, 4, 25, 10));
      final c2 = _entity(
        id: 'c2',
        rawType: 'dispute_opened',
        timestamp: DateTime.utc(2026, 4, 25, 11),
      );
      when(() => repo.fetchUnacknowledgedCritical())
          .thenAnswer((_) async => [c1, c2]);

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);

      await notifier.syncUnacknowledgedCritical();

      expect(
        container.read(systemEventProvider).processedEventIds.length,
        2,
      );
    });

    test(
        'E14 — repo throws EventSyncUnauthorized → onUnauthorized fired; no '
        'exception propagates (decision-D _runGuarded symmetry)', () async {
      when(() => repo.fetchUnacknowledgedCritical())
          .thenThrow(const EventSyncUnauthorized());

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await expectLater(notifier.syncUnacknowledgedCritical(), completes);
      expect(hits, 1);
    });

    test('E15 — repo throws EventSyncServerFailure → swallowed; no propagation',
        () async {
      when(() => repo.fetchUnacknowledgedCritical())
          .thenThrow(const EventSyncServerFailure('down'));

      final container = _container(repo: repo, local: local);
      final notifier = container.read(eventSyncProvider.notifier);
      var hits = 0;
      notifier.onUnauthorized = () => hits++;

      await expectLater(notifier.syncUnacknowledgedCritical(), completes);
      expect(hits, 0);
    });
  });

  // ─── acknowledge debounce ──────────────────────────────────────────────

  group('acknowledge — debounce', () {
    test('E16 — single ack: no POST before 2s, exactly one POST at 2s', () {
      fakeAsync((async) {
        final container = _container(repo: repo, local: local);
        final notifier = container.read(eventSyncProvider.notifier);

        notifier.acknowledge('a');

        async.elapse(const Duration(milliseconds: 1900));
        verifyNever(() => repo.acknowledgeEvents(any()));

        async.elapse(const Duration(milliseconds: 200));
        verify(() => repo.acknowledgeEvents(any())).called(1);
      });
    });

    test('E17 — 5 acks within 2s → coalesced into one POST with all 5 ids', () {
      fakeAsync((async) {
        final container = _container(repo: repo, local: local);
        final notifier = container.read(eventSyncProvider.notifier);

        for (final id in ['a', 'b', 'c', 'd', 'e']) {
          notifier.acknowledge(id);
        }

        async.elapse(const Duration(seconds: 3));

        final captured =
            verify(() => repo.acknowledgeEvents(captureAny())).captured;
        expect(captured.length, 1);
        expect(
          (captured.single as List<String>).toSet(),
          {'a', 'b', 'c', 'd', 'e'},
        );
      });
    });

    test('E18 — duplicate ack id → only added once to internal buffer', () {
      fakeAsync((async) {
        final container = _container(repo: repo, local: local);
        final notifier = container.read(eventSyncProvider.notifier);

        notifier.acknowledge('x');
        notifier.acknowledge('x');

        async.elapse(const Duration(seconds: 3));

        final captured =
            verify(() => repo.acknowledgeEvents(captureAny())).captured;
        expect(captured.length, 1);
        expect(captured.single, ['x']);
      });
    });

    test(
        'E19 — each new ack within debounce window resets the timer; 10 acks '
        '100ms apart → ONE POST 2s after the last ack', () {
      fakeAsync((async) {
        final container = _container(repo: repo, local: local);
        final notifier = container.read(eventSyncProvider.notifier);

        // Last ack lands at t=900ms (10 acks: i=0 at t=0, …, i=9 at t=900),
        // and the loop closes at t=1000ms. The reset-on-ack contract puts
        // the active timer's fire point at t=900+2000 = t=2900ms.
        for (var i = 0; i < 10; i++) {
          notifier.acknowledge('id$i');
          async.elapse(const Duration(milliseconds: 100));
        }
        verifyNever(() => repo.acknowledgeEvents(any()));

        // Advance to just before t=2900 → still no flush.
        async.elapse(const Duration(milliseconds: 1899));
        verifyNever(() => repo.acknowledgeEvents(any()));

        // Cross t=2900 → single flush fires.
        async.elapse(const Duration(milliseconds: 200));
        verify(() => repo.acknowledgeEvents(any())).called(1);
      });
    });
  });

  // ─── flush mechanics ───────────────────────────────────────────────────

  group('acknowledge — flush mechanics', () {
    test(
        'E20 — _pendingAcks cleared BEFORE await: ack mid-flight queues for next '
        'batch, not lost', () {
      fakeAsync((async) {
        final inFlight = <Completer<void>>[];
        when(() => repo.acknowledgeEvents(any())).thenAnswer((_) {
          final c = Completer<void>();
          inFlight.add(c);
          return c.future;
        });

        final container = _container(repo: repo, local: local);
        final notifier = container.read(eventSyncProvider.notifier);

        // t=0: enqueue 'a'. Debounce timer set for 2s.
        notifier.acknowledge('a');

        // t=2s: timer fires _flushAcks → list cleared → POST starts (in-flight).
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();
        expect(inFlight.length, 1);
        expect(inFlight[0].isCompleted, isFalse);

        // t=2.1s: enqueue 'y' — must land in the (now-empty) buffer and arm a
        // fresh debounce timer for the next batch.
        async.elapse(const Duration(milliseconds: 100));
        notifier.acknowledge('y');

        // Complete the first POST so the await returns.
        inFlight[0].complete();
        async.flushMicrotasks();

        // 2s of quiet from the 'y' ack → second flush.
        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        final captured =
            verify(() => repo.acknowledgeEvents(captureAny())).captured;
        expect(captured.length, 2);
        expect(captured[0], ['a']);
        expect((captured[1] as List<String>).toSet(), {'y'});
      });
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/domain/entities/system_event_entity.dart';
import 'package:frontend/core/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/presentation/state/system_event_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

SystemEventEntity _entity({
  required String id,
  String rawType = 'job_dispatched',
  required DateTime timestamp,
  String role = 'technician',
  Map<String, dynamic> payload = const <String, dynamic>{},
}) {
  return SystemEventEntity.fromComponents(
    id: id,
    rawType: rawType,
    targetRoleStr: role,
    timestamp: timestamp,
    payload: payload,
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
    // Defaults: no persisted cursor, no other reads/writes from build().
    when(() => local.getLastSyncTimestamp()).thenReturn(null);
  });

  // ─── Cold-start cursor seeding ─────────────────────────────────────────

  group('cold-start cursor seeding', () {
    test('S1 — null persisted cursor → state.lastSyncTimestamp == null', () {
      when(() => local.getLastSyncTimestamp()).thenReturn(null);
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(state.lastSyncTimestamp, isNull);
    });

    test('S2 — valid ISO persisted cursor seeds state', () {
      when(() => local.getLastSyncTimestamp())
          .thenReturn('2026-04-25T12:00:00Z');
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(
        state.lastSyncTimestamp,
        DateTime.parse('2026-04-25T12:00:00Z').toUtc(),
      );
    });

    test('S3 — garbage persisted cursor → null (DateTime.tryParse never throws)',
        () {
      when(() => local.getLastSyncTimestamp()).thenReturn('garbage');
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(state.lastSyncTimestamp, isNull);
    });

    test(
        'S4 — even with a valid cursor, processedEventIds and latestEvent stay default '
        '(session-scoped invariant)', () {
      when(() => local.getLastSyncTimestamp())
          .thenReturn('2026-04-25T12:00:00Z');
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(state.processedEventIds, isEmpty);
      expect(state.latestEvent, isNull);
    });
  });

  // ─── processEvent — accept paths ───────────────────────────────────────

  group('processEvent — accept paths', () {
    test('S5 — first event ever → accepted, latestEvent + map + cursor set', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final ts = DateTime.utc(2026, 4, 25, 12);
      final event = _entity(id: 'e1', timestamp: ts);

      final accepted = notifier.processEvent(event);

      final state = container.read(systemEventProvider);
      expect(accepted, isTrue);
      expect(state.latestEvent, event);
      expect(state.processedEventIds, {'e1': ts});
      expect(state.lastSyncTimestamp, ts);
    });

    test(
        'S6 — second event, different rawType, NEWER → accepted, both ids retained, '
        'cursor advances', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final t1 = DateTime.utc(2026, 4, 25, 12);
      final t2 = DateTime.utc(2026, 4, 25, 13);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: t1),
      );

      final accepted = notifier.processEvent(
        _entity(id: 'e2', rawType: 'chat_message', timestamp: t2),
      );

      final state = container.read(systemEventProvider);
      expect(accepted, isTrue);
      expect(state.processedEventIds.keys, containsAll(<String>['e1', 'e2']));
      expect(state.lastSyncTimestamp, t2);
    });

    test(
        'S7 — different rawType, OLDER ts → accepted (different-type bypass), '
        'latestEvent updates, cursor NOT regressed', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final tNewer = DateTime.utc(2026, 4, 25, 13);
      final tOlder = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: tNewer),
      );
      final cursorBefore = container.read(systemEventProvider).lastSyncTimestamp;

      final olderDifferentType =
          _entity(id: 'e2', rawType: 'chat_message', timestamp: tOlder);
      final accepted = notifier.processEvent(olderDifferentType);

      final state = container.read(systemEventProvider);
      expect(accepted, isTrue);
      expect(state.latestEvent, olderDifferentType);
      expect(state.lastSyncTimestamp, cursorBefore);
      expect(state.lastSyncTimestamp, tNewer);
    });

    test('S8 — same rawType, NEWER ts → accepted, cursor advances', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final t1 = DateTime.utc(2026, 4, 25, 12);
      final t2 = DateTime.utc(2026, 4, 25, 13);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: t1),
      );

      final accepted = notifier.processEvent(
        _entity(id: 'e2', rawType: 'job_dispatched', timestamp: t2),
      );

      final state = container.read(systemEventProvider);
      expect(accepted, isTrue);
      expect(state.lastSyncTimestamp, t2);
    });
  });

  // ─── processEvent — reject paths ───────────────────────────────────────

  group('processEvent — reject paths', () {
    test('S9 — duplicate id → rejected, state unchanged', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final ts = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(_entity(id: 'e1', timestamp: ts));
      final snapshot = container.read(systemEventProvider);

      final accepted = notifier.processEvent(
        _entity(id: 'e1', timestamp: ts.add(const Duration(hours: 1))),
      );

      final after = container.read(systemEventProvider);
      expect(accepted, isFalse);
      expect(after, snapshot);
    });

    test('S10 — same rawType, OLDER ts → rejected, state unchanged', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final tNewer = DateTime.utc(2026, 4, 25, 13);
      final tOlder = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: tNewer),
      );
      final snapshot = container.read(systemEventProvider);

      final accepted = notifier.processEvent(
        _entity(id: 'e2', rawType: 'job_dispatched', timestamp: tOlder),
      );

      final after = container.read(systemEventProvider);
      expect(accepted, isFalse);
      expect(after, snapshot);
    });
  });

  // ─── Dedup-map prune ───────────────────────────────────────────────────

  group('dedup-map prune', () {
    test(
        'S11 — fill to 100 then add 101st → prune fires; final map = 51 entries '
        '(50 newest of original + the new event)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final base = DateTime.utc(2026, 4, 25, 12);

      // 100 events with strictly ascending timestamps and distinct ids.
      // chat_message bypasses the order guard for the 101st (different
      // rawType from the 100 here would change behavior; we keep the same
      // rawType but feed in ascending order so each subsequent event is
      // accepted by the order guard).
      for (var i = 1; i <= 100; i++) {
        notifier.processEvent(
          _entity(
            id: 'e$i',
            rawType: 'job_dispatched',
            timestamp: base.add(Duration(minutes: i)),
          ),
        );
      }
      expect(container.read(systemEventProvider).processedEventIds.length, 100);

      notifier.processEvent(
        _entity(
          id: 'e101',
          rawType: 'job_dispatched',
          timestamp: base.add(const Duration(minutes: 101)),
        ),
      );

      final ids =
          container.read(systemEventProvider).processedEventIds.keys.toSet();
      expect(ids.length, 51);
      // 50 oldest (e1..e50) removed.
      for (var i = 1; i <= 50; i++) {
        expect(ids.contains('e$i'), isFalse, reason: 'e$i should be pruned');
      }
      // 50 newest of original (e51..e100) plus e101 retained.
      for (var i = 51; i <= 100; i++) {
        expect(ids.contains('e$i'), isTrue, reason: 'e$i should remain');
      }
      expect(ids.contains('e101'), isTrue);
    });
  });

  // ─── Cursor advance contract ───────────────────────────────────────────

  group('cursor advance contract', () {
    test('S12 — event.ts == current cursor → cursor unchanged (strict isAfter)',
        () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final ts = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: ts),
      );
      final cursorBefore =
          container.read(systemEventProvider).lastSyncTimestamp;

      notifier.processEvent(
        _entity(id: 'e2', rawType: 'chat_message', timestamp: ts),
      );

      expect(
        container.read(systemEventProvider).lastSyncTimestamp,
        cursorBefore,
      );
    });

    test(
        'S13 — older ts but different rawType (accepted) → cursor unchanged',
        () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final tNewer = DateTime.utc(2026, 4, 25, 13);
      final tOlder = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_dispatched', timestamp: tNewer),
      );

      notifier.processEvent(
        _entity(id: 'e2', rawType: 'chat_message', timestamp: tOlder),
      );

      expect(
        container.read(systemEventProvider).lastSyncTimestamp,
        tNewer,
      );
    });
  });

  // ─── Reset + privacy ───────────────────────────────────────────────────

  group('reset + privacy guarantee', () {
    test(
        'S14 — reset() clears in-memory state to defaults and does NOT touch '
        'persistence (orchestrator owns persistence cleanup)', () {
      when(() => local.getLastSyncTimestamp())
          .thenReturn('2026-04-25T12:00:00Z');
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      notifier.processEvent(
        _entity(id: 'e1', timestamp: DateTime.utc(2026, 4, 25, 14)),
      );

      notifier.reset();

      expect(container.read(systemEventProvider), const SystemEventState());
      verifyNever(() => local.clearLastSyncTimestamp());
      verifyNever(() => local.clearCachedEvents());
      verifyNever(() => local.clearPendingAcks());
    });

    test(
        'S15 — privacy: post-teardown state (null cursor + null cache) → fresh '
        'container builds with default state, no inherited cursor', () {
      when(() => local.getLastSyncTimestamp()).thenReturn(null);
      when(() => local.getCachedEventList()).thenReturn(null);
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(state, const SystemEventState());
      expect(state.lastSyncTimestamp, isNull);
    });
  });
}

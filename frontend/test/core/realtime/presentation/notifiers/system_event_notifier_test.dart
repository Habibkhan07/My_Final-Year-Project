import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/state/system_event_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

SystemEventEntity _entity({
  required String id,
  String rawType = 'job_new_request',
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
    overrides: [eventLocalDataSourceProvider.overrideWithValue(local)],
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
      when(
        () => local.getLastSyncTimestamp(),
      ).thenReturn('2026-04-25T12:00:00Z');
      final container = _buildContainer(local);

      final state = container.read(systemEventProvider);

      expect(
        state.lastSyncTimestamp,
        DateTime.parse('2026-04-25T12:00:00Z').toUtc(),
      );
    });

    test(
      'S3 — garbage persisted cursor → null (DateTime.tryParse never throws)',
      () {
        when(() => local.getLastSyncTimestamp()).thenReturn('garbage');
        final container = _buildContainer(local);

        final state = container.read(systemEventProvider);

        expect(state.lastSyncTimestamp, isNull);
      },
    );

    test(
      'S4 — even with a valid cursor, processedEventIds and latestEvent stay default '
      '(session-scoped invariant)',
      () {
        when(
          () => local.getLastSyncTimestamp(),
        ).thenReturn('2026-04-25T12:00:00Z');
        final container = _buildContainer(local);

        final state = container.read(systemEventProvider);

        expect(state.processedEventIds, isEmpty);
        expect(state.latestEvent, isNull);
      },
    );
  });

  // ─── processEvent — accept paths ───────────────────────────────────────

  group('processEvent — accept paths', () {
    test(
      'S5 — first event ever → accepted, latestEvent + map + cursor set',
      () {
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
      },
    );

    test(
      'S6 — second event, different rawType, NEWER → accepted, both ids retained, '
      'cursor advances',
      () {
        final container = _buildContainer(local);
        final notifier = container.read(systemEventProvider.notifier);
        final t1 = DateTime.utc(2026, 4, 25, 12);
        final t2 = DateTime.utc(2026, 4, 25, 13);
        notifier.processEvent(
          _entity(id: 'e1', rawType: 'job_new_request', timestamp: t1),
        );

        final accepted = notifier.processEvent(
          _entity(id: 'e2', rawType: 'chat_message', timestamp: t2),
        );

        final state = container.read(systemEventProvider);
        expect(accepted, isTrue);
        expect(state.processedEventIds.keys, containsAll(<String>['e1', 'e2']));
        expect(state.lastSyncTimestamp, t2);
      },
    );

    test('S7 — different rawType, OLDER ts → accepted (different-type bypass), '
        'latestEvent updates, cursor NOT regressed', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final tNewer = DateTime.utc(2026, 4, 25, 13);
      final tOlder = DateTime.utc(2026, 4, 25, 12);
      notifier.processEvent(
        _entity(id: 'e1', rawType: 'job_new_request', timestamp: tNewer),
      );
      final cursorBefore = container
          .read(systemEventProvider)
          .lastSyncTimestamp;

      final olderDifferentType = _entity(
        id: 'e2',
        rawType: 'chat_message',
        timestamp: tOlder,
      );
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
        _entity(id: 'e1', rawType: 'job_new_request', timestamp: t1),
      );

      final accepted = notifier.processEvent(
        _entity(id: 'e2', rawType: 'job_new_request', timestamp: t2),
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
        _entity(id: 'e1', rawType: 'job_new_request', timestamp: tNewer),
      );
      final snapshot = container.read(systemEventProvider);

      final accepted = notifier.processEvent(
        _entity(id: 'e2', rawType: 'job_new_request', timestamp: tOlder),
      );

      final after = container.read(systemEventProvider);
      expect(accepted, isFalse);
      expect(after, snapshot);
    });
  });

  // ─── Dedup-map prune (windowed) ────────────────────────────────────────

  group('dedup-map prune — 24h window', () {
    test('S11a — entry older than 24h relative to incoming event → pruned', () {
      // Insert two events: e_old at t=0, e_recent at t=20h. Then insert
      // e_now at t=25h — this drives the cutoff to t=25h - 24h = t=1h, so
      // e_old (at t=0) falls outside the window and is pruned, while
      // e_recent (at t=20h) stays.
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final base = DateTime.utc(2026, 4, 25, 0);

      notifier.processEvent(
        _entity(id: 'e_old', rawType: 'job_new_request', timestamp: base),
      );
      notifier.processEvent(
        _entity(
          id: 'e_recent',
          rawType: 'chat_message',
          timestamp: base.add(const Duration(hours: 20)),
        ),
      );
      expect(container.read(systemEventProvider).processedEventIds.length, 2);

      notifier.processEvent(
        _entity(
          id: 'e_now',
          rawType: 'payment_received',
          timestamp: base.add(const Duration(hours: 25)),
        ),
      );

      final ids = container
          .read(systemEventProvider)
          .processedEventIds
          .keys
          .toSet();
      expect(
        ids.contains('e_old'),
        isFalse,
        reason: 'entry older than 24h relative to e_now must be pruned',
      );
      expect(
        ids.contains('e_recent'),
        isTrue,
        reason: 'entry within the 24h window must be retained',
      );
      expect(ids.contains('e_now'), isTrue);
    });

    test('S11b — entries all within 24h → none pruned, all retained', () {
      // No event is older than 24h relative to any other → window prune is
      // a no-op. Three distinct events should all sit in the dedup map.
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final base = DateTime.utc(2026, 4, 25, 0);

      for (var i = 0; i < 3; i++) {
        notifier.processEvent(
          _entity(
            id: 'e$i',
            // Mix rawTypes so the order guard doesn't reject ascending-by-1h
            // (it doesn't, because each is later, but the mix makes intent
            // clear).
            rawType: 'job_new_request',
            timestamp: base.add(Duration(hours: i)),
          ),
        );
      }

      final ids = container
          .read(systemEventProvider)
          .processedEventIds
          .keys
          .toSet();
      expect(ids, {
        'e0',
        'e1',
        'e2',
      }, reason: 'all three entries within the 24h window must remain');
    });

    test('S11c — boundary: entry exactly at the 24h cutoff is RETAINED '
        '(prune uses strict isBefore)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final base = DateTime.utc(2026, 4, 25, 0);

      notifier.processEvent(_entity(id: 'e_boundary', timestamp: base));
      notifier.processEvent(
        _entity(
          id: 'e_now',
          rawType: 'chat_message',
          // Exactly 24h after the boundary entry — boundary entry's
          // timestamp == cutoff → not "before" cutoff → retained.
          timestamp: base.add(const Duration(hours: 24)),
        ),
      );

      final ids = container
          .read(systemEventProvider)
          .processedEventIds
          .keys
          .toSet();
      expect(
        ids.contains('e_boundary'),
        isTrue,
        reason:
            'entry at exactly the cutoff instant must be retained — '
            'isBefore is strict, so equal-timestamp survives',
      );
      expect(ids.contains('e_now'), isTrue);
    });

    test('S11d — defense in depth: hard cap fires when 500 events all sit '
        'inside the 24h window (concentrated burst); map shrinks to '
        '_kHardCapKeep = 250 newest', () {
      // This branch is expected to be cold in normal use — it exists so a
      // pathological event burst can't blow memory. Insert 500 events
      // (cap=500 → kicks in on the 500th), then one more to verify the
      // cap-then-add-then-prune behavior.
      //
      // We use a single rawType with strictly ascending timestamps so the
      // order guard accepts each event in turn. 1-second spacing keeps all
      // 501 events comfortably inside the 24h window — the windowed prune
      // is therefore a no-op and only the hard cap matters.
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final base = DateTime.utc(2026, 4, 25, 0);

      for (var i = 1; i <= 501; i++) {
        notifier.processEvent(
          _entity(
            id: 'e$i',
            rawType: 'job_new_request',
            timestamp: base.add(Duration(seconds: i)),
          ),
        );
      }

      final ids = container
          .read(systemEventProvider)
          .processedEventIds
          .keys
          .toSet();
      // After the cap fires (at 500), 250 newest of the first 500 are
      // kept; the 501st is added → final size 251. Equivalent to the
      // previous LRU contract but at a 5× larger threshold.
      expect(
        ids.length,
        251,
        reason:
            'cap fires when len ≥ 500, prunes to 250 newest, then '
            'the in-flight event is added → 251',
      );
      // The 250 oldest (e1..e250) are gone.
      expect(ids.contains('e1'), isFalse);
      expect(ids.contains('e250'), isFalse);
      // The 250 newest of the original 500 (e251..e500) are kept, plus e501.
      expect(ids.contains('e251'), isTrue);
      expect(ids.contains('e500'), isTrue);
      expect(ids.contains('e501'), isTrue);
    });
  });

  // ─── Cursor advance contract ───────────────────────────────────────────

  group('cursor advance contract', () {
    test(
      'S12 — event.ts == current cursor → cursor unchanged (strict isAfter)',
      () {
        final container = _buildContainer(local);
        final notifier = container.read(systemEventProvider.notifier);
        final ts = DateTime.utc(2026, 4, 25, 12);
        notifier.processEvent(
          _entity(id: 'e1', rawType: 'job_new_request', timestamp: ts),
        );
        final cursorBefore = container
            .read(systemEventProvider)
            .lastSyncTimestamp;

        notifier.processEvent(
          _entity(id: 'e2', rawType: 'chat_message', timestamp: ts),
        );

        expect(
          container.read(systemEventProvider).lastSyncTimestamp,
          cursorBefore,
        );
      },
    );

    test(
      'S13 — older ts but different rawType (accepted) → cursor unchanged',
      () {
        final container = _buildContainer(local);
        final notifier = container.read(systemEventProvider.notifier);
        final tNewer = DateTime.utc(2026, 4, 25, 13);
        final tOlder = DateTime.utc(2026, 4, 25, 12);
        notifier.processEvent(
          _entity(id: 'e1', rawType: 'job_new_request', timestamp: tNewer),
        );

        notifier.processEvent(
          _entity(id: 'e2', rawType: 'chat_message', timestamp: tOlder),
        );

        expect(container.read(systemEventProvider).lastSyncTimestamp, tNewer);
      },
    );
  });

  // ─── Flag #19 envelope filters: expiresAt + recipientUserId ────────────

  group('processEvent — flag #19 P2 recipient filter', () {
    test(
      'S16 — event with recipientUserId == current auth user → accepted',
      () {
        final container = ProviderContainer(
          overrides: [
            eventLocalDataSourceProvider.overrideWithValue(local),
            currentAuthUserIdProvider.overrideWithValue(42),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(systemEventProvider.notifier);

        final event = SystemEventEntity.fromComponents(
          id: 'e1',
          rawType: 'job_new_request',
          targetRoleStr: 'technician',
          timestamp: DateTime.utc(2026, 4, 25, 12),
          payload: const <String, dynamic>{},
          recipientUserId: 42,
        );
        final accepted = notifier.processEvent(event);

        expect(accepted, isTrue);
        expect(container.read(systemEventProvider).latestEvent, event);
      },
    );

    test('S17 — event recipientUserId != current auth user → rejected '
        '(multi-account device race defense)', () {
      final container = ProviderContainer(
        overrides: [
          eventLocalDataSourceProvider.overrideWithValue(local),
          currentAuthUserIdProvider.overrideWithValue(42),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(systemEventProvider.notifier);

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: DateTime.utc(2026, 4, 25, 12),
        payload: const <String, dynamic>{},
        recipientUserId: 99, // not 42
      );
      final accepted = notifier.processEvent(event);

      expect(accepted, isFalse);
      expect(
        container.read(systemEventProvider).latestEvent,
        isNull,
        reason: 'cross-user event must not enter pipeline state',
      );
    });

    test('S18 — currentAuthUserId is null → filter is a no-op '
        '(pre-rollout backwards compat: auth feature has not yet exposed '
        'numeric id on UserEntity)', () {
      final container = ProviderContainer(
        overrides: [
          eventLocalDataSourceProvider.overrideWithValue(local),
          // Default currentAuthUserIdProvider returns null — no override.
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(systemEventProvider.notifier);

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: DateTime.utc(2026, 4, 25, 12),
        payload: const <String, dynamic>{},
        recipientUserId: 42,
      );
      final accepted = notifier.processEvent(event);

      expect(
        accepted,
        isTrue,
        reason:
            'with no current-user id wired, the filter must not '
            'gate events — would otherwise drop EVERYTHING during '
            'the rollout window before auth gains a numeric id',
      );
    });

    test('S19 — event has no recipientUserId → filter is a no-op '
        '(legacy events emitted by backends pre-flag #19)', () {
      final container = ProviderContainer(
        overrides: [
          eventLocalDataSourceProvider.overrideWithValue(local),
          currentAuthUserIdProvider.overrideWithValue(42),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(systemEventProvider.notifier);

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: DateTime.utc(2026, 4, 25, 12),
        payload: const <String, dynamic>{},
        // recipientUserId omitted → null
      );
      final accepted = notifier.processEvent(event);

      expect(
        accepted,
        isTrue,
        reason: 'legacy events without recipient must pass through',
      );
    });
  });

  group('processEvent — flag #19 P1 expiry filter', () {
    test('S20 — event with expiresAt in the future → accepted', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      // Pin local clock so the test is deterministic.
      final localNow = DateTime.utc(2026, 4, 25, 12);
      notifier.debugLocalNow = () => localNow;

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: localNow.subtract(const Duration(seconds: 5)),
        payload: const <String, dynamic>{},
        expiresAt: localNow.add(const Duration(minutes: 4)),
      );

      expect(notifier.processEvent(event), isTrue);
    });

    test('S21 — event with expiresAt in the past → rejected '
        '(stale FCM tap-intent on a long-ignored notification)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final localNow = DateTime.utc(2026, 4, 25, 12);
      notifier.debugLocalNow = () => localNow;

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        // Dispatched 10 minutes ago with a 60-second SLA.
        timestamp: localNow.subtract(const Duration(minutes: 10)),
        payload: const <String, dynamic>{},
        expiresAt: localNow.subtract(const Duration(minutes: 9)),
      );

      expect(notifier.processEvent(event), isFalse);
      expect(
        container.read(systemEventProvider).latestEvent,
        isNull,
        reason: 'expired event must not enter pipeline state',
      );
    });

    test('S22 — boundary: expiresAt == serverNow → rejected '
        '(SLA fires the moment the deadline lands, matching server '
        'Celery semantics)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);
      final localNow = DateTime.utc(2026, 4, 25, 12);
      notifier.debugLocalNow = () => localNow;

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: localNow.subtract(const Duration(seconds: 60)),
        payload: const <String, dynamic>{},
        expiresAt: localNow, // exactly now
      );

      expect(notifier.processEvent(event), isFalse);
    });

    test('S23 — event with no expiresAt → filter is a no-op '
        '(events without a time-windowed semantic, e.g. payment_received)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);

      final event = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'payment_received',
        targetRoleStr: 'technician',
        timestamp: DateTime.utc(2026, 4, 25, 12),
        payload: const <String, dynamic>{},
        // expiresAt omitted → null
      );

      expect(notifier.processEvent(event), isTrue);
    });

    test('S24 — server-time anchor: WS source updates the anchor; expiry '
        'check after a WS event uses the anchor + elapsed-since-anchor '
        'rather than DateTime.now() (clock-skew immunity)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);

      // Simulate a device whose local clock is 1 hour BEHIND the
      // server's clock. Without an anchor, an event with
      // expiresAt = serverTime + 30s would look fresh by 1h+30s
      // (because device.now() reads as "1h before serverTime"). With a
      // WS anchor placed at serverTime, the expiry filter correctly
      // detects "30s ahead of serverNow."
      final serverTime = DateTime.utc(2026, 4, 25, 12);
      final deviceTimeBehind = serverTime.subtract(const Duration(hours: 1));
      notifier.debugLocalNow = () => deviceTimeBehind;

      // First arrival: a WS event with `event.timestamp == serverTime`.
      // This sets the anchor to serverTime/deviceTimeBehind.
      final wsEvent = SystemEventEntity.fromComponents(
        id: 'e1',
        rawType: 'chat_message',
        targetRoleStr: 'technician',
        timestamp: serverTime,
        payload: const <String, dynamic>{},
      );
      notifier.processEvent(wsEvent, source: SystemEventSource.ws);

      // Now an event arrives via FCM with `expiresAt` slightly in the
      // past relative to server time. Without the anchor, the filter
      // would mistakenly accept it (device clock thinks it's an hour
      // earlier). With the anchor, it correctly drops.
      final staleViaFcm = SystemEventEntity.fromComponents(
        id: 'e2',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: serverTime.subtract(const Duration(seconds: 30)),
        payload: const <String, dynamic>{},
        expiresAt: serverTime.subtract(const Duration(seconds: 1)),
      );
      expect(
        notifier.processEvent(staleViaFcm, source: SystemEventSource.fcm),
        isFalse,
        reason:
            'expiry filter must use the WS-anchored server-time '
            'estimate, not the device-clock fallback',
      );
    });

    test('S25 — FCM-source events do NOT update the server-time anchor '
        '(FCM payloads can be hours stale; back-dating the anchor would '
        'mis-fire the expiry filter on subsequent events)', () {
      final container = _buildContainer(local);
      final notifier = container.read(systemEventProvider.notifier);

      final realServerTime = DateTime.utc(2026, 4, 25, 12);
      notifier.debugLocalNow = () => realServerTime;

      // First seed a WS anchor at the real server time.
      final wsEvent = SystemEventEntity.fromComponents(
        id: 'ws1',
        rawType: 'chat_message',
        targetRoleStr: 'technician',
        timestamp: realServerTime,
        payload: const <String, dynamic>{},
      );
      notifier.processEvent(wsEvent, source: SystemEventSource.ws);

      // Now an FCM event with a 4-hour-stale timestamp arrives. If
      // the notifier wrongly anchored on this, subsequent expiry
      // checks would think we're 4 hours in the past.
      final staleFcm = SystemEventEntity.fromComponents(
        id: 'fcm1',
        rawType: 'job_new_request',
        targetRoleStr: 'technician',
        timestamp: realServerTime.subtract(const Duration(hours: 4)),
        payload: const <String, dynamic>{},
        // No expiresAt → expiry filter doesn't drop.
      );
      notifier.processEvent(staleFcm, source: SystemEventSource.fcm);

      // Verify the anchor was not regressed: a fresh event with
      // `expiresAt == realServerTime + 1ms` must still be accepted
      // (would be rejected if the anchor had been back-dated 4h and
      // the device clock had drifted forward).
      final freshAfter = SystemEventEntity.fromComponents(
        id: 'e_fresh',
        rawType: 'payment_received',
        targetRoleStr: 'technician',
        timestamp: realServerTime,
        payload: const <String, dynamic>{},
        expiresAt: realServerTime.add(const Duration(seconds: 1)),
      );
      expect(notifier.processEvent(freshAfter), isTrue);
    });
  });

  // ─── Reset + privacy ───────────────────────────────────────────────────

  group('reset + privacy guarantee', () {
    test('S14 — reset() clears in-memory state to defaults and does NOT touch '
        'persistence (orchestrator owns persistence cleanup)', () {
      when(
        () => local.getLastSyncTimestamp(),
      ).thenReturn('2026-04-25T12:00:00Z');
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
      'container builds with default state, no inherited cursor',
      () {
        when(() => local.getLastSyncTimestamp()).thenReturn(null);
        when(() => local.getCachedEventList()).thenReturn(null);
        final container = _buildContainer(local);

        final state = container.read(systemEventProvider);

        expect(state, const SystemEventState());
        expect(state.lastSyncTimestamp, isNull);
      },
    );
  });
}

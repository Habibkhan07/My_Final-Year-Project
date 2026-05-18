import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/data/repositories/event_repository.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/fcm_tap_intent_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/services/fcm_handler.dart';
import 'package:mocktail/mocktail.dart';

class _MockSystemEventNotifier extends Mock implements SystemEventNotifier {}

class _MockEventSyncNotifier extends Mock implements EventSyncNotifier {}

class _MockFcmTapIntentNotifier extends Mock implements FcmTapIntentNotifier {}

class _MockEventRepository extends Mock implements EventRepository {}

class _MockEventLocalDataSource extends Mock implements EventLocalDataSource {}

SystemEventEntity _fallbackEntity() {
  return SystemEventEntity.fromComponents(
    id: '__fallback__',
    rawType: 'JOB_CREATED',
    targetRoleStr: 'technician',
    timestamp: DateTime.utc(2026, 4, 25, 12),
    payload: const <String, dynamic>{},
  );
}

Map<String, dynamic> _baseData({
  String id = 'e1',
  String rawType = 'JOB_CREATED',
  String targetRole = 'technician',
  String timestamp = '2026-04-25T12:00:00Z',
  Object? payload,
}) {
  // FCM is the offline-fallback channel for events specifically — streams
  // never reach FCM — so every FCM-data fixture pins `kind: "event"`.
  return <String, dynamic>{
    'kind': 'event',
    'id': id,
    'rawType': rawType,
    'targetRole': targetRole,
    'timestamp': timestamp,
    'payload': ?payload,
  };
}

void main() {
  late _MockSystemEventNotifier eventNotifier;
  late _MockEventSyncNotifier syncNotifier;
  late _MockFcmTapIntentNotifier tapIntentNotifier;
  late _MockEventRepository repo;
  late _MockEventLocalDataSource local;

  setUpAll(() {
    registerFallbackValue(_fallbackEntity());
    registerFallbackValue(SystemEventSource.unknown);
  });

  setUp(() {
    eventNotifier = _MockSystemEventNotifier();
    syncNotifier = _MockEventSyncNotifier();
    tapIntentNotifier = _MockFcmTapIntentNotifier();
    repo = _MockEventRepository();
    local = _MockEventLocalDataSource();

    when(
      () => eventNotifier.processEvent(any(), source: any(named: 'source')),
    ).thenReturn(true);
    when(() => syncNotifier.syncMissedEvents()).thenAnswer((_) async {});
    when(() => tapIntentNotifier.setTapIntent(any())).thenReturn(null);
    when(
      () => local.consumePendingBackgroundEvents(),
    ).thenAnswer((_) async => <Map<String, dynamic>>[]);
    when(() => repo.unregisterDevice(any())).thenAnswer((_) async {});
  });

  FCMHandler buildHandler() => FCMHandler(
    eventNotifier: eventNotifier,
    syncNotifier: syncNotifier,
    tapIntentNotifier: tapIntentNotifier,
    repository: repo,
    localDataSource: local,
  );

  // ─── _processRemoteMessage — payload normalization ────────────────────

  group('processRemoteMessage — payload normalization', () {
    test('F1 — nested-map payload passes through unchanged', () {
      final handler = buildHandler();

      handler.processRemoteMessage(
        _baseData(payload: <String, dynamic>{'job_id': 'abc'}),
      );

      // FCM-source tag is part of the contract — the notifier's
      // server-time anchor depends on this not being `ws`.
      final captured = verify(
        () => eventNotifier.processEvent(
          captureAny(),
          source: SystemEventSource.fcm,
        ),
      ).captured;
      expect(captured, hasLength(1));
      final entity = captured.single as SystemEventEntity;
      expect(entity.payload, {'job_id': 'abc'});
      expect(entity.id, 'e1');
    });

    test('F2 — FCM string-encoded payload is jsonDecoded before mapping '
        '(production case)', () {
      final handler = buildHandler();

      handler.processRemoteMessage(_baseData(payload: '{"job_id":"abc"}'));

      final captured = verify(
        () => eventNotifier.processEvent(
          captureAny(),
          source: SystemEventSource.fcm,
        ),
      ).captured;
      expect(captured, hasLength(1));
      final entity = captured.single as SystemEventEntity;
      expect(entity.payload, {'job_id': 'abc'});
    });

    test('F3a — payload absent → fromJson fails, processEvent NOT called', () {
      final handler = buildHandler();

      // SystemEventModel.fromJson treats `payload` as a required field — a
      // missing key triggers a TypeError that the outer try swallows.
      handler.processRemoteMessage(_baseData());

      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
    });

    test('F3b — payload is empty string → forwarded to fromJson which fails '
        'on type mismatch, processEvent NOT called', () {
      final handler = buildHandler();

      // The handler's guard only decodes when `isNotEmpty`, so '' is
      // forwarded as-is to fromJson, which expects a Map<String, dynamic>
      // and fails the type check.
      handler.processRemoteMessage(_baseData(payload: ''));

      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
    });

    test(
      'F4 — malformed timestamp → mapper returns null, processEvent NOT called',
      () {
        final handler = buildHandler();

        handler.processRemoteMessage(
          _baseData(payload: <String, dynamic>{}, timestamp: 'not-a-date'),
        );

        verifyNever(
          () => eventNotifier.processEvent(any(), source: any(named: 'source')),
        );
      },
    );

    test('F5 — jsonDecode throws on malformed string payload, swallowed', () {
      final handler = buildHandler();

      handler.processRemoteMessage(_baseData(payload: '{not valid json'));

      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
    });
  });

  // ─── processPendingBackgroundEvents ──────────────────────────────────

  group('processPendingBackgroundEvents', () {
    test(
      'F6 — three events drained in queue order, then sync called',
      () async {
        when(() => local.consumePendingBackgroundEvents()).thenAnswer(
          (_) async => [
            _baseData(id: 'e1', payload: <String, dynamic>{}),
            _baseData(id: 'e2', payload: <String, dynamic>{}),
            _baseData(id: 'e3', payload: <String, dynamic>{}),
          ],
        );

        final handler = buildHandler();
        await handler.processPendingBackgroundEvents();

        verifyInOrder([
          () => eventNotifier.processEvent(
            any(that: predicate<SystemEventEntity>((e) => e.id == 'e1')),
            source: SystemEventSource.fcm,
          ),
          () => eventNotifier.processEvent(
            any(that: predicate<SystemEventEntity>((e) => e.id == 'e2')),
            source: SystemEventSource.fcm,
          ),
          () => eventNotifier.processEvent(
            any(that: predicate<SystemEventEntity>((e) => e.id == 'e3')),
            source: SystemEventSource.fcm,
          ),
          () => syncNotifier.syncMissedEvents(),
        ]);
      },
    );

    test('F7 — empty queue: no processEvent calls, syncMissedEvents '
        'STILL called (post-drain reconcile is unconditional)', () async {
      when(
        () => local.consumePendingBackgroundEvents(),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      final handler = buildHandler();
      await handler.processPendingBackgroundEvents();

      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
      verify(() => syncNotifier.syncMissedEvents()).called(1);
    });

    test('F8 — consumePendingBackgroundEvents throws → swallowed, '
        'syncMissedEvents NOT called', () async {
      when(
        () => local.consumePendingBackgroundEvents(),
      ).thenThrow(Exception('boom'));

      final handler = buildHandler();

      // Must not throw.
      await handler.processPendingBackgroundEvents();

      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
      verifyNever(() => syncNotifier.syncMissedEvents());
    });

    test('F9 — dedup integration: WS-delivered event suppresses identical '
        'FCM-drained event (real SystemEventNotifier)', () async {
      // Stub the local source the SystemEventNotifier consults during build()
      // and the local source the FCMHandler consults during drain. They are
      // the same provider, so a single mock satisfies both.
      when(() => local.getLastSyncTimestamp()).thenReturn(null);

      final container = ProviderContainer(
        overrides: [eventLocalDataSourceProvider.overrideWithValue(local)],
      );
      addTearDown(container.dispose);

      final realNotifier = container.read(systemEventProvider.notifier);

      // 1. WS-side delivery first.
      final wsEntity = SystemEventEntity.fromComponents(
        id: 'X',
        rawType: 'JOB_CREATED',
        targetRoleStr: 'technician',
        timestamp: DateTime.utc(2026, 4, 25, 12),
        payload: const <String, dynamic>{},
      );
      final firstAccept = realNotifier.processEvent(wsEntity);
      expect(firstAccept, isTrue);

      // 2. Drain a queue that contains the same id.
      when(() => local.consumePendingBackgroundEvents()).thenAnswer(
        (_) async => [
          _baseData(id: 'X', payload: <String, dynamic>{'duplicate': true}),
        ],
      );

      final handler = FCMHandler(
        eventNotifier: realNotifier,
        syncNotifier: syncNotifier,
        tapIntentNotifier: tapIntentNotifier,
        repository: repo,
        localDataSource: local,
      );
      await handler.processPendingBackgroundEvents();

      // Dedup must have rejected the second arrival — observable via state:
      // only one id in the dedup map and `latestEvent` is still the WS copy
      // (no `duplicate: true` payload overwrite).
      final state = container.read(systemEventProvider);
      expect(state.processedEventIds.keys, ['X']);
      expect(state.latestEvent, isNotNull);
      expect(state.latestEvent!.payload.containsKey('duplicate'), isFalse);
    });
  });

  // ─── processTapMessage — user tap on tray notification ───────────────

  group('processTapMessage — user-initiated tap path', () {
    test('FT1 — well-formed tap feeds tapIntentNotifier, NOT systemEvent', () {
      final handler = buildHandler();

      handler.processTapMessage(
        _baseData(
          id: 'tap-evt',
          rawType: 'BOOKING_REJECTED',
          payload: <String, dynamic>{'job_id': '42'},
        ),
      );

      final captured = verify(
        () => tapIntentNotifier.setTapIntent(captureAny()),
      ).captured;
      expect(captured, hasLength(1));
      final entity = captured.single as SystemEventEntity;
      expect(entity.id, 'tap-evt');
      expect(entity.payload, {'job_id': '42'});
      // Tap bypasses the funnel — `processEvent` MUST NOT be called.
      // Routing dedup/expiry/banner rules don't apply to user-initiated taps.
      verifyNever(
        () => eventNotifier.processEvent(any(), source: any(named: 'source')),
      );
    });

    test('FT2 — string-encoded payload is jsonDecoded before mapping '
        '(production FCM shape)', () {
      final handler = buildHandler();

      handler.processTapMessage(
        _baseData(
          id: 'tap-evt-2',
          rawType: 'BOOKING_REJECTED',
          payload: '{"job_id":"42","reason":"sla_timeout"}',
        ),
      );

      final captured = verify(
        () => tapIntentNotifier.setTapIntent(captureAny()),
      ).captured;
      final entity = captured.single as SystemEventEntity;
      expect(entity.payload, {'job_id': '42', 'reason': 'sla_timeout'});
    });

    test('FT3 — malformed payload → decode fails, tapIntent NOT set', () {
      final handler = buildHandler();

      handler.processTapMessage(_baseData(payload: '{not valid json'));

      verifyNever(() => tapIntentNotifier.setTapIntent(any()));
    });

    test('FT4 — payload missing → fromJson fails, tapIntent NOT set', () {
      final handler = buildHandler();

      handler.processTapMessage(_baseData());

      verifyNever(() => tapIntentNotifier.setTapIntent(any()));
    });
  });

  // ─── unregister ──────────────────────────────────────────────────────

  group('unregister', () {
    test('F10 — _currentToken set → repository.unregisterDevice called, '
        'token nulled afterwards', () async {
      final handler = buildHandler()..debugCurrentToken = 'fcm-tok-123';

      await handler.unregister();

      verify(() => repo.unregisterDevice('fcm-tok-123')).called(1);
      expect(handler.debugCurrentToken, isNull);
    });

    test(
      'F11 — _currentToken null → repository.unregisterDevice NOT called',
      () async {
        final handler = buildHandler();
        // Pre-condition: no init() has been run, so _currentToken is null.
        expect(handler.debugCurrentToken, isNull);

        await handler.unregister();

        verifyNever(() => repo.unregisterDevice(any()));
      },
    );
  });
}

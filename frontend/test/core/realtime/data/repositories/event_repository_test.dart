import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/data/datasources/event_remote_data_source.dart';
import 'package:frontend/core/realtime/data/models/system_event_model.dart';
import 'package:frontend/core/realtime/data/repositories/event_repository.dart';
import 'package:frontend/core/realtime/domain/failures/event_failures.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EventRemoteDataSource {}

class _MockLocal extends Mock implements EventLocalDataSource {}

SystemEventModel _event({
  String id = 'evt-1',
  String timestamp = '2025-01-01T00:00:00Z',
}) {
  return SystemEventModel(
    id: id,
    rawType: 'job_dispatched',
    targetRole: 'technician',
    timestamp: timestamp,
    payload: const {},
  );
}

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late EventRepository repo;

  setUpAll(() {
    registerFallbackValue(<SystemEventModel>[]);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    repo = EventRepository(remote, local);

    // Default no-op stubs; individual tests override.
    when(() => local.cacheEventList(any())).thenAnswer((_) async {});
    when(() => local.saveLastSyncTimestamp(any())).thenAnswer((_) async {});
    when(() => local.getCachedEventList()).thenReturn(null);
    when(() => local.getPendingAcks()).thenReturn(const <String>[]);
    when(() => local.savePendingAcks(any())).thenAnswer((_) async {});
    when(() => local.clearPendingAcks()).thenAnswer((_) async {});
  });

  // ─── syncMissedEvents — cursor selection ───────────────────────────────

  group('syncMissedEvents — cursor selection', () {
    test('P1 — newest timestamp wins regardless of array order', () async {
      final batch = [
        _event(id: 'a', timestamp: '2025-01-02T00:00:00Z'),
        _event(id: 'b', timestamp: '2025-01-01T00:00:00Z'),
        _event(id: 'c', timestamp: '2025-01-03T00:00:00Z'),
      ];
      when(() => remote.fetchEventsSince(any())).thenAnswer((_) async => batch);

      await repo.syncMissedEvents('2024-12-01T00:00:00Z');

      verify(() => local.saveLastSyncTimestamp('2025-01-03T00:00:00Z'))
          .called(1);
    });

    test(
        'P2 — empty batch caches empty list but does NOT advance cursor',
        () async {
      when(() => remote.fetchEventsSince(any())).thenAnswer((_) async => []);

      await repo.syncMissedEvents('2024-12-01T00:00:00Z');

      verify(() => local.cacheEventList(<SystemEventModel>[])).called(1);
      verifyNever(() => local.saveLastSyncTimestamp(any()));
    });
  });

  // ─── syncMissedEvents — offline-first ──────────────────────────────────

  group('syncMissedEvents — offline-first', () {
    test('P3 — SocketException + cache present → returns cached entities', () async {
      when(() => remote.fetchEventsSince(any()))
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedEventList()).thenReturn([_event()]);

      final result = await repo.syncMissedEvents('2024-12-01T00:00:00Z');

      expect(result.length, 1);
      expect(result.first.id, 'evt-1');
    });

    test('P4 — SocketException + cache absent → throws EventSyncNetworkFailure',
        () async {
      when(() => remote.fetchEventsSince(any()))
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedEventList()).thenReturn(null);

      await expectLater(
        () => repo.syncMissedEvents('2024-12-01T00:00:00Z'),
        throwsA(isA<EventSyncNetworkFailure>()),
      );
    });

    test('P5 — TimeoutException + cache present → returns cached', () async {
      when(() => remote.fetchEventsSince(any()))
          .thenThrow(TimeoutException('timeout'));
      when(() => local.getCachedEventList()).thenReturn([_event()]);

      final result = await repo.syncMissedEvents('2024-12-01T00:00:00Z');

      expect(result.length, 1);
    });

    test('P6 — TimeoutException + cache absent → throws EventSyncNetworkFailure',
        () async {
      when(() => remote.fetchEventsSince(any()))
          .thenThrow(TimeoutException('timeout'));
      when(() => local.getCachedEventList()).thenReturn(null);

      await expectLater(
        () => repo.syncMissedEvents('2024-12-01T00:00:00Z'),
        throwsA(isA<EventSyncNetworkFailure>()),
      );
    });
  });

  // ─── syncMissedEvents — error mapping ──────────────────────────────────

  group('syncMissedEvents — error mapping', () {
    test('P7 — HttpFailure(401) → EventSyncUnauthorized', () async {
      when(() => remote.fetchEventsSince(any())).thenThrow(
        const HttpFailure(
            statusCode: 401, code: 'unauthorized', message: 'expired'),
      );

      await expectLater(
        () => repo.syncMissedEvents('2024-12-01T00:00:00Z'),
        throwsA(isA<EventSyncUnauthorized>()),
      );
    });

    test('P8 — HttpFailure(500, "backend down") → EventSyncServerFailure preserves message',
        () async {
      when(() => remote.fetchEventsSince(any())).thenThrow(
        const HttpFailure(
            statusCode: 500, code: 'internal_error', message: 'backend down'),
      );

      await expectLater(
        () => repo.syncMissedEvents('2024-12-01T00:00:00Z'),
        throwsA(isA<EventSyncServerFailure>()
            .having((f) => f.message, 'message', 'backend down')),
      );
    });

    test('P9 — HttpFailure(403) → EventSyncServerFailure (non-401 → ServerFailure)',
        () async {
      when(() => remote.fetchEventsSince(any())).thenThrow(
        const HttpFailure(
            statusCode: 403, code: 'forbidden', message: 'no perms'),
      );

      await expectLater(
        () => repo.syncMissedEvents('2024-12-01T00:00:00Z'),
        throwsA(isA<EventSyncServerFailure>()),
      );
    });
  });

  // ─── fetchUnacknowledgedCritical ───────────────────────────────────────

  group('fetchUnacknowledgedCritical', () {
    test('P10 — happy path returns mapped entities and caches model list',
        () async {
      final batch = [_event(id: 'a'), _event(id: 'b')];
      when(() => remote.fetchUnacknowledgedCritical())
          .thenAnswer((_) async => batch);

      final result = await repo.fetchUnacknowledgedCritical();

      expect(result.length, 2);
      verify(() => local.cacheEventList(batch)).called(1);
    });

    test(
        'P11 — NEVER advances saveLastSyncTimestamp (resurfacing must not regress cursor)',
        () async {
      final batch = [
        _event(id: 'a', timestamp: '2025-01-05T00:00:00Z'),
      ];
      when(() => remote.fetchUnacknowledgedCritical())
          .thenAnswer((_) async => batch);

      await repo.fetchUnacknowledgedCritical();

      verifyNever(() => local.saveLastSyncTimestamp(any()));
    });

    test('P12 — SocketException + cache present → returns cached', () async {
      when(() => remote.fetchUnacknowledgedCritical())
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedEventList()).thenReturn([_event()]);

      final result = await repo.fetchUnacknowledgedCritical();

      expect(result.length, 1);
    });

    test('P13 — SocketException + cache absent → throws EventSyncNetworkFailure',
        () async {
      when(() => remote.fetchUnacknowledgedCritical())
          .thenThrow(const SocketException('offline'));
      when(() => local.getCachedEventList()).thenReturn(null);

      await expectLater(
        () => repo.fetchUnacknowledgedCritical(),
        throwsA(isA<EventSyncNetworkFailure>()),
      );
    });

    test('P14 — HttpFailure(401) → EventSyncUnauthorized', () async {
      when(() => remote.fetchUnacknowledgedCritical()).thenThrow(
        const HttpFailure(
            statusCode: 401, code: 'unauthorized', message: 'expired'),
      );

      await expectLater(
        () => repo.fetchUnacknowledgedCritical(),
        throwsA(isA<EventSyncUnauthorized>()),
      );
    });

    test('P15 — HttpFailure(non-401) → EventSyncServerFailure', () async {
      when(() => remote.fetchUnacknowledgedCritical()).thenThrow(
        const HttpFailure(
            statusCode: 500, code: 'internal_error', message: 'down'),
      );

      await expectLater(
        () => repo.fetchUnacknowledgedCritical(),
        throwsA(isA<EventSyncServerFailure>()),
      );
    });
  });

  // ─── acknowledgeEvents — never-throws contract ─────────────────────────

  group('acknowledgeEvents', () {
    test(
        'P16 — inputs merged with pending and deduped before POST',
        () async {
      when(() => local.getPendingAcks()).thenReturn(['b', 'c']);
      when(() => remote.acknowledgeEvents(any())).thenAnswer((_) async {});

      await repo.acknowledgeEvents(['a', 'b']);

      final captured =
          verify(() => remote.acknowledgeEvents(captureAny())).captured;
      expect(captured.length, 1);
      final sent = (captured.single as List<String>).toSet();
      expect(sent, {'a', 'b', 'c'});
    });

    test('P17 — empty input + empty pending → no remote POST', () async {
      when(() => local.getPendingAcks()).thenReturn(const <String>[]);

      await repo.acknowledgeEvents(const []);

      verifyNever(() => remote.acknowledgeEvents(any()));
      verifyNever(() => local.savePendingAcks(any()));
      verifyNever(() => local.clearPendingAcks());
    });

    test('P18 — empty input + non-empty pending → POSTs the existing pending set',
        () async {
      when(() => local.getPendingAcks()).thenReturn(['x', 'y']);
      when(() => remote.acknowledgeEvents(any())).thenAnswer((_) async {});

      await repo.acknowledgeEvents(const []);

      final captured =
          verify(() => remote.acknowledgeEvents(captureAny())).captured;
      final sent = (captured.single as List<String>).toSet();
      expect(sent, {'x', 'y'});
    });

    test('P19 — POST succeeds → clearPendingAcks called; savePendingAcks NOT called',
        () async {
      when(() => remote.acknowledgeEvents(any())).thenAnswer((_) async {});

      await repo.acknowledgeEvents(['a']);

      verify(() => local.clearPendingAcks()).called(1);
      verifyNever(() => local.savePendingAcks(any()));
    });

    group('P20 — POST throws → savePendingAcks(merged) and no exception escapes',
        () {
      Future<void> runFor(Object error) async {
        when(() => local.getPendingAcks()).thenReturn(['existing']);
        when(() => remote.acknowledgeEvents(any())).thenThrow(error);

        await expectLater(
          () => repo.acknowledgeEvents(['new']),
          returnsNormally,
        );

        final captured =
            verify(() => local.savePendingAcks(captureAny())).captured;
        final saved = (captured.single as List<String>).toSet();
        expect(saved, {'existing', 'new'});
        verifyNever(() => local.clearPendingAcks());
      }

      test('HttpFailure', () async {
        await runFor(const HttpFailure(
            statusCode: 500, code: 'internal_error', message: 'fail'));
      });

      test('SocketException', () async {
        await runFor(const SocketException('offline'));
      });

      test('TimeoutException', () async {
        await runFor(TimeoutException('timeout'));
      });
    });
  });

  // ─── registerDevice ────────────────────────────────────────────────────

  group('registerDevice', () {
    test('P21 — happy path delegates to remote.registerDevice', () async {
      when(() => remote.registerDevice(any(), any())).thenAnswer((_) async {});

      await repo.registerDevice('tok', 'android');

      verify(() => remote.registerDevice('tok', 'android')).called(1);
    });

    group('P22 — network errors → DeviceRegistrationNetworkFailure', () {
      test('SocketException', () async {
        when(() => remote.registerDevice(any(), any()))
            .thenThrow(const SocketException('offline'));

        await expectLater(
          () => repo.registerDevice('tok', 'android'),
          throwsA(isA<DeviceRegistrationNetworkFailure>()),
        );
      });

      test('TimeoutException', () async {
        when(() => remote.registerDevice(any(), any()))
            .thenThrow(TimeoutException('timeout'));

        await expectLater(
          () => repo.registerDevice('tok', 'android'),
          throwsA(isA<DeviceRegistrationNetworkFailure>()),
        );
      });
    });

    test('P23 — HttpFailure → DeviceRegistrationServerFailure preserves message',
        () async {
      when(() => remote.registerDevice(any(), any())).thenThrow(
        const HttpFailure(
            statusCode: 500,
            code: 'internal_error',
            message: 'down for maintenance'),
      );

      await expectLater(
        () => repo.registerDevice('tok', 'android'),
        throwsA(isA<DeviceRegistrationServerFailure>()
            .having((f) => f.message, 'message', 'down for maintenance')),
      );
    });
  });

  // ─── unregisterDevice — best-effort, never-throws ──────────────────────

  group('unregisterDevice', () {
    test('P24 — happy path delegates to remote.unregisterDevice', () async {
      when(() => remote.unregisterDevice(any())).thenAnswer((_) async {});

      await repo.unregisterDevice('tok');

      verify(() => remote.unregisterDevice('tok')).called(1);
    });

    group('P25 — any exception is swallowed', () {
      test('SocketException', () async {
        when(() => remote.unregisterDevice(any()))
            .thenThrow(const SocketException('offline'));

        await expectLater(
          () => repo.unregisterDevice('tok'),
          returnsNormally,
        );
      });

      test('HttpFailure(500)', () async {
        when(() => remote.unregisterDevice(any())).thenThrow(
          const HttpFailure(
              statusCode: 500, code: 'internal_error', message: 'fail'),
        );

        await expectLater(
          () => repo.unregisterDevice('tok'),
          returnsNormally,
        );
      });
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

ProviderContainer _buildContainer(EventLocalDataSource local) {
  final container = ProviderContainer(
    overrides: [
      eventLocalDataSourceProvider.overrideWithValue(local),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Map<String, dynamic> _eventFrame({
  String id = 'd-evt-1',
  String rawType = 'job_dispatched',
  String targetRole = 'technician',
  String timestamp = '2026-04-25T12:00:00Z',
  Map<String, dynamic> payload = const <String, dynamic>{},
}) =>
    <String, dynamic>{
      'kind': 'event',
      'id': id,
      'rawType': rawType,
      'targetRole': targetRole,
      'timestamp': timestamp,
      'payload': payload,
    };

Map<String, dynamic> _streamFrame({
  String streamType = 'wallet_balance',
  String timestamp = '2026-04-25T12:00:00Z',
  Map<String, dynamic> payload = const <String, dynamic>{'balance': 4237},
}) =>
    <String, dynamic>{
      'kind': 'stream',
      'streamType': streamType,
      'timestamp': timestamp,
      'payload': payload,
    };

void main() {
  late _MockLocal local;

  setUp(() {
    local = _MockLocal();
    // SystemEventNotifier.build() reads this when seeded — return null so
    // every test starts from a clean cursor.
    when(() => local.getLastSyncTimestamp()).thenReturn(null);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D1 — kind=event happy path
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D1 — kind="event" frame: mapped entity is forwarded to '
      'SystemEventNotifier.processEvent', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    dispatcher.dispatch(_eventFrame(id: 'd-evt-1'));

    final state = container.read(systemEventProvider);
    expect(state.latestEvent, isNotNull);
    expect(state.latestEvent!.id, 'd-evt-1');
    expect(state.processedEventIds.containsKey('d-evt-1'), isTrue);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D2 — kind=stream with registered handler
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D2 — kind="stream" with registered handler: handler invoked with '
      'payload only (no envelope)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    Map<String, dynamic>? receivedPayload;
    dispatcher.register('wallet_balance', (payload) {
      receivedPayload = payload;
    });

    dispatcher.dispatch(_streamFrame(payload: const {'balance': 5000}));

    expect(receivedPayload, equals(const {'balance': 5000}));
    // Stream frames must NEVER touch the event pipeline.
    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D3 — kind=stream with no handler registered
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D3 — kind="stream" with unknown streamType (no handler registered): '
      'dropped silently, registry unchanged, no throw', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    expect(
      () => dispatcher.dispatch(_streamFrame(streamType: 'telemetry_v2')),
      returnsNormally,
    );
    expect(dispatcher.hasHandlerFor('telemetry_v2'), isFalse);
    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D4 — kind=event but mapper returns null (bad timestamp)
  // ───────────────────────────────────────────────────────────────────────
  //
  // Adjustment 2 from the patch decision log: the dispatcher's event path
  // must explicitly null-check mapper.toDomain() and drop, never push a
  // null entity into the notifier. Verifies that contract directly.

  test(
      'D4 — kind="event" with malformed timestamp: mapper returns null, '
      'dispatcher drops silently, processEvent NOT called', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    dispatcher.dispatch(_eventFrame(timestamp: 'not-a-real-timestamp'));

    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D5 — Missing kind: severe + assert in debug
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D5 — frame missing "kind" field: throws AssertionError in debug '
      '(contract violation, not version skew)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    final frameMissingKind = <String, dynamic>{
      'id': 'd-evt-no-kind',
      'rawType': 'job_dispatched',
      'targetRole': 'technician',
      'timestamp': '2026-04-25T12:00:00Z',
      'payload': <String, dynamic>{},
    };

    expect(
      () => dispatcher.dispatch(frameMissingKind),
      throwsA(isA<AssertionError>()),
    );
    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D6 — Unknown kind value
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D6 — frame with unknown kind value (e.g. "telemetry-v2"): dropped '
      'silently with warning log, no throw (treated as version skew)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    final frame = <String, dynamic>{
      'kind': 'telemetry-v2',
      'foo': 'bar',
    };

    expect(() => dispatcher.dispatch(frame), returnsNormally);
    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D7 — register / unregister round-trip
  // ───────────────────────────────────────────────────────────────────────

  test(
      'D7 — register then unregister: handler not invoked after unregister; '
      're-register replaces handler (last-writer-wins)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    var callsToFirstHandler = 0;
    var callsToSecondHandler = 0;

    dispatcher.register('wallet_balance', (_) => callsToFirstHandler++);
    dispatcher.dispatch(_streamFrame());
    expect(callsToFirstHandler, 1);

    dispatcher.unregister('wallet_balance');
    dispatcher.dispatch(_streamFrame());
    expect(callsToFirstHandler, 1, reason: 'after unregister, no more calls');

    // Re-register a different handler under the same key.
    dispatcher.register('wallet_balance', (_) => callsToSecondHandler++);
    dispatcher.dispatch(_streamFrame());
    expect(callsToSecondHandler, 1);
    expect(callsToFirstHandler, 1, reason: 'first handler stays unchanged');
  });
}

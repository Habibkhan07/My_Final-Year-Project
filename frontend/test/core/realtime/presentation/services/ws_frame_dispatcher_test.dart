import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocal extends Mock implements EventLocalDataSource {}

ProviderContainer _buildContainer(EventLocalDataSource local) {
  final container = ProviderContainer(
    overrides: [eventLocalDataSourceProvider.overrideWithValue(local)],
  );
  addTearDown(container.dispose);
  return container;
}

Map<String, dynamic> _eventFrame({
  String id = 'd-evt-1',
  String rawType = 'job_new_request',
  String targetRole = 'technician',
  String timestamp = '2026-04-25T12:00:00Z',
  Map<String, dynamic> payload = const <String, dynamic>{},
}) => <String, dynamic>{
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
}) => <String, dynamic>{
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

  test('D1 — kind="event" frame: mapped entity is forwarded to '
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

  test('D2 — kind="stream" with registered handler: handler invoked with '
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

  test('D3 — kind="stream" with unknown streamType (no handler registered): '
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

  test('D4 — kind="event" with malformed timestamp: mapper returns null, '
      'dispatcher drops silently, processEvent NOT called', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    dispatcher.dispatch(_eventFrame(timestamp: 'not-a-real-timestamp'));

    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D5 — Missing kind: severe + assert in debug
  // ───────────────────────────────────────────────────────────────────────

  test('D5 — frame missing "kind" field: throws AssertionError in debug '
      '(contract violation, not version skew)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    final frameMissingKind = <String, dynamic>{
      'id': 'd-evt-no-kind',
      'rawType': 'job_new_request',
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

  test('D6 — frame with unknown kind value (e.g. "telemetry-v2"): dropped '
      'silently with warning log, no throw (treated as version skew)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    final frame = <String, dynamic>{'kind': 'telemetry-v2', 'foo': 'bar'};

    expect(() => dispatcher.dispatch(frame), returnsNormally);
    expect(container.read(systemEventProvider).latestEvent, isNull);
  });

  // ───────────────────────────────────────────────────────────────────────
  // D7 — register / unregister round-trip
  // ───────────────────────────────────────────────────────────────────────

  test('D7 — register then unregister: handler not invoked after unregister; '
      're-register replaces handler (last-writer-wins)', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    var callsToFirstHandler = 0;
    var callsToSecondHandler = 0;

    void firstHandler(Map<String, dynamic> _) => callsToFirstHandler++;
    void secondHandler(Map<String, dynamic> _) => callsToSecondHandler++;

    dispatcher.register('wallet_balance', firstHandler);
    dispatcher.dispatch(_streamFrame());
    expect(callsToFirstHandler, 1);

    dispatcher.unregister('wallet_balance', firstHandler);
    dispatcher.dispatch(_streamFrame());
    expect(callsToFirstHandler, 1, reason: 'after unregister, no more calls');

    // Re-register a different handler under the same key.
    dispatcher.register('wallet_balance', secondHandler);
    dispatcher.dispatch(_streamFrame());
    expect(callsToSecondHandler, 1);
    expect(callsToFirstHandler, 1, reason: 'first handler stays unchanged');
  });

  // ───────────────────────────────────────────────────────────────────────
  // D8 — identity-checked unregister (audit C5 / R-3)
  // ───────────────────────────────────────────────────────────────────────
  //
  // Race scenario: notifier-A registers handler-A. Notifier-B then
  // registers handler-B for the same streamType (last-writer-wins
  // overwrites A). Now A's `ref.onDispose` runs and calls unregister.
  // A naive `_streamHandlers.remove(streamType)` would silently delete
  // B's handler — leaving the new screen with no GPS frames forever.
  // The identity-checked unregister makes A's late dispose a no-op
  // when the registered handler is no longer A's.

  test('D8 — unregister with stale handler is a no-op when a successor has '
      'replaced the registration', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    var callsToA = 0;
    var callsToB = 0;
    void handlerA(Map<String, dynamic> _) => callsToA++;
    void handlerB(Map<String, dynamic> _) => callsToB++;

    // A registers, then B replaces (last-writer-wins).
    dispatcher.register('wallet_balance', handlerA);
    dispatcher.register('wallet_balance', handlerB);

    // A's late onDispose. Identity check sees B is registered, not A,
    // so the unregister does NOTHING — B remains live.
    dispatcher.unregister('wallet_balance', handlerA);

    dispatcher.dispatch(_streamFrame());
    expect(callsToB, 1, reason: 'B stays registered after A\'s stale unregister');
    expect(callsToA, 0, reason: 'A is no longer registered');
    expect(dispatcher.hasHandlerFor('wallet_balance'), isTrue);
  });

  test('D9 — unregister with the currently-registered handler removes it', () {
    final container = _buildContainer(local);
    final dispatcher = container.read(wsFrameDispatcherProvider);

    var calls = 0;
    void handler(Map<String, dynamic> _) => calls++;

    dispatcher.register('wallet_balance', handler);
    dispatcher.unregister('wallet_balance', handler);

    dispatcher.dispatch(_streamFrame());
    expect(calls, 0);
    expect(dispatcher.hasHandlerFor('wallet_balance'), isFalse);
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'package:frontend/core/realtime/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'package:frontend/core/realtime/presentation/services/fcm_handler.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocalDataSource extends Mock
    implements EventLocalDataSource {}

class _MockSystemEventNotifier extends Mock implements SystemEventNotifier {}

class _MockWsConnectionNotifier extends Mock
    implements WsConnectionNotifier {}

class _MockFCMHandler extends Mock implements FCMHandler {}

class _MockEventSyncNotifier extends Mock implements EventSyncNotifier {}

/// Recording fake notifiers used by the boot-flow tests below. Each one
/// extends the real notifier and overrides only the methods that
/// `bootAfterAuth` touches; everything else inherits.

class _RecordingWsNotifier extends WsConnectionNotifier {
  final List<String> connectCalls = [];
  int disconnectCount = 0;
  Completer<void>? blockConnect;

  @override
  WsConnectionStatus build() => WsConnectionStatus.disconnected;

  @override
  Future<void> connect(String authToken) async {
    connectCalls.add(authToken);
    if (blockConnect != null) await blockConnect!.future;
  }

  @override
  void disconnect() {
    disconnectCount++;
  }
}

class _RecordingEventSyncNotifier extends EventSyncNotifier {
  @override
  Object? build() => null;
}

/// `bootAfterAuth` takes a `Ref`, but tests work with `ProviderContainer`.
/// This probe provider just returns its own `ref` so each test can fetch a
/// `Ref` that is wired into the container's overrides.
final _refProbe = Provider<Ref>((ref) => ref);

void main() {
  // ─── Privacy canary ───────────────────────────────────────────────────
  //
  // The session-1 privacy fix added three persistence-clearing calls and a
  // callback teardown to `performTeardown`. This test pins down the exact
  // call sequence so a future contributor cannot silently reorder or drop
  // any of them — doing so would let one user's events leak into the next
  // user's session on a shared device.

  test(
      'O1 — performTeardown calls dependencies in the documented order '
      'and clears onUnauthorized', () async {
    final ws = _MockWsConnectionNotifier();
    final fcm = _MockFCMHandler();
    final sysEvent = _MockSystemEventNotifier();
    final eventSync = _MockEventSyncNotifier();
    final local = _MockEventLocalDataSource();

    when(() => fcm.unregister()).thenAnswer((_) async {});
    when(() => local.clearLastSyncTimestamp()).thenAnswer((_) async {});
    when(() => local.clearCachedEvents()).thenAnswer((_) async {});
    when(() => local.clearPendingAcks()).thenAnswer((_) async {});

    // Pre-condition: a non-null callback is wired so the test can prove the
    // null-assignment at the tail of teardown actually happened.
    eventSync.onUnauthorized = () {};
    // Discard the setter call we just made so the verify() below counts
    // only the assignment performed by `performTeardown`.
    clearInteractions(eventSync);

    await AppLifecycleOrchestrator.performTeardown(
      wsConnection: ws,
      fcmHandler: fcm,
      systemEventNotifier: sysEvent,
      eventSync: eventSync,
      local: local,
    );

    // Strict ordering — see `performTeardown` dartdoc for the rationale of
    // each step. `verifyInOrder` allows other unrelated calls between, but
    // we have no other interactions to worry about because every dependency
    // is a fresh mock.
    verifyInOrder([
      () => ws.disconnect(),
      () => fcm.unregister(),
      () => sysEvent.reset(),
      () => local.clearLastSyncTimestamp(),
      () => local.clearCachedEvents(),
      () => local.clearPendingAcks(),
    ]);

    // Tail: the unauthorized hook must be nulled exactly once.
    verify(() => eventSync.onUnauthorized = null).called(1);
  });

  // ─── Boot hooks registry ────────────────────────────────────────────────
  //
  // The session-2 refactor moved the inline `ref.read(incomingJobQueueProvider)`
  // out of `bootAfterAuth` and into `realtimeBootHooksProvider`. These tests
  // pin the contract: the registry contains the queue provider, and
  // `bootAfterAuth` actually iterates it. Without these, a future contributor
  // could silently drop the for-loop or empty the registry and the first
  // `job_new_request` after every login would be missed.

  group('realtimeBootHooksProvider registry', () {
    test('R1 — default registry contains incomingJobQueueProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final hooks = container.read(realtimeBootHooksProvider);

      expect(hooks, contains(incomingJobQueueProvider),
          reason: 'list-route event features must be registered here so '
              'their queue notifier wakes before WS connect; missing entry '
              'silently drops the first event after every login');
    });

    test('R2 — bootAfterAuth reads every entry in the registry', () async {
      final probeReads = <int>[];
      // Probe providers double as registry entries and as side-effect
      // counters: each `ref.read` increments `probeReads`.
      final probeA = Provider<int>((ref) {
        probeReads.add(0);
        return 0;
      });
      final probeB = Provider<int>((ref) {
        probeReads.add(1);
        return 1;
      });

      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final container = ProviderContainer(overrides: [
        realtimeBootHooksProvider.overrideWith((ref) => [probeA, probeB]),
        realtime_di.fcmHandlerProvider.overrideWithValue(fcm),
        eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
        wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
      ]);
      addTearDown(container.dispose);

      await AppLifecycleOrchestrator.bootAfterAuth(
          container.read(_refProbe), 'token');

      // Both probes must have been read exactly once. If a future refactor
      // drops the for-loop, this fails immediately.
      expect(probeReads, [0, 1]);
    });
  });

  // ─── bootAfterAuth — sentinel race ──────────────────────────────────────
  //
  // The original session-2 plan dismissed the boot/teardown race as
  // "benign." It is actually "connecting → disconnecting →
  // connecting-with-stale-token" because boot's WS connect runs after
  // teardown clears the token. The sentinel (`onUnauthorized == null`)
  // turns the third leg into a no-op. This test pins that behavior.

  group('bootAfterAuth sentinel', () {
    test(
        'B1 — happy path: callback set, hooks read, FCM init, WS connect',
        () async {
      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) async {});

      final container = ProviderContainer(overrides: [
        realtimeBootHooksProvider.overrideWith((ref) => const []),
        realtime_di.fcmHandlerProvider.overrideWithValue(fcm),
        eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
        wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
      ]);
      addTearDown(container.dispose);

      await AppLifecycleOrchestrator.bootAfterAuth(
          container.read(_refProbe), 'happy-token');

      verify(() => fcm.initialize()).called(1);
      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      expect(ws.connectCalls, ['happy-token']);
      expect(container.read(eventSyncProvider.notifier).onUnauthorized,
          isNotNull);
    });

    test(
        'B2 — sentinel: if onUnauthorized is nulled while FCM init awaits, '
        'WS.connect MUST NOT fire (prevents stale-token reconnect)',
        () async {
      final fcmGate = Completer<void>();
      final fcm = _MockFCMHandler();
      when(() => fcm.initialize()).thenAnswer((_) => fcmGate.future);

      final container = ProviderContainer(overrides: [
        realtimeBootHooksProvider.overrideWith((ref) => const []),
        realtime_di.fcmHandlerProvider.overrideWithValue(fcm),
        eventSyncProvider.overrideWith(_RecordingEventSyncNotifier.new),
        wsConnectionProvider.overrideWith(_RecordingWsNotifier.new),
      ]);
      addTearDown(container.dispose);

      // Kick off boot — it will park inside `fcm.initialize()`.
      final bootFuture =
          AppLifecycleOrchestrator.bootAfterAuth(
              container.read(_refProbe), 'race-token');
      await Future<void>.delayed(Duration.zero);

      // Simulate teardown landing while boot is parked: null the callback.
      // (The real `performTeardown` does this last; here we model just the
      // observable signal the sentinel checks.)
      container.read(eventSyncProvider.notifier).onUnauthorized = null;

      // Release FCM init; boot resumes and hits the sentinel.
      fcmGate.complete();
      await bootFuture;

      final ws =
          container.read(wsConnectionProvider.notifier) as _RecordingWsNotifier;
      expect(ws.connectCalls, isEmpty,
          reason: 'sentinel must skip WS.connect when teardown ran during '
              'FCM init; otherwise we would reconnect with a token that '
              'repository.logout has cleared');
    });
  });
}

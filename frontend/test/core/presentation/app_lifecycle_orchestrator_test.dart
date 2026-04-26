import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/presentation/app_lifecycle_orchestrator.dart';
import 'package:frontend/core/presentation/notifiers/event_sync_notifier.dart';
import 'package:frontend/core/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/presentation/services/fcm_handler.dart';
import 'package:mocktail/mocktail.dart';

class _MockEventLocalDataSource extends Mock
    implements EventLocalDataSource {}

class _MockSystemEventNotifier extends Mock implements SystemEventNotifier {}

class _MockWsConnectionNotifier extends Mock
    implements WsConnectionNotifier {}

class _MockFCMHandler extends Mock implements FCMHandler {}

class _MockEventSyncNotifier extends Mock implements EventSyncNotifier {}

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
}

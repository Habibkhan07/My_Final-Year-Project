import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/event_local_data_source.dart';
import '../../data/datasources/event_remote_data_source.dart';
import '../../data/repositories/event_repository.dart';
import '../notifiers/event_sync_notifier.dart';
import '../notifiers/fcm_tap_intent_notifier.dart';
import '../notifiers/system_event_notifier.dart';
import '../services/fcm_handler.dart';
import '../services/ws_frame_dispatcher.dart';
// SharedPreferences comes from the existing technician-onboarding DI; the
// main() entrypoint overrides it with the async-loaded instance. Reusing
// the same provider guarantees we're looking at the same SharedPreferences
// instance the FCM background isolate writes into.
import '../../../../features/technician/onboarding/presentation/providers/dependency_injection.dart';

part 'dependency_injection.g.dart';

/// Leaf-only wiring for the realtime event subsystem. Notifier classes
/// auto-register via `@riverpod` on their declarations — do NOT add them
/// here; duplicating would produce two distinct provider instances and
/// defeat the single-ingestion guarantee of [SystemEventNotifier].

// ─── Infrastructure ────────────────────────────────────────────────────────

/// Dedicated http.Client for the event remote. Kept separate from the
/// addresses feature's client so disposing one doesn't affect the other.
@Riverpod(keepAlive: true)
http.Client eventHttpClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
}

@Riverpod(keepAlive: true)
FlutterSecureStorage eventSecureStorage(Ref ref) =>
    const FlutterSecureStorage();

// ─── Data Sources ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
EventRemoteDataSource eventRemoteDataSource(Ref ref) {
  return EventRemoteDataSource(
    client: ref.watch(eventHttpClientProvider),
    secureStorage: ref.watch(eventSecureStorageProvider),
  );
}

@Riverpod(keepAlive: true)
EventLocalDataSource eventLocalDataSource(Ref ref) {
  // sharedPreferencesProvider is declared in the onboarding feature's DI
  // file and overridden in main() with the async-loaded instance.
  final prefs = ref.watch(sharedPreferencesProvider);
  return EventLocalDataSource(prefs);
}

// ─── Repository ────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return EventRepository(
    ref.watch(eventRemoteDataSourceProvider),
    ref.watch(eventLocalDataSourceProvider),
  );
}

// ─── WS Frame Dispatcher ──────────────────────────────────────────────────

/// Wire-edge router for WebSocket frames. Splits `kind: "event"` traffic
/// (durable, pipelined into [SystemEventNotifier]) from `kind: "stream"`
/// traffic (transient, dispatched to per-`streamType` handlers registered
/// by feature DI files).
///
/// keepAlive: the handler registry must outlive widget lifecycles, same
/// reason [systemEventProvider] is keepAlive. Disposing the dispatcher
/// mid-session would silently drop every registered stream handler.
@Riverpod(keepAlive: true)
WsFrameDispatcher wsFrameDispatcher(Ref ref) => WsFrameDispatcher(ref);

// ─── FCM Handler ──────────────────────────────────────────────────────────

/// Instantiated once by the App Lifecycle Orchestrator in session 4. The
/// handler owns stream subscriptions, so this provider is keepAlive to
/// prevent repeated instantiation from double-subscribing to Firebase
/// message streams.
@Riverpod(keepAlive: true)
FCMHandler fcmHandler(Ref ref) {
  return FCMHandler(
    eventNotifier: ref.read(systemEventProvider.notifier),
    syncNotifier: ref.read(eventSyncProvider.notifier),
    tapIntentNotifier: ref.read(fcmTapIntentProvider.notifier),
    repository: ref.watch(eventRepositoryProvider),
    localDataSource: ref.watch(eventLocalDataSourceProvider),
  );
}

// ─── Shared GlobalKeys ────────────────────────────────────────────────────
//
// Plain `Provider` (not `@riverpod`) because `GlobalKey` instances are
// imperative singletons that don't fit code-gen cleanly. Riverpod's
// provider-singleton guarantee gives us the "same instance for both
// consumers" invariant that `EventUrgencyRouter` ↔ `GoRouter` and
// `EventUrgencyRouter` ↔ `MaterialApp.router` both rely on.

final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (_) => GlobalKey<NavigatorState>(),
);

final scaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (_) => GlobalKey<ScaffoldMessengerState>(),
    );

// ─── Current auth user id (callback-inversion seam, flag #19) ──────────────
//
// Returns the auth user id of the currently-signed-in user, or null when
// no one is signed in. The pipeline's recipient filter consults this via
// `ref.read(currentAuthUserIdProvider)` every time an event arrives, so
// the value is fresh per-event.
//
// **Why a default-null Provider, not a direct authProvider import.** Core
// must not import features (`SystemEventNotifier` is in core, `authProvider`
// is in features). `main.dart`'s `bootApp` ProviderScope overrides this
// seam with `ref.watch(authProvider.select((async) => async.value?.user?.id))`
// — the sanctioned core ↔ features bridge. The default-null implementation
// here is what tests and any non-prod ProviderContainer see when no
// override is supplied; in that mode the recipient filter no-ops on null,
// which is the documented backwards-compat path for legacy / unauthenticated
// flows. See flag #19 (resolved 2026-05-03).
final currentAuthUserIdProvider = Provider<int?>((_) => null);

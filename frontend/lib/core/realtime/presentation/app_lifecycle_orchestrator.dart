import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// ─── Sanctioned core → features imports ────────────────────────────────────
// This file is the *only* place in `lib/core/` that imports from `lib/features/`.
// The orchestrator is the app composition root: it bridges the realtime event
// subsystem (core) with feature notifiers at the lifecycle layer. Anywhere
// else in core, this kind of bridging must instead use a callback inversion
// (see `EventSyncNotifier.onUnauthorized` for the pattern).
//
// Adding a feature import here is permitted only when the orchestrator
// genuinely needs to drive that feature's lifecycle (e.g. waking a
// `keepAlive: true` realtime subscriber before the WS connect cascade).
// Anywhere else in core: callback inversion, not a direct import.
// ───────────────────────────────────────────────────────────────────────────
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import '../data/datasources/event_local_data_source.dart';
import '../domain/entities/system_event_entity.dart';
import '../domain/entities/target_role.dart';
import 'notifiers/event_sync_notifier.dart';
import 'notifiers/system_event_notifier.dart';
import 'notifiers/ws_connection_notifier.dart';
import 'providers/dependency_injection.dart';
import 'router/event_urgency_router.dart';
import 'services/fcm_handler.dart';
import 'state/connection_state.dart';
import 'state/system_event_state.dart';

part 'app_lifecycle_orchestrator.g.dart';

/// Wraps the app root and owns the realtime event subsystem's runtime wiring:
///
///   * `WidgetsBindingObserver` for `resumed`/`paused` transitions.
///   * `ref.listenManual(systemEventProvider, …)` to drive the
///     [EventUrgencyRouter] off of every newly accepted event.
///   * Static helpers that the auth feature calls on login / logout.
///
/// ─── Source of truth: identity vs. token ──────────────────────────────────
/// **Identity** (the signed-in `UserEntity`, role, names) comes from
/// [authProvider]. **The auth token** comes from `FlutterSecureStorage`
/// under the key `'auth_token'` — the single source of truth shared with
/// every data source in the app. The orchestrator never reads the token
/// off `UserEntity`: doing so creates a divergence window during a future
/// token rotation where the WebSocket and REST layers could go out with
/// different tokens.
///
/// ─── Mounting ──────────────────────────────────────────────────────────────
/// Place this widget *above* `MaterialApp.router` in the tree, and pass the
/// same `navigatorKey` and `scaffoldMessengerKey` to both — otherwise the
/// router will not be able to navigate or surface banners.
///
/// ```dart
/// final navigatorKey = GlobalKey<NavigatorState>();
/// final messengerKey = GlobalKey<ScaffoldMessengerState>();
///
/// runApp(
///   ProviderScope(
///     child: AppLifecycleOrchestrator(
///       navigatorKey: navigatorKey,
///       scaffoldMessengerKey: messengerKey,
///       child: MaterialApp.router(
///         scaffoldMessengerKey: messengerKey,
///         routerConfig: GoRouter(navigatorKey: navigatorKey, …),
///       ),
///     ),
///   ),
/// );
/// ```
///
/// ─── Boot / teardown ──────────────────────────────────────────────────────
/// Auth callers wire the subsystem in two places:
///
/// ```dart
/// // After a successful login that yields an auth token (fire-and-forget;
/// // awaiting would stall auth state on the WS handshake — the user would
/// // sit in AsyncLoading until the socket completes). Wrap the call in
/// // `.catchError(log)` at the call site so failures surface in dev/ops.
/// unawaited(
///   AppLifecycleOrchestrator.bootAfterAuth(ref, token).catchError(log),
/// );
///
/// // Before clearing local auth state on logout (awaited — WS device-
/// // unregister POST needs the token still valid; reversing this order
/// // silently breaks server-side device-unregister and leaves stale FCM
/// // subscriptions on the backend):
/// await AppLifecycleOrchestrator.teardownOnLogout(ref);
/// ```
class AppLifecycleOrchestrator extends ConsumerStatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const AppLifecycleOrchestrator({
    required this.child,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
    super.key,
  });

  @override
  ConsumerState<AppLifecycleOrchestrator> createState() =>
      _AppLifecycleOrchestratorState();

  // ─── Boot / teardown (called by the auth feature) ────────────────────────

  /// Wires the realtime subsystem after a successful login.
  ///
  /// Order matters:
  ///   1. Set `eventSyncProvider.notifier.onUnauthorized` *first*. If the FCM
  ///      device-registration call returns 401 because the token expired
  ///      between sessions, the callback must already be in place — otherwise
  ///      the 401 is logged and swallowed and the user is left on a logged-in
  ///      shell talking to a backend that has rejected them.
  ///   2. Wake every list-route subscriber registered in
  ///      [realtimeBootHooksProvider]. `keepAlive: true` notifiers do not
  ///      subscribe to `systemEventProvider` until first read; reading them
  ///      here guarantees they wake before the first event of their type
  ///      arrives. Adding a new event = appending to that registry, never
  ///      editing this method. See CLAUDE.md → "Per-event feature wiring".
  ///   3. Initialize FCM (permission, token register, listeners, drain
  ///      isolate queue).
  ///   4. Sentinel check — if logout fired during step 3, teardown nulled
  ///      `onUnauthorized`. Bail before the WS connect to avoid the
  ///      "connecting → disconnecting → connecting-with-stale-token" race.
  ///   5. Open the WebSocket. The connect cascade triggers
  ///      `syncMissedEvents → syncUnacknowledgedCritical → flush pending ACKs`
  ///      automatically, so no manual sync call is needed here.
  ///
  /// Residual race (out of scope here, tracked in flag.md): if logout fires
  /// during the `_channel!.ready` handshake at step 5, [WsConnectionNotifier]
  /// can still re-arm a reconnect timer in its catch path. That is a WS
  /// layer concern, not an auth-bridge concern.
  ///
  /// The `ref.listenManual` set up in `initState` activates as soon as events
  /// start flowing through `SystemEventNotifier`.
  static Future<void> bootAfterAuth(Ref ref, String authToken) async {
    ref.read(eventSyncProvider.notifier).onUnauthorized = () {
      ref.read(authProvider.notifier).logout();
    };

    for (final hook in ref.read(realtimeBootHooksProvider)) {
      ref.read(hook);
    }

    await ref.read(fcmHandlerProvider).initialize();

    // Sentinel: if `performTeardown` ran while we were awaiting FCM init,
    // it nulled `onUnauthorized`. Skip the WS connect — otherwise we'd open
    // a socket with a token `repository.logout()` has just cleared, and the
    // next 401 would have no callback to recover the auth state.
    if (ref.read(eventSyncProvider.notifier).onUnauthorized == null) return;

    await ref.read(wsConnectionProvider.notifier).connect(authToken);
  }

  /// Tears down the realtime subsystem before the auth feature clears local
  /// auth state.
  ///
  /// Order matters:
  ///   1. Disconnect WS first so no new events arrive during teardown.
  ///   2. Unregister FCM token so the backend stops dispatching to this
  ///      device. Best-effort — the repository swallows network errors.
  ///   3. Reset `SystemEventNotifier` so a different user logging in on the
  ///      same device cannot see the previous session's events.
  ///   4. Clear the `onUnauthorized` callback last so a stray in-flight
  ///      response cannot trigger a second logout against fresh state.
  @visibleForTesting
  static Future<void> performTeardown({
    required WsConnectionNotifier wsConnection,
    required FCMHandler fcmHandler,
    required SystemEventNotifier systemEventNotifier,
    required EventSyncNotifier eventSync,
    required EventLocalDataSource local,
  }) async {
    wsConnection.disconnect();
    await fcmHandler.unregister();
    systemEventNotifier.reset();
    await local.clearLastSyncTimestamp();
    await local.clearCachedEvents();
    await local.clearPendingAcks();
    eventSync.onUnauthorized = null;
  }

  static Future<void> teardownOnLogout(Ref ref) => performTeardown(
    wsConnection: ref.read(wsConnectionProvider.notifier),
    fcmHandler: ref.read(fcmHandlerProvider),
    systemEventNotifier: ref.read(systemEventProvider.notifier),
    eventSync: ref.read(eventSyncProvider.notifier),
    local: ref.read(eventLocalDataSourceProvider),
  );
}

class _AppLifecycleOrchestratorState
    extends ConsumerState<AppLifecycleOrchestrator>
    with WidgetsBindingObserver {
  /// Mirrors `EventRemoteDataSource._tokenKey`. Single source of truth for
  /// the auth token across the app — see the class-level dartdoc.
  static const _tokenKey = 'auth_token';

  static const _logName = 'core.presentation.app_lifecycle_orchestrator';

  late final EventUrgencyRouter _router;
  ProviderSubscription<SystemEventState>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _router = EventUrgencyRouter(
      navigatorKey: widget.navigatorKey,
      scaffoldMessengerKey: widget.scaffoldMessengerKey,
    );

    // Drive the router off of `latestEvent` transitions.
    //
    // The id-equality guard is load-bearing: `SystemEventState` mutates on
    // dedup-map prunes too, and without the guard the listener would re-fire
    // and re-route the same event each time the map is pruned.
    _eventSubscription = ref.listenManual<SystemEventState>(
      systemEventProvider,
      (previous, next) {
        final event = next.latestEvent;
        if (event == null) return;
        if (previous?.latestEvent?.id == event.id) return;
        _routeEvent(event);
      },
    );
  }

  @override
  void dispose() {
    _eventSubscription?.close();
    _eventSubscription = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
    // `paused`, `inactive`, `detached`, `hidden`: no action.
    // The WebSocket stays alive as long as the OS allows; FCM covers the gap
    // when the OS suspends the socket.
  }

  void _routeEvent(SystemEventEntity event) {
    final auth = ref.read(authProvider).value;
    final user = auth?.user;
    if (user == null) return;
    final role =
        user.isTechnician ? TargetRole.technician : TargetRole.customer;
    _router.handleEvent(event, role, ref);
  }

  /// Runs on every foreground transition. Three jobs:
  ///   1. If the WS is closed/failed, reconnect — that triggers the full
  ///      sync cascade.
  ///   2. If the WS is still connected (the OS may have kept the socket but
  ///      dropped frames), force a sync directly so we don't miss events.
  ///   3. Drain the FCM background isolate queue regardless, because the
  ///      background handler may have written events while we were away.
  ///
  /// Token comes from `FlutterSecureStorage` (single source of truth shared
  /// with `EventRemoteDataSource`), never from `UserEntity.token`. A read
  /// failure or absent key is treated as "not signed in" and we return
  /// early — same outcome the data sources produce on the same condition.
  Future<void> _onResumed() async {
    final String? token;
    try {
      token = await ref.read(eventSecureStorageProvider).read(key: _tokenKey);
    } catch (e, stack) {
      log(
        '_onResumed: secure storage read failed; treating as signed out: $e',
        name: _logName,
        stackTrace: stack,
      );
      return;
    }
    if (token == null || token.isEmpty) return;

    final wsStatus = ref.read(wsConnectionProvider);
    switch (wsStatus) {
      case WsConnectionStatus.disconnected:
      case WsConnectionStatus.failed:
        await ref.read(wsConnectionProvider.notifier).connect(token);
      case WsConnectionStatus.connected:
        await ref.read(eventSyncProvider.notifier).syncMissedEvents();
      case WsConnectionStatus.connecting:
      case WsConnectionStatus.reconnecting:
        break;
    }

    await ref.read(fcmHandlerProvider).processPendingBackgroundEvents();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ─── Boot hooks registry ──────────────────────────────────────────────────
/// Providers whose `keepAlive: true` notifiers must wake during
/// [AppLifecycleOrchestrator.bootAfterAuth] so they subscribe to
/// `systemEventProvider` BEFORE the WS connect cascade fires.
///
/// Adding a new list-route event feature: append the feature's queue
/// provider here. There is intentionally no other registration site —
/// this keeps the boot extension point in one file alongside the
/// orchestrator that consumes it.
///
/// Order is currently irrelevant — entries are independent. If a future
/// feature needs to wake AFTER another, document the constraint here and
/// reorder.
///
/// Tests override this provider with `[]` (or with probe providers) to
/// keep `AuthNotifier` tests narrow and to assert that the for-loop in
/// `bootAfterAuth` actually iterates the registry.
@Riverpod(keepAlive: true)
List<ProviderListenable<Object?>> realtimeBootHooks(Ref ref) => [
  incomingJobQueueProvider,
];

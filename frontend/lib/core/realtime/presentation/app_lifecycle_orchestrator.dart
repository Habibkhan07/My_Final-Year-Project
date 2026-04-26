import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Sanctioned core → features import ─────────────────────────────────────
// This file is the *only* place in `lib/core/` that imports from `lib/features/`.
// The orchestrator is the app composition root: it bridges the realtime event
// subsystem (core) with the auth feature (features/auth) at the lifecycle
// layer. Anywhere else in core, this kind of bridging must instead use a
// callback inversion (see `EventSyncNotifier.onUnauthorized` for the pattern).
// Do NOT add a second import like this — extend the orchestrator instead.
// ───────────────────────────────────────────────────────────────────────────
import '../../../features/auth/presentation/providers/auth_notifier.dart';
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
/// // After a successful login that yields an auth token:
/// await AppLifecycleOrchestrator.bootAfterAuth(ref, token);
///
/// // Before clearing local auth state on logout:
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
  ///   2. Initialize FCM (permission, token register, listeners, drain
  ///      isolate queue).
  ///   3. Open the WebSocket. The connect cascade triggers
  ///      `syncMissedEvents → syncUnacknowledgedCritical → flush pending ACKs`
  ///      automatically, so no manual sync call is needed here.
  ///
  /// The `ref.listenManual` set up in `initState` activates as soon as events
  /// start flowing through `SystemEventNotifier`.
  static Future<void> bootAfterAuth(WidgetRef ref, String authToken) async {
    ref.read(eventSyncProvider.notifier).onUnauthorized = () {
      ref.read(authProvider.notifier).logout();
    };
    await ref.read(fcmHandlerProvider).initialize();
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

  static Future<void> teardownOnLogout(WidgetRef ref) => performTeardown(
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

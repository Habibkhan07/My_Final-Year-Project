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
import '../../../features/customer/addresses/presentation/providers/dependency_injection.dart';
import '../../../features/customer/bookings/presentation/providers/customer_bookings_counts_notifier.dart';
import '../../../features/customer/bookings/presentation/providers/customer_bookings_list_notifier.dart';
import '../../../features/customer/chatbot/presentation/providers/dependency_injection.dart';
import '../../../features/customer/profile/presentation/providers/dependency_injection.dart';
import '../../../features/customer/profile/presentation/providers/profile_notifier.dart';
import '../../../features/technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart';
import '../../../features/technician/incoming_job_requests/presentation/providers/incoming_job_queue_notifier.dart';
import '../../../features/technician/schedule/presentation/providers/scheduled_jobs_counts_notifier.dart';
import '../../../features/technician/schedule/presentation/providers/scheduled_jobs_list_notifier.dart';
import '../../../features/technician/location_broadcaster/presentation/providers/dependency_injection.dart'
    as location_broadcaster_di;
import '../../../features/technician/location_broadcaster/presentation/services/foreground_location_lifecycle.dart';
import '../../../features/technician/profile/presentation/providers/dependency_injection.dart'
    as tech_profile_di;
import '../../../features/technician/profile/presentation/providers/skills_notifier.dart';
import '../data/datasources/event_local_data_source.dart';
import '../domain/entities/system_event_entity.dart';
import '../domain/entities/target_role.dart';
import 'notifiers/event_sync_notifier.dart';
import 'notifiers/fcm_tap_intent_notifier.dart';
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
  ///      [realtimeBootHooksProvider] (shared — always run). `keepAlive: true`
  ///      notifiers do not subscribe to `systemEventProvider` until first
  ///      read; reading them here guarantees they wake before the first
  ///      event of their type arrives. Adding a new event = appending to
  ///      that registry, never editing this method. See CLAUDE.md →
  ///      "Per-event feature wiring".
  ///   3. If [isTechnician] is true, additionally wake every subscriber
  ///      in [realtimeTechnicianBootHooksProvider]. These notifiers fetch
  ///      from tech-gated endpoints (`/api/technicians/me/...`); waking
  ///      them for a non-technician would fire wasted GETs that each 403
  ///      and pollute the notifier with a cached `AsyncError`. The caller
  ///      passes the flag from the cached `UserEntity` — we deliberately
  ///      do NOT read `authProvider` here because this method runs
  ///      fire-and-forget from inside the `build()` / `verifyOtp` flow
  ///      where the auth state may not yet have been assigned.
  ///   4. Initialize FCM (permission, token register, listeners, drain
  ///      isolate queue).
  ///   5. Sentinel check — if logout fired during step 4, teardown nulled
  ///      `onUnauthorized`. Bail before the WS connect to avoid the
  ///      "connecting → disconnecting → connecting-with-stale-token" race.
  ///   6. Open the WebSocket. The connect cascade triggers
  ///      `syncMissedEvents → syncUnacknowledgedCritical → flush pending ACKs`
  ///      automatically, so no manual sync call is needed here.
  ///
  /// Residual race (out of scope here, tracked in flag.md): if logout fires
  /// during the `_channel!.ready` handshake at step 6, [WsConnectionNotifier]
  /// can still re-arm a reconnect timer in its catch path. That is a WS
  /// layer concern, not an auth-bridge concern.
  ///
  /// The `ref.listenManual` set up in `initState` activates as soon as events
  /// start flowing through `SystemEventNotifier`.
  ///
  /// Mid-session role flip (customer → approved tech): the cached
  /// `user.isTechnician` only refreshes on the next verify-otp, so a user
  /// approved between sessions will not have the tech hooks woken until
  /// re-login. This is consistent with the pre-existing behaviour where
  /// the tech notifiers (woken for everyone but 403'ing for non-techs)
  /// already cached `AsyncError` and required either invalidation or
  /// re-login to recover. See flag.md.
  static Future<void> bootAfterAuth(
    Ref ref,
    String authToken, {
    required bool isTechnician,
  }) async {
    ref.read(eventSyncProvider.notifier).onUnauthorized = () {
      ref.read(authProvider.notifier).logout();
    };

    for (final hook in ref.read(realtimeBootHooksProvider)) {
      ref.read(hook);
    }
    if (isTechnician) {
      for (final hook in ref.read(realtimeTechnicianBootHooksProvider)) {
        ref.read(hook);
      }
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
  ///   1. **Unregister FCM device first** — flag #19 family privacy fix.
  ///      The backend dispatches FCM unconditionally for every event (no
  ///      presence check), so the moment we ask it to stop dispatching to
  ///      this device, the queue of in-flight Celery tasks that would
  ///      otherwise produce tray notifications for user A goes silent.
  ///      Doing this AFTER `wsConnection.disconnect()` would widen the
  ///      window where backend keeps fanning events out via FCM-only
  ///      (because WS is closed). On a multi-account device, those
  ///      late-fired notifications would land at user B's session after
  ///      they log in — the notification ingestion path can't tell
  ///      they were tagged for user A. Best-effort: the repository
  ///      swallows network errors so a phone that loses connectivity
  ///      mid-logout still completes teardown.
  ///   2. **Tear down the tech-location foreground service** —
  ///      stops any in-flight Geolocator stream and clears the auth-token
  ///      blob from FlutterForegroundTask's shared-prefs persistence.
  ///      Must run BEFORE WS disconnect for symmetry with FCM (both are
  ///      device → backend publishers; we silence them before cutting
  ///      the WS), and must run during teardown rather than relying on
  ///      the controller's `ref.onDispose` because the saved blob
  ///      persists across app restarts independently of the controller's
  ///      Riverpod lifecycle. Without this step, tech B logging in on
  ///      the same device would inherit tech A's saved auth token.
  ///   3. Disconnect WS so no new frames arrive during the rest of
  ///      teardown.
  ///   4. Reset `SystemEventNotifier` so a different user logging in on
  ///      the same device cannot see the previous session's events.
  ///   5. Clear persisted realtime caches (sync cursor, cached event list,
  ///      pending ACK queue) so cache-fallback paths in the next session
  ///      cannot surface user A's data.
  ///   6. Null the `onUnauthorized` callback last so a stray in-flight
  ///      response cannot trigger a second logout against fresh state.
  @visibleForTesting
  static Future<void> performTeardown({
    required WsConnectionNotifier wsConnection,
    required FCMHandler fcmHandler,
    required ForegroundLocationLifecycle foregroundLocationLifecycle,
    required SystemEventNotifier systemEventNotifier,
    required EventSyncNotifier eventSync,
    required EventLocalDataSource local,
  }) async {
    await fcmHandler.unregister();
    await foregroundLocationLifecycle.tearDown();
    wsConnection.disconnect();
    systemEventNotifier.reset();
    await local.clearLastSyncTimestamp();
    await local.clearCachedEvents();
    await local.clearPendingAcks();
    eventSync.onUnauthorized = null;
  }

  /// Clears all per-user caches and resets `keepAlive` notifiers so a
  /// second user signing in on the same device cannot read the previous
  /// user's data via either the offline-fallback path (SharedPreferences)
  /// or the in-memory provider state.
  ///
  /// Called only from [teardownOnLogout]. Split out so the test surface
  /// can mock the realtime side independently of the customer-data side.
  ///
  /// Why both layers: the SharedPreferences cache survives logout because
  /// `AuthLocalDataSource.clearAll()` only removes the auth token + the
  /// cached `UserEntity` — every other feature's Tier-2 cache (profile,
  /// addresses, ...) is invisible to it. Without this reset, a second
  /// user offline at boot would see the first user's profile/addresses.
  ///
  /// Each clear is wrapped in its own try/catch so a missing dependency
  /// (e.g. tests of the realtime subsystem that don't override
  /// `sharedPreferencesProvider`) cannot make logout itself fail. In
  /// production every override is wired in `main.dart`'s `ProviderScope`,
  /// so the catches are pure test-resilience belts.
  ///
  /// Adding a new per-user cache? Wire its `.clear()` call here and
  /// `ref.invalidate(<provider>)` below.
  @visibleForTesting
  static Future<void> clearCustomerDataCaches(Ref ref) async {
    // Persisted caches (Tier 2 — SharedPreferences).
    await _safelyClear(
      () async => (ref.read(profileLocalDataSourceProvider)).clear(),
      'profileLocalDataSource',
    );
    await _safelyClear(
      () async => (ref.read(addressLocalDataSourceProvider)).clear(),
      'addressLocalDataSource',
    );
    // Chatbot writes two key shapes into prefs: the active conversation
    // id (per booking, for dispute persona resumability) and per-screen
    // drafts. Both are per-user; the second signer-in on a shared device
    // must not inherit them. The notifiers themselves are `@riverpod`
    // (auto-dispose), so no provider invalidation is needed — only the
    // prefs keys persist across screen pops.
    await _safelyClear(
      () async => (ref.read(chatbotLocalDataSourceProvider)).clear(),
      'chatbotLocalDataSource',
    );
    // Technician skills cache. Key `cached_tech_skills` is single-user
    // so user A's skill list would otherwise be served to user B at the
    // next list/picker read, with knock-on effects: My Skills shows
    // the wrong rows, Add Skill picker offers sub-services the new
    // tech already has (BE rejects with 409 duplicate_skill), and the
    // resulting "X is already in your skills" snackbar contradicts
    // what My Skills displays.
    await _safelyClear(
      () async => (ref.read(tech_profile_di.skillsLocalDataSourceProvider))
          .clear(),
      'skillsLocalDataSource',
    );

    // In-memory provider state. All three are `@Riverpod(keepAlive: true)`
    // so they survive the logout flow unless explicitly invalidated;
    // without this, `ref.watch(profileProvider)` (and friends) returns
    // the previous user's `AsyncData` until something else triggers a
    // rebuild.
    _safelyInvalidate(ref, profileProvider, 'profileProvider');
    _safelyInvalidate(ref, addressesProvider, 'addressesProvider');
    _safelyInvalidate(ref, skillsProvider, 'skillsProvider');
  }

  static Future<void> _safelyClear(
    Future<void> Function() op,
    String name,
  ) async {
    try {
      await op();
    } catch (e, st) {
      log(
        'clearCustomerDataCaches: $name clear failed: $e',
        name: 'core.presentation.app_lifecycle_orchestrator',
        stackTrace: st,
      );
    }
  }

  static void _safelyInvalidate(Ref ref, ProviderOrFamily p, String name) {
    try {
      ref.invalidate(p);
    } catch (e, st) {
      log(
        'clearCustomerDataCaches: $name invalidate failed: $e',
        name: 'core.presentation.app_lifecycle_orchestrator',
        stackTrace: st,
      );
    }
  }

  static Future<void> teardownOnLogout(Ref ref) async {
    await performTeardown(
      wsConnection: ref.read(wsConnectionProvider.notifier),
      fcmHandler: ref.read(fcmHandlerProvider),
      foregroundLocationLifecycle: ref.read(
        location_broadcaster_di.foregroundLocationLifecycleProvider,
      ),
      systemEventNotifier: ref.read(systemEventProvider.notifier),
      eventSync: ref.read(eventSyncProvider.notifier),
      local: ref.read(eventLocalDataSourceProvider),
    );
    // Customer-data caches: cleared AFTER realtime teardown so any
    // FCM-unregister / WS-disconnect side-effect that races with this
    // can't repopulate the cache it just cleared.
    await clearCustomerDataCaches(ref);
  }
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
  ProviderSubscription<SystemEventEntity?>? _tapIntentSubscription;

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

    // Tap-intent channel: user tapped a tray FCM notification. The
    // dedicated `fcmTapIntentProvider` is used (not `systemEventProvider`)
    // because a tap is user-initiated and must bypass the dedup/expiry/
    // banner path that the funnel applies to automatic delivery.
    //
    // `fireImmediately: true` so a cold-start tap (`getInitialMessage`
    // populated the slot before this widget mounted) is still routed.
    // The notifier is `keepAlive: true` and its `clear()` runs after we
    // route, so a subsequent state rebuild won't re-fire on a stale value.
    _tapIntentSubscription = ref.listenManual<SystemEventEntity?>(
      fcmTapIntentProvider,
      (previous, next) {
        if (next == null) return;
        if (previous?.id == next.id) return;
        _routeTapIntent(next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _eventSubscription?.close();
    _eventSubscription = null;
    _tapIntentSubscription?.close();
    _tapIntentSubscription = null;
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
    final role = user.isTechnician
        ? TargetRole.technician
        : TargetRole.customer;
    _router.handleEvent(event, role, ref);
  }

  /// User tapped a tray FCM notification — route directly to the event's
  /// target screen, then clear the intent slot so the same value doesn't
  /// trigger a duplicate push on a later rebuild.
  ///
  /// We don't gate on a signed-in user here: if a tap arrives while
  /// signed-out (rare — token was revoked mid-flight), `routeTapIntent`
  /// returns false and `clear()` still runs so the slot doesn't stay
  /// stuck. The router's role gate handles the multi-account case where
  /// a tap meant for the other role lands.
  void _routeTapIntent(SystemEventEntity event) {
    final auth = ref.read(authProvider).value;
    final user = auth?.user;
    final role = user == null
        ? null
        : (user.isTechnician ? TargetRole.technician : TargetRole.customer);
    if (role != null) {
      _router.routeTapIntent(event, role);
    }
    // Always clear, even if we didn't route — a wedged slot would re-fire
    // a stale tap-intent the next time the listener is re-attached.
    ref.read(fcmTapIntentProvider.notifier).clear();
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
/// **Audience: shared.** These notifiers fire for every authenticated
/// user regardless of role. Endpoints behind them accept any token.
/// Tech-only providers live in [realtimeTechnicianBootHooksProvider]
/// and only wake when `bootAfterAuth(..., isTechnician: true)`.
///
/// Adding a new list-route event feature:
///   * Customer-side / role-agnostic → append here.
///   * Tech-only (endpoint gated by `IsTechnician` or similar) →
///     append to [realtimeTechnicianBootHooksProvider] instead.
/// There is intentionally no third registration site — these two
/// registries are the boot extension points alongside the orchestrator.
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
  // Customer-side My Bookings list. List-route event feature: must
  // wake before WS frames fire after auth so `job_accepted` /
  // `booking_rejected` patches land on a subscribed notifier instead
  // of going to dead-letter via SystemEventNotifier dedup. The counts
  // notifier is paired here for symmetry — it listens to the same
  // events to refresh its aggregate.
  //
  // Stays in the *shared* registry rather than a customer-only one:
  // a technician can still have customer-side bookings under the
  // unified user model, and the `/api/customers/bookings/` endpoint
  // accepts any authenticated token. Cheap to wake regardless.
  customerBookingsListProvider,
  customerBookingsCountsProvider,
];

/// Realtime boot hooks that wake ONLY when the authenticated user is a
/// technician. Gated by `bootAfterAuth(..., isTechnician: ...)`.
///
/// Every provider here fetches from a tech-gated endpoint:
///
///   * `incomingJobQueueProvider`     → `/api/technicians/me/incoming-jobs/`
///   * `technicianDashboardProvider`  → `/api/technicians/dashboard/`
///   * `scheduledJobsListProvider`    → `/api/technicians/me/scheduled-jobs/`
///   * `scheduledJobsCountsProvider`  → `/api/technicians/me/scheduled-jobs/counts/`
///
/// Without the gate, a customer login would fire all four GETs and each
/// would 403 (the backend's `IsTechnician` permission rejects), polluting
/// every `keepAlive: true` notifier's state with an `AsyncError` that has
/// no consumer.
///
/// Mid-session edge case: a customer who applies for tech onboarding and
/// gets approved by admin will have `user.isTechnician == false` cached
/// until next verify-otp. The tech hooks will NOT wake until re-login.
/// This matches the pre-split behaviour (where the providers always woke
/// but cached the 403 `AsyncError` from the initial login as a customer)
/// — either way, re-login was required to get clean tech state. See
/// flag.md.
///
/// Tests override this provider with `[]` to keep narrow, exactly like
/// the shared registry above.
@Riverpod(keepAlive: true)
List<ProviderListenable<Object?>> realtimeTechnicianBootHooks(Ref ref) => [
  incomingJobQueueProvider,
  // Technician dashboard. keepAlive: true notifier that listens to
  // `systemEventProvider` for job-completed / cancelled / payment /
  // wallet events. Without this wake-up, the dashboard's listener
  // doesn't register until the tech opens the dashboard tab — any
  // event that fired while the tech was on Jobs / Wallet / Profile
  // tabs would silently drop and the dashboard would render stale
  // aggregates until pull-to-refresh.
  technicianDashboardProvider,
  // Technician Schedule list + counts. Same audience-flipped wakeup
  // requirement as the customer-side My Bookings entries in the shared
  // registry — the tech may be on any tab when a state-machine event
  // lands; without these registered the Schedule list/counts would
  // diverge from the dashboard's denormalised "next job" view until
  // pull-to-refresh.
  scheduledJobsListProvider,
  scheduledJobsCountsProvider,
];

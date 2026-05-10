// Tech-side foreground GPS broadcaster controller.
//
// Lifecycle:
//   • Watches `bookingDetailProvider(jobId)` — when (status × role)
//     enters {EN_ROUTE, ARRIVED} for a technician viewer, starts the
//     foreground service. When status leaves OR screen pops, stops.
//   • The orchestrator screen `ref.watch`-es this provider in its
//     build (alongside the existing event notifiers) — `keepAlive: false`
//     means popping the screen disposes the provider, which auto-stops
//     the service via the dispose hook.
//
// SECURITY: this controller writes the auth token to FlutterForegroundTask's
// shared-prefs blob (so the isolate can authenticate POSTs). The token is
// also in flutter_secure_storage already; the prefs blob is the SAME
// trust boundary because both are stored on-device with no remote
// readback. On logout, `AppLifecycleOrchestrator.performTeardown` calls
// `ForegroundLocationLifecycle.tearDown()` which removes the blob — so a
// different tech logging in cannot inherit the previous tech's token
// (audit C3 / S-1).
//
// ─── Lifecycle state machine (audit C4 / F-6 / F-7 / F-8 / P-1-3 / S-3) ──
// The previous `bool _running` was set TRUE only AFTER awaiting
// `FlutterForegroundTask.startService(...)` — a long stretch through
// permission requests + token reads + saveData + startService. During
// that window, multiple races were live:
//   1. Re-entry: bookingDetailProvider firing twice in quick succession
//      saw `!_running` both times and called _startService twice
//      concurrently — two foreground services racing to register.
//   2. Stop-during-start: status flipping out of EN_ROUTE while we
//      awaited startService left the listener silently no-oping (the
//      first call still in flight had _running == false), and the
//      eventual success set _running = true for a status that no longer
//      wanted tracking — service leaked.
//   3. Dispose-during-start: ref.onDispose's `if (_running)` was false,
//      so the platform service was not torn down; once _startService
//      completed it set _running = true on a disposed provider — a
//      ghost service.
//   4. ServiceAlreadyStartedException: the package wraps this in
//      `ServiceRequestFailure(error: ServiceAlreadyStartedException())`;
//      the previous code treated the failure as `BroadcastState.error`
//      even though the platform was correctly running.
//
// The fix:
//   • Replace `bool _running` with `_LifecycleStatus` (idle | starting |
//     running | stopping). Set `starting` SYNCHRONOUSLY before any await
//     so re-entry is guarded structurally.
//   • Route all transitions through a single `_evaluate()` method that
//     reads the current bookingDetail snapshot and decides start vs stop.
//   • `_evaluate()` is called from the listener AND from the tail of
//     `_startService` / `_stopService` so a status flip that arrived
//     mid-transition is honoured the moment the in-flight transition
//     settles.
//   • `ref.mounted` checked after each await — if disposed, abort and
//     fire a stopService cleanup if the platform side may have started.
//   • `ServiceRequestFailure` whose error `is ServiceAlreadyStartedException`
//     treated as a soft-success (the platform invariant we wanted is met).

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../orchestrator/domain/entities/booking_detail.dart';
import '../../../../orchestrator/domain/entities/booking_orchestrator_role.dart';
import '../../../../orchestrator/presentation/providers/booking_detail_provider.dart';
import '../../domain/entities/broadcast_state.dart';
import '../../domain/ports/foreground_task_backend.dart';
import '../../domain/ports/geolocator_backend.dart';
import '../services/foreground_task_handler.dart';
import 'dependency_injection.dart';

part 'foreground_location_service_controller.g.dart';

/// Internal lifecycle status. Distinct from [BroadcastState] (which is
/// the UI-facing surface) — the lifecycle is finer-grained because the
/// transient `starting` / `stopping` phases must be observable to guard
/// against re-entry, even though the UI conflates them with `idle`.
enum _LifecycleStatus { idle, starting, running, stopping }

/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)
@Riverpod(keepAlive: false)
class ForegroundLocationServiceController
    extends _$ForegroundLocationServiceController {
  static const _kSubscribableStatuses = <BookingStatus>{
    BookingStatus.enRoute,
    BookingStatus.arrived,
  };
  static const _kAuthTokenStorageKey = 'auth_token';
  static const _kNotificationChannelId = 'tech_location_tracking';
  static const _kNotificationChannelName = 'Tracking job';
  static const _kLogName = 'feature.location_broadcaster';

  late final int _jobId;
  _LifecycleStatus _status = _LifecycleStatus.idle;

  /// Audit H13: ports cached at `build()` so the controller body can
  /// invoke them like local fields and tests can override the
  /// providers without threading `ref` through every helper.
  late final IForegroundTaskBackend _foregroundTask;
  late final IGeolocatorBackend _geolocator;

  /// Audit H4: latched true when the isolate reports a fatal auth
  /// error (401 / 403). Blocks `_evaluate` from restarting the service
  /// until the booking transitions out of {EN_ROUTE, ARRIVED} — which
  /// is the only meaningful "state changed, retry" signal we have
  /// inside the screen's lifetime. Without this, _stopService's tail
  /// re-evaluate would start a fresh service that immediately fails
  /// with the same bad token in a tight loop.
  bool _fatalAuthErrorLatched = false;

  /// Audit H4: instance method bound to `addTaskDataCallback` so the
  /// isolate can signal fatal auth errors back to the main isolate.
  /// Stored as a field so we can identity-equal-remove on stop /
  /// dispose (the package's API requires the SAME callback reference).
  void Function(Object data)? _isolateDataCallback;

  @override
  BroadcastState build(int jobId) {
    _jobId = jobId;
    _foregroundTask = ref.watch(foregroundTaskBackendProvider);
    _geolocator = ref.watch(geolocatorBackendProvider);

    ref.listen(bookingDetailProvider(jobId), (previous, next) {
      next.whenData((_) => _evaluate());
    });

    ref.onDispose(() {
      // The platform service may be running independently of `_status`
      // (e.g. dispose fires mid-start; startService is awaiting). Issue
      // stopService unconditionally for any non-idle status — the
      // platform call is idempotent and the cost of an extra stop on a
      // not-running service is nil.
      if (_status != _LifecycleStatus.idle) {
        unawaited(_foregroundTask.stopService());
      }
      _unregisterIsolateDataCallback();
      _status = _LifecycleStatus.idle;
    });

    return BroadcastState.idle;
  }

  /// Single source of truth for "what should be running right now?".
  /// Idempotent — safe to call from the listener, from the tail of
  /// `_startService`, and from the tail of `_stopService`. When a
  /// transition is in flight (`starting` / `stopping`) this is a no-op;
  /// the in-flight transition's `finally` block re-invokes `_evaluate`
  /// so a status flip is settled the moment the wire becomes free.
  void _evaluate() {
    if (!ref.mounted) return;
    if (_status == _LifecycleStatus.starting ||
        _status == _LifecycleStatus.stopping) {
      return;
    }

    final asyncBooking = ref.read(bookingDetailProvider(_jobId));
    if (!asyncBooking.hasValue) return;
    final booking = asyncBooking.requireValue;
    final shouldRun =
        booking.viewerRole == BookingOrchestratorRole.technician &&
        _kSubscribableStatuses.contains(booking.status);

    // Audit H4: clearing the latch on shouldRun=false is the only
    // automatic recovery path — the booking moving out of EN_ROUTE
    // (or screen pop disposing the controller) gets us out of the
    // error state. While latched + shouldRun, do NOT restart.
    if (!shouldRun) _fatalAuthErrorLatched = false;

    if (shouldRun &&
        _status == _LifecycleStatus.idle &&
        !_fatalAuthErrorLatched) {
      unawaited(_startService(booking));
    } else if (!shouldRun && _status == _LifecycleStatus.running) {
      unawaited(_stopService());
    }
  }

  Future<void> _startService(BookingDetail booking) async {
    // SYNCHRONOUS transition before any await — this is the re-entry
    // guard. Any concurrent listener / tail re-evaluate sees `starting`
    // and short-circuits.
    _status = _LifecycleStatus.starting;
    // Tail re-evaluate runs only after a successful settle — without
    // this gate a failed start (denied permission, missing token,
    // platform error) would leave `_status = idle` + `shouldRun = true`
    // and the tail `_evaluate()` would restart the service in a tight
    // loop forever, since the cause of failure has not changed. The
    // listener on `bookingDetailProvider` is the natural recovery
    // channel — when status flips OUT of EN_ROUTE/ARRIVED or the user
    // re-grants a permission and any provider invalidates, the next
    // listener fire will retry. (Audit H13 surfaced this loop.)
    var settledRunning = false;
    try {
      // SECURITY: tech_profile gate is server-side; we additionally
      // gate this controller on viewerRole == technician above.
      final denied = await _ensurePermissions();
      if (!ref.mounted) return;
      if (denied != null) {
        state = denied;
        _status = _LifecycleStatus.idle;
        return;
      }

      final token = await ref
          .read(locationBroadcasterSecureStorageProvider)
          .read(key: _kAuthTokenStorageKey);
      if (!ref.mounted) return;
      if (token == null || token.isEmpty) {
        developer.log(
          'No auth token in secure storage — cannot start tracking.',
          name: _kLogName,
          level: 1000,
        );
        state = BroadcastState.error;
        _status = _LifecycleStatus.idle;
        return;
      }

      // AndroidNotificationOptions is NOT a const constructor; the
      // class instantiates non-const default values (e.g. visibility
      // wrapper). Build it normally.
      _foregroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: _kNotificationChannelId,
          channelName: _kNotificationChannelName,
          channelDescription:
              'Sends your live location to the customer for the active job.',
        ),
        iosNotificationOptions: const IOSNotificationOptions(),
        foregroundTaskOptions: ForegroundTaskOptions(
          // Geolocator's getPositionStream is the heartbeat — we don't
          // need flutter_foreground_task's onRepeatEvent to fire.
          // (`ForegroundTaskOptions` is const-eligible but
          // `ForegroundTaskEventAction.nothing()` constructs a non-const
          // instance, so the wrapper is non-const too.)
          eventAction: ForegroundTaskEventAction.nothing(),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      // saveData BEFORE startService — the isolate reads it on onStart.
      final config = TechLocationTaskKeys.encodeConfig(
        authToken: token,
        bookingId: booking.id,
      );
      await _foregroundTask.saveData(
        key: TechLocationTaskKeys.configKey,
        value: config,
      );
      if (!ref.mounted) return;

      // Audit F-10 (Batch A): `customer.fullName.split(' ').first`
      // crashes nothing but produces ugly notification text on
      // pathological inputs — leading whitespace ("` Ali`") yields an
      // empty first token; multiple spaces ("`Ali  Khan`") still work
      // but stray unicode whitespace (NBSP from copy-paste) doesn't
      // split. Trim + RegExp split + isEmpty fallback hardens the
      // user-visible string.
      final trimmedName = booking.customer.fullName.trim();
      final firstName = trimmedName.isEmpty
          ? 'customer'
          : trimmedName.split(RegExp(r'\s+')).first;
      final result = await _foregroundTask.startService(
        serviceTypes: const [ForegroundServiceTypes.location],
        notificationTitle: 'Tracking job',
        notificationText: 'Sending your location to $firstName',
        callback: startTechLocationTaskCallback,
      );

      // Audit C4: ServiceAlreadyStartedException is a soft-success — the
      // platform service is already running, which is exactly the
      // post-condition this method aims for. The package wraps the
      // throw inside `ServiceRequestFailure(error: ...)` (see
      // flutter_foreground_task v9.x source), so we must unwrap.
      final softSuccess =
          result is ServiceRequestSuccess ||
          (result is ServiceRequestFailure &&
              result.error is ServiceAlreadyStartedException);

      if (!ref.mounted) {
        // Disposed during startService. Tear down the platform service
        // explicitly — the dispose hook fires unconditionally now, but
        // by the time it ran `_status` was still `starting`, so the
        // hook DID call stopService. Defensive: another stop here is a
        // no-op but covers the case where dispose ordering changes.
        if (softSuccess) unawaited(_foregroundTask.stopService());
        return;
      }

      if (softSuccess) {
        _status = _LifecycleStatus.running;
        state = BroadcastState.running;
        _registerIsolateDataCallback();
        settledRunning = true;
      } else {
        developer.log(
          'startService failed: $result',
          name: _kLogName,
          level: 1000,
        );
        _status = _LifecycleStatus.idle;
        state = BroadcastState.error;
      }
    } finally {
      // Tail re-evaluate ONLY after a successful settle (running). On
      // success this catches the case where shouldRun flipped to false
      // mid-start — the listener short-circuited because we were
      // `starting`, so the tail evaluate is the only chance to honour
      // the flip. On failure, re-evaluating would just retry with the
      // same bad inputs in a tight loop (see comment at the top of
      // this method).
      if (settledRunning) _evaluate();
    }
  }

  Future<void> _stopService() async {
    _status = _LifecycleStatus.stopping;
    _unregisterIsolateDataCallback();
    try {
      await _foregroundTask.stopService();
    } finally {
      if (ref.mounted) {
        _status = _LifecycleStatus.idle;
        state = BroadcastState.idle;
      }
      // Symmetric tail: a status flip mid-stop (re-entered EN_ROUTE
      // again) wakes the next start.
      _evaluate();
    }
  }

  /// Audit H4: registers a `FlutterForegroundTask.addTaskDataCallback`
  /// listener so the isolate's `sendDataToMain` messages reach this
  /// controller. Idempotent — calling twice is a no-op (the package
  /// dedupes on identity).
  void _registerIsolateDataCallback() {
    if (_isolateDataCallback != null) return;
    final callback = _onIsolateData;
    _isolateDataCallback = callback;
    _foregroundTask.addTaskDataCallback(callback);
  }

  void _unregisterIsolateDataCallback() {
    final callback = _isolateDataCallback;
    if (callback == null) return;
    _foregroundTask.removeTaskDataCallback(callback);
    _isolateDataCallback = null;
  }

  /// Receives messages forwarded from `_TechLocationTaskHandler` via
  /// `FlutterForegroundTask.sendDataToMain`. Currently only handles
  /// `fatal_auth_error` — token expired or tech reassigned, both
  /// terminal for this booking. Stops the service and surfaces
  /// `BroadcastState.error` so the C6 banner shows the failure.
  void _onIsolateData(Object data) {
    if (!ref.mounted) return;
    if (data is! Map) return;
    final kind = data[TechLocationTaskKeys.messageKind];
    if (kind != TechLocationTaskKeys.fatalAuthErrorKind) return;

    developer.log(
      'Fatal auth error from isolate: '
      'statusCode=${data[TechLocationTaskKeys.messageStatusCode]} '
      'code=${data[TechLocationTaskKeys.messageCode]}',
      name: _kLogName,
      level: 1000,
    );
    // Latch BEFORE stopping so _stopService's tail _evaluate sees the
    // latch and does not restart immediately. State transitions to
    // error first; _stopService will overwrite to idle in its tail
    // — re-set to error after to keep the banner visible.
    _fatalAuthErrorLatched = true;
    if (_status == _LifecycleStatus.running) {
      unawaited(
        _stopService().whenComplete(() {
          if (ref.mounted) state = BroadcastState.error;
        }),
      );
    } else {
      state = BroadcastState.error;
    }
  }

  /// Ensures location + (Android 13+) notification permissions are
  /// granted. Returns `null` when the service has the minimum
  /// permissions to start (foreground location + notifications);
  /// otherwise returns the specific denied state to surface in the UI.
  ///
  /// **Background location is best-effort** (audit C2 / F-1). After
  /// foreground location is granted, this method attempts to upgrade
  /// to `LocationPermission.always` (= `ACCESS_BACKGROUND_LOCATION`).
  /// On Android 10 this can succeed via the runtime dialog. On
  /// Android 11+ the runtime upgrade is blocked — only the OS Settings
  /// page can grant it. We do NOT fail-closed if background is denied:
  /// the foreground service can still publish GPS while the notification
  /// keeps the app foregrounded by the OS. We just log it; the banner
  /// + tap-to-settings flow lets the tech upgrade later.
  Future<BroadcastState?> _ensurePermissions() async {
    var permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return BroadcastState.permissionDenied;
    }

    final notifGranted = await _foregroundTask.checkNotificationPermission();
    if (notifGranted != NotificationPermission.granted) {
      final requested = await _foregroundTask.requestNotificationPermission();
      if (requested != NotificationPermission.granted) {
        return BroadcastState.notificationPermissionDenied;
      }
    }

    // Best-effort upgrade to background location.
    if (permission == LocationPermission.whileInUse) {
      // On Android 10 this prompts the user; on 11+ it returns
      // whileInUse unchanged (user must use Settings).
      final upgraded = await _geolocator.requestPermission();
      if (upgraded != LocationPermission.always) {
        developer.log(
          'ACCESS_BACKGROUND_LOCATION not granted (got $upgraded). Tracking '
          'will work while the app is foregrounded by the notification but '
          'may drop on screen lock on some Android versions. Tech can '
          'upgrade via OS Settings → Permissions → Location → "Allow all '
          'the time".',
          name: _kLogName,
          level: 800, // info
        );
      }
    }

    return null;
  }

  /// Opens the OS app-settings page so the tech can grant a denied
  /// permission. Used by the banner's tap-to-settings affordance
  /// (audit C2). Returns true when the OS launched the settings activity.
  ///
  /// We do NOT auto-restart the service after the tech returns from
  /// settings: the controller's existing listener on
  /// `bookingDetailProvider` plus the `onResumed` lifecycle hook means
  /// the next status fire (or app resume) re-evaluates and starts the
  /// service if permissions are now sufficient.
  Future<bool> openSystemSettings() => _geolocator.openAppSettings();
}

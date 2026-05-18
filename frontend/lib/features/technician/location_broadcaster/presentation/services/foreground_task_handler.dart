// Top-level entry point for the flutter_foreground_task isolate.
//
// The isolate is NOT in Riverpod's world — providers don't cross
// isolate boundaries. The production callback constructs adapters
// + factories explicitly and hands them to the handler.
//
// SECURITY: this isolate runs Geolocator and POSTs each fix to the
// backend's tech-location endpoint, which gates by tech_profile +
// assigned-tech IDOR + 4-second throttle. The client only carries
// the auth token forward; it never makes authorisation decisions
// itself.
//
// Audit H13 (isolate side): the handler accepts ports + factories via
// constructor with production defaults. Tests construct the handler
// directly with fakes and drive `onStart` / `_onFix` / `onDestroy`
// without going through `setTaskHandler` at all.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../data/adapters/isolate_flutter_foreground_task_backend.dart';
import '../../data/adapters/isolate_geolocator_backend.dart';
import '../../data/datasources/tech_location_remote_data_source.dart';
import '../../domain/ports/isolate_foreground_task_backend.dart';
import '../../domain/ports/isolate_geolocator_backend.dart';

/// Top-level entry point. `flutter_foreground_task` requires the
/// callback to be a top-level (non-method) function annotated with
/// `@pragma('vm:entry-point')` so the AOT compiler retains it for the
/// background isolate. The function name itself is unimportant — it's
/// passed by reference to `FlutterForegroundTask.startService(callback:)`.
@pragma('vm:entry-point')
void startTechLocationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(
    TechLocationTaskHandler(
      foregroundTask: const IsolateFlutterForegroundTaskBackend(),
      geolocator: const IsolateGeolocatorBackend(),
    ),
  );
}

/// Default `http.Client` factory — kept as a top-level so the handler
/// stays free of `dart:io` imports beyond what's already needed.
http.Client _defaultClientFactory() => http.Client();

/// Default `TechLocationRemoteDataSource` factory — closes over the
/// just-created client.
TechLocationRemoteDataSource _defaultRemoteFactory(http.Client client) =>
    TechLocationRemoteDataSource(client);

/// CTRL-13 (Batch I): factory for the isolate-side
/// `FlutterSecureStorage` reader. flutter_foreground_task v9
/// initialises platform channels for the task isolate on startup,
/// so secure storage works the same way it does on the main isolate
/// (Android Keystore-backed EncryptedSharedPreferences). Tests inject
/// a recording fake whose `read` returns a stubbed token.
FlutterSecureStorage _defaultSecureStorageFactory() =>
    const FlutterSecureStorage();

/// Keys for the config blob the controller saves before
/// startService. Kept as constants in this file (not the controller's)
/// because the isolate side is the source of truth — the controller
/// imports these.
///
/// CTRL-13 (Batch I): the blob now carries ONLY the bookingId (no
/// secrets). The auth token is read from `flutter_secure_storage`
/// inside the isolate's `onStart`. Pre-fix, the JWT was encoded
/// alongside the bookingId and persisted to a plain shared-prefs
/// file — which is readable on rooted devices and via `adb backup`,
/// violating CLAUDE.md's "JWT tokens: flutter_secure_storage only"
/// rule.
class TechLocationTaskKeys {
  static const String configKey = 'tech_location_config';

  /// CTRL-13 (Batch I): secure-storage key the auth token lives
  /// under. Owned by this file so the controller and the handler
  /// agree on the lookup path without one importing the other's
  /// internal constants.
  static const String authTokenStorageKey = 'auth_token';

  /// Audit H4: wire-format keys for `FlutterForegroundTask.sendDataToMain`
  /// messages. The isolate emits a fatal-auth message when a POST
  /// returns 401 / 403; the controller's `addTaskDataCallback` listens
  /// and flips `BroadcastState.error`.
  ///
  /// SendPort serialization survives `Map<String, Object?>` of
  /// primitives, so we keep the wire shape plain JSON-ish.
  static const String messageKind = 'kind';
  static const String fatalAuthErrorKind = 'fatal_auth_error';
  static const String messageStatusCode = 'status_code';
  static const String messageCode = 'code';

  /// Audit F-15 (Batch B): wire-format kind for the
  /// `permission_lost` envelope. Emitted when the isolate detects
  /// that location permission was revoked between the controller's
  /// pre-flight check and the isolate's spin-up, OR mid-session
  /// (Geolocator throws `PermissionDeniedException` /
  /// `LocationServiceDisabledException` from the position stream).
  /// The controller flips `BroadcastState.permissionDenied` so the
  /// C6 banner surfaces — without this signal, the customer sees a
  /// frozen marker with no explanation.
  static const String permissionLostKind = 'permission_lost';

  /// Audit Batch H: wire-format kind for the `open_booking` envelope.
  /// Emitted when the tech taps the persistent tracking notification
  /// while the app is backgrounded — the controller's data callback
  /// uses the carried `booking_id` to route the tech back to the
  /// orchestrator screen. The accompanying `_foregroundTask.launchApp()`
  /// call brings the app to foreground from a backgrounded-but-alive
  /// state; if the app was killed entirely, Android starts a fresh
  /// instance via the launch intent and the standard Flutter route
  /// restoration takes over.
  static const String openBookingKind = 'open_booking';

  /// Wire-format key for the booking id in the `open_booking` envelope.
  /// Reused as the path-parameter for the orchestrator route.
  static const String messageBookingId = 'booking_id';

  static const String _logName = 'feature.location_broadcaster.handler';

  /// CTRL-13 (Batch I): encode the bookingId to a string the isolate
  /// can decode back. Pre-fix this also carried the auth token via a
  /// 0x1F-delimited blob — the JWT is now read from secure storage in
  /// the isolate instead, so the blob carries no secret.
  static String encodeConfig({required int bookingId}) => '$bookingId';

  /// Inverse of [encodeConfig]. Returns `null` on malformed input
  /// (caller treats this as "do not start broadcasting").
  ///
  /// HND-9 (Batch I): tightened from `< 0` to `<= 0` since
  /// auto-incrementing booking ids start at 1; bookingId=0 cannot
  /// legitimately appear and would only land here from a malformed
  /// blob.
  static int? decodeConfig(String raw) {
    final id = int.tryParse(raw);
    if (id == null || id <= 0) return null;
    return id;
  }
}

/// Public so tests can construct + drive directly. Production callers
/// go through `startTechLocationTaskCallback`.
class TechLocationTaskHandler extends TaskHandler {
  final IIsolateForegroundTaskBackend _foregroundTask;
  final IIsolateGeolocatorBackend _geolocator;
  final http.Client Function() _clientFactory;
  final TechLocationRemoteDataSource Function(http.Client) _remoteFactory;
  /// CTRL-13 (Batch I): factory for the isolate-side secure-storage
  /// reader. Production uses real flutter_secure_storage; tests inject
  /// a recording fake whose `read` returns a stubbed token.
  final FlutterSecureStorage Function() _secureStorageFactory;

  StreamSubscription<Position>? _positionSub;
  http.Client? _isolateClient;
  TechLocationRemoteDataSource? _remote;

  int _bookingId = -1;
  String _authToken = '';

  /// Audit F-20 (Batch B): serialize `_onFix` so two POSTs can never
  /// be in flight at the same time. `Stream.listen` does NOT await
  /// async callbacks — if a hung HTTP call (e.g. flaky tower handover)
  /// runs past the next 5s position emission, both POSTs run
  /// concurrently and race the backend's per-tech 4s throttle.
  /// Dropping mid-flight fixes is safe: the next geolocator emission
  /// is at most ~5s away and the customer's marker tween is keyed
  /// off the latest accepted frame, not the dropped one.
  bool _postInFlight = false;

  TechLocationTaskHandler({
    required IIsolateForegroundTaskBackend foregroundTask,
    required IIsolateGeolocatorBackend geolocator,
    http.Client Function() clientFactory = _defaultClientFactory,
    TechLocationRemoteDataSource Function(http.Client) remoteFactory =
        _defaultRemoteFactory,
    FlutterSecureStorage Function() secureStorageFactory =
        _defaultSecureStorageFactory,
  }) : _foregroundTask = foregroundTask,
       _geolocator = geolocator,
       _clientFactory = clientFactory,
       _remoteFactory = remoteFactory,
       _secureStorageFactory = secureStorageFactory;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await _foregroundTask.getData<String>(
      key: TechLocationTaskKeys.configKey,
    );
    if (raw == null) {
      // Controller bug — startService called without saveData. The
      // service will keep running (the notification stays up) but
      // emit no frames. Documented in the controller; a no-op here
      // is the safest tradeoff.
      return;
    }
    final bookingId = TechLocationTaskKeys.decodeConfig(raw);
    if (bookingId == null) return;
    _bookingId = bookingId;

    // CTRL-13 (Batch I): read the auth token from secure storage in
    // the isolate. flutter_foreground_task v9 initialises platform
    // channels for this isolate so flutter_secure_storage works the
    // same way it does on the main isolate. A missing / empty token
    // is fatal — emit fatal_auth_error so the controller flips
    // BroadcastState.error and the C6 banner surfaces.
    String token;
    try {
      token = await _secureStorageFactory()
              .read(key: TechLocationTaskKeys.authTokenStorageKey) ??
          '';
    } on Exception catch (e, stack) {
      developer.log(
        'tech-location secure-storage read failed: $e',
        name: TechLocationTaskKeys._logName,
        level: 1000,
        stackTrace: stack,
      );
      token = '';
    }
    if (token.isEmpty) {
      _foregroundTask.sendDataToMain({
        TechLocationTaskKeys.messageKind:
            TechLocationTaskKeys.fatalAuthErrorKind,
        TechLocationTaskKeys.messageStatusCode: 0,
        TechLocationTaskKeys.messageCode: 'no_token',
      });
      return;
    }
    _authToken = token;

    _isolateClient = _clientFactory();
    _remote = _remoteFactory(_isolateClient!);

    // Permission may have been revoked between the controller's check
    // and this isolate spinning up. Re-check defensively. Audit F-15
    // (Batch B): pre-fix this was a silent early-return — controller
    // had no signal that the isolate gave up, customer saw frozen
    // marker with no banner. Now we send `permission_lost` to main
    // so the C6 banner surfaces with "Open Settings".
    final permission = await _geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _foregroundTask.sendDataToMain({
        TechLocationTaskKeys.messageKind:
            TechLocationTaskKeys.permissionLostKind,
      });
      return;
    }

    _positionSub = _geolocator
        .getPositionStream(
          // Audit F-21 (Batch F) + P1.1: heartbeat cadence tightened
          // from 15s to 5s so a stationary tech's marker updates at a
          // pace the customer's eye treats as "live", not "stuck".
          // Constraints satisfied:
          //   - Backend throttles per (tech, booking) at 4s — 5s leaves
          //     a 1s safety margin against monotonic-clock drift, so
          //     every heartbeat passes the throttle.
          //   - 60s "offline" client threshold still well-buffered
          //     (12x the cadence).
          //   - The widget's frame-tween duration (3500ms) settles
          //     ~1.5s before the next heartbeat lands — no tween-vs-
          //     frame collisions.
          // Moving tech behaviour is unaffected: `distanceFilter:10m`
          // emits sub-5s on a motorbike at urban speeds; those frames
          // get throttle-paced server-side to ~5s effective cadence.
          // We do NOT set `foregroundNotificationConfig` here —
          // flutter_foreground_task owns the notification.
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
            intervalDuration: const Duration(seconds: 5),
          ),
        )
        .listen(_onFix, onError: _onPositionStreamError);
  }

  /// Audit F-15 (Batch B): handle errors emitted by the position
  /// stream. Geolocator surfaces `PermissionDeniedException` /
  /// `LocationServiceDisabledException` when permission is revoked
  /// or location services turned off mid-session. Pre-fix the
  /// stream had no `onError` and these exceptions silently bubbled
  /// to the zone, leaving the customer with a frozen marker. Now
  /// we signal main and stop emitting.
  void _onPositionStreamError(Object error, StackTrace stack) {
    developer.log(
      'tech-location position stream error: $error',
      name: TechLocationTaskKeys._logName,
      level: 1000,
      stackTrace: stack,
    );
    if (error is PermissionDeniedException ||
        error is LocationServiceDisabledException) {
      _foregroundTask.sendDataToMain({
        TechLocationTaskKeys.messageKind:
            TechLocationTaskKeys.permissionLostKind,
      });
    }
  }

  Future<void> _onFix(Position position) async {
    final remote = _remote;
    if (remote == null) return;
    // Audit P2-4: defend against geolocator emitting NaN / infinite
    // values on cold-start or hardware glitch. `jsonEncode` writes
    // these as `null`, the backend serializer 400s, and the isolate
    // logs+drops — wasting one POST per glitched fix. Drop early.
    if (!position.latitude.isFinite || !position.longitude.isFinite) {
      return;
    }
    // Audit F-20 (Batch B): re-entry guard. If a previous POST is
    // still in flight, drop this fix rather than firing a second
    // concurrent request — see `_postInFlight` rationale on the
    // field declaration.
    if (_postInFlight) return;
    _postInFlight = true;
    try {
      await remote.postLocation(
        bookingId: _bookingId,
        authToken: _authToken,
        lat: position.latitude,
        lng: position.longitude,
        // Geolocator returns 0 for accuracy when unknown; pass null to
        // keep the wire payload minimal (backend tolerates either).
        accuracyMeters: position.accuracy > 0 ? position.accuracy : null,
        // Audit H1 (F-4): `heading == 0.0` is ambiguous in geolocator —
        // it means BOTH "facing true north" AND "device cannot report
        // heading." `0.0 >= 0` is true, so a `>= 0` check would never
        // fire null. Use `headingAccuracy` instead: <= 0 means the
        // device has no compass fix, regardless of the heading value.
        // Without this, stationary techs always get a north-pointing
        // bike marker on the customer's map.
        heading: position.headingAccuracy <= 0 ? null : position.heading,
      );
    } on HttpFailure catch (e, stack) {
      // Audit H4 (F-11/S-6): the previous `catch (_) {}` swallowed
      // EVERY error silently — a 401 (token expired) or 403 (not the
      // assigned tech) would keep firing GPS into a wall forever.
      developer.log(
        'tech-location POST failed: ${e.statusCode} ${e.code} ${e.message}',
        name: TechLocationTaskKeys._logName,
        level: 1000,
        stackTrace: stack,
      );
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Fatal — no GPS frame will succeed until the tech logs in
        // again or is reassigned. Tell main to stop the service and
        // surface `BroadcastState.error`.
        _foregroundTask.sendDataToMain({
          TechLocationTaskKeys.messageKind:
              TechLocationTaskKeys.fatalAuthErrorKind,
          TechLocationTaskKeys.messageStatusCode: e.statusCode,
          TechLocationTaskKeys.messageCode: e.code,
        });
      }
      // Transient failures (5xx, network) just drop this frame; the
      // next fix retries implicitly.
    } catch (e, stack) {
      // Anything else — log so it's not silent. No main-side signal
      // because we can't classify "fatal" vs "transient" without a
      // typed error.
      developer.log(
        'tech-location POST threw unexpected: $e',
        name: TechLocationTaskKeys._logName,
        level: 1000,
        stackTrace: stack,
      );
    } finally {
      // Audit F-20 (Batch B): always clear the in-flight guard so the
      // next emitted fix can attempt its POST. Inside `finally` so
      // even an exception leak (which shouldn't reach here — both
      // catch blocks are above — but defensive) won't latch the
      // guard true.
      _postInFlight = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // ForegroundTaskOptions.eventAction = nothing(); not used.
  }

  /// Audit Batch H: tap on the persistent tracking notification.
  ///
  /// flutter_foreground_task v9 calls this when the user taps the
  /// notification body. We do two things:
  ///   1. Send an `open_booking` envelope to the main isolate so the
  ///      controller's `addTaskDataCallback` can route the tech back
  ///      to the orchestrator screen for `_bookingId`. Necessary
  ///      whether the app was actively visible (no-op-ish — go() to
  ///      same route) or backgrounded with a child screen pushed.
  ///   2. Call `launchApp()` to bring the app to foreground when it
  ///      was suspended. Safe to call when the app is already
  ///      foregrounded — the package treats it as a no-op.
  ///
  /// We do NOT pass a `route` to launchApp because Flutter doesn't
  /// auto-rebuild the navigator from `onNewIntent` extras for an
  /// already-running app — the `sendDataToMain` envelope is the
  /// reliable navigation signal in that case.
  @override
  void onNotificationPressed() {
    if (_bookingId < 0) return; // never started; no booking to open
    _foregroundTask.sendDataToMain({
      TechLocationTaskKeys.messageKind: TechLocationTaskKeys.openBookingKind,
      TechLocationTaskKeys.messageBookingId: _bookingId,
    });
    _foregroundTask.launchApp();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isolateClient?.close();
    _isolateClient = null;
    _remote = null;
  }
}

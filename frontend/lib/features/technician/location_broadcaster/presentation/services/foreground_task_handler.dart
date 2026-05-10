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

/// Keys + delimiter for the config blob the controller saves before
/// startService. Kept as constants in this file (not the controller's)
/// because the isolate side is the source of truth — the controller
/// imports these.
class TechLocationTaskKeys {
  static const String configKey = 'tech_location_config';

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

  static const String _logName = 'feature.location_broadcaster.handler';

  /// ASCII Unit Separator (0x1F). Picked because it cannot legally
  /// appear inside an auth token or numeric booking id, so a simple
  /// `split` round-trips losslessly without JSON serialization. The
  /// `\u001F` escape sequence is used here (NOT a literal 0x1F byte)
  /// because some editors / file writers strip the unprintable char
  /// silently. If that happened, `encodeConfig` would collapse to
  /// `'$authToken$bookingId'` and every isolate spin-up would fail
  /// silently when `decodeConfig` rejects parts.length != 2. Audit
  /// P1-3 caught a regression where this had become a literal byte.
  static const String _delimiter = '\u001F';

  /// Encode `(authToken, bookingId)` to a single string the
  /// foreground task handler can split back. Used by the controller's
  /// `_startService`.
  static String encodeConfig({
    required String authToken,
    required int bookingId,
  }) => '$authToken$_delimiter$bookingId';

  /// Inverse of [encodeConfig]. Returns `null` on malformed input
  /// (caller treats this as "do not start broadcasting").
  static ({String authToken, int bookingId})? decodeConfig(String raw) {
    final parts = raw.split(_delimiter);
    if (parts.length != 2) return null;
    final id = int.tryParse(parts[1]);
    if (id == null || id < 0 || parts[0].isEmpty) return null;
    return (authToken: parts[0], bookingId: id);
  }
}

/// Public so tests can construct + drive directly. Production callers
/// go through `startTechLocationTaskCallback`.
class TechLocationTaskHandler extends TaskHandler {
  final IIsolateForegroundTaskBackend _foregroundTask;
  final IIsolateGeolocatorBackend _geolocator;
  final http.Client Function() _clientFactory;
  final TechLocationRemoteDataSource Function(http.Client) _remoteFactory;

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
  }) : _foregroundTask = foregroundTask,
       _geolocator = geolocator,
       _clientFactory = clientFactory,
       _remoteFactory = remoteFactory;

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
    final decoded = TechLocationTaskKeys.decodeConfig(raw);
    if (decoded == null) return;
    _authToken = decoded.authToken;
    _bookingId = decoded.bookingId;

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
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            // 10m + the geolocator's internal timer (which fires roughly
            // every second on most Android devices) gives us GPS frames at
            // a real-world cadence near 5s while moving and rarely while
            // stationary. The backend's 4s throttle absorbs occasional
            // sub-5s bursts.
            distanceFilter: 10,
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

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isolateClient?.close();
    _isolateClient = null;
    _remote = null;
  }
}

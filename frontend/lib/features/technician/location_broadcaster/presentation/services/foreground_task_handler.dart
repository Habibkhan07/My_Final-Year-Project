// Top-level entry point for the flutter_foreground_task isolate.
//
// The isolate is NOT in Riverpod's world — providers don't cross
// isolate boundaries. We construct a fresh `http.Client()` here and
// read the auth token + booking id from the shared-prefs blob saved
// by the controller via FlutterForegroundTask.saveData().
//
// SECURITY: this isolate runs Geolocator and POSTs each fix to the
// backend's tech-location endpoint, which gates by tech_profile +
// assigned-tech IDOR + 4-second throttle. The client only carries
// the auth token forward; it never makes authorisation decisions
// itself.

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/common/errors/http_failure.dart';
import '../../data/datasources/tech_location_remote_data_source.dart';

/// Top-level entry point. `flutter_foreground_task` requires the
/// callback to be a top-level (non-method) function annotated with
/// `@pragma('vm:entry-point')` so the AOT compiler retains it for the
/// background isolate. The function name itself is unimportant — it's
/// passed by reference to `FlutterForegroundTask.startService(callback:)`.
@pragma('vm:entry-point')
void startTechLocationTaskCallback() {
  FlutterForegroundTask.setTaskHandler(_TechLocationTaskHandler());
}

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

  static const String _logName = 'feature.location_broadcaster.handler';

  /// ASCII Unit Separator (0x1F). Picked because it cannot legally
  /// appear inside an auth token or numeric booking id, so a simple
  /// `split` round-trips losslessly without JSON serialization.
  static const String _delimiter = '';

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

class _TechLocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSub;
  http.Client? _isolateClient;
  TechLocationRemoteDataSource? _remote;

  int _bookingId = -1;
  String _authToken = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final raw = await FlutterForegroundTask.getData<String>(
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

    _isolateClient = http.Client();
    _remote = TechLocationRemoteDataSource(_isolateClient!);

    // Permission may have been revoked between the controller's check
    // and this isolate spinning up. Re-check defensively.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // controller's status listener will handle the UI surface
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        // 10m + the geolocator's internal timer (which fires roughly
        // every second on most Android devices) gives us GPS frames at
        // a real-world cadence near 5s while moving and rarely while
        // stationary. The backend's 4s throttle absorbs occasional
        // sub-5s bursts.
        distanceFilter: 10,
      ),
    ).listen(_onFix);
  }

  Future<void> _onFix(Position position) async {
    final remote = _remote;
    if (remote == null) return;
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
        FlutterForegroundTask.sendDataToMain({
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

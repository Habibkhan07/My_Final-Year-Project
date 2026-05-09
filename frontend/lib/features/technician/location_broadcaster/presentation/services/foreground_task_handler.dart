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

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
        // Geolocator returns 0 for accuracy and heading when unknown.
        // Backend serializer accepts null but tolerates 0 too — pass
        // null when the value is meaningless to keep the wire payload
        // minimal.
        accuracyMeters: position.accuracy > 0 ? position.accuracy : null,
        heading: position.heading >= 0 ? position.heading : null,
      );
    } catch (_) {
      // Transient failures are expected (network blips, 5xx). The
      // foreground service stays alive; the next fix retries
      // implicitly. No retry queue — telemetry is fine to drop.
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

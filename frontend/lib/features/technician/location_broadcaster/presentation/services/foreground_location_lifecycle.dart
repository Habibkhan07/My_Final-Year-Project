// Lifecycle helper for the tech-side foreground GPS service.
//
// SECURITY: this class owns the only safe path to clear the auth-token
// blob saved in FlutterForegroundTask's shared-prefs persistence (see
// `foreground_location_service_controller._startService` and
// `foreground_task_handler.TechLocationTaskKeys`). The blob persists
// across app restarts; without an explicit logout teardown a different
// tech logging in on the same device would inherit the previous tech's
// saved token and the next service start would POST to the backend as
// the wrong tech (the backend's assigned-tech IDOR check rejects, but
// the token itself would still be on disk for any other consumer of the
// shared-prefs file).
//
// Called from `AppLifecycleOrchestrator.performTeardown` between
// `fcmHandler.unregister()` and `wsConnection.disconnect()` so the
// device stops publishing GPS BEFORE the WS connection drops.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_task_handler.dart';

class ForegroundLocationLifecycle {
  const ForegroundLocationLifecycle();

  /// Stops any in-flight tech-location foreground service AND removes
  /// the saved config blob (auth token + booking id) from
  /// FlutterForegroundTask's shared-prefs persistence.
  ///
  /// Idempotent: `stopService` is a no-op when no service is running;
  /// `removeData` is a no-op when the key is absent. Safe to call from
  /// the auth-bridge teardown regardless of whether the user was a tech
  /// who had been broadcasting (or even a tech at all).
  Future<void> tearDown() async {
    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(
      key: TechLocationTaskKeys.configKey,
    );
  }
}

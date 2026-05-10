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
//
// Audit H13: consumes the `IForegroundTaskBackend` port instead of the
// static `FlutterForegroundTask.X` API directly so tests can verify the
// teardown contract with a recording fake.

import '../../domain/ports/foreground_task_backend.dart';
import 'foreground_task_handler.dart';

class ForegroundLocationLifecycle {
  final IForegroundTaskBackend _foregroundTask;

  const ForegroundLocationLifecycle(this._foregroundTask);

  /// Stops any in-flight tech-location foreground service AND removes
  /// the saved config blob (auth token + booking id) from
  /// FlutterForegroundTask's shared-prefs persistence.
  ///
  /// Idempotent: `stopService` is a no-op when no service is running;
  /// `removeData` is a no-op when the key is absent. Safe to call from
  /// the auth-bridge teardown regardless of whether the user was a tech
  /// who had been broadcasting (or even a tech at all).
  Future<void> tearDown() async {
    await _foregroundTask.stopService();
    await _foregroundTask.removeData(key: TechLocationTaskKeys.configKey);
  }
}

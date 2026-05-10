// Port for the `flutter_foreground_task` static surface used by the
// **isolate** side of the broadcaster feature.
//
// Audit H13 (isolate side): `_TechLocationTaskHandler` previously
// coupled to `FlutterForegroundTask.getData` and
// `FlutterForegroundTask.sendDataToMain` directly, leaving onStart's
// config-decode + onFix's fatal-auth signalling impossible to verify
// in unit tests. This protocol is the seam — production passes
// `IsolateFlutterForegroundTaskBackend` (forwards to the real static
// API), tests pass a recording fake.
//
// Kept distinct from `IForegroundTaskBackend` (main-side) by design:
// the two surfaces don't overlap, and Riverpod doesn't cross isolate
// boundaries so a single port couldn't be reused even if it did.

abstract class IIsolateForegroundTaskBackend {
  /// Reads a value the main-side controller previously stashed via
  /// `IForegroundTaskBackend.saveData`. Returns `null` when the key is
  /// absent (e.g. the controller called startService without the
  /// preceding saveData — a controller bug the handler tolerates).
  Future<T?> getData<T>({required String key});

  /// Forwards a primitive payload back to the main isolate, where the
  /// controller's `addTaskDataCallback` listener picks it up. Used to
  /// signal fatal-auth (401/403) errors so the controller can stop the
  /// service and surface `BroadcastState.error`.
  void sendDataToMain(Object data);
}

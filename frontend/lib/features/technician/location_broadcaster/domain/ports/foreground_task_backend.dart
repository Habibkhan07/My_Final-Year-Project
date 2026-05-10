// Port for the `flutter_foreground_task` static surface used by the
// main-isolate side of the broadcaster feature.
//
// Audit H13 (T-3 / T-22): the controller couples to
// `FlutterForegroundTask.<static>` directly, which makes the
// status × role lifecycle, permission flow, and fatal-auth latch
// unverifiable in unit tests. This protocol is the seam — production
// passes `FlutterForegroundTaskBackend` (forwards to the real static
// API), tests pass a recording fake.
//
// Scope: ONLY the calls the main-isolate consumers (`ForegroundLocation
// ServiceController`, `ForegroundLocationLifecycle`) actually invoke.
// The isolate-side handler (`_TechLocationTaskHandler`) has its own
// boundary because its calls cross the isolate (e.g. `getData`,
// `sendDataToMain`) and would muddy the main-isolate protocol.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

abstract class IForegroundTaskBackend {
  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  });

  Future<NotificationPermission> checkNotificationPermission();
  Future<NotificationPermission> requestNotificationPermission();

  Future<void> saveData({required String key, required String value});
  Future<void> removeData({required String key});

  Future<ServiceRequestResult> startService({
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  });

  Future<ServiceRequestResult> stopService();

  /// Registers [callback] for messages forwarded from the foreground
  /// isolate's `sendDataToMain`. Tests' recording fake exposes a
  /// `simulateIsolateMessage(...)` method to drive registered callbacks
  /// synchronously.
  void addTaskDataCallback(void Function(Object data) callback);

  void removeTaskDataCallback(void Function(Object data) callback);
}

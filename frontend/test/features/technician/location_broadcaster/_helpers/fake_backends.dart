// Recording fake adapters for the H13 ports.
//
// These are NOT mocks — mocktail can't easily handle the
// `flutter_foreground_task` types (and stubbing every method per test
// would balloon the test bodies). Instead each fake exposes a small
// API for tests to:
//   • inspect what the controller called (e.g. `startCalls`,
//     `permissionRequestCount`).
//   • drive the next return value (e.g. `nextStartResult`).
//   • simulate isolate→main messages (`simulateIsolateMessage(...)`).
//
// Defaults are "happy path": permissions granted, services start
// successfully. Tests override only the bits they care about.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:frontend/features/technician/location_broadcaster/domain/ports/foreground_task_backend.dart';
import 'package:frontend/features/technician/location_broadcaster/domain/ports/geolocator_backend.dart';
import 'package:geolocator/geolocator.dart';

class FakeForegroundTaskBackend implements IForegroundTaskBackend {
  // ─── Tunables for tests ────────────────────────────────────────────
  ServiceRequestResult nextStartResult = const ServiceRequestSuccess();
  ServiceRequestResult nextStopResult = const ServiceRequestSuccess();
  NotificationPermission notificationPermission = NotificationPermission.granted;
  NotificationPermission notificationRequestResult =
      NotificationPermission.granted;

  // ─── Recorded interactions ─────────────────────────────────────────
  int initCalls = 0;
  final List<({String key, String value})> saveDataCalls = [];
  final List<String> removeDataCalls = [];
  int startCalls = 0;
  int stopCalls = 0;
  String? lastNotificationTitle;
  String? lastNotificationText;
  int notificationPermissionChecks = 0;
  int notificationPermissionRequests = 0;
  final List<void Function(Object data)> registeredCallbacks = [];
  final List<void Function(Object data)> unregisteredCallbacks = [];

  /// Drives `addTaskDataCallback` listeners synchronously. Tests use
  /// this to simulate `_TechLocationTaskHandler.sendDataToMain(...)`.
  void simulateIsolateMessage(Object data) {
    for (final cb in List.of(registeredCallbacks)) {
      cb(data);
    }
  }

  @override
  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) {
    initCalls++;
  }

  @override
  Future<NotificationPermission> checkNotificationPermission() async {
    notificationPermissionChecks++;
    return notificationPermission;
  }

  @override
  Future<NotificationPermission> requestNotificationPermission() async {
    notificationPermissionRequests++;
    return notificationRequestResult;
  }

  @override
  Future<void> saveData({required String key, required String value}) async {
    saveDataCalls.add((key: key, value: value));
  }

  @override
  Future<void> removeData({required String key}) async {
    removeDataCalls.add(key);
  }

  @override
  Future<ServiceRequestResult> startService({
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    Function? callback,
  }) async {
    startCalls++;
    lastNotificationTitle = notificationTitle;
    lastNotificationText = notificationText;
    return nextStartResult;
  }

  @override
  Future<ServiceRequestResult> stopService() async {
    stopCalls++;
    return nextStopResult;
  }

  @override
  void addTaskDataCallback(void Function(Object data) callback) {
    registeredCallbacks.add(callback);
  }

  @override
  void removeTaskDataCallback(void Function(Object data) callback) {
    registeredCallbacks.remove(callback);
    unregisteredCallbacks.add(callback);
  }
}

class FakeGeolocatorBackend implements IGeolocatorBackend {
  // ─── Tunables ──────────────────────────────────────────────────────
  /// Sequence of `checkPermission()` results the controller will see.
  /// First call returns `[0]`, second `[1]`, etc.; once exhausted,
  /// the LAST element is repeated.
  List<LocationPermission> checkPermissionSequence = [
    LocationPermission.always,
  ];
  List<LocationPermission> requestPermissionSequence = [
    LocationPermission.always,
  ];
  bool nextOpenAppSettingsResult = true;

  // ─── Recorded interactions ─────────────────────────────────────────
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int openAppSettingsCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    final i = checkPermissionCalls < checkPermissionSequence.length
        ? checkPermissionCalls
        : checkPermissionSequence.length - 1;
    checkPermissionCalls++;
    return checkPermissionSequence[i];
  }

  @override
  Future<LocationPermission> requestPermission() async {
    final i = requestPermissionCalls < requestPermissionSequence.length
        ? requestPermissionCalls
        : requestPermissionSequence.length - 1;
    requestPermissionCalls++;
    return requestPermissionSequence[i];
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return nextOpenAppSettingsResult;
  }
}

// Production adapter: forwards every method to the real
// `FlutterForegroundTask.<static>` API. Stateless — the package keeps
// its own static state.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../domain/ports/foreground_task_backend.dart';

class FlutterForegroundTaskBackend implements IForegroundTaskBackend {
  const FlutterForegroundTaskBackend();

  @override
  void init({
    required AndroidNotificationOptions androidNotificationOptions,
    required IOSNotificationOptions iosNotificationOptions,
    required ForegroundTaskOptions foregroundTaskOptions,
  }) {
    FlutterForegroundTask.init(
      androidNotificationOptions: androidNotificationOptions,
      iosNotificationOptions: iosNotificationOptions,
      foregroundTaskOptions: foregroundTaskOptions,
    );
  }

  @override
  Future<NotificationPermission> checkNotificationPermission() =>
      FlutterForegroundTask.checkNotificationPermission();

  @override
  Future<NotificationPermission> requestNotificationPermission() =>
      FlutterForegroundTask.requestNotificationPermission();

  @override
  Future<void> saveData({required String key, required String value}) =>
      FlutterForegroundTask.saveData(key: key, value: value);

  @override
  Future<void> removeData({required String key}) =>
      FlutterForegroundTask.removeData(key: key);

  @override
  Future<ServiceRequestResult> startService({
    List<ForegroundServiceTypes>? serviceTypes,
    required String notificationTitle,
    required String notificationText,
    NotificationIcon? notificationIcon,
    Function? callback,
  }) {
    return FlutterForegroundTask.startService(
      serviceTypes: serviceTypes,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
      notificationIcon: notificationIcon,
      callback: callback,
    );
  }

  @override
  Future<ServiceRequestResult> stopService() =>
      FlutterForegroundTask.stopService();

  @override
  void addTaskDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.addTaskDataCallback(callback);
  }

  @override
  void removeTaskDataCallback(void Function(Object data) callback) {
    FlutterForegroundTask.removeTaskDataCallback(callback);
  }
}

// Production adapter for the isolate-side foreground-task surface.
// Stateless — the package keeps its own static state.

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../domain/ports/isolate_foreground_task_backend.dart';

class IsolateFlutterForegroundTaskBackend
    implements IIsolateForegroundTaskBackend {
  const IsolateFlutterForegroundTaskBackend();

  @override
  Future<T?> getData<T>({required String key}) =>
      FlutterForegroundTask.getData<T>(key: key);

  @override
  void sendDataToMain(Object data) {
    FlutterForegroundTask.sendDataToMain(data);
  }

  @override
  void launchApp([String? route]) {
    FlutterForegroundTask.launchApp(route);
  }
}

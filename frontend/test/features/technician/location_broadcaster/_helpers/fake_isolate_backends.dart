// Recording fakes for the isolate-side ports used by
// `TechLocationTaskHandler`.
//
// Mirrors the H13 main-side fakes' shape:
//   • `nextX` tunables for return values.
//   • Recorded fields tests inspect.
//   • Stream controller for position-stream injection.

import 'dart:async';

import 'package:frontend/features/technician/location_broadcaster/domain/ports/isolate_foreground_task_backend.dart';
import 'package:frontend/features/technician/location_broadcaster/domain/ports/isolate_geolocator_backend.dart';
import 'package:geolocator/geolocator.dart';

class FakeIsolateForegroundTaskBackend implements IIsolateForegroundTaskBackend {
  /// Returned by [getData] for the matching key. Default `null` =
  /// "controller never saved a config blob."
  String? nextConfigBlob;

  final List<String> getDataCalls = [];
  final List<Object> sentToMain = [];
  final List<String?> launchAppCalls = [];

  @override
  Future<T?> getData<T>({required String key}) async {
    getDataCalls.add(key);
    return nextConfigBlob as T?;
  }

  @override
  void sendDataToMain(Object data) {
    sentToMain.add(data);
  }

  @override
  void launchApp([String? route]) {
    launchAppCalls.add(route);
  }
}

class FakeIsolateGeolocatorBackend implements IIsolateGeolocatorBackend {
  LocationPermission nextPermission = LocationPermission.always;

  /// Stream the handler subscribes to. Tests push `Position` values
  /// onto this controller to drive `_onFix`. Broadcast variant —
  /// avoids the hang where a single-subscription `close()` future
  /// never completes when the early-return tests never attached a
  /// listener.
  final StreamController<Position> positionController =
      StreamController<Position>.broadcast();

  final List<LocationSettings?> getPositionStreamCalls = [];
  int checkPermissionCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCalls++;
    return nextPermission;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    getPositionStreamCalls.add(locationSettings);
    return positionController.stream;
  }

  Future<void> close() async {
    if (!positionController.isClosed) await positionController.close();
  }
}

/// Convenience factory matching geolocator's `Position(...)` shape.
Position fakePosition({
  double lat = 31.5204,
  double lng = 74.3587,
  double accuracy = 5.0,
  double heading = 90.0,
  double headingAccuracy = 5.0,
  double speed = 0.0,
}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: accuracy,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: heading,
    headingAccuracy: headingAccuracy,
    speed: speed,
    speedAccuracy: 0.0,
  );
}

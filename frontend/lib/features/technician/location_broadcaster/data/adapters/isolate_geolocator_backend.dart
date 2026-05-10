// Production adapter for the isolate-side Geolocator surface.
// Stateless.

import 'package:geolocator/geolocator.dart';

import '../../domain/ports/isolate_geolocator_backend.dart';

class IsolateGeolocatorBackend implements IIsolateGeolocatorBackend {
  const IsolateGeolocatorBackend();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      Geolocator.getPositionStream(locationSettings: locationSettings);
}

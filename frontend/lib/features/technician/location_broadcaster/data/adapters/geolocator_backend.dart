// Production adapter: forwards every method to the real
// `Geolocator.<static>` API. Stateless.

import 'package:geolocator/geolocator.dart';

import '../../domain/ports/geolocator_backend.dart';

class GeolocatorBackend implements IGeolocatorBackend {
  const GeolocatorBackend();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}

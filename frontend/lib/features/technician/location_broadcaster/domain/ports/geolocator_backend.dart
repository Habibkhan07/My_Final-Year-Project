// Port for the `Geolocator` static surface used by the main-isolate
// side of the broadcaster feature.
//
// Audit H13: scope is the calls `ForegroundLocationServiceController`
// makes during permission resolution + the settings deep-link.
// `Geolocator.getPositionStream` is intentionally NOT in this protocol
// — it lives in the isolate-side task handler, behind a separate seam.

import 'package:geolocator/geolocator.dart';

abstract class IGeolocatorBackend {
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<bool> openAppSettings();
}

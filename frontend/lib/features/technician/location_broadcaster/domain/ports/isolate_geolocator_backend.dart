// Port for the `Geolocator` static surface used by the **isolate**
// side of the broadcaster feature.
//
// Audit H13 (isolate side): `_TechLocationTaskHandler` couples to
// `Geolocator.checkPermission` + `Geolocator.getPositionStream`
// directly. The position-stream call in particular needs a seam — the
// real `Geolocator.getPositionStream` requires a Flutter binding and
// platform channels that don't exist in the test isolate, so without
// this port we cannot drive `_onFix` at all.
//
// Kept distinct from `IGeolocatorBackend` (main-side) by design:
// `requestPermission` and `openAppSettings` are main-isolate concerns
// (they pop dialogs / activities); the isolate only checks permission
// defensively and listens on the stream.

import 'package:geolocator/geolocator.dart';

abstract class IIsolateGeolocatorBackend {
  /// Defensive re-check inside the isolate. The main-side controller
  /// has already gated startService on permission, but the user can
  /// revoke between then and the isolate spinning up.
  Future<LocationPermission> checkPermission();

  /// Stream of GPS fixes. Cancellation of the returned subscription is
  /// the handler's job — adapters do not retain the stream.
  Stream<Position> getPositionStream({LocationSettings? locationSettings});
}

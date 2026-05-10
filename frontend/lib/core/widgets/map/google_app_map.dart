import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import 'i_app_map.dart';
import 'live_marker_factory.dart';

/// google_maps_flutter implementation of [IAppMap].
///
/// Engaged when `--dart-define=MAP_PROVIDER=google` AND a
/// `GOOGLE_MAPS_API_KEY` is set. Marker bitmaps are produced on the
/// fly by [LiveMarkerFactory] (canvas-painted PNGs cached by kind).
/// Camera control mirrors [OsmAppMap] for UX parity — same recentre
/// behaviour, same `onUserGesture` contract.
class GoogleAppMap extends StatefulWidget implements IAppMap {
  @override
  final LatLng initialCenter;
  @override
  final double initialZoom;
  @override
  final List<MapMarker> markers;
  @override
  final List<MapPolyline> polylines;
  @override
  final LatLng? cameraTarget;
  @override
  final double? cameraZoom;
  @override
  final List<LatLng>? cameraBounds;
  @override
  final VoidCallback? onUserGesture;

  const GoogleAppMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 15.0,
    this.markers = const [],
    this.polylines = const [],
    this.cameraTarget,
    this.cameraZoom,
    this.cameraBounds,
    this.onUserGesture,
  });

  @override
  State<GoogleAppMap> createState() => _GoogleAppMapState();
}

class _GoogleAppMapState extends State<GoogleAppMap> {
  final Completer<gmaps.GoogleMapController> _controllerCompleter =
      Completer<gmaps.GoogleMapController>();

  /// gmaps marker set, recomputed when `widget.markers` change. We
  /// resolve `BitmapDescriptor` futures and only setState once all
  /// descriptors for the current set are ready — keeps the marker
  /// list visually stable (no "pop-in").
  Set<gmaps.Marker> _renderedMarkers = const {};

  bool _programmaticMoveInFlight = false;

  @override
  void initState() {
    super.initState();
    unawaited(_resolveMarkers(widget.markers));
  }

  @override
  void didUpdateWidget(covariant GoogleAppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!GoogleAppMapInternals.markersEqual(
      oldWidget.markers,
      widget.markers,
    )) {
      unawaited(_resolveMarkers(widget.markers));
    }
    _maybeApplyCamera(oldWidget);
  }

  Future<void> _resolveMarkers(List<MapMarker> incoming) async {
    // Audit M-3 (Batch C): pass the host device's pixel ratio through
    // to the marker factory so the cache key + bitmap rendering match
    // the device. `View.of(context)` works from initState (unlike
    // `MediaQuery.of(context)` which requires the inherited-widget
    // tree to be ready).
    final dpr = View.of(context).devicePixelRatio;
    final resolved = await GoogleAppMapInternals.resolveAllMarkers(
      incoming,
      resolveIcon: (kind) =>
          LiveMarkerFactory.buildGoogleMarker(kind, devicePixelRatio: dpr),
    );
    if (!mounted) return;
    setState(() => _renderedMarkers = resolved);
  }

  Future<void> _maybeApplyCamera(GoogleAppMap oldWidget) async {
    // GMAP-3 (Batch I): bound the wait on the controller completer
    // so test isolates (which never mount a real `gmaps.GoogleMap`,
    // so `onMapCreated` never fires) don't hang forever. Production
    // is unaffected — `onMapCreated` resolves the completer within
    // a few hundred ms of mount. A 5s ceiling is well past that and
    // short enough that a stuck test fails fast.
    final gmaps.GoogleMapController controller;
    try {
      controller = await _controllerCompleter.future
          .timeout(const Duration(seconds: 5));
    } on TimeoutException {
      return;
    }
    if (!mounted) return;

    final newTarget = widget.cameraTarget;
    final oldTarget = oldWidget.cameraTarget;
    final targetChanged =
        newTarget != null &&
        (oldTarget == null ||
            oldTarget.latitude != newTarget.latitude ||
            oldTarget.longitude != newTarget.longitude ||
            oldWidget.cameraZoom != widget.cameraZoom);

    if (targetChanged) {
      _programmaticMoveInFlight = true;
      // Audit M-14 (Batch C): when the caller does NOT supply a zoom,
      // preserve the current camera zoom (matches OSM's behaviour of
      // `widget.cameraZoom ?? _controller.camera.zoom`). Pre-fix, a
      // target-only follow-camera move snapped back to `initialZoom`,
      // erasing whatever pinch-zoom the user had applied. The
      // `newLatLng` constructor preserves the current zoom natively.
      final zoom = widget.cameraZoom;
      final update = zoom != null
          ? gmaps.CameraUpdate.newLatLngZoom(
              gmaps.LatLng(newTarget.latitude, newTarget.longitude),
              zoom,
            )
          : gmaps.CameraUpdate.newLatLng(
              gmaps.LatLng(newTarget.latitude, newTarget.longitude),
            );
      await controller.animateCamera(update);
      _programmaticMoveInFlight = false;
      return;
    }

    final newBounds = widget.cameraBounds;
    final boundsChanged =
        newBounds != null &&
        newBounds.isNotEmpty &&
        !GoogleAppMapInternals.listsAreSame(oldWidget.cameraBounds, newBounds);
    if (boundsChanged && newTarget == null) {
      final fit = GoogleAppMapInternals.computeBounds(newBounds);
      _programmaticMoveInFlight = true;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(fit, 64),
      );
      _programmaticMoveInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      onMapCreated: (controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
      },
      markers: _renderedMarkers,
      polylines: widget.polylines
          .map(
            (p) => gmaps.Polyline(
              polylineId: gmaps.PolylineId(p.id),
              points: p.points
                  .map((ll) => gmaps.LatLng(ll.latitude, ll.longitude))
                  .toList(),
              color: p.color,
              width: p.strokeWidth.round(),
            ),
          )
          .toSet(),
      // We own the recentre / follow logic. The native FAB is noise.
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      onCameraMoveStarted: () {
        if (!_programmaticMoveInFlight) {
          widget.onUserGesture?.call();
        }
      },
    );
  }
}

/// Test-visible internals for `GoogleAppMap`.
///
/// `_GoogleAppMapState` is library-private so its helpers cannot be
/// reached from a test file. Hoisting them onto a public companion
/// class — annotated `@visibleForTesting` — keeps the helpers available
/// to unit tests without pretending the API is public.
///
/// The marker-resolution future-merge accepts an injectable
/// `resolveIcon` so tests do not need to spin up the
/// `LiveMarkerFactory` canvas pipeline (which requires a Flutter
/// binding plus the gmaps platform side). Production callers always
/// pass `LiveMarkerFactory.buildGoogleMarker`.
@visibleForTesting
class GoogleAppMapInternals {
  GoogleAppMapInternals._();

  /// Returns true when the two marker lists are field-equal in order.
  /// `MapMarker` defines value equality on (id, position, kind,
  /// rotationDegrees), so reference inequality with field equality
  /// must register as "equal" here — otherwise every parent rebuild
  /// would trigger a costly marker re-resolve.
  static bool markersEqual(List<MapMarker> a, List<MapMarker> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Returns true when both LatLng lists have the same length and
  /// component-equal positions in order. Both null → true. One null →
  /// false.
  static bool listsAreSame(List<LatLng>? a, List<LatLng>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }

  /// Smallest axis-aligned bounding box covering every point.
  /// Caller must gate on `points.isNotEmpty` — accessing `points.first`
  /// on an empty list throws `StateError` (intentional; an empty input
  /// has no defined bounds).
  static gmaps.LatLngBounds computeBounds(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return gmaps.LatLngBounds(
      southwest: gmaps.LatLng(minLat, minLng),
      northeast: gmaps.LatLng(maxLat, maxLng),
    );
  }

  /// Resolves every incoming marker's icon in parallel and returns the
  /// gmaps marker set ONLY when every descriptor is ready. The
  /// `Future.wait` is load-bearing — emitting markers as they resolve
  /// would visually pop in (audit T-1).
  ///
  /// `resolveIcon` is the test seam. Production callers pass
  /// `LiveMarkerFactory.buildGoogleMarker`.
  static Future<Set<gmaps.Marker>> resolveAllMarkers(
    List<MapMarker> incoming, {
    required Future<gmaps.BitmapDescriptor> Function(MarkerKind) resolveIcon,
  }) async {
    final futures = incoming.map((m) async {
      final icon = await resolveIcon(m.kind);
      return gmaps.Marker(
        markerId: gmaps.MarkerId(m.id),
        position: gmaps.LatLng(m.position.latitude, m.position.longitude),
        rotation: m.rotationDegrees,
        anchor: const Offset(0.5, 0.5),
        icon: icon,
        flat: true,
      );
    }).toList();
    final resolved = await Future.wait(futures);
    return resolved.toSet();
  }
}

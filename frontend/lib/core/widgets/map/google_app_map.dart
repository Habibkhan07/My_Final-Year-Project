import 'dart:async';

import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart'
    show EagerGestureRecognizer, OneSequenceGestureRecognizer;
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
  final List<MapCircle> circles;
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
    this.circles = const [],
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

  /// GMAP-P1 (audit P1.3): icon descriptors cached per (kind, dpr) so
  /// `build()` constructs the gmaps.Marker Set synchronously from the
  /// current widget state. Pre-fix every tween tick (60Hz during the
  /// marker animation) fired an async `_resolveMarkers` cascade —
  /// `setState` + GoogleMap diff per frame — that contributed to
  /// gesture flakiness during the active animation. Now the async
  /// work runs ONCE per unique (kind, dpr) and tween position updates
  /// flow straight through `build()` with no extra setState.
  ///
  /// Cache shape uses a record key so two distinct device pixel
  /// ratios on the same kind don't collide (an Android tablet whose
  /// display config changes mid-session — rare but defended).
  final Map<({MarkerKind kind, double dpr}), gmaps.BitmapDescriptor>
      _iconCache = {};

  bool _programmaticMoveInFlight = false;

  /// GMAP-P3 (audit "slow to move" bulletproof Tier 1): stable
  /// reference to the gesture recognizer Factory Set shared across
  /// every GoogleAppMap instance and every build().
  ///
  /// Pre-fix this Set lived inline inside `build()` — a fresh
  /// `Set<Factory>` containing a fresh `Factory` containing a fresh
  /// closure was allocated on every rebuild. `Factory` doesn't
  /// override `==`, so google_maps_flutter's diff compared old vs
  /// new gestureRecognizers by element identity and saw "different"
  /// on every rebuild → rebound the platform view's gesture recognizers
  /// at 60Hz during the marker tween. The pinch/pan state machine
  /// was constantly being reset mid-touch.
  ///
  /// Sharing the factory Set across instances is safe: factories are
  /// templates and the plugin invokes `factory.constructor()` per
  /// platform view to obtain a fresh recognizer instance. EagerGesture-
  /// Recognizer has no per-instance state that would leak.
  static final Set<Factory<OneSequenceGestureRecognizer>>
      _gestureRecognizers = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(
      () => EagerGestureRecognizer(),
    ),
  };

  /// GMAP-P3: cached at first build, reused on every subsequent build.
  /// `initialCameraPosition` is consumed exactly once by the plugin
  /// (when the platform view first mounts), so identity stability
  /// across rebuilds isn't load-bearing — caching it is tidiness, not
  /// correctness. The reused reference still keeps the build() body
  /// allocation-free during the tween hot path.
  late final gmaps.CameraPosition _initialCameraPosition =
      gmaps.CameraPosition(
        target: gmaps.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoom: widget.initialZoom,
      );

  /// GMAP-P3: stable callback identities. Pre-fix `onMapCreated` and
  /// `onCameraMoveStarted` were inline closures inside build(), so
  /// google_maps_flutter saw "new callback reference" on every rebuild
  /// and re-registered the platform-side listeners. Captured as
  /// `late final` so identity is stable; the closure body resolves
  /// `widget.onUserGesture` and `_programmaticMoveInFlight` dynamically
  /// per-call (same behaviour as the original inline closures).
  late final void Function(gmaps.GoogleMapController) _onMapCreated =
      (controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
      };

  late final VoidCallback _onCameraMoveStarted = () {
    if (!_programmaticMoveInFlight) {
      widget.onUserGesture?.call();
    }
  };

  @override
  void initState() {
    super.initState();
    unawaited(_ensureIconsForCurrentMarkers());
  }

  @override
  void didUpdateWidget(covariant GoogleAppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // GMAP-P1: only fire async icon resolution when a NEW kind appears
    // (rare — once per kind at mount). Position / rotation updates are
    // picked up by `build()` reading from `_iconCache` synchronously,
    // so the tween hot path no longer triggers setState on this widget.
    final newKinds = widget.markers.map((m) => m.kind).toSet();
    final oldKinds = oldWidget.markers.map((m) => m.kind).toSet();
    if (newKinds.difference(oldKinds).isNotEmpty) {
      unawaited(_ensureIconsForCurrentMarkers());
    }
    _maybeApplyCamera(oldWidget);
  }

  /// Resolves icon descriptors for any marker kinds present on the
  /// current widget but missing from the cache. Idempotent — calling
  /// twice when nothing's missing is a no-op (no setState, no future).
  ///
  /// Audit M-3 (Batch C): pass the host device's pixel ratio through
  /// to the marker factory so the cache key + bitmap rendering match
  /// the device. `View.of(context)` works from initState (unlike
  /// `MediaQuery.of(context)` which requires the inherited-widget
  /// tree to be ready).
  Future<void> _ensureIconsForCurrentMarkers() async {
    final dpr = View.of(context).devicePixelRatio;
    final neededKinds = widget.markers.map((m) => m.kind).toSet();
    final missing = neededKinds
        .where((k) => !_iconCache.containsKey((kind: k, dpr: dpr)))
        .toList(growable: false);
    if (missing.isEmpty) return;

    final entries = await Future.wait(
      missing.map((k) async {
        final desc = await LiveMarkerFactory.buildGoogleMarker(
          k,
          devicePixelRatio: dpr,
        );
        return MapEntry((kind: k, dpr: dpr), desc);
      }),
    );
    if (!mounted) return;
    setState(() {
      _iconCache.addEntries(entries);
    });
  }

  /// Synchronously constructs the gmaps.Marker Set from the current
  /// `widget.markers` + the resolved icon cache. Markers whose icon
  /// hasn't resolved yet are skipped — transient, same UX as the
  /// pre-fix "wait for resolution" path (which simply rendered an
  /// empty set during the same window).
  Set<gmaps.Marker> _buildSyncMarkerSet() {
    final dpr = View.of(context).devicePixelRatio;
    final markers = <gmaps.Marker>{};
    for (final m in widget.markers) {
      final icon = _iconCache[(kind: m.kind, dpr: dpr)];
      if (icon == null) continue;
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(m.id),
          position: gmaps.LatLng(m.position.latitude, m.position.longitude),
          rotation: m.rotationDegrees,
          anchor: const Offset(0.5, 0.5),
          icon: icon,
          flat: true,
        ),
      );
    }
    return markers;
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
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: _onMapCreated,
      markers: _buildSyncMarkerSet(),
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
      // P2: GPS accuracy circles. Google natively interprets `radius`
      // in metres, so the value passes through unchanged. Circles
      // render below markers + polylines by default in google_maps_flutter
      // so the tech bubble + route line stay visually on top.
      circles: widget.circles
          .map(
            (c) => gmaps.Circle(
              circleId: gmaps.CircleId(c.id),
              center: gmaps.LatLng(c.center.latitude, c.center.longitude),
              radius: c.radiusMeters,
              fillColor: c.fillColor,
              strokeColor: c.strokeColor,
              strokeWidth: c.strokeWidth.round(),
            ),
          )
          .toSet(),
      // We own the recentre / follow logic. The native FAB is noise.
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      // GMAP-P3 (audit bulletproof Tier 1): static-final Set hoisted
      // out of build(). See `_gestureRecognizers` docstring above.
      gestureRecognizers: _gestureRecognizers,
      // GMAP-P3: stable callback identity — see `_onCameraMoveStarted`
      // docstring. Pre-fix this was a fresh closure on every rebuild,
      // causing the plugin to re-bind the platform-side listener at
      // 60Hz during the marker tween.
      onCameraMoveStarted: _onCameraMoveStarted,
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

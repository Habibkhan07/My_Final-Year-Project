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
    if (!_markersEqual(oldWidget.markers, widget.markers)) {
      unawaited(_resolveMarkers(widget.markers));
    }
    _maybeApplyCamera(oldWidget);
  }

  Future<void> _resolveMarkers(List<MapMarker> incoming) async {
    final futures = incoming.map((m) async {
      final icon = await LiveMarkerFactory.buildGoogleMarker(m.kind);
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
    if (!mounted) return;
    setState(() => _renderedMarkers = resolved.toSet());
  }

  static bool _markersEqual(List<MapMarker> a, List<MapMarker> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _maybeApplyCamera(GoogleAppMap oldWidget) async {
    final controller = await _controllerCompleter.future;
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
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(newTarget.latitude, newTarget.longitude),
          widget.cameraZoom ?? widget.initialZoom,
        ),
      );
      _programmaticMoveInFlight = false;
      return;
    }

    final newBounds = widget.cameraBounds;
    final boundsChanged =
        newBounds != null &&
        newBounds.isNotEmpty &&
        !_listsAreSame(oldWidget.cameraBounds, newBounds);
    if (boundsChanged && newTarget == null) {
      final fit = _computeBounds(newBounds);
      _programmaticMoveInFlight = true;
      await controller.animateCamera(
        gmaps.CameraUpdate.newLatLngBounds(fit, 64),
      );
      _programmaticMoveInFlight = false;
    }
  }

  static gmaps.LatLngBounds _computeBounds(List<LatLng> points) {
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

  static bool _listsAreSame(List<LatLng>? a, List<LatLng>? b) {
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

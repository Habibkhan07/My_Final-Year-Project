import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'i_app_map.dart';
import 'live_marker_factory.dart';

/// flutter_map (OSM) implementation of [IAppMap].
///
/// Default for dev / demo per `project_maps_strategy` — no API key,
/// works out of the box. Production parity is maintained: the same
/// marker bubble look, same polyline thickness, same camera follow
/// semantics as [GoogleAppMap].
///
/// The widget is stateful because `MapController` instances must
/// survive widget rebuilds, and the camera is driven imperatively
/// in `didUpdateWidget` when the parent changes
/// [cameraTarget] / [cameraBounds].
class OsmAppMap extends StatefulWidget implements IAppMap {
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

  const OsmAppMap({
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
  State<OsmAppMap> createState() => _OsmAppMapState();
}

class _OsmAppMapState extends State<OsmAppMap> {
  late final MapController _controller;

  /// Set true while we're driving a programmatic camera move so the
  /// `onPositionChanged` callback can distinguish our own moves from
  /// the user's pinch / drag gestures.
  bool _programmaticMoveInFlight = false;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
  }

  @override
  void didUpdateWidget(covariant OsmAppMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeApplyCamera(oldWidget);
  }

  void _maybeApplyCamera(OsmAppMap oldWidget) {
    // cameraTarget wins over cameraBounds when both supplied.
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
      _controller.move(newTarget, widget.cameraZoom ?? _controller.camera.zoom);
      // Reset on next frame — flutter_map fires onPositionChanged
      // synchronously inside `move`, so by the next microtask the
      // gesture window is open again.
      // OSM-2 (Batch I): mounted-guard inside the post-frame callback.
      // If the widget unmounts before the next frame fires (rare —
      // navigation pop mid-camera-move), the callback was writing to
      // a defunct State.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _programmaticMoveInFlight = false;
      });
      return;
    }

    final newBounds = widget.cameraBounds;
    final boundsChanged =
        newBounds != null &&
        newBounds.isNotEmpty &&
        !_listsAreSame(oldWidget.cameraBounds, newBounds);
    if (boundsChanged && newTarget == null) {
      _programmaticMoveInFlight = true;
      _controller.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(newBounds),
          padding: const EdgeInsets.all(64),
        ),
      );
      // OSM-2 (Batch I): mounted-guard, see above.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _programmaticMoveInFlight = false;
      });
    }
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
    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        // Pinch-zoom + drag are enough for v1; rotation/tilt are off
        // because the marker bubble already encodes heading via its
        // own Transform.rotate.
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.pinchZoom |
              InteractiveFlag.drag |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation,
        ),
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture && !_programmaticMoveInFlight) {
            widget.onUserGesture?.call();
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fyp.frontend',
          // OSM tile policy: respect their attribution. v1 we honour
          // the User-Agent requirement; visible attribution will be
          // added during the design-system cleanup pass.
        ),
        if (widget.polylines.isNotEmpty)
          PolylineLayer(
            polylines: widget.polylines
                .map(
                  (p) => Polyline(
                    points: p.points,
                    color: p.color,
                    strokeWidth: p.strokeWidth,
                  ),
                )
                .toList(growable: false),
          ),
        if (widget.markers.isNotEmpty)
          MarkerLayer(
            markers: widget.markers
                .map(
                  (m) => Marker(
                    point: m.position,
                    width: LiveMarkerFactory.bubbleDiameter,
                    height: LiveMarkerFactory.bubbleDiameter,
                    // alignment.center keeps the bubble centred on the
                    // GPS point — visually correct for both house and
                    // motorbike (no "pin tip" at the bottom).
                    alignment: Alignment.center,
                    child: LiveMarkerFactory.buildOsmMarker(m),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

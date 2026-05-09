import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

/// Provider-agnostic map widget protocol.
///
/// Both [OsmAppMap] and [GoogleAppMap] implement this. Consumers
/// (`LiveTrackingMap`) receive an `IAppMap` builder via the
/// `appMapBuilderProvider` Riverpod provider and never touch the
/// concrete classes — keeping the build-time `MAP_PROVIDER` choice
/// invisible to feature code.
///
/// Camera control is **declarative**, not imperative. The parent owns
/// the camera state (target + zoom OR a bounds list) and rebuilds the
/// map with new props to move the view. This sidesteps the lifecycle
/// asymmetry between flutter_map's synchronous `MapController` and
/// google_maps_flutter's asynchronously-acquired `GoogleMapController`.
abstract class IAppMap extends Widget {
  const IAppMap({super.key});

  /// Camera center on first build. Subsequent moves go through
  /// [cameraTarget] or [cameraBounds].
  LatLng get initialCenter;

  double get initialZoom;

  List<MapMarker> get markers;

  List<MapPolyline> get polylines;

  /// When non-null, the map animates to this point + [cameraZoom] on
  /// every prop change. Wins over [cameraBounds] when both are set.
  LatLng? get cameraTarget;

  /// Used together with [cameraTarget] to drive imperative recentre /
  /// follow-the-tech behaviour from the parent.
  double? get cameraZoom;

  /// When non-null AND [cameraTarget] is null, the map fits the camera
  /// to encompass these points with a fixed padding. Used on the very
  /// first GPS frame to show "tech + customer + route" all at once.
  List<LatLng>? get cameraBounds;

  /// Fired ONCE per user-driven pan/zoom (not for programmatic moves
  /// triggered by [cameraTarget] / [cameraBounds] prop changes). The
  /// parent uses this to disable auto-follow until the user taps the
  /// recentre FAB.
  VoidCallback? get onUserGesture;
}

/// Semantic kind of a marker. The marker factory turns this into the
/// actual icon + colour bubble for each provider. We deliberately do
/// NOT expose raw asset paths here — keeping the surface narrow means
/// future re-skins (custom truck icon for tech, etc.) only touch the
/// factory.
enum MarkerKind {
  /// The customer's destination. Rendered as a green house bubble.
  customer,

  /// Technician on the move (EN_ROUTE). Orange motorbike bubble,
  /// rotated to GPS heading.
  technicianMoving,

  /// Technician stationary (ARRIVED). Orange person bubble, no rotation.
  technicianStopped,
}

@immutable
class MapMarker {
  /// Stable identifier for the marker. flutter_map ignores it; Google
  /// Maps uses it as `MarkerId`. We keep it consistent across providers.
  final String id;

  final LatLng position;

  final MarkerKind kind;

  /// Degrees clockwise from north. 0 when not applicable (customer
  /// marker, or stationary technician, or null GPS heading).
  final double rotationDegrees;

  const MapMarker({
    required this.id,
    required this.position,
    required this.kind,
    this.rotationDegrees = 0.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapMarker &&
          other.id == id &&
          other.position.latitude == position.latitude &&
          other.position.longitude == position.longitude &&
          other.kind == kind &&
          other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(
    id,
    position.latitude,
    position.longitude,
    kind,
    rotationDegrees,
  );
}

@immutable
class MapPolyline {
  final String id;
  final List<LatLng> points;

  /// Stroke colour. The live tracking widget passes a strong primary
  /// colour for clarity at low map zoom.
  final Color color;

  /// Stroke width in logical pixels. Default 6 — thicker than the
  /// flutter_map default (3) so the route is legible from a distance.
  final double strokeWidth;

  const MapPolyline({
    required this.id,
    required this.points,
    required this.color,
    this.strokeWidth = 6.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPolyline &&
          other.id == id &&
          other.color == color &&
          other.strokeWidth == strokeWidth &&
          _pointsEqual(other.points, points);

  static bool _pointsEqual(List<LatLng> a, List<LatLng> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].latitude != b[i].latitude || a[i].longitude != b[i].longitude) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    color,
    strokeWidth,
    points.length,
    points.isEmpty ? 0 : points.first.latitude,
    points.isEmpty ? 0 : points.last.latitude,
  );
}

import 'package:latlong2/latlong.dart';

/// Provider-agnostic directions API.
///
/// Concrete impls: [OsrmDirectionsService] (OSM provider, public
/// `router.project-osrm.org` instance for dev) and
/// [GoogleDirectionsService] (Google Directions API). Selection
/// happens at the `directionsServiceProvider` Riverpod provider —
/// consumer code (`LiveTrackingMap`) never imports either.
///
/// Throws subclasses of [DirectionsFailure] on failure; the consumer
/// is expected to soft-fail (keep the previous polyline + ETA).
abstract class IDirectionsService {
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  });
}

/// Result of a successful directions call.
///
/// [polyline] is a decoded list of `LatLng` points ready to drop into
/// a `MapPolyline`. Both impls normalise to this shape (Google's
/// `overview_polyline.points` encoded string is decoded; OSRM's
/// `geometries=geojson` raw coords are reordered lng,lat → lat,lng).
class DirectionsResult {
  final List<LatLng> polyline;

  /// Server-side estimated travel time in seconds. Used as the seed
  /// for the client-side ETA tickdown (`Timer.periodic(1s)` decrements
  /// until the next polyline fetch replaces it).
  final int etaSeconds;

  /// Total route distance in metres along the polyline. Displayed as
  /// "X.X km" on the ETA pill.
  final int distanceMeters;

  /// When this result was fetched (client wall clock). Used by
  /// `LiveTrackingMap` for the 30-second cooldown between fetches.
  final DateTime fetchedAt;

  const DirectionsResult({
    required this.polyline,
    required this.etaSeconds,
    required this.distanceMeters,
    required this.fetchedAt,
  });
}

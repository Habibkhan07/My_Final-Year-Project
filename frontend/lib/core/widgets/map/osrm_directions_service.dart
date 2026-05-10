import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'directions_failures.dart';
import 'i_directions_service.dart';

/// OSRM-backed directions provider. Free, no API key, returns
/// GeoJSON-encoded coordinates that need no decoding step.
///
/// Default base URL is the public OSRM demo instance — fine for dev
/// + demo, NOT fine for production (soft-rate-limited and the project
/// asks not to be used at scale). flag.md will note this; production
/// must self-host OSRM or fall back to Google.
class OsrmDirectionsService implements IDirectionsService {
  // SECURITY: read-only directions API. No PII flows; the only inputs
  // are the user's current location and the booking's destination
  // (both already on the user's device).
  final http.Client _client;
  final String _baseUrl;

  OsrmDirectionsService(
    this._client, {
    String baseUrl = 'https://router.project-osrm.org',
  }) : _baseUrl = baseUrl;

  @override
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // OSRM expects coords as `lng,lat` (note: NOT lat,lng like every
    // other API). Order is load-bearing.
    final coords =
        '${origin.longitude},${origin.latitude}'
        ';${destination.longitude},${destination.latitude}';

    final uri = Uri.parse('$_baseUrl/route/v1/driving/$coords').replace(
      queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
    );

    final http.Response response;
    try {
      // Audit H3 (M-5/T-7d): public OSRM routinely hangs 8-30s. Without
      // a timeout, the in-flight directions fetch sits in `_fetching`
      // forever and the polyline never updates. 8s is generous enough
      // for a fully-warm OSRM call and short enough that the user
      // doesn't watch a stale ETA tickdown for half a minute.
      response = await _client.get(uri).timeout(const Duration(seconds: 8));
    } on TimeoutException {
      throw const DirectionsNetworkFailure();
    } on SocketException {
      throw const DirectionsNetworkFailure();
    } catch (e) {
      throw UnknownDirectionsFailure(e.toString());
    }

    if (response.statusCode >= 500) {
      throw DirectionsServerFailure(response.statusCode);
    }
    if (response.statusCode != 200) {
      throw const DirectionsNetworkFailure();
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw UnknownDirectionsFailure('OSRM body not JSON: $e');
    }

    if (data['code'] != 'Ok') {
      // OSRM uses 'NoRoute', 'NoSegment', 'InvalidValue', etc. Treat
      // anything non-Ok as "couldn't route" — the user-facing UX is
      // identical (hide the polyline; live marker still works).
      throw const DirectionsNoRoute();
    }

    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const DirectionsNoRoute();
    }

    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List?;
    if (coordinates == null || coordinates.isEmpty) {
      throw const DirectionsNoRoute();
    }

    final points = coordinates
        .whereType<List>()
        .map(
          (c) => LatLng(
            (c[1] as num).toDouble(), // GeoJSON is lng,lat — flip to lat,lng
            (c[0] as num).toDouble(),
          ),
        )
        .toList(growable: false);

    final etaSeconds = ((route['duration'] as num?) ?? 0).round();
    final distanceMeters = ((route['distance'] as num?) ?? 0).round();

    return DirectionsResult(
      polyline: points,
      etaSeconds: etaSeconds,
      distanceMeters: distanceMeters,
      fetchedAt: DateTime.now(),
    );
  }
}

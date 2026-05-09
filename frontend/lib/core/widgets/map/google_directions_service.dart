import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../constants.dart';
import 'directions_failures.dart';
import 'i_directions_service.dart';

/// Google Directions API directions provider.
///
/// Used only when `MAP_PROVIDER=google` AND a `GOOGLE_MAPS_API_KEY`
/// has been provisioned. Throws `UnknownDirectionsFailure` when the
/// resolved API key is empty so the silent-key-missing case surfaces
/// in logs (flag #16 footgun).
///
/// The `apiKey` parameter overrides the compile-time constant from
/// `AppConstants.googleMapsApiKey`. Production code never passes it
/// (the default reads `AppConstants`); tests inject a stub key to
/// exercise the happy + parse paths.
class GoogleDirectionsService implements IDirectionsService {
  // SECURITY: read-only Directions API call. The booking's destination
  // is on the device already; no token / PII is sent.
  final http.Client _client;
  final String _apiKey;

  GoogleDirectionsService(this._client, {String? apiKey})
    : _apiKey = apiKey ?? AppConstants.googleMapsApiKey;

  static const _kHost = 'maps.googleapis.com';
  static const _kPath = '/maps/api/directions/json';

  @override
  Future<DirectionsResult> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      throw const UnknownDirectionsFailure(
        'Google Maps API key is not configured. '
        'Pass --dart-define=GOOGLE_MAPS_API_KEY=... at build time.',
      );
    }

    final uri = Uri.https(_kHost, _kPath, {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'departure_time': 'now', // enables traffic-aware ETA on best-effort
      'key': apiKey,
    });

    final http.Response response;
    try {
      response = await _client.get(uri);
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
      throw UnknownDirectionsFailure('Google body not JSON: $e');
    }

    final apiStatus = data['status'] as String?;
    if (apiStatus == 'OVER_QUERY_LIMIT' || apiStatus == 'OVER_DAILY_LIMIT') {
      throw const DirectionsApiQuotaExceeded();
    }
    if (apiStatus == 'ZERO_RESULTS' || apiStatus == 'NOT_FOUND') {
      throw const DirectionsNoRoute();
    }
    if (apiStatus != 'OK') {
      // Includes REQUEST_DENIED (bad key), INVALID_REQUEST, etc.
      // Surface via UnknownDirectionsFailure so the message lands in
      // logs verbatim — distinguishing these is a setup bug, not a
      // user-facing concern.
      throw UnknownDirectionsFailure('Google Directions status=$apiStatus');
    }

    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw const DirectionsNoRoute();
    }

    final firstRoute = routes.first as Map<String, dynamic>;
    final overview =
        (firstRoute['overview_polyline'] as Map?)?['points'] as String?;
    final legs = firstRoute['legs'] as List?;
    if (overview == null || legs == null || legs.isEmpty) {
      throw const DirectionsNoRoute();
    }

    final firstLeg = legs.first as Map<String, dynamic>;
    // duration_in_traffic is best-effort (only when departure_time set
    // AND for routes Google has traffic data on); fall back to the
    // standard duration field.
    final durationInTraffic =
        (firstLeg['duration_in_traffic'] as Map<String, dynamic>?)?['value'];
    final duration = (firstLeg['duration'] as Map<String, dynamic>?)?['value'];
    final etaSeconds = ((durationInTraffic ?? duration ?? 0) as num).round();
    final distanceMeters =
        (((firstLeg['distance'] as Map<String, dynamic>?)?['value']) as num? ??
                0)
            .round();

    final decoded = PolylinePoints()
        .decodePolyline(overview)
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList(growable: false);

    return DirectionsResult(
      polyline: decoded,
      etaSeconds: etaSeconds,
      distanceMeters: distanceMeters,
      fetchedAt: DateTime.now(),
    );
  }
}

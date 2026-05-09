import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/place_search_entity.dart';
import '../models/place_details.dart';
import 'geocoding_data_source.dart';

/// OpenStreetMap Nominatim adapter — DEV ONLY.
///
/// The Nominatim public endpoint is for development and small-scale apps.
/// Their usage policy explicitly forbids use in production-scale workloads
/// (1 req/sec hard cap, mandatory descriptive User-Agent). The factory in
/// `presentation/providers/dependency_injection.dart` only constructs this
/// adapter when no `GOOGLE_MAPS_API_KEY` is provided.
class NominatimGeocodingDataSource implements GeocodingDataSource {
  final http.Client _client;

  static const String _userAgent = 'FYP_HomeServices_App/1.0 (dev)';
  static const Map<String, String> _headers = {
    'User-Agent': _userAgent,
    'Accept-Language': 'en',
  };

  NominatimGeocodingDataSource(this._client);

  @override
  Future<List<PlaceSearchEntity>> searchPlaces(
    String query,
    String sessionToken,
  ) async {
    if (query.isEmpty) return const [];

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeQueryComponent(query)}'
      '&format=json&addressdetails=1&limit=5&countrycodes=pk',
    );
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) return const [];

    final list = (jsonDecode(response.body) as List)
        .cast<Map<String, dynamic>>();
    return list.map((p) {
      final display = p['display_name'] as String? ?? '';
      final firstComma = display.indexOf(',');
      return PlaceSearchEntity(
        placeId: p['place_id']?.toString() ?? '',
        description: display,
        mainText: firstComma > 0 ? display.substring(0, firstComma) : display,
        secondaryText: firstComma > 0 ? display.substring(firstComma + 2) : '',
      );
    }).toList();
  }

  @override
  Future<PlaceDetails> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    // Nominatim's `details` endpoint requires `osm_type` + `osm_id`, and the
    // `place_id` from `search` is unstable across servers. The pragmatic
    // approach for the dev path: re-query the same query string is overkill,
    // so we fall through to `lookup` which accepts the place_id directly when
    // available. Worst case the structured fields come back null and we
    // surface the formatted_address only.
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/details.php'
      '?place_id=$placeId&format=json&addressdetails=1',
    );
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) {
      throw const FormatException('Nominatim place details failed');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final centroid = json['centroid'] as Map<String, dynamic>?;
    final coords = centroid?['coordinates'] as List?;
    final lng = (coords != null && coords.length >= 2)
        ? (coords[0] as num).toDouble()
        : 0.0;
    final lat = (coords != null && coords.length >= 2)
        ? (coords[1] as num).toDouble()
        : 0.0;
    final formatted =
        (json['localname'] as String?) ??
        (json['display_name'] as String?) ??
        '$lat, $lng';

    return _parseAddressBlock(
      formatted: formatted,
      lat: lat,
      lng: lng,
      address: (json['address'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  Future<PlaceDetails> reverseGeocode(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lng&format=json&addressdetails=1&zoom=14',
    );
    final response = await _client.get(url, headers: _headers);
    if (response.statusCode != 200) return _coordOnly(lat, lng);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final formatted = json['display_name'] as String? ?? '$lat, $lng';
    return _parseAddressBlock(
      formatted: formatted,
      lat: lat,
      lng: lng,
      address: (json['address'] as Map<String, dynamic>?) ?? const {},
    );
  }

  PlaceDetails _parseAddressBlock({
    required String formatted,
    required double lat,
    required double lng,
    required Map<String, dynamic> address,
  }) {
    String? get(List<String> keys) {
      for (final k in keys) {
        final v = address[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    final countryCode = (address['country_code'] as String?)?.toUpperCase();

    return PlaceDetails(
      formattedAddress: formatted,
      latitude: lat,
      longitude: lng,
      neighborhood: get(const ['neighbourhood', 'residential']),
      suburb: get(const ['suburb', 'city_district']),
      city: get(const ['city', 'town', 'village', 'municipality']),
      state: get(const ['state', 'region']),
      country: (countryCode != null && countryCode.isNotEmpty)
          ? countryCode
          : null,
      postalCode: get(const ['postcode']),
    );
  }

  PlaceDetails _coordOnly(double lat, double lng) => PlaceDetails(
    formattedAddress: '$lat, $lng',
    latitude: lat,
    longitude: lng,
  );
}

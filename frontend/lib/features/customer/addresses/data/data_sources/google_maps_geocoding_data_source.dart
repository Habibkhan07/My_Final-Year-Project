import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/place_search_entity.dart';
import '../models/place_details.dart';
import 'geocoding_data_source.dart';

/// Google Maps Platform adapter. Production geocoder.
///
/// Requires a `GOOGLE_MAPS_API_KEY` dart-define. The factory in
/// `presentation/providers/dependency_injection.dart` only constructs this
/// adapter when the key is present — see [NominatimGeocodingDataSource] for
/// the dev fallback.
class GoogleMapsGeocodingDataSource implements GeocodingDataSource {
  final http.Client _client;
  final String _apiKey;

  GoogleMapsGeocodingDataSource(this._client, this._apiKey)
    : assert(
        _apiKey.length > 0,
        'GoogleMapsGeocodingDataSource requires a non-empty API key',
      );

  @override
  Future<List<PlaceSearchEntity>> searchPlaces(
    String query,
    String sessionToken,
  ) async {
    if (query.isEmpty) return const [];

    final url =
        Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
          'input': query,
          'key': _apiKey,
          'sessiontoken': sessionToken,
          'components': 'country:pk',
        });
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw const FormatException(
        'Failed to communicate with Google Places API',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS') return const [];
    if (status != 'OK')
      throw _googleErr(status, json['error_message'] as String?);

    final preds = (json['predictions'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    return preds.map((p) {
      final struct =
          (p['structured_formatting'] as Map<String, dynamic>?) ?? const {};
      return PlaceSearchEntity(
        placeId: p['place_id'] as String,
        description: p['description'] as String,
        mainText: struct['main_text'] as String? ?? p['description'] as String,
        secondaryText: struct['secondary_text'] as String? ?? '',
      );
    }).toList();
  }

  @override
  Future<PlaceDetails> getPlaceDetails(
    String placeId,
    String sessionToken,
  ) async {
    // `address_components` is critical — that's where the structured fields
    // live. The previous data source asked only for `geometry,formatted_address`
    // and threw away the locality data Google was already returning.
    final url =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'key': _apiKey,
          'sessiontoken': sessionToken,
          'fields': 'geometry,formatted_address,address_components',
        });
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      throw const FormatException(
        'Failed to communicate with Google Places API',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status != 'OK')
      throw _googleErr(status, json['error_message'] as String?);

    final result = json['result'] as Map<String, dynamic>;
    return _parseDetails(result);
  }

  @override
  Future<PlaceDetails> reverseGeocode(double lat, double lng) async {
    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': _apiKey,
    });
    final response = await _client.get(url);
    if (response.statusCode != 200) {
      // Contract: never block the UI. Caller falls back to "$lat, $lng".
      return _coordOnly(lat, lng);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String? ?? 'UNKNOWN';
    if (status == 'ZERO_RESULTS') return _coordOnly(lat, lng);
    if (status != 'OK') return _coordOnly(lat, lng);

    final results = (json['results'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    if (results.isEmpty) return _coordOnly(lat, lng);
    return _parseDetails(results.first, fallbackLat: lat, fallbackLng: lng);
  }

  PlaceDetails _parseDetails(
    Map<String, dynamic> result, {
    double? fallbackLat,
    double? fallbackLng,
  }) {
    final geometry = result['geometry'] as Map<String, dynamic>?;
    final loc = geometry?['location'] as Map<String, dynamic>?;
    final lat = (loc?['lat'] as num?)?.toDouble() ?? fallbackLat ?? 0.0;
    final lng = (loc?['lng'] as num?)?.toDouble() ?? fallbackLng ?? 0.0;

    final formatted = result['formatted_address'] as String? ?? '$lat, $lng';
    final components = (result['address_components'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    String? pick(List<String> wanted) {
      for (final c in components) {
        final types = (c['types'] as List? ?? const []).cast<String>();
        for (final t in wanted) {
          if (types.contains(t)) return c['long_name'] as String?;
        }
      }
      return null;
    }

    String? pickShort(List<String> wanted) {
      for (final c in components) {
        final types = (c['types'] as List? ?? const []).cast<String>();
        for (final t in wanted) {
          if (types.contains(t)) return c['short_name'] as String?;
        }
      }
      return null;
    }

    // Pakistan-relevant Google address_components type mapping.
    return PlaceDetails(
      formattedAddress: formatted,
      latitude: lat,
      longitude: lng,
      neighborhood: pick(const ['neighborhood']),
      suburb: pick(const ['sublocality_level_1', 'sublocality']),
      city: pick(const ['locality', 'postal_town']),
      state: pick(const ['administrative_area_level_1']),
      country: pickShort(const ['country'])?.toUpperCase(),
      postalCode: pick(const ['postal_code']),
    );
  }

  PlaceDetails _coordOnly(double lat, double lng) => PlaceDetails(
    formattedAddress: '$lat, $lng',
    latitude: lat,
    longitude: lng,
  );

  Exception _googleErr(String status, String? msg) =>
      FormatException('Google API Error: $status - ${msg ?? 'Unknown error'}');
}

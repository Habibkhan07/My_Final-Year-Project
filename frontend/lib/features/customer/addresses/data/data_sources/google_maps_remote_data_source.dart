import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles geocoding and place search operations via Google Maps Platform.
class GoogleMapsRemoteDataSource {
  final http.Client _client;
  
  // Use flutter's --dart-define=GOOGLE_MAPS_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  GoogleMapsRemoteDataSource(this._client) {
    if (_apiKey.isEmpty) {
      // Fallback to OSM Nominatim if no API key is provided
      print('WARNING: GOOGLE_MAPS_API_KEY is not set. Falling back to free OpenStreetMap Nominatim API.');
    }
  }

  /// Searches for places using Google Places Autocomplete API.
  Future<List<Map<String, dynamic>>> searchPlaces(String query, String sessionToken) async {
    if (query.isEmpty) return [];

    if (_apiKey.isEmpty) {
      // Fallback to Nominatim (OpenStreetMap)
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=pk');
      final response = await _client.get(url, headers: {'User-Agent': 'FYP_HomeServices_App/1.0'});
      
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((place) => {
          'place_id': place['place_id'].toString(), // Use OSM place_id
          'description': place['display_name'],
        }).toList();
      }
      return [];
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'components': 'country:pk', // Restrict to Pakistan as per project context
    });

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK' || json['status'] == 'ZERO_RESULTS') {
        return List<Map<String, dynamic>>.from(json['predictions'] ?? []);
      }
      throw _handleGoogleError(json['status'], json['error_message']);
    }
    throw const FormatException('Failed to communicate with Google Places API');
  }

  /// Retrieves detailed information (Lat/Lng, formatted address) for a specific place.
  Future<Map<String, dynamic>> getPlaceDetails(String placeId, String sessionToken) async {
    if (_apiKey.isEmpty) {
      // Fallback to Nominatim place details
      final url = Uri.parse('https://nominatim.openstreetmap.org/details?place_id=$placeId&format=json');
      final response = await _client.get(url, headers: {'User-Agent': 'FYP_HomeServices_App/1.0'});
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final geometry = json['geometry'];
        if (geometry != null && geometry['type'] == 'Point') {
           final coordinates = geometry['coordinates'];
           return {
             'formatted_address': json['localname'] ?? 'Unknown Address',
             'geometry': {
               'location': {
                 'lat': coordinates[1],
                 'lng': coordinates[0],
               }
             }
           };
        }
      }
      throw const FormatException('Failed to get details from Nominatim');
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'key': _apiKey,
      'sessiontoken': sessionToken,
      'fields': 'geometry,formatted_address',
    });

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        return json['result'] as Map<String, dynamic>;
      }
      throw _handleGoogleError(json['status'], json['error_message']);
    }
    throw const FormatException('Failed to communicate with Google Places API');
  }

  /// Reverse-geocodes coordinates into a formatted address.
  Future<String> reverseGeocode(double lat, double lng) async {
    if (_apiKey.isEmpty) {
      // Fallback to Nominatim Reverse Geocoding
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final response = await _client.get(url, headers: {'User-Agent': 'FYP_HomeServices_App/1.0'});
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['display_name'] ?? '$lat, $lng';
      }
      return '$lat, $lng';
    }

    final url = Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
      'latlng': '$lat,$lng',
      'key': _apiKey,
    });

    final response = await _client.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        final results = json['results'] as List;
        if (results.isNotEmpty) {
          return results.first['formatted_address'] as String;
        }
      }
      // If no results, just fall through and throw
      if (json['status'] != 'ZERO_RESULTS') {
        throw _handleGoogleError(json['status'], json['error_message']);
      }
    }
    throw const FormatException('Failed to reverse geocode coordinates');
  }

  Exception _handleGoogleError(String status, String? errorMessage) {
    // We throw a generic format exception which the Repository will catch
    // and map to a Domain AddressFailure.
    return FormatException('Google API Error: $status - ${errorMessage ?? 'Unknown error'}');
  }
}

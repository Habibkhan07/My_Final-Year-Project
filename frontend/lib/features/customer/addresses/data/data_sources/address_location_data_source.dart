import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/place_details.dart';

class AddressLocationDataSource {
  /// Resolves the device's current GPS position and reverse-geocodes it via
  /// the platform's native geocoder (Apple/Android), which works offline using
  /// platform-cached map data. The repository layers an HTTP geocoder on top
  /// to enrich the structured fields when network is available.
  ///
  /// Throws [LocationServiceDisabledException] when GPS is off.
  /// Throws [PermissionDeniedException] when the user has denied location access.
  Future<PlaceDetails> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const PermissionDeniedException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
          'Location permission permanently denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return _placemarkDetails(position.latitude, position.longitude);
  }

  Future<PlaceDetails> reverseGeocode(double lat, double lng) =>
      _placemarkDetails(lat, lng);

  Future<PlaceDetails> _placemarkDetails(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return _coordOnly(lat, lng);
      final p = placemarks.first;

      final formatted = [
        if (p.street != null && p.street!.isNotEmpty) p.street,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea,
      ].join(', ');

      return PlaceDetails(
        formattedAddress: formatted.isEmpty ? '$lat, $lng' : formatted,
        latitude: lat,
        longitude: lng,
        suburb: _emptyToNull(p.subLocality),
        city: _emptyToNull(p.locality),
        state: _emptyToNull(p.administrativeArea),
        country: _emptyToNull(p.isoCountryCode)?.toUpperCase(),
        postalCode: _emptyToNull(p.postalCode),
      );
    } catch (_) {
      // Native geocoder unavailable — return coord-only so the UI still works.
      return _coordOnly(lat, lng);
    }
  }

  PlaceDetails _coordOnly(double lat, double lng) => PlaceDetails(
        formattedAddress: '$lat, $lng',
        latitude: lat,
        longitude: lng,
      );

  String? _emptyToNull(String? s) =>
      (s == null || s.isEmpty) ? null : s;
}

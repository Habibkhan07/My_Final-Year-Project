import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AddressLocationDataSource {
  /// Resolves the device's current GPS position and reverse-geocodes it.
  ///
  /// Throws [LocationServiceDisabledException] when GPS is off.
  /// Throws [PermissionDeniedException] when the user has denied location access.
  Future<({double latitude, double longitude, String streetAddress})>
      getCurrentLocation() async {
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

    final streetAddress =
        await _reverseGeocode(position.latitude, position.longitude);

    return (
      latitude: position.latitude,
      longitude: position.longitude,
      streetAddress: streetAddress,
    );
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return '$lat, $lng';
      final p = placemarks.first;
      return [
        if (p.street != null && p.street!.isNotEmpty) p.street,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality,
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
          p.administrativeArea,
      ].join(', ');
    } catch (_) {
      // If reverse geocoding fails, fall back to raw coordinates — address is
      // still usable for the booking flow.
      return '$lat, $lng';
    }
  }
}

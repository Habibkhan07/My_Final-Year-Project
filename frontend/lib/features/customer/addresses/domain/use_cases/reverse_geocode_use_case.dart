import '../repositories/i_address_repository.dart';

/// Converts arbitrary coordinates to a human-readable street address string.
///
/// Used by the map picker after every completed pan gesture.
/// Never throws — the repository guarantees a fallback `"lat, lng"` string.
class ReverseGeocodeUseCase {
  final IAddressRepository repository;
  const ReverseGeocodeUseCase(this.repository);

  Future<String> call(double lat, double lng) =>
      repository.reverseGeocode(lat, lng);
}

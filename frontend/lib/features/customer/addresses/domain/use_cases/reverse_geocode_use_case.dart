import '../../data/models/place_details.dart';
import '../repositories/i_address_repository.dart';

/// Reverse-geocodes arbitrary coordinates to a [PlaceDetails].
///
/// Used by the map picker after every completed pan gesture. Never throws —
/// the repository guarantees a fallback `"lat, lng"` PlaceDetails on failure.
class ReverseGeocodeUseCase {
  final IAddressRepository repository;
  const ReverseGeocodeUseCase(this.repository);

  Future<PlaceDetails> call(double lat, double lng) =>
      repository.reverseGeocode(lat, lng);
}

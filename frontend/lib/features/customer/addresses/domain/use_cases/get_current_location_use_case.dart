import '../../data/models/place_details.dart';
import '../repositories/i_address_repository.dart';

/// Resolves the device's current GPS position and reverse-geocodes it.
///
/// Returns a [PlaceDetails] so the save-address form can pre-fill lat/lng,
/// the formatted street address, AND the structured locality fields in a
/// single call.
/// Throws [AddressLocationPermissionDenied] or [AddressLocationServiceDisabled].
class GetCurrentLocationUseCase {
  final IAddressRepository repository;
  const GetCurrentLocationUseCase(this.repository);

  Future<PlaceDetails> call() => repository.getCurrentLocation();
}

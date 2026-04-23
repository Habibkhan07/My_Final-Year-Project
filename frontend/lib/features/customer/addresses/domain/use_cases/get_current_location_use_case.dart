import '../repositories/i_address_repository.dart';

/// Resolves the device's current GPS position and reverse-geocodes it to a
/// human-readable street address.
///
/// Returns a named record so the save-address form can pre-fill all three
/// fields (lat, lng, streetAddress) in a single call.
/// Throws [AddressLocationPermissionDenied] or [AddressLocationServiceDisabled].
class GetCurrentLocationUseCase {
  final IAddressRepository repository;
  const GetCurrentLocationUseCase(this.repository);

  Future<({double latitude, double longitude, String streetAddress})> call() =>
      repository.getCurrentLocation();
}

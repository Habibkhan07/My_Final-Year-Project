import '../repositories/i_address_repository.dart';

class GetPlaceDetailsUseCase {
  final IAddressRepository repository;

  GetPlaceDetailsUseCase(this.repository);

  Future<({double latitude, double longitude, String streetAddress})> call(
      String placeId, String sessionToken) {
    return repository.getPlaceDetails(placeId, sessionToken);
  }
}

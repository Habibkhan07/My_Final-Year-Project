import '../../data/models/place_details.dart';
import '../repositories/i_address_repository.dart';

class GetPlaceDetailsUseCase {
  final IAddressRepository repository;

  GetPlaceDetailsUseCase(this.repository);

  Future<PlaceDetails> call(String placeId, String sessionToken) {
    return repository.getPlaceDetails(placeId, sessionToken);
  }
}

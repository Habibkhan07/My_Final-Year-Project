import '../entities/place_search_entity.dart';
import '../repositories/i_address_repository.dart';

class SearchPlacesUseCase {
  final IAddressRepository repository;

  SearchPlacesUseCase(this.repository);

  Future<List<PlaceSearchEntity>> call(String query, String sessionToken) {
    return repository.searchPlaces(query, sessionToken);
  }
}

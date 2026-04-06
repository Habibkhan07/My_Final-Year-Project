import '../repositories/search_repository.dart';

class GetRecentSearchesUseCase {
  final SearchRepository repository;
  GetRecentSearchesUseCase(this.repository);

  Future<List<String>> execute() {
    return repository.getRecentSearches();
  }
}

import '../repositories/search_repository.dart';

class ClearRecentSearchesUseCase {
  final SearchRepository repository;
  ClearRecentSearchesUseCase(this.repository);

  Future<void> execute() {
    return repository.clearRecentSearches();
  }
}

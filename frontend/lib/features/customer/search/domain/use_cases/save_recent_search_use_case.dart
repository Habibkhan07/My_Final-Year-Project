import '../repositories/search_repository.dart';

class SaveRecentSearchUseCase {
  final SearchRepository repository;
  SaveRecentSearchUseCase(this.repository);

  Future<void> execute(String query) {
    return repository.saveRecentSearch(query);
  }
}

import '../entities/search_result_entity.dart';
import '../repositories/search_repository.dart';

class GetSearchSuggestionsUseCase {
  final SearchRepository repository;
  GetSearchSuggestionsUseCase(this.repository);

  Future<List<SearchResultEntity>> execute(String query) {
    return repository.getSuggestions(query);
  }
}

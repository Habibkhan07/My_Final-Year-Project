import '../entities/search_result_entity.dart';

abstract class SearchRepository {
  /// Fetches live suggestions from the remote catalog.
  /// Throws [SearchFailure].
  Future<List<SearchResultEntity>> getSuggestions(String query);

  /// Retrieves the list of recent search queries from local storage.
  Future<List<String>> getRecentSearches();

  /// Persists a new search query to the local history.
  Future<void> saveRecentSearch(String query);

  /// Clears the entire search history.
  Future<void> clearRecentSearches();
}

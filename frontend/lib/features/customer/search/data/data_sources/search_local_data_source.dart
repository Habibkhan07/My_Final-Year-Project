import 'package:shared_preferences/shared_preferences.dart';

class SearchLocalDataSource {
  final SharedPreferences _prefs;
  static const String _recentSearchesKey = 'recent_searches_history';
  static const int _maxHistory = 10;

  SearchLocalDataSource(this._prefs);

  Future<List<String>> getRecentSearches() async {
    return _prefs.getStringList(_recentSearchesKey) ?? [];
  }

  Future<void> saveRecentSearch(String query) async {
    final history = await getRecentSearches();

    // Remove if already exists (to move to top)
    history.removeWhere((item) => item.toLowerCase() == query.toLowerCase());

    // Add to top
    history.insert(0, query);

    // Cap history
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }

    await _prefs.setStringList(_recentSearchesKey, history);
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(_recentSearchesKey);
  }
}

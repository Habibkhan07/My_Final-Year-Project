import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_feed_model.dart';

class HomeLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const String cachedHomeFeedKey = 'CACHED_HOME_FEED';

  HomeLocalDataSource(this.sharedPreferences);

  Future<void> cacheHomeFeed(HomeFeedModel model) async {
    final jsonString = jsonEncode(model.toJson());
    await sharedPreferences.setString(cachedHomeFeedKey, jsonString);
  }

  Future<HomeFeedModel?> getCachedHomeFeed() async {
    final jsonString = sharedPreferences.getString(cachedHomeFeedKey);
    if (jsonString != null) {
      try {
        final jsonMap = jsonDecode(jsonString);
        return HomeFeedModel.fromJson(jsonMap);
      } catch (_) {
        // If parsing fails, return null
        return null;
      }
    }
    return null;
  }
}

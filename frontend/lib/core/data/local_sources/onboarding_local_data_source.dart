import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/technician/onboarding/data/models/service_model.dart';

class OnboardingLocalDataSource {
  final SharedPreferences _sharedPreferences;
  static const String _onboardingCompleteKey = 'is_onboarding_complete';
  static const String _metadataCacheKey = 'onboarding_metadata_cache';

  OnboardingLocalDataSource(this._sharedPreferences);

  Future<void> saveOnboardingComplete(bool isComplete) async {
    await _sharedPreferences.setBool(_onboardingCompleteKey, isComplete);
  }

  bool isOnboardingComplete() {
    return _sharedPreferences.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> saveOnboardingMetadata(List<ServiceModel> services) async {
    final jsonString = jsonEncode(services.map((s) => s.toJson()).toList());
    await _sharedPreferences.setString(_metadataCacheKey, jsonString);
  }

  Future<List<ServiceModel>?> getOnboardingMetadata() async {
    final jsonString = _sharedPreferences.getString(_metadataCacheKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => ServiceModel.fromJson(json)).toList();
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

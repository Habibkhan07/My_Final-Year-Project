import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/domain/entities/user_entity.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user_profile';

  AuthLocalDataSource(this._secureStorage, this._prefs);

  // --- Tier 1: Secure Storage (Tokens) ---
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // --- Tier 2: App Cache (User Profile) ---
  Future<void> saveUser(UserEntity user) async {
    final jsonString = jsonEncode(user.toJson());
    await _prefs.setString(_userKey, jsonString);
  }

  Future<UserEntity?> getUser() async {
    final jsonString = _prefs.getString(_userKey);
    if (jsonString != null) {
      try {
        return UserEntity.fromJson(jsonDecode(jsonString));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // --- Utility ---
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _tokenKey);
    await _prefs.remove(_userKey);
  }
}

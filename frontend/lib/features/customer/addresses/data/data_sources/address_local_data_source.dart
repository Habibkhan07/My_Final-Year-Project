import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address_model.dart';

class AddressLocalDataSource {
  final SharedPreferences prefs;

  static const String _key = 'cached_addresses';

  const AddressLocalDataSource(this.prefs);

  Future<void> cacheAddresses(List<CustomerAddressModel> addresses) async {
    final jsonString = jsonEncode(addresses.map((a) => a.toJson()).toList());
    await prefs.setString(_key, jsonString);
  }

  /// Returns null when the cache is empty or corrupted.
  List<CustomerAddressModel>? getCachedAddresses() {
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return null;
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((e) => CustomerAddressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  /// Clears the cached addresses. Called from `teardownOnLogout` so the
  /// next user signing in on the same device cannot read the previous
  /// user's saved addresses via the offline-fallback path.
  Future<void> clear() async {
    await prefs.remove(_key);
  }
}

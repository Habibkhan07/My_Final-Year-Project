import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/customer_profile_model.dart';

/// Tier 2 cache for the customer's own profile.
///
/// Per CLAUDE.md offline-first rule, every read on the repository
/// caches into this layer immediately on success. `SocketException`
/// on a subsequent read falls back to this cache; a miss propagates
/// as `ProfileNetworkFailure`.
///
/// Stored under a single key — there is only ever one logged-in user's
/// profile at a time, and `clearAll()` runs on logout via the auth
/// repository's local data source. We do NOT key by user id here; the
/// auth local cache is the source of truth for "who is logged in".
class ProfileLocalDataSource {
  static const String _key = 'cached_profile_me';
  final SharedPreferences _prefs;

  ProfileLocalDataSource(this._prefs);

  Future<void> cacheProfile(CustomerProfileModel model) async {
    await _prefs.setString(_key, jsonEncode(model.toJson()));
  }

  /// Returns `null` on cache-miss OR on corrupted JSON. Never throws —
  /// a corrupted cache must not break the offline path, just degrade
  /// it to a `ProfileNetworkFailure` upstream.
  CustomerProfileModel? getCachedProfile() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return CustomerProfileModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async => _prefs.remove(_key);
}

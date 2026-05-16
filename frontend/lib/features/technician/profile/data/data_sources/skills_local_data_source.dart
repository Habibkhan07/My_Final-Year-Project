import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/technician_skill_model.dart';

/// Tier 2 cache for the technician's skill list.
///
/// Per CLAUDE.md offline-first rule, every successful `listMySkills`
/// caches into this layer. A subsequent `SocketException` falls back
/// to the cache; a miss propagates as `SkillsNetworkFailure`.
/// Mutations (`add` / `remove`) are NOT cached optimistically; on
/// success they invalidate the cache so the next read re-fetches.
///
/// Single key, no user-id partitioning — the auth local cache owns
/// "who is logged in", and `clearAll()` runs on logout via the auth
/// repository, which clears every other feature's cache too.
class SkillsLocalDataSource {
  static const String _key = 'cached_tech_skills';
  final SharedPreferences _prefs;

  SkillsLocalDataSource(this._prefs);

  Future<void> cacheSkills(List<TechnicianSkillModel> models) async {
    final encoded = jsonEncode(models.map((m) => m.toJson()).toList());
    await _prefs.setString(_key, encoded);
  }

  /// Returns `null` on cache-miss or corrupted JSON. Never throws.
  List<TechnicianSkillModel>? getCachedSkills() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(TechnicianSkillModel.fromJson)
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async => _prefs.remove(_key);
}

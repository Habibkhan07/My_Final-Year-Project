// SharedPreferences-backed cache for the FIRST page of each segment.
//
// Same contract as the customer-side `CustomerBookingsLocalDataSource`:
//
//   * Caches only the first page (cursor=null). Pagination cache adds
//     complexity for marginal value — the cache exists to rescue the
//     offline open-tab UX, not to enable offline pagination.
//
//   * Separate keys per segment so Upcoming and Past don't overwrite
//     each other.
//
//   * Cached value is the raw JSON envelope + a `cached_at` ISO
//     timestamp. The repository unwraps both when serving a fallback so
//     the page entity carries `isStaleCache=true` + `cachedAt`.
//
//   * Cache key carries a `_v1` suffix. Bumping the version on a wire-
//     shape change is the migration story — old keys go unread, next
//     network success rewrites under the new key.
//
// SharedPreferences (not sqflite) for the same reason as the customer
// side: ≤50 items per page, no query patterns, single envelope read.
import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/scheduled_job_segment.dart';
import '../models/scheduled_jobs_list_response_model.dart';

abstract class IScheduledJobsLocalDataSource {
  /// Persist the first-page response for [segment]. Caller is the
  /// repository's network-success path. Subsequent pages are NOT cached.
  Future<void> cacheFirstPage(
    ScheduledJobSegment segment,
    ScheduledJobsListResponseModel response,
  );

  /// Returns the cached first-page envelope + the timestamp it was
  /// stored at, or null when nothing is cached for [segment]. Returns
  /// null on any decode error (logged).
  Future<CachedScheduledJobsPage?> getCachedFirstPage(
    ScheduledJobSegment segment,
  );

  /// Drop every cached segment. Used on logout / account switch /
  /// future cache-version bumps.
  Future<void> clear();
}

/// Result of [IScheduledJobsLocalDataSource.getCachedFirstPage].
class CachedScheduledJobsPage {
  final ScheduledJobsListResponseModel response;
  final DateTime cachedAt;

  const CachedScheduledJobsPage({
    required this.response,
    required this.cachedAt,
  });
}

class ScheduledJobsLocalDataSource implements IScheduledJobsLocalDataSource {
  final SharedPreferences _prefs;

  static const _logName = 'features.technician.schedule.local_data_source';

  /// Bump on wire-shape change. Old keys go unread.
  static const _versionSuffix = '_v1';
  static const _baseKey = 'CACHED_SCHEDULED_JOBS';

  static List<ScheduledJobSegment> get _allSegments =>
      ScheduledJobSegment.values;

  ScheduledJobsLocalDataSource(this._prefs);

  String _keyFor(ScheduledJobSegment segment) =>
      '${_baseKey}_${segment.wireValue}$_versionSuffix';

  @override
  Future<void> cacheFirstPage(
    ScheduledJobSegment segment,
    ScheduledJobsListResponseModel response,
  ) async {
    final envelope = <String, dynamic>{
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'response': response.toJson(),
    };
    await _prefs.setString(_keyFor(segment), jsonEncode(envelope));
  }

  @override
  Future<CachedScheduledJobsPage?> getCachedFirstPage(
    ScheduledJobSegment segment,
  ) async {
    final raw = _prefs.getString(_keyFor(segment));
    if (raw == null) return null;
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAtStr = outer['cached_at'] as String?;
      final responseJson = outer['response'] as Map<String, dynamic>?;
      if (cachedAtStr == null || responseJson == null) {
        log(
          'Cache envelope for segment=${segment.wireValue} is missing '
          'expected fields; treating as miss.',
          name: _logName,
        );
        return null;
      }
      final cachedAt = DateTime.tryParse(cachedAtStr);
      if (cachedAt == null) {
        log(
          'Cache envelope for segment=${segment.wireValue} has '
          'unparseable cached_at "$cachedAtStr"; treating as miss.',
          name: _logName,
        );
        return null;
      }
      return CachedScheduledJobsPage(
        response: ScheduledJobsListResponseModel.fromJson(responseJson),
        cachedAt: cachedAt,
      );
    } catch (e, stack) {
      log(
        'Cache decode failed for segment=${segment.wireValue}: $e',
        name: _logName,
        stackTrace: stack,
      );
      return null;
    }
  }

  @override
  Future<void> clear() async {
    for (final segment in _allSegments) {
      await _prefs.remove(_keyFor(segment));
    }
  }
}

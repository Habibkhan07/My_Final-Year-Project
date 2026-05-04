// SharedPreferences-backed cache for the FIRST page of each segment.
//
// **Cache contract.**
//
//   * Caches only the first page (cursor=null). Pagination cache adds
//     complexity for marginal value — the cache exists to rescue the
//     offline open-tab UX, not to enable offline pagination through
//     pages 2+.
//
//   * Separate keys per segment so Upcoming and Past don't overwrite
//     each other (the user toggling segments while offline should still
//     see what they had).
//
//   * Cached value is the raw JSON envelope as it came off the wire,
//     plus a `cached_at` ISO timestamp. The repository unwraps both
//     when serving a cache fallback so the page entity carries the
//     `isStaleCache=true` + `cachedAt` flags the screen needs for the
//     "Last updated 8 min ago" disclosure.
//
//   * Cache key carries a `_v1` suffix. Bumping the version on a wire-
//     shape change is the migration story — old keys go unread, the
//     next network success rewrites under the new key. Old entries
//     leak until the user fully resets storage; acceptable for a v1
//     cache of <50 items.
//
// **Why SharedPreferences and not sqflite.**
// The list is ≤50 items and is rendered as a single page envelope.
// Querying isn't required (the data source returns the whole envelope
// in one read). Adding sqflite would just be more dependencies for the
// same UX.
import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/booking_segment.dart';
import '../models/bookings_list_response_model.dart';

abstract class ICustomerBookingsLocalDataSource {
  /// Persist the first-page response for [segment]. Caller is the
  /// repository's network-success path. Subsequent pages are NOT
  /// cached (see class doc).
  Future<void> cacheFirstPage(
    BookingSegment segment,
    BookingsListResponseModel response,
  );

  /// Returns the cached first-page envelope + the timestamp it was
  /// stored at, or null when nothing is cached for [segment]. Returns
  /// null on any decode error (logged).
  Future<CachedBookingsPage?> getCachedFirstPage(BookingSegment segment);

  /// Drop every cached segment. Used on logout / account switch /
  /// future cache-version bumps.
  Future<void> clear();
}

/// Result of [ICustomerBookingsLocalDataSource.getCachedFirstPage].
class CachedBookingsPage {
  final BookingsListResponseModel response;
  final DateTime cachedAt;

  const CachedBookingsPage({
    required this.response,
    required this.cachedAt,
  });
}

class CustomerBookingsLocalDataSource
    implements ICustomerBookingsLocalDataSource {
  final SharedPreferences _prefs;

  static const _logName = 'features.customer.bookings.local_data_source';

  /// Bump on wire-shape change. Old keys go unread.
  static const _versionSuffix = '_v1';
  static const _baseKey = 'CACHED_CUSTOMER_BOOKINGS';

  /// Reading at boot to decide whether we have any cached segments at
  /// all is faster against an enumerable set of known keys than a
  /// `SharedPreferences.getKeys()` filter.
  static List<BookingSegment> get _allSegments => BookingSegment.values;

  CustomerBookingsLocalDataSource(this._prefs);

  String _keyFor(BookingSegment segment) =>
      '${_baseKey}_${segment.wireValue}$_versionSuffix';

  @override
  Future<void> cacheFirstPage(
    BookingSegment segment,
    BookingsListResponseModel response,
  ) async {
    final envelope = <String, dynamic>{
      'cached_at': DateTime.now().toUtc().toIso8601String(),
      'response': response.toJson(),
    };
    await _prefs.setString(_keyFor(segment), jsonEncode(envelope));
  }

  @override
  Future<CachedBookingsPage?> getCachedFirstPage(
    BookingSegment segment,
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
      return CachedBookingsPage(
        response: BookingsListResponseModel.fromJson(responseJson),
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

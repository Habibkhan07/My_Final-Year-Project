import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/system_event_model.dart';

/// SharedPreferences-backed cache for the event sync subsystem.
///
/// Four storage slots:
///   1. `cached_events`       — last-known-good list of [SystemEventModel],
///                              used as offline fallback by the repository.
///   2. `last_sync_timestamp` — ISO-8601 cursor for `/api/events/sync/`.
///   3. `pending_bg_events`   — FCM events received while the app was
///                              terminated and processed by a background
///                              isolate (see CRITICAL COUPLING below).
///   4. `pending_acks`        — event IDs whose ACK call failed and must
///                              be retried on the next sync cycle.
///
/// Every read method is defensive: on absent key or corrupt JSON it logs
/// and returns `null` / `[]` — never throws. Writing malformed data from
/// elsewhere cannot break the repository.
///
/// ─── CRITICAL COUPLING (session 3) ──────────────────────────────────────
/// The background FCM message handler runs in a **separate Dart isolate**
/// where Riverpod DI is not available. It writes directly to
/// [_keyPendingBackgroundEvents] via its own [SharedPreferences] instance.
/// The main-isolate side then drains the queue through
/// [consumePendingBackgroundEvents] on app resume.
///
/// Consequence: the literal string value of [_keyPendingBackgroundEvents]
/// is part of this class's public contract with the isolate handler.
/// Renaming it here without updating the session-3 handler will silently
/// lose events.
/// ────────────────────────────────────────────────────────────────────────
class EventLocalDataSource {
  final SharedPreferences _prefs;

  /// Prefix prevents collisions with keys owned by other features.
  static const _keyPrefix = 'event_sync_';
  static const _keyCachedEvents = '${_keyPrefix}cached_events';
  static const _keyLastSyncTimestamp = '${_keyPrefix}last_sync_timestamp';
  static const _keyPendingBackgroundEvents = '${_keyPrefix}pending_bg_events';
  static const _keyPendingAcks = '${_keyPrefix}pending_acks';

  /// FIFO cap on the pending-background-events queue. Without a cap, a
  /// wedged FCM init in the main isolate (failing every drain attempt) lets
  /// the BG handler keep appending forever, growing SharedPreferences
  /// unboundedly. 50 is generous: the WS reconnect's `/sync/?since=` call
  /// recovers anything older than that anyway, so dropping the oldest
  /// entries on cap is a backstop, not a data-loss event.
  ///
  /// **CRITICAL COUPLING.** This constant must match the one in
  /// `fcm_background_handler.dart` (currently 50). The BG isolate writes
  /// to the same SharedPreferences key and applies its own cap; if the two
  /// values diverge, one isolate would let the queue exceed what the other
  /// considers safe. See `_keyPendingBackgroundEvents`'s coupling note.
  static const _kMaxPendingBackgroundEvents = 50;

  static const _logName = 'core.data.event_local';

  const EventLocalDataSource(this._prefs);

  // ─── Event Cache ────────────────────────────────────────────────────────

  /// Overwrites the event cache with [events] (JSON-encoded as a list).
  /// On serialization failure: log and skip — the previous cache stays intact.
  Future<void> cacheEventList(List<SystemEventModel> events) async {
    try {
      final encoded = jsonEncode(events.map((e) => e.toJson()).toList());
      await _prefs.setString(_keyCachedEvents, encoded);
    } catch (e, stack) {
      log(
        'cacheEventList: failed to encode ${events.length} events: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Returns the cached event list, or `null` if absent / corrupt.
  List<SystemEventModel>? getCachedEventList() {
    final raw = _prefs.getString(_keyCachedEvents);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => SystemEventModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      log(
        'getCachedEventList: corrupt cache, returning null: $e',
        name: _logName,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Removes the offline-fallback event cache. Called by orchestrator
  /// teardown so user B never sees user A's cached events on cache-fallback.
  Future<void> clearCachedEvents() async {
    await _prefs.remove(_keyCachedEvents);
  }

  // ─── Sync Timestamp ─────────────────────────────────────────────────────

  Future<void> saveLastSyncTimestamp(String isoTimestamp) async {
    await _prefs.setString(_keyLastSyncTimestamp, isoTimestamp);
  }

  String? getLastSyncTimestamp() => _prefs.getString(_keyLastSyncTimestamp);

  /// Removes the persisted sync cursor. Called by orchestrator
  /// teardown to prevent cross-account event leakage on shared devices.
  Future<void> clearLastSyncTimestamp() async {
    await _prefs.remove(_keyLastSyncTimestamp);
  }

  // ─── Pending Background FCM Events ──────────────────────────────────────

  /// Appends [eventJson] to the pending-background-events queue, with FIFO
  /// eviction once the queue exceeds [_kMaxPendingBackgroundEvents].
  /// On corrupt existing data: start fresh — a corrupt queue should never
  /// block a new event from being queued.
  Future<void> savePendingBackgroundEvent(
    Map<String, dynamic> eventJson,
  ) async {
    final existing = _readPendingBackgroundList();
    existing.add(eventJson);
    // FIFO cap: drop the oldest entries so the queue never exceeds the
    // documented bound. Anything dropped is recoverable via the WS
    // reconnect's `/sync/?since=` catch-up, so we never escalate to the
    // user.
    if (existing.length > _kMaxPendingBackgroundEvents) {
      final overflow = existing.length - _kMaxPendingBackgroundEvents;
      existing.removeRange(0, overflow);
    }
    try {
      await _prefs.setString(_keyPendingBackgroundEvents, jsonEncode(existing));
    } catch (e, stack) {
      log(
        'savePendingBackgroundEvent: failed to write queue: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Returns and clears the pending-background-events queue.
  /// Returns `[]` if empty or corrupt.
  Future<List<Map<String, dynamic>>> consumePendingBackgroundEvents() async {
    final list = _readPendingBackgroundList();
    await _prefs.remove(_keyPendingBackgroundEvents);
    return list;
  }

  List<Map<String, dynamic>> _readPendingBackgroundList() {
    final raw = _prefs.getString(_keyPendingBackgroundEvents);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (e, stack) {
      log(
        '_readPendingBackgroundList: corrupt queue, discarding: $e',
        name: _logName,
        stackTrace: stack,
      );
      return <Map<String, dynamic>>[];
    }
  }

  // ─── Pending ACKs ───────────────────────────────────────────────────────

  /// Merges [ids] with any existing pending ACKs, dedupes, writes back.
  Future<void> savePendingAcks(List<String> ids) async {
    final merged = <String>{...getPendingAcks(), ...ids}.toList();
    try {
      await _prefs.setString(_keyPendingAcks, jsonEncode(merged));
    } catch (e, stack) {
      log(
        'savePendingAcks: failed to write: $e',
        name: _logName,
        stackTrace: stack,
      );
    }
  }

  /// Returns the pending ACK IDs, or `[]` if absent / corrupt.
  List<String> getPendingAcks() {
    final raw = _prefs.getString(_keyPendingAcks);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.whereType<String>().toList();
    } catch (e, stack) {
      log(
        'getPendingAcks: corrupt queue, returning empty: $e',
        name: _logName,
        stackTrace: stack,
      );
      return const <String>[];
    }
  }

  Future<void> clearPendingAcks() async {
    await _prefs.remove(_keyPendingAcks);
  }
}

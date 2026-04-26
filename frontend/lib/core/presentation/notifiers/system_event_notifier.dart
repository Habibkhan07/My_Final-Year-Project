import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/system_event_entity.dart';
import '../providers/dependency_injection.dart';
import '../state/system_event_state.dart';

part 'system_event_notifier.g.dart';

/// Single ingestion funnel for every real-time event, regardless of source
/// (WebSocket, FCM foreground, FCM background drain, REST sync, REST
/// unacknowledged-critical refresh).
///
/// Responsibilities — in this exact order:
///   1. Dedup by event id.
///   2. Ignore late-arriving events of the same type (an FCM copy of an
///      older transition arriving after a WS copy of a newer one).
///   3. Cap the dedup map at [_kMaxDedupEntries] with batch pruning.
///   4. Advance [SystemEventState.lastSyncTimestamp] whenever a newer event
///      lands — this is the cursor that the next REST sync uses.
///
/// keepAlive: the dedup map and last-sync cursor must survive across widget
/// rebuilds; otherwise a route change would wipe the dedup set and replay
/// every event once.
@Riverpod(keepAlive: true)
class SystemEventNotifier extends _$SystemEventNotifier {
  static const _kMaxDedupEntries = 100;
  static const _kPruneCount = 50;

  @override
  SystemEventState build() {
    // Cold-start cursor seeding. The previous session's
    // [EventRepository.syncMissedEvents] persisted the newest event's
    // timestamp via [EventLocalDataSource.saveLastSyncTimestamp]; reading
    // it back here means [EventSyncNotifier.syncMissedEvents] picks up
    // from where we left off instead of falling back to the 24-hour
    // window every cold start.
    //
    // The dedup map and `latestEvent` are intentionally NOT seeded — they
    // are session-scoped, and re-emitting an already-handled event would
    // make the router fire spuriously on launch.
    final persistedIso =
        ref.read(eventLocalDataSourceProvider).getLastSyncTimestamp();
    final seededCursor =
        persistedIso == null ? null : DateTime.tryParse(persistedIso);
    return SystemEventState(lastSyncTimestamp: seededCursor);
  }

  /// Attempts to accept [event] into the pipeline.
  ///
  /// Returns `true` if the event was accepted and observers should react
  /// (router, UI). Returns `false` for any reason the event was rejected
  /// (duplicate, out-of-order, same-type-but-older) — callers treat that as
  /// a silent no-op.
  bool processEvent(SystemEventEntity event) {
    // 1. Dedup — we've seen this id already.
    if (state.processedEventIds.containsKey(event.id)) {
      return false;
    }

    // 2. Order guard — an older same-type event arriving after a newer one
    //    would regress the UI (e.g. ACCEPTED landing after EN_ROUTE). Only
    //    compare same rawType; different types represent different things
    //    and are always allowed through.
    final latest = state.latestEvent;
    if (latest != null &&
        latest.rawType == event.rawType &&
        event.timestamp.isBefore(latest.timestamp)) {
      return false;
    }

    // 3. Prune — when the map is at cap, drop the oldest half in a single
    //    rebuild. Freezed state is immutable, so we always construct a new
    //    map; never mutate state.processedEventIds directly.
    var working = state.processedEventIds;
    if (working.length >= _kMaxDedupEntries) {
      final sorted = working.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final keepCount = _kMaxDedupEntries - _kPruneCount;
      final newest = sorted.sublist(sorted.length - keepCount);
      working = {for (final entry in newest) entry.key: entry.value};
    }

    // 4. Add the new id to the (possibly pruned) map.
    final newMap = {...working, event.id: event.timestamp};

    // 5. Advance the sync cursor if this event is newer than what we've seen.
    final previousCursor = state.lastSyncTimestamp;
    final newCursor =
        previousCursor == null || event.timestamp.isAfter(previousCursor)
            ? event.timestamp
            : previousCursor;

    // 6. Single atomic state emission — router listeners wake up here.
    state = state.copyWith(
      latestEvent: event,
      processedEventIds: newMap,
      lastSyncTimestamp: newCursor,
    );

    return true;
  }

  /// Cursor for the next `/api/events/sync/?since=...` call. Null when the
  /// notifier has never processed an event (fresh install / post-logout).
  DateTime? getLastSyncTimestamp() => state.lastSyncTimestamp;

  /// Clears all in-memory event state. Called on logout so a different user
  /// logging in on the same device can't see the previous session's events.
  void reset() {
    state = const SystemEventState();
  }
}

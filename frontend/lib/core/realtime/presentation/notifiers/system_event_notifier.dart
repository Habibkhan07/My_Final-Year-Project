import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/system_event_entity.dart';
import '../providers/dependency_injection.dart';
import '../state/system_event_state.dart';

part 'system_event_notifier.g.dart';

/// Where an event came from. Used by [SystemEventNotifier] to decide
/// whether to update the server-time anchor — only WS events are
/// near-live by definition, so only they should drive the anchor.
///
/// FCM tap-intent events can be hours stale (the technician left a
/// notification in the tray), and `/sync/?since=` replays can carry
/// equally stale timestamps. Anchoring on either would back-date the
/// pipeline's notion of "now" and mis-fire the expiry filter.
enum SystemEventSource {
  /// Frame from the live WebSocket connection. Updates the anchor.
  ws,

  /// FCM payload — foreground listener, background drain, or tap-intent.
  /// Does NOT update the anchor.
  fcm,

  /// REST `/api/realtime/events/sync/?since=` replay. Does NOT update
  /// the anchor.
  sync,

  /// Source not specified by the caller. Treated as non-anchoring;
  /// callers that genuinely originate from the WS path should pass
  /// [ws] explicitly.
  unknown,
}

/// Single ingestion funnel for every real-time event, regardless of source
/// (WebSocket, FCM foreground, FCM background drain, REST sync, REST
/// unacknowledged-critical refresh).
///
/// Responsibilities — in this exact order:
///   1. Dedup by event id.
///   2. Ignore late-arriving events of the same type (an FCM copy of an
///      older transition arriving after a WS copy of a newer one).
///   3. Window-prune the dedup map: drop entries whose timestamp is older
///      than [_kDedupWindow] relative to the incoming event. Plus a hard
///      cap at [_kMaxDedupEntries] as a safety net if the window-prune
///      somehow leaves too many entries (concentrated burst inside 24h).
///   4. Advance [SystemEventState.lastSyncTimestamp] whenever a newer event
///      lands — this is the cursor that the next REST sync uses.
///
/// **Why windowed-by-time, not LRU-by-count.** A heavy-day technician can
/// process 100+ events while still having older notifications sitting in
/// their tray. The previous count-based LRU would prune ids out of the
/// dedup set after 100 events; tapping a stale tray notification could
/// then re-summon a sheet for an offer that was already resolved hours
/// earlier (the dedup miss falls through to the queue notifier's
/// per-jobId guard, but only if the job is still in the queue — for an
/// already-resolved offer the queue is empty and the per-jobId guard
/// can't fire). The 24-hour window matches the backend's
/// `UNACKNOWLEDGED_WINDOW` constant: events older than that are no longer
/// replay candidates, so the dedup memory of them adds nothing.
///
/// **Why anchor on the event's timestamp, not DateTime.now().** Using
/// `DateTime.now()` would couple the prune cutoff to the device's
/// wall-clock, which can be wildly off (manual time setting, dead phone
/// just turned on after months, NTP-sync-failed rural device). Anchoring
/// on `event.timestamp` (server-stamped) means the cutoff is consistent
/// with the timestamps already stored in the map: both are server-side
/// times, so "older than 24h" is well-defined regardless of device clock.
///
/// keepAlive: the dedup map and last-sync cursor must survive across widget
/// rebuilds; otherwise a route change would wipe the dedup set and replay
/// every event once.
@Riverpod(keepAlive: true)
class SystemEventNotifier extends _$SystemEventNotifier {
  /// Entries older than this (relative to the latest accepted event's
  /// server timestamp) are dropped from the dedup map. Matches the
  /// backend's `UNACKNOWLEDGED_WINDOW` — an event older than this can no
  /// longer be re-broadcast or replayed via `/api/events/sync/?since=`,
  /// so dedup memory of it serves no purpose.
  static const _kDedupWindow = Duration(hours: 24);

  /// Hard cap defense-in-depth. The windowed prune is the primary
  /// mechanism; this only fires in pathological burst scenarios (many
  /// events concentrated within 24h). Set generously: a typical active
  /// technician sees < 50 events/day; 500 covers 10× that.
  static const _kMaxDedupEntries = 500;

  /// When the hard cap fires, prune to this many entries (keeping the
  /// newest). Half-the-cap is a balance between "rarely re-prune in a
  /// burst" and "don't keep so many that the next prune is heavy."
  static const _kHardCapKeep = 250;

  // ─── Server-time anchor (flag #19) ───────────────────────────────────────
  //
  // The expiry filter (P1) compares `event.expiresAt` against "what time
  // is it now on the server side." A naive `DateTime.now()` would couple
  // expiry decisions to the device's wall clock, which can be wildly off
  // (manual time setting, dead phone, NTP-failed rural device). To stay
  // robust, we anchor on the timestamp of the most recent WS-delivered
  // event (live by definition) and add the elapsed local time since that
  // anchor was observed. This gives a server-clock estimate that's
  // monotonically increasing and insensitive to device-clock skew up to
  // the WS reconnect cadence.
  //
  // Only WS events update the anchor — FCM tap-intent events can be hours
  // stale and would back-date the anchor; same for `/sync/?since=`
  // replays.
  DateTime? _serverAnchorTimestamp;
  DateTime? _serverAnchorObservedAt;

  /// Test-only seam to control the local-clock side of the server-time
  /// estimate. Production callers leave this null and the notifier uses
  /// `DateTime.now()`.
  @visibleForTesting
  DateTime Function()? debugLocalNow;

  /// Best estimate of the current server-side wall clock. Returns the
  /// server-anchored value if a WS event has ever been observed,
  /// otherwise falls back to local UTC. Always returns UTC.
  DateTime _serverNow() {
    final localNow = (debugLocalNow ?? () => DateTime.now()).call().toUtc();
    final anchorTs = _serverAnchorTimestamp;
    final anchorObserved = _serverAnchorObservedAt;
    if (anchorTs == null || anchorObserved == null) {
      return localNow;
    }
    final elapsed = localNow.difference(anchorObserved);
    return anchorTs.add(elapsed);
  }

  void _updateServerAnchor(DateTime serverTimestamp) {
    final localNow = (debugLocalNow ?? () => DateTime.now()).call().toUtc();
    // Take max(existing, incoming) so a delayed WS frame can't regress
    // the anchor — the anchor is "the latest server time we know about,"
    // never older.
    final current = _serverAnchorTimestamp;
    if (current == null || serverTimestamp.isAfter(current)) {
      _serverAnchorTimestamp = serverTimestamp;
      _serverAnchorObservedAt = localNow;
    }
  }

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
    final persistedIso = ref
        .read(eventLocalDataSourceProvider)
        .getLastSyncTimestamp();
    final seededCursor = persistedIso == null
        ? null
        : DateTime.tryParse(persistedIso);
    return SystemEventState(lastSyncTimestamp: seededCursor);
  }

  /// Attempts to accept [event] into the pipeline.
  ///
  /// Returns `true` if the event was accepted and observers should react
  /// (router, UI). Returns `false` for any reason the event was rejected
  /// (duplicate, out-of-order, same-type-but-older, expired, wrong
  /// recipient) — callers treat that as a silent no-op.
  ///
  /// [source] tells the notifier whether to anchor the server-time
  /// estimate on this event (only [SystemEventSource.ws] does). Defaults
  /// to [SystemEventSource.unknown]; the WS dispatcher passes
  /// [SystemEventSource.ws] explicitly.
  bool processEvent(
    SystemEventEntity event, {
    SystemEventSource source = SystemEventSource.unknown,
  }) {
    // 0. Server-time anchor — done before filtering so the anchor
    //    reflects "the latest server-stamped instant we've seen via the
    //    live socket," regardless of whether this particular event ends
    //    up being kept or dropped. Only WS events qualify; FCM and sync
    //    timestamps can be hours stale.
    if (source == SystemEventSource.ws) {
      _updateServerAnchor(event.timestamp);
    }

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

    // 2.5 Recipient filter (flag #19, resolved 2026-05-03). Drops events
    //    whose recipient does not match the currently-authenticated user.
    //    Defends against the multi-account-device race where a notification
    //    queued for user A arrives at user B's session after a logout/login.
    //
    //    Defensive: only fires when BOTH sides are non-null. Backend ships
    //    `recipient_user_id` on every envelope; `currentAuthUserIdProvider`
    //    is overridden in `main.dart` to read the live auth user id. Either
    //    side being null (legacy `EventLog` replay, or signed-out container)
    //    means the gate no-ops — the documented backwards-compat path.
    final eventRecipientId = event.recipientUserId;
    if (eventRecipientId != null) {
      final currentUserId = ref.read(currentAuthUserIdProvider);
      if (currentUserId != null && currentUserId != eventRecipientId) {
        log(
          'Dropping cross-user event: id=${event.id} '
          'recipient=$eventRecipientId currentUser=$currentUserId',
          name: 'core.presentation.system_event_notifier',
        );
        return false;
      }
    }

    // 2.6 Expiry filter (flag #19, resolved 2026-05-03). Drops events whose
    //    `expiresAt` is in the past relative to the server-time anchor.
    //    This is the pipeline-level home for the staleness check; every
    //    present and future typed event inherits it without per-feature
    //    work. `JobNewRequestMapper` retains its own freshness check as
    //    defence-in-depth (intentional — see the mapper's docstring).
    final eventExpiresAt = event.expiresAt;
    if (eventExpiresAt != null) {
      final now = _serverNow();
      if (!now.isBefore(eventExpiresAt)) {
        log(
          'Dropping expired event: id=${event.id} '
          'expiredAt=${eventExpiresAt.toIso8601String()} '
          'serverNow=${now.toIso8601String()}',
          name: 'core.presentation.system_event_notifier',
        );
        return false;
      }
    }

    // 3. Window-prune — drop ids whose timestamp is older than
    //    `_kDedupWindow` relative to the incoming event. Anchoring on the
    //    incoming event's server timestamp (rather than DateTime.now())
    //    keeps the prune cutoff insensitive to device-clock skew.
    //    Freezed state is immutable, so we always construct a new map;
    //    never mutate state.processedEventIds directly.
    final pruneCutoff = event.timestamp.subtract(_kDedupWindow);
    var working = <String, DateTime>{
      for (final entry in state.processedEventIds.entries)
        if (!entry.value.isBefore(pruneCutoff)) entry.key: entry.value,
    };

    // 4. Hard cap defense — if the windowed prune left more than
    //    `_kMaxDedupEntries` (a concentrated burst inside the 24h window),
    //    truncate to the `_kHardCapKeep` newest. This branch is expected
    //    to be cold in normal use; existing tests + production telemetry
    //    should never see it fire.
    if (working.length >= _kMaxDedupEntries) {
      final sorted = working.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      final newest = sorted.sublist(sorted.length - _kHardCapKeep);
      working = {for (final entry in newest) entry.key: entry.value};
    }

    // 5. Add the new id to the (possibly pruned) map.
    final newMap = {...working, event.id: event.timestamp};

    // 6. Advance the sync cursor if this event is newer than what we've seen.
    final previousCursor = state.lastSyncTimestamp;
    final newCursor =
        previousCursor == null || event.timestamp.isAfter(previousCursor)
        ? event.timestamp
        : previousCursor;

    // 7. Single atomic state emission — router listeners wake up here.
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
  /// Also resets the server-time anchor — otherwise the next user's first
  /// expiry filter call would compute "now" from the previous user's last
  /// WS event, slightly miscalibrating the freshness check until the new
  /// user's WS reconnects.
  void reset() {
    state = const SystemEventState();
    _serverAnchorTimestamp = null;
    _serverAnchorObservedAt = null;
  }
}

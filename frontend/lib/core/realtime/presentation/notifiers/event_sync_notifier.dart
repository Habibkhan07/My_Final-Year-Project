import 'dart:async';
import 'dart:developer';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/failures/event_failures.dart';
import '../providers/dependency_injection.dart';
import 'system_event_notifier.dart';

part 'event_sync_notifier.g.dart';

/// REST-side of the realtime pipeline:
///   - Recovery: fetch events missed while the WebSocket was down.
///   - Recovery: re-surface unacknowledged critical events on cold start.
///   - Outgoing: debounced ACK batching.
///
/// This notifier exposes no observable state — it is a pure orchestrator of
/// side effects. `build()` returns `null`; callers only use `.notifier`.
///
/// keepAlive: the pending-ACK list and debounce timer must persist across
/// widget rebuilds. Disposing would drop in-flight ACKs.
///
/// ─── Unauthorized-logout inversion (CLAUDE.md: no core→features imports) ──
/// On [EventSyncUnauthorized] this notifier invokes [onUnauthorized] if set.
/// The App Lifecycle Orchestrator (session 4) is responsible for wiring it:
///
///   ref.read(eventSyncProvider.notifier).onUnauthorized =
///       () => ref.read(authProvider.notifier).logout();
///
/// Core layer never imports authProvider.
/// ─────────────────────────────────────────────────────────────────────────
@Riverpod(keepAlive: true)
class EventSyncNotifier extends _$EventSyncNotifier {
  /// Batch any `acknowledge()` calls made within this window into a single
  /// HTTP request. Prevents 10 separate POSTs when 10 critical events arrive
  /// in quick succession after an offline period.
  static const _kAckDebounceDuration = Duration(seconds: 2);

  /// Cursor fallback on a fresh install / after logout, when the
  /// [SystemEventNotifier] has never seen an event.
  static const _kDefaultSyncWindow = Duration(hours: 24);

  static const _logName = 'core.presentation.event_sync';

  final List<String> _pendingAcks = [];
  Timer? _ackDebounceTimer;

  /// Invoked when a sync/ACK call returns 401. Wired by the App Lifecycle
  /// Orchestrator in session 4 to trigger a logout. Left null here so the
  /// core layer stays feature-agnostic.
  void Function()? onUnauthorized;

  @override
  Object? build() {
    ref.onDispose(() {
      _ackDebounceTimer?.cancel();
    });
    return null;
  }

  /// Pulls events the server has accumulated since our last-known cursor,
  /// feeds them through the dedup/order pipeline in chronological order,
  /// then re-surfaces any unacknowledged critical events and flushes any
  /// locally-queued pending ACKs.
  ///
  /// Called from [WsConnectionNotifier] right after the socket opens. Also
  /// safe to call manually (e.g. on pull-to-refresh of an events view).
  Future<void> syncMissedEvents() async {
    await _runGuarded(() async {
      final eventNotifier = ref.read(systemEventProvider.notifier);
      final cursor =
          eventNotifier.getLastSyncTimestamp() ??
          DateTime.now().subtract(_kDefaultSyncWindow);
      final isoTimestamp = cursor.toUtc().toIso8601String();

      final repo = ref.read(eventRepositoryProvider);
      final missed = await repo.syncMissedEvents(isoTimestamp);

      // Chronological order matters — the notifier's same-type order guard
      // would reject a newer event if we fed it before an older one.
      final sorted = [...missed]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final event in sorted) {
        // Tag as `sync` so the notifier does NOT update its server-time
        // anchor on these timestamps — `/sync/?since=` replays can carry
        // events that are hours stale (long offline window).
        eventNotifier.processEvent(event, source: SystemEventSource.sync);
      }

      await syncUnacknowledgedCritical();

      // Flush any ACKs that failed during a previous offline period.
      final pending = ref.read(eventLocalDataSourceProvider).getPendingAcks();
      if (pending.isNotEmpty) {
        _pendingAcks.addAll(pending);
        await _flushAcks();
      }
    });
  }

  /// Pulls critical events the backend has not yet seen an ACK for and
  /// re-displays them through the normal pipeline. The router will no-op
  /// on duplicates it has already shown.
  Future<void> syncUnacknowledgedCritical() async {
    await _runGuarded(() async {
      final repo = ref.read(eventRepositoryProvider);
      final unacked = await repo.fetchUnacknowledgedCritical();
      final eventNotifier = ref.read(systemEventProvider.notifier);
      for (final event in unacked) {
        // REST replay; like `/sync/?since=`, do not anchor the server-time
        // estimate on these timestamps.
        eventNotifier.processEvent(event, source: SystemEventSource.sync);
      }
    });
  }

  /// Enqueues [eventId] for the next ACK batch. Safe to call rapidly — all
  /// calls within [_kAckDebounceDuration] are coalesced into a single POST.
  void acknowledge(String eventId) {
    if (_pendingAcks.contains(eventId)) return;
    _pendingAcks.add(eventId);
    _ackDebounceTimer?.cancel();
    _ackDebounceTimer = Timer(_kAckDebounceDuration, _flushAcks);
  }

  Future<void> _flushAcks() async {
    if (_pendingAcks.isEmpty) return;
    final toSend = List<String>.from(_pendingAcks);
    _pendingAcks.clear();
    final repo = ref.read(eventRepositoryProvider);
    // Repository persists on failure to its own retry queue — never throws.
    await repo.acknowledgeEvents(toSend);
  }

  /// Wraps [action] so a sync error never crashes the caller. On 401 we
  /// invoke the orchestrator-owned [onUnauthorized] callback instead of
  /// importing auth from core.
  Future<void> _runGuarded(Future<void> Function() action) async {
    try {
      await action();
    } on EventSyncUnauthorized {
      log('sync unauthorized — invoking onUnauthorized hook', name: _logName);
      onUnauthorized?.call();
    } on EventSyncFailure catch (e, stack) {
      log('sync failure: $e', name: _logName, stackTrace: stack);
    } catch (e, stack) {
      log('unexpected sync error: $e', name: _logName, stackTrace: stack);
    }
  }
}

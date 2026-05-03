// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_event_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SystemEventNotifier)
final systemEventProvider = SystemEventNotifierProvider._();

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
final class SystemEventNotifierProvider
    extends $NotifierProvider<SystemEventNotifier, SystemEventState> {
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
  SystemEventNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemEventProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemEventNotifierHash();

  @$internal
  @override
  SystemEventNotifier create() => SystemEventNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemEventState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemEventState>(value),
    );
  }
}

String _$systemEventNotifierHash() =>
    r'46e8cebe834e10a0e64aedf62505c4db707b86c6';

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

abstract class _$SystemEventNotifier extends $Notifier<SystemEventState> {
  SystemEventState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SystemEventState, SystemEventState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SystemEventState, SystemEventState>,
              SystemEventState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

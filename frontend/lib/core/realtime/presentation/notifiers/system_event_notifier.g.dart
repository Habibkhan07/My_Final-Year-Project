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
///   3. Cap the dedup map at [_kMaxDedupEntries] with batch pruning.
///   4. Advance [SystemEventState.lastSyncTimestamp] whenever a newer event
///      lands — this is the cursor that the next REST sync uses.
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
///   3. Cap the dedup map at [_kMaxDedupEntries] with batch pruning.
///   4. Advance [SystemEventState.lastSyncTimestamp] whenever a newer event
///      lands — this is the cursor that the next REST sync uses.
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
  ///   3. Cap the dedup map at [_kMaxDedupEntries] with batch pruning.
  ///   4. Advance [SystemEventState.lastSyncTimestamp] whenever a newer event
  ///      lands — this is the cursor that the next REST sync uses.
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
    r'b0dbe7be40941fc4053b27a6bba025ca83cebedd';

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

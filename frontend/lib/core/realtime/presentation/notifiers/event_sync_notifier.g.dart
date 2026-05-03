// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_sync_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(EventSyncNotifier)
final eventSyncProvider = EventSyncNotifierProvider._();

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
final class EventSyncNotifierProvider
    extends $NotifierProvider<EventSyncNotifier, Object?> {
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
  EventSyncNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventSyncNotifierHash();

  @$internal
  @override
  EventSyncNotifier create() => EventSyncNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Object? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Object?>(value),
    );
  }
}

String _$eventSyncNotifierHash() => r'14b47a022622ff562dae9d32e34e0a09a0ae8e7d';

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

abstract class _$EventSyncNotifier extends $Notifier<Object?> {
  Object? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Object?, Object?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Object?, Object?>,
              Object?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

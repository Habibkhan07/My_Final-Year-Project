// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_orchestrator_events_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: false — this notifier is scoped to the orchestrator
/// screen lifetime. The screen `ref.read`s it in `initState` to wake
/// the listener; popping the screen unmounts the provider and stops
/// the refresh chain.
///
/// Rationale for *not* registering in `realtimeBootHooksProvider`:
/// the orchestrator screen is detail-route, not list-route. There's
/// no queue to fill at boot — the screen mounts on user nav and
/// hydrates on first read. Events arriving while the screen is closed
/// are persisted in `EventLog` and replayed on next mount via the
/// initial fetch (the response reflects the latest state).

@ProviderFor(BookingOrchestratorEventsNotifier)
final bookingOrchestratorEventsProvider =
    BookingOrchestratorEventsNotifierFamily._();

/// keepAlive: false — this notifier is scoped to the orchestrator
/// screen lifetime. The screen `ref.read`s it in `initState` to wake
/// the listener; popping the screen unmounts the provider and stops
/// the refresh chain.
///
/// Rationale for *not* registering in `realtimeBootHooksProvider`:
/// the orchestrator screen is detail-route, not list-route. There's
/// no queue to fill at boot — the screen mounts on user nav and
/// hydrates on first read. Events arriving while the screen is closed
/// are persisted in `EventLog` and replayed on next mount via the
/// initial fetch (the response reflects the latest state).
final class BookingOrchestratorEventsNotifierProvider
    extends $NotifierProvider<BookingOrchestratorEventsNotifier, void> {
  /// keepAlive: false — this notifier is scoped to the orchestrator
  /// screen lifetime. The screen `ref.read`s it in `initState` to wake
  /// the listener; popping the screen unmounts the provider and stops
  /// the refresh chain.
  ///
  /// Rationale for *not* registering in `realtimeBootHooksProvider`:
  /// the orchestrator screen is detail-route, not list-route. There's
  /// no queue to fill at boot — the screen mounts on user nav and
  /// hydrates on first read. Events arriving while the screen is closed
  /// are persisted in `EventLog` and replayed on next mount via the
  /// initial fetch (the response reflects the latest state).
  BookingOrchestratorEventsNotifierProvider._({
    required BookingOrchestratorEventsNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bookingOrchestratorEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$bookingOrchestratorEventsNotifierHash();

  @override
  String toString() {
    return r'bookingOrchestratorEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookingOrchestratorEventsNotifier create() =>
      BookingOrchestratorEventsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookingOrchestratorEventsNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingOrchestratorEventsNotifierHash() =>
    r'fd3ccaf9247d093c3e5ee9ceb8f22064f86493b7';

/// keepAlive: false — this notifier is scoped to the orchestrator
/// screen lifetime. The screen `ref.read`s it in `initState` to wake
/// the listener; popping the screen unmounts the provider and stops
/// the refresh chain.
///
/// Rationale for *not* registering in `realtimeBootHooksProvider`:
/// the orchestrator screen is detail-route, not list-route. There's
/// no queue to fill at boot — the screen mounts on user nav and
/// hydrates on first read. Events arriving while the screen is closed
/// are persisted in `EventLog` and replayed on next mount via the
/// initial fetch (the response reflects the latest state).

final class BookingOrchestratorEventsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BookingOrchestratorEventsNotifier,
          void,
          void,
          void,
          int
        > {
  BookingOrchestratorEventsNotifierFamily._()
    : super(
        retry: null,
        name: r'bookingOrchestratorEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// keepAlive: false — this notifier is scoped to the orchestrator
  /// screen lifetime. The screen `ref.read`s it in `initState` to wake
  /// the listener; popping the screen unmounts the provider and stops
  /// the refresh chain.
  ///
  /// Rationale for *not* registering in `realtimeBootHooksProvider`:
  /// the orchestrator screen is detail-route, not list-route. There's
  /// no queue to fill at boot — the screen mounts on user nav and
  /// hydrates on first read. Events arriving while the screen is closed
  /// are persisted in `EventLog` and replayed on next mount via the
  /// initial fetch (the response reflects the latest state).

  BookingOrchestratorEventsNotifierProvider call(int jobId) =>
      BookingOrchestratorEventsNotifierProvider._(argument: jobId, from: this);

  @override
  String toString() => r'bookingOrchestratorEventsProvider';
}

/// keepAlive: false — this notifier is scoped to the orchestrator
/// screen lifetime. The screen `ref.read`s it in `initState` to wake
/// the listener; popping the screen unmounts the provider and stops
/// the refresh chain.
///
/// Rationale for *not* registering in `realtimeBootHooksProvider`:
/// the orchestrator screen is detail-route, not list-route. There's
/// no queue to fill at boot — the screen mounts on user nav and
/// hydrates on first read. Events arriving while the screen is closed
/// are persisted in `EventLog` and replayed on next mount via the
/// initial fetch (the response reflects the latest state).

abstract class _$BookingOrchestratorEventsNotifier extends $Notifier<void> {
  late final _$args = ref.$arg as int;
  int get jobId => _$args;

  void build(int jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

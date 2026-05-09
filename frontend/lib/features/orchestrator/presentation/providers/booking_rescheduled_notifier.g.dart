// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_rescheduled_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: false — scoped to the orchestrator screen lifetime,
/// matching `BookingOrchestratorEventsNotifier`.

@ProviderFor(BookingRescheduledNotifier)
final bookingRescheduledProvider = BookingRescheduledNotifierFamily._();

/// keepAlive: false — scoped to the orchestrator screen lifetime,
/// matching `BookingOrchestratorEventsNotifier`.
final class BookingRescheduledNotifierProvider
    extends $NotifierProvider<BookingRescheduledNotifier, void> {
  /// keepAlive: false — scoped to the orchestrator screen lifetime,
  /// matching `BookingOrchestratorEventsNotifier`.
  BookingRescheduledNotifierProvider._({
    required BookingRescheduledNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'bookingRescheduledProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookingRescheduledNotifierHash();

  @override
  String toString() {
    return r'bookingRescheduledProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookingRescheduledNotifier create() => BookingRescheduledNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookingRescheduledNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookingRescheduledNotifierHash() =>
    r'3eb552c52cc9b925f3f606d15aab0d64013e6233';

/// keepAlive: false — scoped to the orchestrator screen lifetime,
/// matching `BookingOrchestratorEventsNotifier`.

final class BookingRescheduledNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BookingRescheduledNotifier,
          void,
          void,
          void,
          int
        > {
  BookingRescheduledNotifierFamily._()
    : super(
        retry: null,
        name: r'bookingRescheduledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// keepAlive: false — scoped to the orchestrator screen lifetime,
  /// matching `BookingOrchestratorEventsNotifier`.

  BookingRescheduledNotifierProvider call(int jobId) =>
      BookingRescheduledNotifierProvider._(argument: jobId, from: this);

  @override
  String toString() => r'bookingRescheduledProvider';
}

/// keepAlive: false — scoped to the orchestrator screen lifetime,
/// matching `BookingOrchestratorEventsNotifier`.

abstract class _$BookingRescheduledNotifier extends $Notifier<void> {
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_location_stream_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the latest [TechGpsFrame] received for [jobId], or `null`
/// before the first frame arrives.
///
/// keepAlive: false — scoped to the orchestrator screen lifetime.
/// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
/// popping the screen disposes the provider, which unregisters the
/// dispatcher handler.
///
/// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
/// dispatcher invokes the registered handler, we MUST NOT mutate
/// `state` synchronously inside `build()`. A frame buffered in the WS
/// channel before `build()` returns would corrupt initial state.
/// Deferring via `Future.microtask` guarantees the mutation lands on
/// the next microtask after `build()` returned. The `ref.mounted`
/// guard prevents post-disposal writes (the screen popped while a
/// frame was in flight).

@ProviderFor(TechnicianLocationStreamNotifier)
final technicianLocationStreamProvider =
    TechnicianLocationStreamNotifierFamily._();

/// Holds the latest [TechGpsFrame] received for [jobId], or `null`
/// before the first frame arrives.
///
/// keepAlive: false — scoped to the orchestrator screen lifetime.
/// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
/// popping the screen disposes the provider, which unregisters the
/// dispatcher handler.
///
/// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
/// dispatcher invokes the registered handler, we MUST NOT mutate
/// `state` synchronously inside `build()`. A frame buffered in the WS
/// channel before `build()` returns would corrupt initial state.
/// Deferring via `Future.microtask` guarantees the mutation lands on
/// the next microtask after `build()` returned. The `ref.mounted`
/// guard prevents post-disposal writes (the screen popped while a
/// frame was in flight).
final class TechnicianLocationStreamNotifierProvider
    extends $NotifierProvider<TechnicianLocationStreamNotifier, TechGpsFrame?> {
  /// Holds the latest [TechGpsFrame] received for [jobId], or `null`
  /// before the first frame arrives.
  ///
  /// keepAlive: false — scoped to the orchestrator screen lifetime.
  /// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
  /// popping the screen disposes the provider, which unregisters the
  /// dispatcher handler.
  ///
  /// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
  /// dispatcher invokes the registered handler, we MUST NOT mutate
  /// `state` synchronously inside `build()`. A frame buffered in the WS
  /// channel before `build()` returns would corrupt initial state.
  /// Deferring via `Future.microtask` guarantees the mutation lands on
  /// the next microtask after `build()` returned. The `ref.mounted`
  /// guard prevents post-disposal writes (the screen popped while a
  /// frame was in flight).
  TechnicianLocationStreamNotifierProvider._({
    required TechnicianLocationStreamNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'technicianLocationStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$technicianLocationStreamNotifierHash();

  @override
  String toString() {
    return r'technicianLocationStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TechnicianLocationStreamNotifier create() =>
      TechnicianLocationStreamNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechGpsFrame? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechGpsFrame?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TechnicianLocationStreamNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technicianLocationStreamNotifierHash() =>
    r'2348f7f3cb4ed6c33e883eb8f6a375077b0d7699';

/// Holds the latest [TechGpsFrame] received for [jobId], or `null`
/// before the first frame arrives.
///
/// keepAlive: false — scoped to the orchestrator screen lifetime.
/// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
/// popping the screen disposes the provider, which unregisters the
/// dispatcher handler.
///
/// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
/// dispatcher invokes the registered handler, we MUST NOT mutate
/// `state` synchronously inside `build()`. A frame buffered in the WS
/// channel before `build()` returns would corrupt initial state.
/// Deferring via `Future.microtask` guarantees the mutation lands on
/// the next microtask after `build()` returned. The `ref.mounted`
/// guard prevents post-disposal writes (the screen popped while a
/// frame was in flight).

final class TechnicianLocationStreamNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TechnicianLocationStreamNotifier,
          TechGpsFrame?,
          TechGpsFrame?,
          TechGpsFrame?,
          int
        > {
  TechnicianLocationStreamNotifierFamily._()
    : super(
        retry: null,
        name: r'technicianLocationStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Holds the latest [TechGpsFrame] received for [jobId], or `null`
  /// before the first frame arrives.
  ///
  /// keepAlive: false — scoped to the orchestrator screen lifetime.
  /// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
  /// popping the screen disposes the provider, which unregisters the
  /// dispatcher handler.
  ///
  /// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
  /// dispatcher invokes the registered handler, we MUST NOT mutate
  /// `state` synchronously inside `build()`. A frame buffered in the WS
  /// channel before `build()` returns would corrupt initial state.
  /// Deferring via `Future.microtask` guarantees the mutation lands on
  /// the next microtask after `build()` returned. The `ref.mounted`
  /// guard prevents post-disposal writes (the screen popped while a
  /// frame was in flight).

  TechnicianLocationStreamNotifierProvider call(int jobId) =>
      TechnicianLocationStreamNotifierProvider._(argument: jobId, from: this);

  @override
  String toString() => r'technicianLocationStreamProvider';
}

/// Holds the latest [TechGpsFrame] received for [jobId], or `null`
/// before the first frame arrives.
///
/// keepAlive: false — scoped to the orchestrator screen lifetime.
/// `EnRouteBodyStub` / `ArrivedBodyStub` `ref.watch` this provider;
/// popping the screen disposes the provider, which unregisters the
/// dispatcher handler.
///
/// **Why `Future.microtask` + `ref.mounted` (audit P1-05).** When the
/// dispatcher invokes the registered handler, we MUST NOT mutate
/// `state` synchronously inside `build()`. A frame buffered in the WS
/// channel before `build()` returns would corrupt initial state.
/// Deferring via `Future.microtask` guarantees the mutation lands on
/// the next microtask after `build()` returned. The `ref.mounted`
/// guard prevents post-disposal writes (the screen popped while a
/// frame was in flight).

abstract class _$TechnicianLocationStreamNotifier
    extends $Notifier<TechGpsFrame?> {
  late final _$args = ref.$arg as int;
  int get jobId => _$args;

  TechGpsFrame? build(int jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TechGpsFrame?, TechGpsFrame?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TechGpsFrame?, TechGpsFrame?>,
              TechGpsFrame?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

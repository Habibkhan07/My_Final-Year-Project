// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foreground_location_service_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)

@ProviderFor(ForegroundLocationServiceController)
final foregroundLocationServiceControllerProvider =
    ForegroundLocationServiceControllerFamily._();

/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)
final class ForegroundLocationServiceControllerProvider
    extends
        $NotifierProvider<ForegroundLocationServiceController, BroadcastState> {
  /// Manages the foreground GPS service for a single in-flight booking.
  ///
  /// keepAlive: false — bound to the orchestrator screen's lifetime.
  /// On screen pop: dispose hook stops the service. (Sprint v2 may
  /// promote to keepAlive: true so the tech can navigate away briefly
  /// without losing the customer's tracking — flag.md captures the
  /// limitation.)
  ForegroundLocationServiceControllerProvider._({
    required ForegroundLocationServiceControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'foregroundLocationServiceControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$foregroundLocationServiceControllerHash();

  @override
  String toString() {
    return r'foregroundLocationServiceControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ForegroundLocationServiceController create() =>
      ForegroundLocationServiceController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BroadcastState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BroadcastState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ForegroundLocationServiceControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$foregroundLocationServiceControllerHash() =>
    r'8ad3b50f56614c41d07ab30f56e4cdaf687abf12';

/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)

final class ForegroundLocationServiceControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ForegroundLocationServiceController,
          BroadcastState,
          BroadcastState,
          BroadcastState,
          int
        > {
  ForegroundLocationServiceControllerFamily._()
    : super(
        retry: null,
        name: r'foregroundLocationServiceControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages the foreground GPS service for a single in-flight booking.
  ///
  /// keepAlive: false — bound to the orchestrator screen's lifetime.
  /// On screen pop: dispose hook stops the service. (Sprint v2 may
  /// promote to keepAlive: true so the tech can navigate away briefly
  /// without losing the customer's tracking — flag.md captures the
  /// limitation.)

  ForegroundLocationServiceControllerProvider call(int jobId) =>
      ForegroundLocationServiceControllerProvider._(
        argument: jobId,
        from: this,
      );

  @override
  String toString() => r'foregroundLocationServiceControllerProvider';
}

/// Manages the foreground GPS service for a single in-flight booking.
///
/// keepAlive: false — bound to the orchestrator screen's lifetime.
/// On screen pop: dispose hook stops the service. (Sprint v2 may
/// promote to keepAlive: true so the tech can navigate away briefly
/// without losing the customer's tracking — flag.md captures the
/// limitation.)

abstract class _$ForegroundLocationServiceController
    extends $Notifier<BroadcastState> {
  late final _$args = ref.$arg as int;
  int get jobId => _$args;

  BroadcastState build(int jobId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BroadcastState, BroadcastState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BroadcastState, BroadcastState>,
              BroadcastState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

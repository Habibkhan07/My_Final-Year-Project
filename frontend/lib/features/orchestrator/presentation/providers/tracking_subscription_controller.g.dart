// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tracking_subscription_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive: false — owned by the orchestrator screen lifecycle.
/// The screen `ref.watch`-es this provider in `build()`; popping the
/// screen disposes the provider, which sends a final unsubscribe.

@ProviderFor(TrackingSubscriptionController)
final trackingSubscriptionControllerProvider =
    TrackingSubscriptionControllerFamily._();

/// keepAlive: false — owned by the orchestrator screen lifecycle.
/// The screen `ref.watch`-es this provider in `build()`; popping the
/// screen disposes the provider, which sends a final unsubscribe.
final class TrackingSubscriptionControllerProvider
    extends $NotifierProvider<TrackingSubscriptionController, void> {
  /// keepAlive: false — owned by the orchestrator screen lifecycle.
  /// The screen `ref.watch`-es this provider in `build()`; popping the
  /// screen disposes the provider, which sends a final unsubscribe.
  TrackingSubscriptionControllerProvider._({
    required TrackingSubscriptionControllerFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'trackingSubscriptionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trackingSubscriptionControllerHash();

  @override
  String toString() {
    return r'trackingSubscriptionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TrackingSubscriptionController create() => TrackingSubscriptionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrackingSubscriptionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trackingSubscriptionControllerHash() =>
    r'66d44aa1df2b5383e16b063de0b95ead115a2616';

/// keepAlive: false — owned by the orchestrator screen lifecycle.
/// The screen `ref.watch`-es this provider in `build()`; popping the
/// screen disposes the provider, which sends a final unsubscribe.

final class TrackingSubscriptionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TrackingSubscriptionController,
          void,
          void,
          void,
          int
        > {
  TrackingSubscriptionControllerFamily._()
    : super(
        retry: null,
        name: r'trackingSubscriptionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// keepAlive: false — owned by the orchestrator screen lifecycle.
  /// The screen `ref.watch`-es this provider in `build()`; popping the
  /// screen disposes the provider, which sends a final unsubscribe.

  TrackingSubscriptionControllerProvider call(int jobId) =>
      TrackingSubscriptionControllerProvider._(argument: jobId, from: this);

  @override
  String toString() => r'trackingSubscriptionControllerProvider';
}

/// keepAlive: false — owned by the orchestrator screen lifecycle.
/// The screen `ref.watch`-es this provider in `build()`; popping the
/// screen disposes the provider, which sends a final unsubscribe.

abstract class _$TrackingSubscriptionController extends $Notifier<void> {
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

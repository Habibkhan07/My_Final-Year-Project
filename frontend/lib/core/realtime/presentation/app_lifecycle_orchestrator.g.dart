// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_lifecycle_orchestrator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Providers whose `keepAlive: true` notifiers must wake during
/// [AppLifecycleOrchestrator.bootAfterAuth] so they subscribe to
/// `systemEventProvider` BEFORE the WS connect cascade fires.
///
/// Adding a new list-route event feature: append the feature's queue
/// provider here. There is intentionally no other registration site —
/// this keeps the boot extension point in one file alongside the
/// orchestrator that consumes it.
///
/// Order is currently irrelevant — entries are independent. If a future
/// feature needs to wake AFTER another, document the constraint here and
/// reorder.
///
/// Tests override this provider with `[]` (or with probe providers) to
/// keep `AuthNotifier` tests narrow and to assert that the for-loop in
/// `bootAfterAuth` actually iterates the registry.

@ProviderFor(realtimeBootHooks)
final realtimeBootHooksProvider = RealtimeBootHooksProvider._();

/// Providers whose `keepAlive: true` notifiers must wake during
/// [AppLifecycleOrchestrator.bootAfterAuth] so they subscribe to
/// `systemEventProvider` BEFORE the WS connect cascade fires.
///
/// Adding a new list-route event feature: append the feature's queue
/// provider here. There is intentionally no other registration site —
/// this keeps the boot extension point in one file alongside the
/// orchestrator that consumes it.
///
/// Order is currently irrelevant — entries are independent. If a future
/// feature needs to wake AFTER another, document the constraint here and
/// reorder.
///
/// Tests override this provider with `[]` (or with probe providers) to
/// keep `AuthNotifier` tests narrow and to assert that the for-loop in
/// `bootAfterAuth` actually iterates the registry.

final class RealtimeBootHooksProvider
    extends
        $FunctionalProvider<
          List<ProviderListenable<Object?>>,
          List<ProviderListenable<Object?>>,
          List<ProviderListenable<Object?>>
        >
    with $Provider<List<ProviderListenable<Object?>>> {
  /// Providers whose `keepAlive: true` notifiers must wake during
  /// [AppLifecycleOrchestrator.bootAfterAuth] so they subscribe to
  /// `systemEventProvider` BEFORE the WS connect cascade fires.
  ///
  /// Adding a new list-route event feature: append the feature's queue
  /// provider here. There is intentionally no other registration site —
  /// this keeps the boot extension point in one file alongside the
  /// orchestrator that consumes it.
  ///
  /// Order is currently irrelevant — entries are independent. If a future
  /// feature needs to wake AFTER another, document the constraint here and
  /// reorder.
  ///
  /// Tests override this provider with `[]` (or with probe providers) to
  /// keep `AuthNotifier` tests narrow and to assert that the for-loop in
  /// `bootAfterAuth` actually iterates the registry.
  RealtimeBootHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realtimeBootHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realtimeBootHooksHash();

  @$internal
  @override
  $ProviderElement<List<ProviderListenable<Object?>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ProviderListenable<Object?>> create(Ref ref) {
    return realtimeBootHooks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProviderListenable<Object?>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProviderListenable<Object?>>>(
        value,
      ),
    );
  }
}

String _$realtimeBootHooksHash() => r'ef2353d00eb191e2ea451fb8e6d4d07643a4e097';

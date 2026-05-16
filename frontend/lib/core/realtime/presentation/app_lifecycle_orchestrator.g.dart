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
/// **Audience: shared.** These notifiers fire for every authenticated
/// user regardless of role. Endpoints behind them accept any token.
/// Tech-only providers live in [realtimeTechnicianBootHooksProvider]
/// and only wake when `bootAfterAuth(..., isTechnician: true)`.
///
/// Adding a new list-route event feature:
///   * Customer-side / role-agnostic → append here.
///   * Tech-only (endpoint gated by `IsTechnician` or similar) →
///     append to [realtimeTechnicianBootHooksProvider] instead.
/// There is intentionally no third registration site — these two
/// registries are the boot extension points alongside the orchestrator.
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
/// **Audience: shared.** These notifiers fire for every authenticated
/// user regardless of role. Endpoints behind them accept any token.
/// Tech-only providers live in [realtimeTechnicianBootHooksProvider]
/// and only wake when `bootAfterAuth(..., isTechnician: true)`.
///
/// Adding a new list-route event feature:
///   * Customer-side / role-agnostic → append here.
///   * Tech-only (endpoint gated by `IsTechnician` or similar) →
///     append to [realtimeTechnicianBootHooksProvider] instead.
/// There is intentionally no third registration site — these two
/// registries are the boot extension points alongside the orchestrator.
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
  /// **Audience: shared.** These notifiers fire for every authenticated
  /// user regardless of role. Endpoints behind them accept any token.
  /// Tech-only providers live in [realtimeTechnicianBootHooksProvider]
  /// and only wake when `bootAfterAuth(..., isTechnician: true)`.
  ///
  /// Adding a new list-route event feature:
  ///   * Customer-side / role-agnostic → append here.
  ///   * Tech-only (endpoint gated by `IsTechnician` or similar) →
  ///     append to [realtimeTechnicianBootHooksProvider] instead.
  /// There is intentionally no third registration site — these two
  /// registries are the boot extension points alongside the orchestrator.
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

String _$realtimeBootHooksHash() => r'3988bdb93de8a71b73310c389ac88cfc86b5c9fc';

/// Realtime boot hooks that wake ONLY when the authenticated user is a
/// technician. Gated by `bootAfterAuth(..., isTechnician: ...)`.
///
/// Every provider here fetches from a tech-gated endpoint:
///
///   * `incomingJobQueueProvider`     → `/api/technicians/me/incoming-jobs/`
///   * `technicianDashboardProvider`  → `/api/technicians/dashboard/`
///   * `scheduledJobsListProvider`    → `/api/technicians/me/scheduled-jobs/`
///   * `scheduledJobsCountsProvider`  → `/api/technicians/me/scheduled-jobs/counts/`
///
/// Without the gate, a customer login would fire all four GETs and each
/// would 403 (the backend's `IsTechnician` permission rejects), polluting
/// every `keepAlive: true` notifier's state with an `AsyncError` that has
/// no consumer.
///
/// Mid-session edge case: a customer who applies for tech onboarding and
/// gets approved by admin will have `user.isTechnician == false` cached
/// until next verify-otp. The tech hooks will NOT wake until re-login.
/// This matches the pre-split behaviour (where the providers always woke
/// but cached the 403 `AsyncError` from the initial login as a customer)
/// — either way, re-login was required to get clean tech state. See
/// flag.md.
///
/// Tests override this provider with `[]` to keep narrow, exactly like
/// the shared registry above.

@ProviderFor(realtimeTechnicianBootHooks)
final realtimeTechnicianBootHooksProvider =
    RealtimeTechnicianBootHooksProvider._();

/// Realtime boot hooks that wake ONLY when the authenticated user is a
/// technician. Gated by `bootAfterAuth(..., isTechnician: ...)`.
///
/// Every provider here fetches from a tech-gated endpoint:
///
///   * `incomingJobQueueProvider`     → `/api/technicians/me/incoming-jobs/`
///   * `technicianDashboardProvider`  → `/api/technicians/dashboard/`
///   * `scheduledJobsListProvider`    → `/api/technicians/me/scheduled-jobs/`
///   * `scheduledJobsCountsProvider`  → `/api/technicians/me/scheduled-jobs/counts/`
///
/// Without the gate, a customer login would fire all four GETs and each
/// would 403 (the backend's `IsTechnician` permission rejects), polluting
/// every `keepAlive: true` notifier's state with an `AsyncError` that has
/// no consumer.
///
/// Mid-session edge case: a customer who applies for tech onboarding and
/// gets approved by admin will have `user.isTechnician == false` cached
/// until next verify-otp. The tech hooks will NOT wake until re-login.
/// This matches the pre-split behaviour (where the providers always woke
/// but cached the 403 `AsyncError` from the initial login as a customer)
/// — either way, re-login was required to get clean tech state. See
/// flag.md.
///
/// Tests override this provider with `[]` to keep narrow, exactly like
/// the shared registry above.

final class RealtimeTechnicianBootHooksProvider
    extends
        $FunctionalProvider<
          List<ProviderListenable<Object?>>,
          List<ProviderListenable<Object?>>,
          List<ProviderListenable<Object?>>
        >
    with $Provider<List<ProviderListenable<Object?>>> {
  /// Realtime boot hooks that wake ONLY when the authenticated user is a
  /// technician. Gated by `bootAfterAuth(..., isTechnician: ...)`.
  ///
  /// Every provider here fetches from a tech-gated endpoint:
  ///
  ///   * `incomingJobQueueProvider`     → `/api/technicians/me/incoming-jobs/`
  ///   * `technicianDashboardProvider`  → `/api/technicians/dashboard/`
  ///   * `scheduledJobsListProvider`    → `/api/technicians/me/scheduled-jobs/`
  ///   * `scheduledJobsCountsProvider`  → `/api/technicians/me/scheduled-jobs/counts/`
  ///
  /// Without the gate, a customer login would fire all four GETs and each
  /// would 403 (the backend's `IsTechnician` permission rejects), polluting
  /// every `keepAlive: true` notifier's state with an `AsyncError` that has
  /// no consumer.
  ///
  /// Mid-session edge case: a customer who applies for tech onboarding and
  /// gets approved by admin will have `user.isTechnician == false` cached
  /// until next verify-otp. The tech hooks will NOT wake until re-login.
  /// This matches the pre-split behaviour (where the providers always woke
  /// but cached the 403 `AsyncError` from the initial login as a customer)
  /// — either way, re-login was required to get clean tech state. See
  /// flag.md.
  ///
  /// Tests override this provider with `[]` to keep narrow, exactly like
  /// the shared registry above.
  RealtimeTechnicianBootHooksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'realtimeTechnicianBootHooksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$realtimeTechnicianBootHooksHash();

  @$internal
  @override
  $ProviderElement<List<ProviderListenable<Object?>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ProviderListenable<Object?>> create(Ref ref) {
    return realtimeTechnicianBootHooks(ref);
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

String _$realtimeTechnicianBootHooksHash() =>
    r'6bbe1d95898172e99cb987e05ab43a1606a42865';

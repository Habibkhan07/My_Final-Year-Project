// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the customer's own-profile state.
///
/// `build()` fetches `GET /me/` and caches via the repository's
/// offline-first contract. `updateName()` calls `PATCH /me/` and
/// additionally syncs the auth notifier's cached `UserEntity` so
/// the rest of the app (which still reads first/last name from
/// `authProvider`) immediately sees the new values without a
/// follow-up provider refresh.
///
/// `keepAlive: true`: the profile is read across multiple unrelated
/// screens (tab, edit screen, header pieces) so we keep it warm.
/// Logout invalidation is centralised in
/// `AppLifecycleOrchestrator.clearCustomerDataCaches` — the
/// orchestrator both `ref.invalidate(profileProvider)` and clears the
/// `cached_profile_me` SharedPreferences row, so a second user
/// signing in on the same device cannot read either the in-memory
/// provider state or the offline cache from the previous user.

@ProviderFor(Profile)
final profileProvider = ProfileProvider._();

/// Owns the customer's own-profile state.
///
/// `build()` fetches `GET /me/` and caches via the repository's
/// offline-first contract. `updateName()` calls `PATCH /me/` and
/// additionally syncs the auth notifier's cached `UserEntity` so
/// the rest of the app (which still reads first/last name from
/// `authProvider`) immediately sees the new values without a
/// follow-up provider refresh.
///
/// `keepAlive: true`: the profile is read across multiple unrelated
/// screens (tab, edit screen, header pieces) so we keep it warm.
/// Logout invalidation is centralised in
/// `AppLifecycleOrchestrator.clearCustomerDataCaches` — the
/// orchestrator both `ref.invalidate(profileProvider)` and clears the
/// `cached_profile_me` SharedPreferences row, so a second user
/// signing in on the same device cannot read either the in-memory
/// provider state or the offline cache from the previous user.
final class ProfileProvider
    extends $AsyncNotifierProvider<Profile, CustomerProfileEntity> {
  /// Owns the customer's own-profile state.
  ///
  /// `build()` fetches `GET /me/` and caches via the repository's
  /// offline-first contract. `updateName()` calls `PATCH /me/` and
  /// additionally syncs the auth notifier's cached `UserEntity` so
  /// the rest of the app (which still reads first/last name from
  /// `authProvider`) immediately sees the new values without a
  /// follow-up provider refresh.
  ///
  /// `keepAlive: true`: the profile is read across multiple unrelated
  /// screens (tab, edit screen, header pieces) so we keep it warm.
  /// Logout invalidation is centralised in
  /// `AppLifecycleOrchestrator.clearCustomerDataCaches` — the
  /// orchestrator both `ref.invalidate(profileProvider)` and clears the
  /// `cached_profile_me` SharedPreferences row, so a second user
  /// signing in on the same device cannot read either the in-memory
  /// provider state or the offline cache from the previous user.
  ProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileHash();

  @$internal
  @override
  Profile create() => Profile();
}

String _$profileHash() => r'882114918142fbaa7d3cdcc82f1f079d0160f09d';

/// Owns the customer's own-profile state.
///
/// `build()` fetches `GET /me/` and caches via the repository's
/// offline-first contract. `updateName()` calls `PATCH /me/` and
/// additionally syncs the auth notifier's cached `UserEntity` so
/// the rest of the app (which still reads first/last name from
/// `authProvider`) immediately sees the new values without a
/// follow-up provider refresh.
///
/// `keepAlive: true`: the profile is read across multiple unrelated
/// screens (tab, edit screen, header pieces) so we keep it warm.
/// Logout invalidation is centralised in
/// `AppLifecycleOrchestrator.clearCustomerDataCaches` — the
/// orchestrator both `ref.invalidate(profileProvider)` and clears the
/// `cached_profile_me` SharedPreferences row, so a second user
/// signing in on the same device cannot read either the in-memory
/// provider state or the offline cache from the previous user.

abstract class _$Profile extends $AsyncNotifier<CustomerProfileEntity> {
  FutureOr<CustomerProfileEntity> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<CustomerProfileEntity>, CustomerProfileEntity>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CustomerProfileEntity>,
                CustomerProfileEntity
              >,
              AsyncValue<CustomerProfileEntity>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

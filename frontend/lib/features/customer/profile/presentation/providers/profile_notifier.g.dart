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
/// Invalidate via `ref.invalidate(profileProvider)` on logout — the
/// auth notifier handles this implicitly because logout tears the
/// secure-storage token, which causes the next `getMe()` to throw
/// `ProfileUnauthorizedFailure`.

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
/// Invalidate via `ref.invalidate(profileProvider)` on logout — the
/// auth notifier handles this implicitly because logout tears the
/// secure-storage token, which causes the next `getMe()` to throw
/// `ProfileUnauthorizedFailure`.
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
  /// Invalidate via `ref.invalidate(profileProvider)` on logout — the
  /// auth notifier handles this implicitly because logout tears the
  /// secure-storage token, which causes the next `getMe()` to throw
  /// `ProfileUnauthorizedFailure`.
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

String _$profileHash() => r'29a84930d7d32915c7e5a5ff984ce1eaf428e5c0';

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
/// Invalidate via `ref.invalidate(profileProvider)` on logout — the
/// auth notifier handles this implicitly because logout tears the
/// secure-storage token, which causes the next `getMe()` to throw
/// `ProfileUnauthorizedFailure`.

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

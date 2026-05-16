import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../domain/entities/customer_profile_entity.dart';
import 'dependency_injection.dart';

part 'profile_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class Profile extends _$Profile {
  @override
  Future<CustomerProfileEntity> build() async {
    return ref.read(getMeUseCaseProvider).call();
  }

  /// Refreshes from the network. Surfaced for pull-to-refresh on the
  /// profile tab.
  ///
  /// Why no `AsyncLoading` transition: a bare `state = AsyncLoading()`
  /// would zero out `state.value`, so widgets watching this provider
  /// during the refresh window would flash to "no data" (and a
  /// full-screen spinner / error state on failure). The
  /// `RefreshIndicator` already shows its own spinner; we keep the
  /// underlying data rendered until the new result lands. On error
  /// the state stays at the previous `AsyncData` (the snackbar /
  /// banner is the caller's responsibility).
  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(getMeUseCaseProvider).call(),
    );
    // Only swap state on success — a failed refresh must not replace
    // the visible profile with an error tab.
    if (result.hasValue) state = result;
  }

  /// PATCH the caller's profile. Both fields are required by the
  /// backend serializer; the edit screen pre-fills both and submits
  /// both even if only one was actually changed.
  ///
  /// On success, the auth notifier's cached `UserEntity` is also
  /// updated so widgets reading `authProvider.user.firstName` (e.g.
  /// the dashboard greeting) reflect the new value without an
  /// additional invalidation.
  ///
  /// Returns the [AsyncValue] outcome of the call so the edit screen
  /// can decide UI-side behaviour (snackbar, pop) without having to
  /// race a `ref.listen` against the next `state` mutation. The
  /// notifier's own `state` is only updated on success — a failed
  /// PATCH leaves the profile tab rendering the previous data.
  Future<AsyncValue<CustomerProfileEntity>> updateName({
    required String firstName,
    required String lastName,
  }) async {
    final result = await AsyncValue.guard(() async {
      final updated = await ref.read(updateMeUseCaseProvider).call(
            firstName: firstName,
            lastName: lastName,
          );
      // Sync auth cache — fire-and-forget at the call site since this
      // method is itself just a local cache mutation, no network.
      ref
          .read(authProvider.notifier)
          .updateProfileNames(firstName, lastName);
      return updated;
    });
    if (result.hasValue) state = result;
    return result;
  }
}

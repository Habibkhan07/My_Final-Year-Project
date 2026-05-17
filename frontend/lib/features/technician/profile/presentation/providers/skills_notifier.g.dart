// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skills_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the technician's skill list state.
///
/// `keepAlive: true`: the list is read on the Profile tab AND on the
/// Add Skill picker (for client-side duplicate filtering), so we keep
/// the cached state warm. Logout invalidation flows through the auth
/// repository's local-clear → next read raises Unauthorized → presentation
/// triggers `authProvider.notifier.logout()` (idempotent).
///
/// Mutation methods (`addSkill` / `removeSkill`) follow the project's
/// `AsyncValue.guard` convention (CLAUDE.md): the call is wrapped in
/// guard, state is mutated **only on success** so a failed mutation
/// preserves the previous list, and the AsyncValue is returned so the
/// screen can branch on `hasError` without racing a `ref.listen`
/// against the next state mutation. Unlike a single-entity surface
/// (the customer profile's `updateName` just does `state = result`),
/// our state is a list — we manually merge on success rather than
/// replacing, which is why guard is the wrapper but the state write
/// is bespoke.

@ProviderFor(Skills)
final skillsProvider = SkillsProvider._();

/// Owns the technician's skill list state.
///
/// `keepAlive: true`: the list is read on the Profile tab AND on the
/// Add Skill picker (for client-side duplicate filtering), so we keep
/// the cached state warm. Logout invalidation flows through the auth
/// repository's local-clear → next read raises Unauthorized → presentation
/// triggers `authProvider.notifier.logout()` (idempotent).
///
/// Mutation methods (`addSkill` / `removeSkill`) follow the project's
/// `AsyncValue.guard` convention (CLAUDE.md): the call is wrapped in
/// guard, state is mutated **only on success** so a failed mutation
/// preserves the previous list, and the AsyncValue is returned so the
/// screen can branch on `hasError` without racing a `ref.listen`
/// against the next state mutation. Unlike a single-entity surface
/// (the customer profile's `updateName` just does `state = result`),
/// our state is a list — we manually merge on success rather than
/// replacing, which is why guard is the wrapper but the state write
/// is bespoke.
final class SkillsProvider
    extends $AsyncNotifierProvider<Skills, List<TechnicianSkillEntity>> {
  /// Owns the technician's skill list state.
  ///
  /// `keepAlive: true`: the list is read on the Profile tab AND on the
  /// Add Skill picker (for client-side duplicate filtering), so we keep
  /// the cached state warm. Logout invalidation flows through the auth
  /// repository's local-clear → next read raises Unauthorized → presentation
  /// triggers `authProvider.notifier.logout()` (idempotent).
  ///
  /// Mutation methods (`addSkill` / `removeSkill`) follow the project's
  /// `AsyncValue.guard` convention (CLAUDE.md): the call is wrapped in
  /// guard, state is mutated **only on success** so a failed mutation
  /// preserves the previous list, and the AsyncValue is returned so the
  /// screen can branch on `hasError` without racing a `ref.listen`
  /// against the next state mutation. Unlike a single-entity surface
  /// (the customer profile's `updateName` just does `state = result`),
  /// our state is a list — we manually merge on success rather than
  /// replacing, which is why guard is the wrapper but the state write
  /// is bespoke.
  SkillsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skillsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skillsHash();

  @$internal
  @override
  Skills create() => Skills();
}

String _$skillsHash() => r'520c1d0287aa6f01f373e601c4431ef154716dc1';

/// Owns the technician's skill list state.
///
/// `keepAlive: true`: the list is read on the Profile tab AND on the
/// Add Skill picker (for client-side duplicate filtering), so we keep
/// the cached state warm. Logout invalidation flows through the auth
/// repository's local-clear → next read raises Unauthorized → presentation
/// triggers `authProvider.notifier.logout()` (idempotent).
///
/// Mutation methods (`addSkill` / `removeSkill`) follow the project's
/// `AsyncValue.guard` convention (CLAUDE.md): the call is wrapped in
/// guard, state is mutated **only on success** so a failed mutation
/// preserves the previous list, and the AsyncValue is returned so the
/// screen can branch on `hasError` without racing a `ref.listen`
/// against the next state mutation. Unlike a single-entity surface
/// (the customer profile's `updateName` just does `state = result`),
/// our state is a list — we manually merge on success rather than
/// replacing, which is why guard is the wrapper but the state write
/// is bespoke.

abstract class _$Skills extends $AsyncNotifier<List<TechnicianSkillEntity>> {
  FutureOr<List<TechnicianSkillEntity>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<TechnicianSkillEntity>>,
              List<TechnicianSkillEntity>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<TechnicianSkillEntity>>,
                List<TechnicianSkillEntity>
              >,
              AsyncValue<List<TechnicianSkillEntity>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

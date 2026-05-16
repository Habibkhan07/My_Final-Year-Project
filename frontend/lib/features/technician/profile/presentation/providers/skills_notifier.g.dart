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

@ProviderFor(Skills)
final skillsProvider = SkillsProvider._();

/// Owns the technician's skill list state.
///
/// `keepAlive: true`: the list is read on the Profile tab AND on the
/// Add Skill picker (for client-side duplicate filtering), so we keep
/// the cached state warm. Logout invalidation flows through the auth
/// repository's local-clear → next read raises Unauthorized → presentation
/// triggers `authProvider.notifier.logout()` (idempotent).
final class SkillsProvider
    extends $AsyncNotifierProvider<Skills, List<TechnicianSkillEntity>> {
  /// Owns the technician's skill list state.
  ///
  /// `keepAlive: true`: the list is read on the Profile tab AND on the
  /// Add Skill picker (for client-side duplicate filtering), so we keep
  /// the cached state warm. Logout invalidation flows through the auth
  /// repository's local-clear → next read raises Unauthorized → presentation
  /// triggers `authProvider.notifier.logout()` (idempotent).
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

String _$skillsHash() => r'0997e4b196d7e756dd7e99eeb9a7e34a34533f62';

/// Owns the technician's skill list state.
///
/// `keepAlive: true`: the list is read on the Profile tab AND on the
/// Add Skill picker (for client-side duplicate filtering), so we keep
/// the cached state warm. Logout invalidation flows through the auth
/// repository's local-clear → next read raises Unauthorized → presentation
/// triggers `authProvider.notifier.logout()` (idempotent).

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

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/technician_skill_entity.dart';
import 'dependency_injection.dart';

part 'skills_notifier.g.dart';

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
@Riverpod(keepAlive: true)
class Skills extends _$Skills {
  @override
  Future<List<TechnicianSkillEntity>> build() async {
    return ref.read(listMySkillsUseCaseProvider).call();
  }

  /// Refreshes from the network. Surfaced for pull-to-refresh on the
  /// My Skills screen. Keeps the previous data visible on a failed
  /// refresh instead of flashing to an error tab — the
  /// `RefreshIndicator` already shows its own spinner, and a wiped
  /// state would surface the error tab even though the previous list
  /// is still valid.
  Future<void> refresh() async {
    final result = await AsyncValue.guard(
      () => ref.read(listMySkillsUseCaseProvider).call(),
    );
    if (result.hasValue) state = result;
  }

  /// Add a skill. Returns the [AsyncValue] outcome so the Add Skill
  /// screen can pattern-match on the failure type without a second
  /// `ref.listen` race. On success, merges the new entity into the
  /// current list, sorted by parent service name then sub-service
  /// name to match the backend ordering.
  Future<AsyncValue<TechnicianSkillEntity>> addSkill({
    required int subServiceId,
  }) async {
    final result = await AsyncValue.guard(
      () => ref.read(addSkillUseCaseProvider).call(subServiceId: subServiceId),
    );

    if (result.hasValue) {
      final added = result.requireValue;
      final current = state.value ?? const <TechnicianSkillEntity>[];
      final merged = [...current, added]..sort((a, b) {
          final byService = a.subService.service.name
              .toLowerCase()
              .compareTo(b.subService.service.name.toLowerCase());
          if (byService != 0) return byService;
          return a.subService.name
              .toLowerCase()
              .compareTo(b.subService.name.toLowerCase());
        });
      state = AsyncData(merged);
    }

    return result;
  }

  /// Remove a skill by sub-service id. Returns the [AsyncValue] outcome
  /// so the My Skills screen can render `LastSkillFailure` snacks
  /// without re-deriving them from a thrown exception. On success,
  /// drops the row from the in-memory list.
  Future<AsyncValue<void>> removeSkill({required int subServiceId}) async {
    final result = await AsyncValue.guard(
      () => ref
          .read(removeSkillUseCaseProvider)
          .call(subServiceId: subServiceId),
    );

    if (result.hasValue) {
      final current = state.value ?? const <TechnicianSkillEntity>[];
      state = AsyncData(
        current
            .where((s) => s.subService.id != subServiceId)
            .toList(growable: false),
      );
    }

    return result;
  }
}

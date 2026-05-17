import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_selection_entity.freezed.dart';

/// A selected sub-service in the onboarding wizard. Bridge row is pure
/// membership after the 2026-05-17 refactor — no per-skill years /
/// labor rate; platform pricing comes from the catalog.
@freezed
abstract class SkillSelectionEntity with _$SkillSelectionEntity {
  const factory SkillSelectionEntity({
    required int subServiceId,
  }) = _SkillSelectionEntity;
}

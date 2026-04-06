import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_selection_entity.freezed.dart';

/// [SkillSelectionEntity] represents the tech's selected skill and its labor rates.
/// FLOW: Selected in Onboarding Step 5
@freezed
abstract class SkillSelectionEntity with _$SkillSelectionEntity {
  const factory SkillSelectionEntity({
    required int subServiceId,
    required int yearsOfExperience,
    String? baseRate,
    String? maxRate,
  }) = _SkillSelectionEntity;
}

// domain/entities/skill_selection_entity.dart
import 'package:equatable/equatable.dart';

class SkillSelectionEntity extends Equatable {
  final int subServiceId;
  final int yearsOfExperience;

  const SkillSelectionEntity({
    required this.subServiceId,
    required this.yearsOfExperience,
  });

  @override
  List<Object?> get props => [subServiceId, yearsOfExperience];
}

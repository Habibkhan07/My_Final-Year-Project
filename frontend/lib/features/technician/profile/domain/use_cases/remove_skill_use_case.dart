import '../repositories/i_skills_repository.dart';

class RemoveSkillUseCase {
  final ISkillsRepository repository;
  const RemoveSkillUseCase(this.repository);

  Future<void> call({required int subServiceId}) =>
      repository.removeSkill(subServiceId: subServiceId);
}

import '../entities/technician_skill_entity.dart';
import '../repositories/i_skills_repository.dart';

class AddSkillUseCase {
  final ISkillsRepository repository;
  const AddSkillUseCase(this.repository);

  Future<TechnicianSkillEntity> call({required int subServiceId}) =>
      repository.addSkill(subServiceId: subServiceId);
}

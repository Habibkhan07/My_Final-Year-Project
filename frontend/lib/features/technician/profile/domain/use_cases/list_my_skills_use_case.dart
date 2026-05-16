import '../entities/technician_skill_entity.dart';
import '../repositories/i_skills_repository.dart';

class ListMySkillsUseCase {
  final ISkillsRepository repository;
  const ListMySkillsUseCase(this.repository);

  Future<List<TechnicianSkillEntity>> call() => repository.listMySkills();
}

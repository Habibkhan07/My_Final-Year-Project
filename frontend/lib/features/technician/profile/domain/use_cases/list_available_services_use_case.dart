import '../entities/available_sub_service_entity.dart';
import '../repositories/i_skills_repository.dart';

class ListAvailableServicesUseCase {
  final ISkillsRepository repository;
  const ListAvailableServicesUseCase(this.repository);

  Future<List<AvailableServiceEntity>> call() =>
      repository.listAvailableServices();
}

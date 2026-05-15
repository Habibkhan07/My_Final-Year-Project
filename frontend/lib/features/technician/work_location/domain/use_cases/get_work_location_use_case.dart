import '../entities/work_location_entity.dart';
import '../repositories/i_work_location_repository.dart';

class GetWorkLocationUseCase {
  final IWorkLocationRepository _repo;
  const GetWorkLocationUseCase(this._repo);

  Future<WorkLocationEntity> call() => _repo.getWorkLocation();
}

import '../entities/work_location_entity.dart';
import '../repositories/i_work_location_repository.dart';

class SaveWorkLocationUseCase {
  final IWorkLocationRepository _repo;
  const SaveWorkLocationUseCase(this._repo);

  Future<WorkLocationEntity> call({
    required double latitude,
    required double longitude,
    int? maxTravelRadiusKm,
    String? workAddressLabel,
  }) => _repo.saveWorkLocation(
    latitude: latitude,
    longitude: longitude,
    maxTravelRadiusKm: maxTravelRadiusKm,
    workAddressLabel: workAddressLabel,
  );
}

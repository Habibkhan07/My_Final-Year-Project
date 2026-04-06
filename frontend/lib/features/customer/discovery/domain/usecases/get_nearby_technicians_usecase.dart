import '../../domain/entities/discovery_entities.dart';
import '../../domain/repositories/i_discovery_repository.dart';

class GetNearbyTechniciansUseCase {
  final IDiscoveryRepository repository;

  GetNearbyTechniciansUseCase(this.repository);

  Future<DiscoveryResultEntity> call({
    double? lat,
    double? lng,
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    int page = 1,
  }) {
    return repository.getNearbyTechnicians(
      lat: lat,
      lng: lng,
      query: query,
      serviceId: serviceId,
      subServiceId: subServiceId,
      promotionId: promotionId,
      page: page,
    );
  }
}

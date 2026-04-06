import '../entities/discovery_entities.dart';

abstract class IDiscoveryRepository {
  /// Fetches paginated and filtered technicians from /api/customers/nearby-technicians/
  /// Throws [DiscoveryFailure] on network or server errors.
  Future<DiscoveryResultEntity> getNearbyTechnicians({
    double? lat,
    double? lng,
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    int page = 1,
  });
}

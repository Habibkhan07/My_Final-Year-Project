import '../entities/service_entity.dart';
import '../repositories/technician_onboarding_repository.dart';

class GetOnboardingMetadataUseCase {
  final TechnicianRepository repository;

  GetOnboardingMetadataUseCase(this.repository);

  Future<List<ServiceEntity>> execute() {
    return repository.getOnboardingMetadata();
  }
}

import '../entities/technician_entity.dart';
import '../repositories/technician_onboarding_repository.dart';
// IMPORTANT: You must import your new entity here
import '../entities/skill_selection_entity.dart';
import '../entities/category_license_entity.dart';

class RegisterTechnicianUseCase {
  final TechnicianRepository repository;

  RegisterTechnicianUseCase(this.repository);

  Future<TechnicianEntity> execute({
    required String token,
    required String firstName,
    required String lastName,
    required String profilePictureUuid,
    required String city,
    required String cnicNumber,
    required String cnicPictureUuid,
    required List<SkillSelectionEntity> skills,
    required List<CategoryLicenseEntity> categoryLicenses,
    double? baseLatitude,
    double? baseLongitude,
    int? maxTravelRadiusKm,
    String? workAddressLabel,
  }) {
    return repository.finalizeRegistration(
      token: token,
      firstName: firstName,
      lastName: lastName,
      city: city,
      cnicNumber: cnicNumber,
      profilePictureUuid: profilePictureUuid,
      cnicPictureUuid: cnicPictureUuid,
      skills: skills,
      categoryLicenses: categoryLicenses,
      baseLatitude: baseLatitude,
      baseLongitude: baseLongitude,
      maxTravelRadiusKm: maxTravelRadiusKm,
      workAddressLabel: workAddressLabel,
    );
  }
}

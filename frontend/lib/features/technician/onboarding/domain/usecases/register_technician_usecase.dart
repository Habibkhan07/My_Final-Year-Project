import '../entities/technician_entity.dart';
import '../repositories/technician_onboarding_repository.dart';
// IMPORTANT: You must import your new entity here
import '../entities/skill_selection_entity.dart';

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
    required String bio,
    required int experienceYears,
    required List<SkillSelectionEntity> skills, // Fixed syntax
  }) {
    return repository.finalizeRegistration(
      token: token,
      firstName: firstName,
      lastName: lastName,
      city: city,
      cnicNumber: cnicNumber,
      bio: bio,
      profilePictureUuid: profilePictureUuid,
      cnicPictureUuid: cnicPictureUuid,
      experienceYears: experienceYears,
      skills:
          skills, // This will error until you update the Repository interface
    );
  }
}

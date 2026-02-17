import 'dart:io';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_onboarding_repository.dart';
import '../../domain/failures/technician_failure.dart'; // Import Sealed Class
import '../data_sources/technician_onboarding_remote_datasource.dart';
import '../models/technician_registration_model.dart';
import '../../domain/entities/skill_selection_entity.dart';
import '../../../../../core/common/errors/http_failure.dart'; // Import Data Exception

class TechnicianRepositoryImpl implements TechnicianRepository {
  final TechnicianOnboardingRemoteDataSource remoteDataSource;

  TechnicianRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ServiceEntity>> getOnboardingMetadata() async {
    return _mapFailures(() async {
      final models = await remoteDataSource.getOnboardingMetadata();
      return models
          .map(
            (model) => ServiceEntity(
              id: model.id,
              name: model.name,
              subServices: model.subServices
                  .map(
                    (sub) => SubServiceEntity(
                      id: sub.id,
                      name: sub.name,
                      basePrice: sub.basePrice.toString(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    });
  }

  @override
  Future<String> uploadMedia(File file, String token) async {
    return _mapFailures(
      () => remoteDataSource.uploadTemporaryMedia(file, token),
    );
  }

  @override
  Future<TechnicianEntity> finalizeRegistration({
    required String token,
    required String firstName,
    required String lastName,
    required String city,
    required String cnicNumber,
    required int experienceYears,
    required String bio,
    required String profilePictureUuid,
    required String cnicPictureUuid,
    required List<SkillSelectionEntity> skills,
  }) async {
    return _mapFailures(() async {
      final registrationModel = TechnicianRegistrationModel(
        firstName: firstName,
        lastName: lastName,
        city: city,
        cnicNumber: cnicNumber,
        experienceYears: experienceYears,
        bio: bio,
        profilePictureUuid: profilePictureUuid,
        cnicPictureUuid: cnicPictureUuid,
        skills: skills
            .map(
              (s) => SkillInputModel(
                subServiceId: s.subServiceId,
                yearsOfExperience: s.yearsOfExperience,
                licenseMediaUuid: s.licenseMediaUuid,
              ),
            )
            .toList(),
      );

      final response = await remoteDataSource.finalizeRegistration(
        registrationModel,
        token,
      );

      return TechnicianEntity(
        profileId: response['profile_id'],
        status: response['status'],
        fullName: "$firstName $lastName",
        joinedDate: response['joined_date'] ?? DateTime.now().toString(),
        experienceYears: experienceYears,
      );
    });
  }

  // --- THE MAPPING LOGIC ---
  Future<T> _mapFailures<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on HttpFailure catch (e) {
      switch (e.code) {
        case 'validation_error': // 400
          throw InvalidOnboardingInput(e.errors);

        case 'not_found': // 404 (Expired UUIDs)
          throw OnboardingSessionExpired(e.message);

        case 'resource_conflict': // 409 (Duplicate CNIC)
          throw DuplicateTechnician(e.message);

        default:
          throw OnboardingServerFailure(e.message);
      }
    } catch (e) {
      throw OnboardingServerFailure(e.toString());
    }
  }
}

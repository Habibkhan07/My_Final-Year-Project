import 'dart:io';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_onboarding_repository.dart';
import '../data_sources/technician_onboarding_remote_datasource.dart';
import '../models/technician_registration_model.dart';
import '../../domain/entities/skill_selection_entity.dart';

class TechnicianRepositoryImpl implements TechnicianRepository {
  final TechnicianOnboardingRemoteDataSource remoteDataSource;

  TechnicianRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ServiceEntity>> getOnboardingMetadata() async {
    try {
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
    } on SocketException {
      throw "No internet connection. Please check your network.";
    } catch (e) {
      throw e.toString(); // Propagates the custom error from data source
    }
  }

  @override
  Future<String> uploadMedia(File file, String token) async {
    try {
      return await remoteDataSource.uploadTemporaryMedia(file, token);
    } on SocketException {
      throw "Network error: Failed to upload image.";
    } catch (e) {
      // Catches "Media upload failed" or other custom messages
      throw e.toString();
    }
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
    try {
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
    } on SocketException {
      throw "Connection timed out. Please try again.";
    } on FormatException catch (e) {
      print(
        "MAPPING ERROR: $e",
      ); // This will tell you exactly which field failed
      throw "Bad response from server. Please contact support.";
    } catch (e) {
      // This will catch the backend errors like "uuid_error" you defined
      throw e.toString();
    }
  }
}

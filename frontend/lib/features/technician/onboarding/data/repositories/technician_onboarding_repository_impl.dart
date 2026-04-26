import 'dart:io';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_onboarding_repository.dart';
import '../../domain/failures/technician_failure.dart'; // Import Sealed Class
import '../data_sources/technician_onboarding_remote_datasource.dart';
import '../data_sources/onboarding_local_data_source.dart';
import '../models/technician_registration_model.dart';
import '../models/service_model.dart';
import '../../domain/entities/skill_selection_entity.dart';
import '../../domain/entities/category_license_entity.dart';
import '../../../../../core/common/errors/http_failure.dart'; // Import Data Exception
import 'package:image_picker/image_picker.dart'; // ADD THIS IMPORT

class TechnicianRepositoryImpl implements TechnicianRepository {
  final TechnicianOnboardingRemoteDataSource remoteDataSource;
  final OnboardingLocalDataSource localDataSource;

  TechnicianRepositoryImpl(this.remoteDataSource, this.localDataSource);

  @override
  Future<List<ServiceEntity>> getOnboardingMetadata() async {
    try {
      // 1. Try to fetch from RemoteDataSource
      final models = await remoteDataSource.getOnboardingMetadata();
      
      // 2. If successful, cache the data immediately
      await localDataSource.saveOnboardingMetadata(models);
      
      return _mapModelsToEntities(models);
    } on SocketException catch (_) {
      // 3. Network error: fallback to LocalDataSource
      final cachedModels = await localDataSource.getOnboardingMetadata();
      if (cachedModels != null && cachedModels.isNotEmpty) {
        // 4. Return cached data (Fast Offline Load)
        return _mapModelsToEntities(cachedModels);
      }
      // If cache is empty, bubble up the network failure
      throw const OnboardingNetworkFailure(
        "No internet connection and no cached data available.",
      );
    } catch (e) {
      // For any other unexpected/Http errors, route through standard _mapFailures
      return _mapFailures(() => Future.error(e));
    }
  }
  
  List<ServiceEntity> _mapModelsToEntities(List<ServiceModel> models) {
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
                    basePrice: sub.basePrice,
                    maxPrice: sub.maxPrice,
                    iconName: sub.iconName,
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<String> uploadMedia(XFile file, String token) async {
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
    required List<CategoryLicenseEntity>
    categoryLicenses, // REPLACED MAP WITH ENTITY
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
        categoryLicenses: categoryLicenses
            .map(
              (e) => CategoryLicenseInputModel(
                serviceId: e.serviceId,
                mediaUuid: e.mediaUuid,
              ),
            )
            .toList(),
        skills: skills
            .map(
              (s) => SkillInputModel(
                subServiceId: s.subServiceId,
                yearsOfExperience: s.yearsOfExperience,
                baseRate: s.baseRate,
                maxRate: s.maxRate,
              ),
            )
            .toList(),
      );

      final response = await remoteDataSource.finalizeRegistration(
        registrationModel,
        token,
      );

      // Onboarding complete - update Tier 2 storage
      await localDataSource.saveOnboardingComplete(true);

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
        case 'unauthorized': // Matches exception.py
          throw OnboardingUnauthorized(e.message);

        case 'validation_error': // 400
          throw InvalidOnboardingInput(e.errors);

        case 'not_found': // 404 (Expired UUIDs)
          throw OnboardingSessionExpired(e.message);

        case 'resource_conflict': // 409 (Duplicate CNIC)
          throw DuplicateTechnician(e.message);

        default:
          throw OnboardingServerFailure(e.message);
      }
    }
    // 2. Handle Network Errors (Offline, DNS failure)
    on SocketException catch (_) {
      throw const OnboardingNetworkFailure(
        "No internet connection. Please check your settings.",
      );
    }
    // 3. Handle Bad Data (Server returned HTML instead of JSON)
    on FormatException catch (_) {
      throw const OnboardingParsingFailure(
        "Invalid response format from server.",
      );
    } catch (e) {
      throw OnboardingServerFailure("Unexpected error: ${e.toString()}");
    }
  }
}

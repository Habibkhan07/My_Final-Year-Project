import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/skill_selection_entity.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/entities/category_license_entity.dart';
part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const OnboardingState._();

  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default('') String city,
    @Default('') String cnicNumber,
    String? profilePictureUuid,
    String? cnicPictureUuid,

    // Local file paths for in-wizard thumbnail previews. The wire payload
    // only carries the UUIDs (above); these stay on the client so the
    // user can see what they captured and decide whether to retake.
    // Cleared on submit; never persisted.
    String? profilePicturePath,
    String? cnicPicturePath,
    @Default(<int, String>{}) Map<int, String> categoryLicensePaths,

    // Storing the metadata fetched from the backend
    @Default([]) List<ServiceEntity> services,

    @Default([]) List<SkillSelectionEntity> selectedSkills,
    @Default([]) List<CategoryLicenseEntity> categoryLicenses,

    // Work location — captured in the final wizard step. Optional on
    // the wire, but the wizard's "Submit" gate requires both lat/lng
    // to be non-null so an approved tech is bookable from day one.
    double? baseLatitude,
    double? baseLongitude,
    @Default(10) int maxTravelRadiusKm,
    @Default('') String workAddressLabel,

    @Default(AsyncValue.data(null))
    AsyncValue<TechnicianEntity?> submissionStatus,
  }) = _OnboardingState;
}

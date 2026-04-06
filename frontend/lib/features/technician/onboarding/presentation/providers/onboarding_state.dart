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
    @Default('') String bio,
    @Default(0) int experienceYears,
    String? profilePictureUuid,
    String? cnicPictureUuid,

    // Storing the metadata fetched from the backend
    @Default([]) List<ServiceEntity> services,

    @Default([]) List<SkillSelectionEntity> selectedSkills,
    @Default([]) List<CategoryLicenseEntity> categoryLicenses,

    @Default(AsyncValue.data(null))
    AsyncValue<TechnicianEntity?> submissionStatus,
  }) = _OnboardingState;
}

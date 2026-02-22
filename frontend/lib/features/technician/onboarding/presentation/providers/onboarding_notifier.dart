// lib/features/technician/onboarding/presentation/providers/onboarding_notifier.dart

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'onboarding_state.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
import '../../../../auth/presentation/providers/auth_state.dart';
import '../../domain/entities/skill_selection_entity.dart';
import '../../domain/failures/technician_failure.dart';
import 'dependency_injection.dart';
import '../../../../../core/common/domain/entities/user_entity.dart';
import '../../domain/entities/category_license_entity.dart';
part 'onboarding_notifier.g.dart';

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  FutureOr<OnboardingState> build() async {
    // 1. Fetch Metadata (The "Source of Truth")
    // If this fails, Riverpod catches the exception and puts the Notifier into AsyncError
    final services = await ref
        .read(getOnboardingMetadataUseCaseProvider)
        .execute();

    // 2. Watch existing user info from Auth
    final user = ref.watch(authenticatedUserProvider);

    return OnboardingState(
      firstName: user?.firstName ?? '',
      lastName: user?.lastName ?? '',
      services: services, // Metadata is now intaken
    );
  }

  Future<void> fetchMetadata() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final services = await ref
          .read(getOnboardingMetadataUseCaseProvider)
          .execute();
      return state.value!.copyWith(services: services);
    });
  }

  // --- STEP 0: PERSONAL INFO ---
  void updatePersonalInfo({
    String? firstName,
    String? lastName,
    String? city,
    String? bio,
    int? experienceYears,
    String? cnic,
  }) {
    final current = state.value!;
    state = AsyncData(
      current.copyWith(
        firstName: firstName ?? current.firstName,
        lastName: lastName ?? current.lastName,
        city: city ?? current.city,
        bio: bio ?? current.bio,
        experienceYears: experienceYears ?? current.experienceYears,
        cnicNumber: cnic ?? current.cnicNumber,
      ),
    );
  }

  // --- PHASE 1: MEDIA UPLOAD (Survival Pattern) ---
  Future<void> uploadDocument(XFile file, String type, {int? serviceId}) async {
    final previousData = state.value!;

    // 2. Grab the token from the selector provider.
    final token = ref.read(authenticatedUserProvider)?.token;

    // FAIL FAST: Specific Unauthorized failure to match Django 401
    if (token == null) {
      state = AsyncError<OnboardingState>(
        const OnboardingUnauthorized("Session expired. Please log in again."),
        StackTrace.current,
      ).copyWithPrevious(AsyncData(previousData)); // Preservation
      return;
    }

    final result = await AsyncValue.guard(
      () => ref.read(uploadMediaUseCaseProvider).execute(file, token),
    );

    state = result.when(
      data: (uuid) {
        // NEW LOGIC: Save to Category License List
        if (type == 'license' && serviceId != null) {
          final updatedLicenses = previousData.categoryLicenses
              .where((l) => l.serviceId != serviceId)
              .toList();
          updatedLicenses.add(
            CategoryLicenseEntity(serviceId: serviceId, mediaUuid: uuid),
          );
          return AsyncData(
            previousData.copyWith(categoryLicenses: updatedLicenses),
          );
        }
        return AsyncData(
          previousData.copyWith(
            profilePictureUuid: type == 'profile'
                ? uuid
                : previousData.profilePictureUuid,
            cnicPictureUuid: type == 'cnic'
                ? uuid
                : previousData.cnicPictureUuid,
          ),
        );
      },
      error: (err, stack) => AsyncError<OnboardingState>(
        err,
        stack,
      ).copyWithPrevious(AsyncData(previousData)), // Preservation
      loading: () => AsyncLoading<OnboardingState>().copyWithPrevious(
        AsyncData(previousData),
      ),
    );
  }

  // --- STEP 2: SKILL MANAGEMENT ---
  void toggleSkill(int subServiceId) {
    final current = state.value!;
    final skills = List<SkillSelectionEntity>.from(current.selectedSkills);
    final index = skills.indexWhere((s) => s.subServiceId == subServiceId);

    if (index != -1) {
      skills.removeAt(index);
    } else {
      skills.add(
        SkillSelectionEntity(subServiceId: subServiceId, yearsOfExperience: 0),
      );
    }
    state = AsyncData(current.copyWith(selectedSkills: skills));
  }

  void updateSkillExperience(int subServiceId, int years) {
    final current = state.value!;
    final updated = current.selectedSkills
        .map(
          (s) => s.subServiceId == subServiceId
              ? SkillSelectionEntity(
                  subServiceId: s.subServiceId,
                  yearsOfExperience: years,
                )
              : s,
        )
        .toList();
    state = AsyncData(current.copyWith(selectedSkills: updated));
  }

  // --- NAVIGATION ---
  void nextStep() {
    final current = state.value!;
    state = AsyncData(current.copyWith(currentStep: current.currentStep + 1));
  }

  void previousStep() {
    final current = state.value!;
    if (current.currentStep > 0) {
      state = AsyncData(current.copyWith(currentStep: current.currentStep - 1));
    }
  }

  // --- PHASE 2: FINAL SUBMISSION (Terminal Pattern) ---

  Future<void> finalize() async {
    final s = state.value!;
    final user = ref.read(authenticatedUserProvider);

    if (user?.token == null) {
      state = AsyncError<OnboardingState>(
        const OnboardingUnauthorized("Session expired."),
        StackTrace.current,
      ).copyWithPrevious(AsyncData(s));
      return;
    }

    // Set local submissionStatus to loading while keeping previous draft data
    state = AsyncData(s.copyWith(submissionStatus: const AsyncLoading()));

    final result = await AsyncValue.guard(() async {
      final technician = await ref
          .read(registerTechnicianUseCaseProvider)
          .execute(
            token: user!.token!,
            firstName: s.firstName,
            lastName: s.lastName,
            profilePictureUuid: s.profilePictureUuid!,
            city: s.city,
            cnicNumber: s.cnicNumber,
            cnicPictureUuid: s.cnicPictureUuid!,
            bio: s.bio,
            experienceYears: s.experienceYears,
            categoryLicenses: s.categoryLicenses, // PASSED PERFECTLY
            skills: s.selectedSkills, // PASSED PERFECTLY
          );

      // Identity Sync: Update the Global User to reflect their new technician status
      final authNotifier = ref.read(authProvider.notifier);
      authNotifier.state = AsyncData(
        AuthState(
          user: user.copyWith(firstName: s.firstName, lastName: s.lastName),
        ),
      );

      return technician; // Returning the full Entity
    });

    // Wrap the resulting TechnicianEntity (or error) in the local status
    state = AsyncData(s.copyWith(submissionStatus: result));
  }
}

/// A simple provider that 'watches' the auth state and returns the UserEntity.
/// This allows the OnboardingNotifier to stay clean.
final authenticatedUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).value?.user;
});

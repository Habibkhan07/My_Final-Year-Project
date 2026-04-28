// lib/features/technician/onboarding/presentation/providers/onboarding_notifier.dart

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'onboarding_state.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';
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
    final services = await ref.read(getOnboardingMetadataUseCaseProvider).execute();

    // 2. Read (not watch) user info — onboarding only needs the initial value to
    //    pre-populate fields. Using ref.watch here would re-trigger build() every
    //    time authProvider settles, causing a Loading→Error flicker.
    final user = ref.read(authenticatedUserProvider);

    return OnboardingState(
      firstName: user?.firstName ?? '',
      lastName: user?.lastName ?? '',
      services: services,
    );
  }

  Future<void> fetchMetadata() async {
    state = await AsyncValue.guard(() async {
      final services = await ref.read(getOnboardingMetadataUseCaseProvider).execute();
      // .value is safe here: state may be AsyncError when Retry is pressed,
      // so we can't use requireValue (it throws on error state).
      // .value returns null for both AsyncLoading and AsyncError.
      final current = state.value;
      if (current != null) {
        return current.copyWith(services: services);
      }
      final user = ref.read(authenticatedUserProvider);
      return OnboardingState(
        firstName: user?.firstName ?? '',
        lastName: user?.lastName ?? '',
        services: services,
      );
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
    // requireValue is safer than value! because it guarantees data exists
    final current = state.requireValue; 
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

  // --- PHASE 1: MEDIA UPLOAD (Modern Riverpod v3 Pattern) ---
  Future<void> uploadDocument(XFile file, String type, {int? serviceId}) async {
    final currentData = state.requireValue;

    // AsyncValue.guard automatically preserves currentData during loading!
    state = await AsyncValue.guard(() async {
      final token = ref.read(authenticatedUserProvider)?.token;

      if (token == null) {
        throw const OnboardingUnauthorized("Session expired. Please log in again.");
      }

      final uuid = await ref.read(uploadMediaUseCaseProvider).execute(file, token);

      if (type == 'license' && serviceId != null) {
        final updatedLicenses = currentData.categoryLicenses
            .where((l) => l.serviceId != serviceId)
            .toList();
        updatedLicenses.add(CategoryLicenseEntity(serviceId: serviceId, mediaUuid: uuid));
        
        return currentData.copyWith(categoryLicenses: updatedLicenses);
      }
      
      return currentData.copyWith(
        profilePictureUuid: type == 'profile' ? uuid : currentData.profilePictureUuid,
        cnicPictureUuid: type == 'cnic' ? uuid : currentData.cnicPictureUuid,
      );
    });
  }

  // --- STEP 2: SKILL MANAGEMENT ---
  void toggleSkill(int subServiceId) {
    final current = state.requireValue;
    final skills = List<SkillSelectionEntity>.from(current.selectedSkills);
    final index = skills.indexWhere((s) => s.subServiceId == subServiceId);

    if (index != -1) {
      skills.removeAt(index);
    } else {
      skills.add(SkillSelectionEntity(subServiceId: subServiceId, yearsOfExperience: 0));
    }
    state = AsyncData(current.copyWith(selectedSkills: skills));
  }

  void updateSkillExperience(int subServiceId, int years) {
    final current = state.requireValue;
    final updated = current.selectedSkills
        .map((s) => s.subServiceId == subServiceId
            ? SkillSelectionEntity(
                subServiceId: s.subServiceId,
                yearsOfExperience: years,
                laborRate: s.laborRate,
              )
            : s)
        .toList();
    state = AsyncData(current.copyWith(selectedSkills: updated));
  }

  void updateSkillRate(int subServiceId, {String? laborRate}) {
    final current = state.requireValue;
    final updated = current.selectedSkills
        .map((s) => s.subServiceId == subServiceId
            ? SkillSelectionEntity(
                subServiceId: s.subServiceId,
                yearsOfExperience: s.yearsOfExperience,
                laborRate: laborRate ?? s.laborRate,
              )
            : s)
        .toList();
    state = AsyncData(current.copyWith(selectedSkills: updated));
  }

  // --- NAVIGATION ---
  void nextStep() {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(currentStep: current.currentStep + 1));
  }

  void previousStep() {
    final current = state.requireValue;
    if (current.currentStep > 0) {
      state = AsyncData(current.copyWith(currentStep: current.currentStep - 1));
    }
  }

  // --- PHASE 2: FINAL SUBMISSION ---
  Future<void> finalize() async {
    final s = state.requireValue;
    final user = ref.read(authenticatedUserProvider);

    if (user?.token == null) {
      // Safely insert the error directly into the sub-state without ruining the form
      state = AsyncData(s.copyWith(
        submissionStatus: AsyncError(
          const OnboardingUnauthorized("Session expired. Please log in again."), 
          StackTrace.current,
        )
      ));
      return;
    }

    // 1. Set the specific button status to Loading (keeps the rest of the form intact)
    state = AsyncData(s.copyWith(submissionStatus: const AsyncLoading()));

  // 2. Perform the network request and capture it in a guard
    final result = await AsyncValue.guard(() async {
      final technician = await ref.read(registerTechnicianUseCaseProvider).execute(
        token: user!.token!,
        firstName: s.firstName,
        lastName: s.lastName,
        profilePictureUuid: s.profilePictureUuid!,
        city: s.city,
        cnicNumber: s.cnicNumber,
        cnicPictureUuid: s.cnicPictureUuid!,
        bio: s.bio,
        experienceYears: s.experienceYears,
        categoryLicenses: s.categoryLicenses,
        skills: s.selectedSkills,
      );

      // 3. THE RIVERPOD 3 FIX: Explicit Domain Mutation
      // Tell the Auth domain to safely update the names in memory
      ref.read(authProvider.notifier).updateProfileNames(s.firstName, s.lastName);

      return technician; 
    });

    // 4. Wrap the result in the local submission status
    state = AsyncData(state.requireValue.copyWith(submissionStatus: result));
  }
}

@riverpod
UserEntity? authenticatedUser(Ref ref) {
  return ref.watch(authProvider).value?.user; 
}
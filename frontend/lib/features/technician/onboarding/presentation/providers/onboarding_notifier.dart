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
    final services = await ref
        .read(getOnboardingMetadataUseCaseProvider)
        .execute();

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
      final services = await ref
          .read(getOnboardingMetadataUseCaseProvider)
          .execute();
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

  // --- BASIC INFO + IDENTITY ---
  void updatePersonalInfo({
    String? firstName,
    String? lastName,
    String? city,
    String? cnic,
  }) {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        firstName: firstName ?? current.firstName,
        lastName: lastName ?? current.lastName,
        city: city ?? current.city,
        cnicNumber: cnic ?? current.cnicNumber,
      ),
    );
  }

  // --- WORK LOCATION ---
  void updateWorkLocation({
    required double latitude,
    required double longitude,
    String? addressLabel,
    int? radiusKm,
  }) {
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(
        baseLatitude: latitude,
        baseLongitude: longitude,
        workAddressLabel: addressLabel ?? current.workAddressLabel,
        maxTravelRadiusKm: radiusKm ?? current.maxTravelRadiusKm,
      ),
    );
  }

  // --- PHASE 1: MEDIA UPLOAD (Modern Riverpod v3 Pattern) ---
  //
  // Stores both the backend UUID (wire payload) AND the local file path
  // (in-wizard preview thumbnail). The local path lets the user see
  // what they captured and decide whether to retake.
  //
  // Concurrency: when applying the upload result we re-read
  // ``state.value`` instead of relying on the ``currentData`` captured
  // at function entry — that closes a race window where two concurrent
  // uploads (e.g. profile then CNIC) would have their second result
  // overwrite the first because the second closure's snapshot is older.
  Future<void> uploadDocument(XFile file, String type, {int? serviceId}) async {
    final token = ref.read(authenticatedUserProvider)?.token;
    if (token == null) {
      throw const OnboardingUnauthorized(
        "Session expired. Please log in again.",
      );
    }

    state = await AsyncValue.guard(() async {
      final uuid = await ref
          .read(uploadMediaUseCaseProvider)
          .execute(file, token);

      // Re-read state HERE — a concurrent upload may have shipped a
      // newer state between the function's entry and this point.
      final latest = state.value ?? state.requireValue;

      if (type == 'license' && serviceId != null) {
        final updatedLicenses = latest.categoryLicenses
            .where((l) => l.serviceId != serviceId)
            .toList();
        updatedLicenses.add(
          CategoryLicenseEntity(serviceId: serviceId, mediaUuid: uuid),
        );
        final updatedPaths = Map<int, String>.from(latest.categoryLicensePaths)
          ..[serviceId] = file.path;
        return latest.copyWith(
          categoryLicenses: updatedLicenses,
          categoryLicensePaths: updatedPaths,
        );
      }

      return latest.copyWith(
        profilePictureUuid:
            type == 'profile' ? uuid : latest.profilePictureUuid,
        profilePicturePath:
            type == 'profile' ? file.path : latest.profilePicturePath,
        cnicPictureUuid: type == 'cnic' ? uuid : latest.cnicPictureUuid,
        cnicPicturePath:
            type == 'cnic' ? file.path : latest.cnicPicturePath,
      );
    });
  }

  // --- TRADE SELECTION ---
  void toggleSkill(int subServiceId) {
    final current = state.requireValue;
    final skills = List<SkillSelectionEntity>.from(current.selectedSkills);
    final index = skills.indexWhere((s) => s.subServiceId == subServiceId);

    if (index != -1) {
      skills.removeAt(index);
    } else {
      skills.add(SkillSelectionEntity(subServiceId: subServiceId));
    }
    state = AsyncData(current.copyWith(selectedSkills: skills));
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
      state = AsyncData(
        s.copyWith(
          submissionStatus: AsyncError(
            const OnboardingUnauthorized(
              "Session expired. Please log in again.",
            ),
            StackTrace.current,
          ),
        ),
      );
      return;
    }

    // 1. Set the specific button status to Loading (keeps the rest of the form intact)
    state = AsyncData(s.copyWith(submissionStatus: const AsyncLoading()));

    // 2. Perform the network request and capture it in a guard
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
            categoryLicenses: s.categoryLicenses,
            skills: s.selectedSkills,
            baseLatitude: s.baseLatitude,
            baseLongitude: s.baseLongitude,
            maxTravelRadiusKm: s.maxTravelRadiusKm,
            workAddressLabel: s.workAddressLabel.isEmpty ? null : s.workAddressLabel,
          );

      // 3. THE RIVERPOD 3 FIX: Explicit Domain Mutation
      // Tell the Auth domain to safely update the names in memory
      ref
          .read(authProvider.notifier)
          .updateProfileNames(s.firstName, s.lastName);

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

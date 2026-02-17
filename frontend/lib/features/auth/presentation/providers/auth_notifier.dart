import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/failures/auth_failure.dart'; // Import Sealed Class
import 'auth_state.dart';
import 'dependency_injection.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    return AuthState();
  }

  Future<void> requestOtp(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(requestOtpUseCaseProvider);
      final message = await useCase.execute(phone);
      return AuthState(successMessage: message);
    });
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(verifyOtpUseCaseProvider);
      final user = await useCase.execute(phone, otp);
      return AuthState(user: user);
    });
  }

  Future<void> completeSignup(String firstName, String lastName) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(completeSignupUseCaseProvider);
      final currentUser = state.value?.user;

      // FAIL FAST: Domain Logic
      if (currentUser?.token == null) {
        // Throwing the Domain Exception instead of a String
        throw const Unauthorized(
          "Authentication token missing. Please login again.",
        );
      }

      final message = await useCase.execute(
        firstName,
        lastName,
        currentUser!.token!,
      );

      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        nameRequired: false,
      );

      return AuthState(user: updatedUser, successMessage: message);
    });
  }
}

// ... (Rest of the file remains unchanged: Providers, Timer, etc.)
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
final phoneNumberProvider = StateProvider<String>((ref) => "");
final timerProvider = StreamProvider.autoDispose<int?>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (i) => (29 - i) >= 0 ? (29 - i) : null,
  ).take(31);
});

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'dependency_injection.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  FutureOr<AuthState> build() {
    // The initial state of the provider when first accessed
    return AuthState();
  }

  Future<void> requestOtp(String phone) async {
    state = const AsyncLoading(); // Built-in loading state

    // guard() catches errors and puts them in state.error automatically
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

  // auth_notifier.dart

  Future<void> completeSignup(String firstName, String lastName) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(
        completeSignupUseCaseProvider,
      ); // You'll need to define this provider
      final currentUser = state.value?.user;

      if (currentUser?.token == null) throw "Authentication token missing.";

      final message = await useCase.execute(
        firstName,
        lastName,
        currentUser!.token!,
      );

      // Update the local user entity with the new names
      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        nameRequired: false, // Profile is now complete
      );

      return AuthState(user: updatedUser, successMessage: message);
    });
  }
}

// The new Provider definition
final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final phoneNumberProvider = StateProvider<String>((ref) => "");

// auth_notifier.dart
final timerProvider = StreamProvider.autoDispose<int?>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) {
    final count = 29 - i;
    return count >= 0 ? count : null; // Return null when finished
  }).take(31); // 30 seconds + 1 extra to emit the null value
});

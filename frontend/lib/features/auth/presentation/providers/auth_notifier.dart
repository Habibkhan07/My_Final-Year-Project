// auth_notifier.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/failures/auth_failure.dart'; 
import 'auth_state.dart';
import 'dependency_injection.dart'; 

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    // 1. Check for cached session on startup
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.getCachedUser();
    
    if (user != null) {
      return AuthState(user: user);
    }
    
    return const AuthState();
  }

  Future<void> requestOtp(String phone) async {
    if (state.isLoading) return; 

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(requestOtpUseCaseProvider);
      final message = await useCase.execute(phone);
      return AuthState(successMessage: message);
    });
  }

  Future<void> verifyOtp(String phone, String otp) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(verifyOtpUseCaseProvider);
      final user = await useCase.execute(phone, otp);
      return AuthState(user: user);
    });
  }

  Future<void> completeSignup(String firstName, String lastName) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final useCase = ref.read(completeSignupUseCaseProvider);
      final currentUser = state.value?.user;

      if (currentUser?.token == null) {
        throw const Unauthorized("Authentication token missing. Please login again.");
      }

      final message = await useCase.execute(firstName, lastName, currentUser!.token!);

      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        nameRequired: false,
      );
      
      // Update local cache with the new name info
      await repository.persistUser(updatedUser);

      return AuthState(user: updatedUser, successMessage: message);
    });
  }

  void updateProfileNames(String firstName, String lastName) async {
    final currentUser = state.value?.user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      firstName: firstName,
      lastName: lastName,
      nameRequired: false,
    );

    // Update local cache
    await ref.read(authRepositoryProvider).persistUser(updatedUser);

    state = AsyncData(
      state.requireValue.copyWith(user: updatedUser),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState());
  }
}

@riverpod
class PhoneNumber extends _$PhoneNumber {
  @override
  String build() => "";

  void updatePhone(String newPhone) {
    state = newPhone;
  }
}

@riverpod
Stream<int?> timer(Ref ref) async* {
  yield* Stream.periodic(
    const Duration(seconds: 1),
    (i) => (29 - i) >= 0 ? (29 - i) : null,
  ).take(31);
}

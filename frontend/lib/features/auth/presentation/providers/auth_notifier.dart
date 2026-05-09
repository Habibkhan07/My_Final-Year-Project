// auth_notifier.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/realtime/presentation/app_lifecycle_orchestrator.dart';
import '../../domain/failures/auth_failure.dart';
import 'auth_state.dart';
import 'dependency_injection.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    final repository = ref.read(authRepositoryProvider);
    final user = await repository.getCachedUser();

    if (user != null) {
      _scheduleBoot(user.token);
      return AuthState(user: user);
    }

    return const AuthState();
  }

  /// Fire-and-forget bridge to the realtime subsystem. Called on cold-start
  /// with a cached user and on fresh login from `verifyOtp`.
  ///
  /// Awaiting `bootAfterAuth` would stall auth state on the WS handshake —
  /// the user would sit in `AsyncLoading` for seconds on a slow network and
  /// the router would route to `/login`. Fire-and-forget instead; errors
  /// surface on `wsConnectionProvider`'s own state and via the `.catchError`
  /// log below for dev/ops visibility.
  ///
  /// Empty-string symmetry: matches `_onResumed` in the orchestrator, which
  /// treats `null || isEmpty` as "not signed in." A corrupted cache row
  /// could store `token: ""`; without this guard we'd hand an empty string
  /// to `wsConnection.connect(...)` which the backend rejects with 4001/4003.
  void _scheduleBoot(String? token) {
    if (token == null || token.isEmpty) return;
    unawaited(
      AppLifecycleOrchestrator.bootAfterAuth(ref, token).catchError((
        Object e,
        StackTrace st,
      ) {
        developer.log(
          'bootAfterAuth failed: $e',
          name: 'auth_notifier',
          stackTrace: st,
        );
      }),
    );
  }

  Future<void> requestOtp(String phone) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    try {
      final useCase = ref.read(requestOtpUseCaseProvider);
      final message = await useCase.execute(phone);
      // We MUST preserve the existing user state if it exists
      final currentUser = state.value?.user;
      state = AsyncData(AuthState(successMessage: message, user: currentUser));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    if (state.isLoading) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(verifyOtpUseCaseProvider);
      final user = await useCase.execute(phone, otp);
      _scheduleBoot(user.token);
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

    state = AsyncData(state.requireValue.copyWith(user: updatedUser));
  }

  Future<void> logout() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    // Teardown BEFORE repository.logout(): the WS disconnect side-effect
    // notifies the server to unregister the FCM device, and that POST goes
    // through the auth interceptor which reads the token from secure storage.
    // `repository.logout()` is what clears storage. Reverse the order and
    // device-unregister silently 401s, leaving stale FCM subscriptions on
    // the backend dispatching events to a phone that has logged out.
    await AppLifecycleOrchestrator.teardownOnLogout(ref);
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

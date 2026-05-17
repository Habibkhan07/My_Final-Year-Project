// auth_notifier.dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/common/domain/entities/user_entity.dart';
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
      _scheduleBoot(user);
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
  ///
  /// We pass `user.isTechnician` (not just the token) so the orchestrator
  /// can decide whether to iterate the tech-only boot-hooks registry.
  /// Reading `authProvider` inside `bootAfterAuth` would race with this
  /// `build()` / `verifyOtp` that scheduled it — the state assignment
  /// happens AFTER `_scheduleBoot` returns. Passing the value explicitly
  /// closes that race.
  void _scheduleBoot(UserEntity user) {
    final token = user.token;
    if (token == null || token.isEmpty) return;
    unawaited(
      AppLifecycleOrchestrator.bootAfterAuth(
        ref,
        token,
        isTechnician: user.isTechnician,
      ).catchError((Object e, StackTrace st) {
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

    // INVARIANT: a verify-otp call cannot dislodge a previously-resolved
    // user from state, even during the AsyncLoading window or on
    // failure. This closes the "logged-in then immediately logged out"
    // race documented in audit S-12: the OTP screen has both an
    // auto-submit (on the 6th-digit keystroke) and a manual button.
    // After the first verify lands a token, the user can still trigger
    // a second call. The backend's OTP is single-use, so a duplicate
    // verify USED to return 400 — and the previous flow's bare
    // ``state = const AsyncLoading()`` would have dropped the
    // just-acquired user mid-transition, routing them straight back to
    // /login.
    //
    // Two pieces of belt + suspenders cover this race now:
    //   1. The backend's verify-otp is idempotent within a 60-second
    //      grace window (see ``accounts.services.auth_service``).
    //   2. ``copyWithPrevious`` preserves the prior user value through
    //      the AsyncLoading transition so the router's
    //      ``user == null`` redirect never fires even if a duplicate
    //      verify is in flight and the backend's grace check happens
    //      to reject it.
    //
    // Legitimate re-verify (cached user + fresh OTP from a different
    // session, covered by bridge test A5) still works because we
    // never block the call — we only preserve the prior value.
    state = AsyncLoading<AuthState>().copyWithPrevious(state);
    final result = await AsyncValue.guard(() async {
      final useCase = ref.read(verifyOtpUseCaseProvider);
      final user = await useCase.execute(phone, otp);
      _scheduleBoot(user);
      return AuthState(user: user);
    });
    // On error, keep the prior user reachable via ``state.value`` so
    // the router stays on the OTP screen / continues to see the
    // session — the screen layer surfaces the error via its own
    // ref.listen.
    state = result.copyWithPrevious(state);
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

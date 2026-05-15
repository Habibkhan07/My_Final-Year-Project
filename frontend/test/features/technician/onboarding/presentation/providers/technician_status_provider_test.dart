import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/auth_state.dart';
import 'package:frontend/features/technician/onboarding/data/repositories/technician_status_repository_impl.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/technician_status.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/technician_status_provider.dart';

class MockStatusRepository extends Mock implements TechnicianStatusRepositoryImpl {}

/// Test-only AuthNotifier with a controllable user. Lets the test simulate
/// login → logout transitions by mutating `state` from the outside.
class _ControllableAuthNotifier extends AuthNotifier {
  _ControllableAuthNotifier(this._initialUser);
  final UserEntity? _initialUser;

  @override
  Future<AuthState> build() async => AuthState(user: _initialUser);
}

final _fakeUserA = const UserEntity(
  phone: '+923001234567',
  id: 1,
  firstName: 'A',
  lastName: 'A',
);

final _fakeUserB = const UserEntity(
  phone: '+923009999999',
  id: 2,
  firstName: 'B',
  lastName: 'B',
);

ProviderContainer _makeContainer({
  required UserEntity? initialUser,
  required MockStatusRepository repo,
}) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith(() => _ControllableAuthNotifier(initialUser)),
      technicianStatusRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late MockStatusRepository repo;

  setUp(() {
    repo = MockStatusRepository();
  });

  test('user=null short-circuits to NoProfile without calling the repository', () async {
    final container = _makeContainer(initialUser: null, repo: repo);
    // Warm the auth provider so `build` of the status provider sees the
    // resolved user (or null).
    await container.read(authProvider.future);

    final status = await container.read(technicianStatusProvider.future);

    expect(status, isA<TechnicianStatusNoProfile>());
    verifyNever(() => repo.getMyStatus());
  });

  test('user!=null calls the repository once and emits its result', () async {
    when(() => repo.getMyStatus())
        .thenAnswer((_) async => const TechnicianStatusPending());
    final container = _makeContainer(initialUser: _fakeUserA, repo: repo);
    await container.read(authProvider.future);

    final status = await container.read(technicianStatusProvider.future);

    expect(status, isA<TechnicianStatusPending>());
    verify(() => repo.getMyStatus()).called(1);
  });

  test(
    'repository error surfaces as AsyncError on the provider after refetch',
    () async {
      // Approach: prime a happy result, read once, then flip the mock to
      // error and invalidate. Polling on `hasError` rather than awaiting
      // ``.future`` avoids a Riverpod-internal disposal race when the
      // rebuilt future rejects.
      when(() => repo.getMyStatus())
          .thenAnswer((_) async => const TechnicianStatusPending());
      final container = _makeContainer(initialUser: _fakeUserA, repo: repo);
      await container.read(authProvider.future);

      // Subscription keeps the provider alive across the invalidate +
      // refetch, matching the production keepAlive contract.
      final sub = container.listen(technicianStatusProvider, (_, _) {});
      addTearDown(sub.close);

      // Happy initial read.
      final first = await container.read(technicianStatusProvider.future);
      expect(first, isA<TechnicianStatusPending>());

      // Flip the mock to async-throw on the next call.
      when(() => repo.getMyStatus())
          .thenAnswer((_) async => throw Exception('boom'));
      container.invalidate(technicianStatusProvider);

      // Poll until the rebuilt provider reaches its terminal AsyncError
      // state. Bounded so a regression hangs the test only briefly.
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (DateTime.now().isBefore(deadline)) {
        final value = container.read(technicianStatusProvider);
        if (value.hasError) {
          return; // Success — error reached.
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      fail('Provider never transitioned to AsyncError after invalidate.');
    },
  );

  test(
    'auth identity change (logout → login of a different user) refetches status',
    () async {
      when(() => repo.getMyStatus())
          .thenAnswer((_) async => const TechnicianStatusApproved());
      final container = _makeContainer(initialUser: _fakeUserA, repo: repo);
      await container.read(authProvider.future);

      // First read — first user.
      await container.read(technicianStatusProvider.future);
      verify(() => repo.getMyStatus()).called(1);

      // Simulate auth state change to a different user by replacing the
      // notifier's state. The select projection on user identity changes,
      // which invalidates the status provider's cache (keepAlive: true
      // means it sticks otherwise).
      container.read(authProvider.notifier).state =
          AsyncData(AuthState(user: _fakeUserB));

      await container.read(technicianStatusProvider.future);

      // Second user identity → second fetch.
      verify(() => repo.getMyStatus()).called(1);
    },
  );

  test(
    'auth state change to user=null collapses status to NoProfile without calling repo again',
    () async {
      when(() => repo.getMyStatus())
          .thenAnswer((_) async => const TechnicianStatusPending());
      final container = _makeContainer(initialUser: _fakeUserA, repo: repo);
      await container.read(authProvider.future);

      // First read with a real user.
      final first = await container.read(technicianStatusProvider.future);
      expect(first, isA<TechnicianStatusPending>());

      // Logout — user becomes null.
      container.read(authProvider.notifier).state =
          const AsyncData(AuthState(user: null));

      final second = await container.read(technicianStatusProvider.future);
      expect(second, isA<TechnicianStatusNoProfile>());

      // Repo called once total (for the logged-in user), not on the
      // null branch.
      verify(() => repo.getMyStatus()).called(1);
    },
  );
}

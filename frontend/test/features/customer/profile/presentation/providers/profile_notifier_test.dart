// Tests for the ProfileNotifier state machine.
//
// CLAUDE.md state-layer rule: no widget mounting, only ProviderContainer.
// Mocks the use cases (not the repo) since the notifier reads them
// directly via DI — this isolates the test to the state transitions
// the notifier itself owns.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/profile/domain/entities/customer_profile_entity.dart';
import 'package:frontend/features/customer/profile/domain/failures/profile_failure.dart';
import 'package:frontend/features/customer/profile/domain/use_cases/get_me_use_case.dart';
import 'package:frontend/features/customer/profile/domain/use_cases/update_me_use_case.dart';
import 'package:frontend/features/customer/profile/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/profile/presentation/providers/profile_notifier.dart';

class _MockGetMe extends Mock implements GetMeUseCase {}

class _MockUpdateMe extends Mock implements UpdateMeUseCase {}

class _MockAuthRepo extends Mock implements AuthRepository {}

void main() {
  late _MockGetMe mockGetMe;
  late _MockUpdateMe mockUpdateMe;
  late _MockAuthRepo mockAuthRepo;

  const tProfile = CustomerProfileEntity(
    id: 17,
    phone: '+923001234567',
    isTechnician: false,
    firstName: 'Ali',
    lastName: 'Raza',
  );

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        getMeUseCaseProvider.overrideWithValue(mockGetMe),
        updateMeUseCaseProvider.overrideWithValue(mockUpdateMe),
        // Auth: build cleanly with no cached user so the notifier's
        // call to `authProvider.notifier.updateProfileNames(...)` is a
        // safe no-op (the auth notifier early-returns when user is null).
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
    );
  }

  setUp(() {
    mockGetMe = _MockGetMe();
    mockUpdateMe = _MockUpdateMe();
    mockAuthRepo = _MockAuthRepo();

    when(() => mockAuthRepo.getCachedUser()).thenAnswer((_) async => null);
  });

  // -------------------------------------------------------------------------
  // build()
  // -------------------------------------------------------------------------

  group('build', () {
    test('resolves to AsyncData on use-case success', () async {
      when(() => mockGetMe.call()).thenAnswer((_) async => tProfile);

      final c = makeContainer();
      addTearDown(c.dispose);

      final result = await c.read(profileProvider.future);

      expect(result, tProfile);
      verify(() => mockGetMe.call()).called(1);
    });

    test('resolves to AsyncError when use case throws', () async {
      when(() => mockGetMe.call()).thenAnswer(
        (_) async {
          // Yield to the microtask queue so the build's awaited future
          // does not throw synchronously — Riverpod's state-machine
          // is happier with errors that land after one event loop tick.
          await Future<void>.delayed(Duration.zero);
          throw const ProfileNetworkFailure('offline');
        },
      );

      final c = makeContainer();
      addTearDown(c.dispose);

      // Listener pattern: capture the AsyncLoading → error transition
      // through a listener instead of awaiting `.future`, which lets
      // the build's internal future error out cleanly without
      // involving the test's own future chain.
      //
      // Riverpod surfaces a build-time throw as an `AsyncValue` whose
      // `hasError` is true; the runtime class can be either
      // `AsyncError` (settled) or `AsyncLoading` carrying the prior
      // error (still pumping). Either is correct for "the build
      // failed" — the contract the consumer relies on is
      // `state.hasError && state.error is ProfileNetworkFailure`.
      final transitions = <AsyncValue<CustomerProfileEntity>>[];
      c.listen(profileProvider, (_, next) => transitions.add(next));

      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(Duration.zero);
        if (transitions.any((s) => s.hasError)) break;
      }

      expect(transitions.last.hasError, isTrue);
      expect(transitions.last.error, isA<ProfileNetworkFailure>());
    });
  });

  // -------------------------------------------------------------------------
  // updateName()
  // -------------------------------------------------------------------------

  group('updateName', () {
    test('success: state transitions AsyncData(prev) → AsyncData(new); '
        'no AsyncLoading flash; method returns AsyncData(new)', () async {
      when(() => mockGetMe.call()).thenAnswer((_) async => tProfile);

      const updated = CustomerProfileEntity(
        id: 17,
        phone: '+923001234567',
        isTechnician: false,
        firstName: 'Hamza',
        lastName: 'Khan',
      );
      when(() => mockUpdateMe.call(
            firstName: 'Hamza',
            lastName: 'Khan',
          )).thenAnswer((_) async => updated);

      final c = makeContainer();
      addTearDown(c.dispose);

      // Wait for build.
      await c.read(profileProvider.future);

      // Capture state transitions: must NOT include an AsyncLoading
      // flash. The notifier deliberately keeps the previous data
      // visible while the PATCH is in flight (so the profile tab
      // never blanks on save). The result is surfaced via the return
      // value instead.
      final transitions = <AsyncValue<CustomerProfileEntity>>[];
      c.listen(
        profileProvider,
        (_, next) => transitions.add(next),
        fireImmediately: false,
      );

      final result = await c
          .read(profileProvider.notifier)
          .updateName(firstName: 'Hamza', lastName: 'Khan');

      // Returned value carries the new entity.
      expect(result, isA<AsyncData<CustomerProfileEntity>>());
      expect(result.value, updated);

      // State went straight from AsyncData(tProfile) to AsyncData(updated).
      // Exactly one transition; no intermediate AsyncLoading.
      expect(transitions.length, 1);
      expect(transitions.single, isA<AsyncData<CustomerProfileEntity>>());
      expect(transitions.single.value, updated);
    });

    test('failure: state STAYS at previous AsyncData; method returns '
        'AsyncError carrying the field errors map', () async {
      when(() => mockGetMe.call()).thenAnswer((_) async => tProfile);
      when(() => mockUpdateMe.call(
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          )).thenThrow(
        const ProfileServerFailure(
          'Invalid input data.',
          {'first_name': ['This field may not be blank.']},
        ),
      );

      final c = makeContainer();
      addTearDown(c.dispose);
      await c.read(profileProvider.future);

      final transitions = <AsyncValue<CustomerProfileEntity>>[];
      c.listen(
        profileProvider,
        (_, next) => transitions.add(next),
        fireImmediately: false,
      );

      final result = await c
          .read(profileProvider.notifier)
          .updateName(firstName: '', lastName: 'Khan');

      // Returned value carries the failure with the errors map intact.
      expect(result, isA<AsyncError<CustomerProfileEntity>>());
      final err = result.error;
      expect(err, isA<ProfileServerFailure>());
      expect(
        (err as ProfileServerFailure).errors['first_name'],
        isA<List<dynamic>>(),
      );

      // State did NOT transition — the profile tab keeps rendering
      // the previous data. This is the load-bearing property: a
      // failed save must not replace the tab with a full-screen error.
      expect(transitions, isEmpty);
      expect(c.read(profileProvider).value, tProfile);
    });
  });

  // -------------------------------------------------------------------------
  // refresh()
  // -------------------------------------------------------------------------

  group('refresh', () {
    test('re-invokes the use case and surfaces the new value', () async {
      const refreshed = CustomerProfileEntity(
        id: 17,
        phone: '+923001234567',
        isTechnician: false,
        firstName: 'Refreshed',
        lastName: 'User',
      );
      var callCount = 0;
      when(() => mockGetMe.call()).thenAnswer((_) async {
        callCount += 1;
        return callCount == 1 ? tProfile : refreshed;
      });

      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(profileProvider.future);
      expect(c.read(profileProvider).value, tProfile);

      await c.read(profileProvider.notifier).refresh();

      expect(c.read(profileProvider).value, refreshed);
      verify(() => mockGetMe.call()).called(2);
    });
  });
}

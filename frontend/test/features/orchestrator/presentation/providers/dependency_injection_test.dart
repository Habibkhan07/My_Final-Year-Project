// Tests for the orchestrator's DI seam — specifically the
// `bookingDetailRepository` provider's StateError invariant (#B-19).
//
// The repository requires the auth user id to derive the viewer role
// (customer vs technician). The auth-redirect guard in app_router.dart
// is supposed to prevent unauthenticated nav, but the provider is the
// belt-and-braces invariant: if anything below the router ever tries
// to construct the repo while logged out, we want a loud crash, not a
// silent miscategorization (id=0 would render the wrong primary
// action with the wrong copy).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/orchestrator/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart'
    as onboarding_di;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'bookingDetailRepository throws StateError when auth user id is null (#B-19)',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          onboarding_di.sharedPreferencesProvider.overrideWithValue(prefs),
          // Force the auth user id to null — simulates "this provider got
          // constructed without an authenticated user" (the bug we want
          // to crash on, not paper over).
          currentAuthUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      // Riverpod 3 wraps provider-construction errors in ProviderException.
      // The original StateError is the inner cause; matching on the message
      // is the most stable assertion (the wrapping type is internal).
      expect(
        () => container.read(bookingDetailRepositoryProvider),
        throwsA(
          predicate(
            (e) => e.toString().contains('authenticated user'),
            'wraps StateError mentioning authenticated user',
          ),
        ),
      );
    },
  );

  test(
    'bookingDetailRepository constructs successfully when user id is present',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          onboarding_di.sharedPreferencesProvider.overrideWithValue(prefs),
          currentAuthUserIdProvider.overrideWithValue(7),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(bookingDetailRepositoryProvider);
      expect(repo, isNotNull);
    },
  );
}

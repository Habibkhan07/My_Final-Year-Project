// Tests for `routerProvider` — specifically the `/booking/:job_id`
// route's input validation.
//
// Regression vectors (#B-44, #B-45):
//   * `/booking/abc` (non-numeric path param) used to fall back to id=0
//     and trigger a server 404 → generic "This booking does not exist."
//     The user couldn't tell a malformed link from a missing booking.
//     The bulletproof fix routes malformed input to a dedicated invalid
//     -link screen ("This link isn't a valid booking.").
//   * `/booking/0` (zero) is also rejected — booking ids are positive.
//   * `/booking/42` (valid) reaches the orchestrator screen unchanged.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'package:frontend/core/routing/app_router.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/providers/dependency_injection.dart'
    as auth_di;
import 'package:frontend/core/common/domain/entities/user_entity.dart';
import 'package:mocktail/mocktail.dart';

class _FakeAuthRepository extends Mock implements AuthRepository {}

ProviderContainer _container() {
  final repo = _FakeAuthRepository();
  // Token is empty → AuthNotifier skips bootAfterAuth (the WS handshake).
  // nameRequired=false → router redirect doesn't push us to /profile-setup.
  when(() => repo.getCachedUser()).thenAnswer(
    (_) async => const UserEntity(phone: '+923001234567', id: 7, token: ''),
  );
  return ProviderContainer(
    overrides: [
      auth_di.authRepositoryProvider.overrideWithValue(repo),
      // Empty boot-hooks registry — keeps the orchestrator's
      // app-lifecycle bridge from attempting realtime connects in tests.
      realtimeBootHooksProvider.overrideWith((ref) => const []),
    ],
  );
}

Future<void> _pumpAt(WidgetTester tester, String location) async {
  final container = _container();

  // CRITICAL: warm authProvider before reading routerProvider. The
  // router's redirect lambda checks `authProvider.value?.user`; if
  // we read the router while auth is still AsyncLoading, the redirect
  // sees `user == null` and bounces every navigation to /login. With
  // the future awaited, the redirect sees the cached UserEntity.
  await container.read(authProvider.future);

  final router = container.read(routerProvider);
  router.go(location);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(const UserEntity(phone: ''));
  });

  group('routerProvider /booking/:job_id', () {
    testWidgets('non-numeric job_id surfaces _InvalidBookingLinkScreen', (
      tester,
    ) async {
      await _pumpAt(tester, '/booking/abc');
      // `_InvalidBookingLinkScreen` is private — assert via its visible
      // surfaces (AppBar title + the explainer copy). These are stable
      // contract: changing them changes the user-facing UX.
      expect(find.text('Invalid link'), findsOneWidget);
      expect(find.text("This link isn't a valid booking."), findsOneWidget);
      // Sanity: we did NOT mount the orchestrator screen for a
      // malformed id. The orchestrator screen's app bar always reads
      // "Booking #N" — that text MUST NOT appear here.
      expect(find.textContaining('Booking #'), findsNothing);
    });

    testWidgets('job_id of 0 surfaces _InvalidBookingLinkScreen', (
      tester,
    ) async {
      // Zero is parseable but not a valid PK. The route guard rejects
      // it the same way it rejects "abc".
      await _pumpAt(tester, '/booking/0');
      expect(find.text('Invalid link'), findsOneWidget);
    });

    testWidgets('negative job_id surfaces _InvalidBookingLinkScreen', (
      tester,
    ) async {
      await _pumpAt(tester, '/booking/-3');
      expect(find.text('Invalid link'), findsOneWidget);
    });

    testWidgets('valid numeric job_id reaches the orchestrator screen', (
      tester,
    ) async {
      // Valid numeric id passes the guard. The orchestrator screen
      // mounts and immediately tries to fetch booking detail; with no
      // remote-data-source override it lands in AsyncLoading and
      // shows a spinner. The point of this test is just to confirm
      // we did NOT hit the invalid-link screen for a well-formed id.
      await _pumpAt(tester, '/booking/42');
      expect(find.text('Invalid link'), findsNothing);
      expect(find.text('Booking #42'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

// Pins down the session-1 main-isolate wiring contracts:
//
//   W1 — `navigatorKeyProvider` and `scaffoldMessengerKeyProvider` are
//        singletons (the same key instance reaches every consumer).
//   W2 — A widget tree with multiple readers receives the same key
//        instance for both keys (proves the contract holds end-to-end
//        in a real `ProviderScope`, not just a bare container).
//   W3 — Mounting `AppLifecycleOrchestrator` registers it as a
//        `WidgetsBindingObserver`. Triggering `AppLifecycleState.resumed`
//        drives `_onResumed`, which queries auth-token storage. The
//        verify on the storage read is the load-bearing assertion: if
//        `addObserver` did not run, the lifecycle dispatch is a no-op
//        and the verify fails — replaces the ad-hoc print/revert ritual
//        from earlier session drafts.
void main() {
  group('shared GlobalKey providers', () {
    test(
      'W1a — navigatorKeyProvider returns the same GlobalKey across reads',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final first = container.read(navigatorKeyProvider);
        final second = container.read(navigatorKeyProvider);

        expect(identical(first, second), isTrue);
        expect(first, isA<GlobalKey<NavigatorState>>());
      },
    );

    test('W1b — scaffoldMessengerKeyProvider returns the same GlobalKey across '
        'reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(scaffoldMessengerKeyProvider);
      final second = container.read(scaffoldMessengerKeyProvider);

      expect(identical(first, second), isTrue);
      expect(first, isA<GlobalKey<ScaffoldMessengerState>>());
    });

    testWidgets(
      'W2 — two Consumer readers in the widget tree see identical key '
      'instances for both providers',
      (tester) async {
        GlobalKey<NavigatorState>? navA;
        GlobalKey<NavigatorState>? navB;
        GlobalKey<ScaffoldMessengerState>? msgA;
        GlobalKey<ScaffoldMessengerState>? msgB;

        await tester.pumpWidget(
          ProviderScope(
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    navA = ref.watch(navigatorKeyProvider);
                    msgA = ref.watch(scaffoldMessengerKeyProvider);
                    return const SizedBox();
                  },
                ),
                Consumer(
                  builder: (context, ref, _) {
                    navB = ref.watch(navigatorKeyProvider);
                    msgB = ref.watch(scaffoldMessengerKeyProvider);
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );

        expect(
          identical(navA, navB),
          isTrue,
          reason: 'orchestrator and GoRouter must share a single navigatorKey',
        );
        expect(
          identical(msgA, msgB),
          isTrue,
          reason:
              'orchestrator and MaterialApp.router must share a single '
              'scaffoldMessengerKey',
        );
      },
    );
  });

  group('AppLifecycleOrchestrator main-isolate wiring', () {
    testWidgets('W3 — mounting registers the WidgetsBindingObserver, '
        'lifecycle.resumed drives _onResumed', (tester) async {
      // SystemEventNotifier.build() reads the persisted last-sync cursor on
      // cold start, which routes through eventLocalDataSource → SharedPrefs.
      // Mock prefs with no cursor seed.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Returning null token short-circuits _onResumed before any WS/FCM
      // calls. The verify on read() is what proves observer registration.
      final mockStorage = _MockSecureStorage();
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            eventSecureStorageProvider.overrideWith((ref) => mockStorage),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final navKey = ref.watch(navigatorKeyProvider);
              final msgKey = ref.watch(scaffoldMessengerKeyProvider);
              return AppLifecycleOrchestrator(
                navigatorKey: navKey,
                scaffoldMessengerKey: msgKey,
                child: MaterialApp(
                  navigatorKey: navKey,
                  scaffoldMessengerKey: msgKey,
                  home: const SizedBox(),
                ),
              );
            },
          ),
        ),
      );

      // Pre-condition: nothing has touched storage yet on mount alone.
      verifyNever(() => mockStorage.read(key: any(named: 'key')));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      // Two pumps: first lets the synchronous part of `_onResumed` run up
      // to the storage await; second lets the resolved Future propagate.
      await tester.pump();
      await tester.pump();

      verify(() => mockStorage.read(key: 'auth_token')).called(1);
    });
  });
}

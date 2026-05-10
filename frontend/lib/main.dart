import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'core/realtime/presentation/services/fcm_background_handler.dart';
import 'core/routing/app_router.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/technician/incoming_job_requests/presentation/widgets/incoming_job_sheet_host.dart';
import 'features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'firebase_options.dart';

/// Injectable seams used only by `test/main_app_boot_widget_test.dart`.
/// Production passes the real Firebase / FCM / SharedPreferences entry
/// points by default, so `main()` behaviour is byte-identical to the
/// pre-refactor version.
///
/// `FirebaseInitializer` returns `Future<void>` (not `Future<FirebaseApp>`)
/// so test fakes don't have to construct a `FirebaseApp` instance —
/// `bootApp` discards the return value anyway. The real initializer is
/// wrapped in `_defaultFirebaseInit` below to match the typedef.
typedef FirebaseInitializer = Future<void> Function();
typedef BgHandlerRegistrar = void Function(BackgroundMessageHandler);
typedef SharedPrefsLoader = Future<SharedPreferences> Function();

Future<void> _defaultFirebaseInit() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Builds the app's root widget. Extracted from `main()` so the widget
/// test can pump the real tree with mocked initializers and assert that
/// each load-bearing initialization step actually runs.
///
/// The original flag #7 bug — "realtime stack defined but never mounted
/// in app boot" — was invisible to every existing test precisely because
/// they bypassed `runApp` and exercised the stack via `ProviderContainer`.
/// This seam closes that gap: `test/main_app_boot_widget_test.dart`
/// passes recording fakes for `firebaseInit` / `bgHandlerRegistrar` /
/// `sharedPrefsLoader` and asserts each was invoked, so a future refactor
/// that drops any of them fails the test loudly.
///
/// Behaviour in production is identical to the previous main(): Firebase
/// init → BG handler register → SharedPreferences load → ProviderScope
/// with the prefs override → `_Bootstrap` (which mounts the orchestrator).
@visibleForTesting
Future<Widget> bootApp({
  FirebaseInitializer firebaseInit = _defaultFirebaseInit,
  BgHandlerRegistrar bgHandlerRegistrar = FirebaseMessaging.onBackgroundMessage,
  SharedPrefsLoader sharedPrefsLoader = SharedPreferences.getInstance,
}) async {
  // Initialize Firebase on the main isolate. Without this, foreground FCM
  // listeners (`onMessage`, `onMessageOpenedApp`, `getInitialMessage`) and
  // `getToken()` would crash on first use. The BG isolate also calls
  // `Firebase.initializeApp()` independently inside
  // `firebaseMessagingBackgroundHandler` — these two initializations are
  // deliberately separate (different isolates).
  await firebaseInit();

  // Register the BG handler so the OS has a Dart-side callback to invoke
  // for FCM data messages while the app is terminated. Must run before
  // `runApp`. `firebaseMessagingBackgroundHandler` is a top-level function
  // (required by FCM — instance methods are not addressable from the BG
  // isolate).
  bgHandlerRegistrar(firebaseMessagingBackgroundHandler);

  final sharedPreferences = await sharedPrefsLoader();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      // flag #19 — sanctioned core ↔ features bridge.
      // ``currentAuthUserIdProvider`` is declared in core/realtime DI as a
      // null-returning seam (core must not import features). Production
      // boot is the place that gets to wire it to the live auth state, so
      // the realtime pipeline's recipient filter compares envelope
      // ``recipient_user_id`` against the actual signed-in user id.
      // ``valueOrNull`` keeps the override null-safe before the auth
      // notifier finishes its first build (cold start before cached-user
      // load completes); the recipient filter no-ops on null exactly as
      // documented in CLAUDE.md ("Both halves must be non-null...").
      realtime_di.currentAuthUserIdProvider.overrideWith(
        // ``select`` so the override only re-runs when the id itself
        // changes — every other AsyncValue transition (loading flips,
        // unrelated AuthState mutations) is filtered out.
        (ref) =>
            ref.watch(authProvider.select((async) => async.value?.user?.id)),
      ),
    ],
    child: const _Bootstrap(),
  );
}

/// Test seam: returns the same root widget that `bootApp` wraps in its
/// `ProviderScope`. The widget tests in
/// `test/main_app_boot_widget_test.dart` need to wrap this in their own
/// `ProviderScope` so they can inject realtime/auth provider overrides
/// (`flutter_riverpod` 3.x doesn't expose its `Override` type publicly,
/// so `bootApp` can't accept additional overrides as a parameter).
@visibleForTesting
Widget buildAppRootWidget() => const _Bootstrap();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Audit S-8 (Batch D): in release mode, fail-fast if baseUrl /
  // baseWsUrl point at cleartext. Dev / profile builds remain free
  // to use http://127.0.0.1 against the Django dev server.
  AppConstants.assertReleaseSafeNetworking();
  runApp(await bootApp());
}

/// Bridges `ProviderScope` to `AppLifecycleOrchestrator`. The orchestrator
/// needs `ref` to resolve the shared navigator/messenger keys; `runApp`'s
/// `child` builder doesn't expose a `ref` synchronously.
class _Bootstrap extends ConsumerWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppLifecycleOrchestrator(
      navigatorKey: ref.watch(realtime_di.navigatorKeyProvider),
      scaffoldMessengerKey: ref.watch(realtime_di.scaffoldMessengerKeyProvider),
      child: const MyApp(),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final messengerKey = ref.watch(realtime_di.scaffoldMessengerKeyProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Technician on Demand',
      scaffoldMessengerKey: messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
      // Wraps the entire navigator with the incoming-job sheet overlay so
      // real-time job offers slide up over whatever screen the technician
      // is currently on. Mounted once at the app shell — never per-route.
      // The host is a no-op for non-technician users (their event queue
      // never receives `job_new_request` events).
      builder: (context, child) {
        return IncomingJobSheetHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

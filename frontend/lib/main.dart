import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/realtime/presentation/app_lifecycle_orchestrator.dart';
import 'core/realtime/presentation/providers/dependency_injection.dart'
    as realtime_di;
import 'core/realtime/presentation/services/fcm_background_handler.dart';
import 'core/routing/app_router.dart';
import 'features/technician/onboarding/presentation/providers/dependency_injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase on the main isolate. Without this, foreground FCM
  // listeners (`onMessage`, `onMessageOpenedApp`, `getInitialMessage`) and
  // `getToken()` would crash on first use. The BG isolate also calls
  // `Firebase.initializeApp()` independently inside
  // `firebaseMessagingBackgroundHandler` — these two initializations are
  // deliberately separate (different isolates).
  await Firebase.initializeApp();

  // Register the BG handler so the OS has a Dart-side callback to invoke
  // for FCM data messages while the app is terminated. Must run before
  // `runApp`. `firebaseMessagingBackgroundHandler` is a top-level function
  // (required by FCM — instance methods are not addressable from the BG
  // isolate).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const _Bootstrap(),
    ),
  );
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
    );
  }
}

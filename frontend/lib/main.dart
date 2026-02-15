import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Reach into your core folder for the GPS
import 'core/routing/app_router.dart';

void main() {
  // 1. ProviderScope: This MUST wrap your entire app.
  // It is the container that stores the state of all your providers.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Access the Router: We watch the routerProvider we built earlier.
    final router = ref.watch(routerProvider);

    // 3. .router Constructor: We use this specific constructor
    // to tell Flutter that GoRouter is in charge of the URL/Back Button.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Technician on Demand',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 4. Connect the Config: This links your GPS logic to the app.
      routerConfig: router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/presentation/providers/auth_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user state to check the isTechnician flag
    final user = ref.watch(authProvider.select((async) => async.value?.user));

    return Scaffold(
      appBar: AppBar(title: const Text("Customer Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, ${user?.firstName ?? 'Customer'}!"),
            const SizedBox(height: 20),

            // The Sprint 2 Trigger Button
            ElevatedButton.icon(
              onPressed: () {
                if (user != null) {
                  if (user.isTechnician) {
                    // Path A: Move to Technician Dashboard (Sprint 3)
                    // Update this path when you build the technician home screen
                    context.go('/technician/home');
                  } else {
                    // Path B: Move to Professional Onboarding
                    // FIXED: Now matches the exact route in app_router.dart
                    context.push('/technician/onboarding');
                  }
                }
              },
              icon: const Icon(Icons.handyman),
              label: Text(
                user?.isTechnician ?? false
                    ? "Switch to Technician Mode"
                    : "Become a Technician",
              ),
            ),

            const SizedBox(height: 40),

            // --- TEMPORARY DEV BUTTON (For Testing Only) ---
            // If your backend says isTechnician: true, but you still want
            // to test the UI, use this button to bypass the check.
            TextButton.icon(
              onPressed: () => context.push('/technician/onboarding'),
              icon: const Icon(Icons.bug_report, color: Colors.grey),
              label: const Text(
                "Force Open Onboarding (Dev)",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

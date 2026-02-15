import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
//import '../../features/auth/presentation/providers/auth_state.dart'; // IMPORTANT: Added this import
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/customer/home/presentation/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Accessing the user through the AsyncValue wrapper
  final user = ref.watch(authProvider.select((async) => async.value?.user));

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/otp/:phone',
        builder: (context, state) {
          final phone = state.pathParameters['phone'] ?? 'Unknown';
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],

    redirect: (context, state) {
      final path = state.matchedLocation;
      final isLoggingIn = path == '/login';
      final isVerifyingOtp = path.startsWith('/otp');
      final isSettingUpProfile = path == '/profile-setup';

      // 1. Not Logged In Logic
      if (user == null) {
        if (isLoggingIn || isVerifyingOtp) return null;
        return '/login';
      }

      // 2. Profile Setup Logic (Based on Django flag)
      if (user.nameRequired) {
        if (isSettingUpProfile) return null;
        return '/profile-setup';
      }

      // 3. Already Logged In Logic
      if (isLoggingIn || isVerifyingOtp || isSettingUpProfile) {
        return '/home';
      }

      return null;
    },
  );
});

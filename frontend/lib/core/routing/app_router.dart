import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/customer/home/presentation/screens/home_screen.dart';
import '../../features/customer/search/presentation/pages/search_page.dart';
import '../../features/customer/discovery/presentation/screens/discovery_results_screen.dart';
import '../../features/technician/onboarding/presentation/screens/onboarding_main_screen.dart';
import '../../features/technician/onboarding/presentation/screens/registration_success_screen.dart';
import '../../features/technician/onboarding/domain/entities/technician_entity.dart';
import '../../features/booking/presentation/screens/technician_profile_screen.dart';
import '../../features/customer/addresses/presentation/screens/map_picker_screen.dart';
import '../../features/technician/dashboard/presentation/screens/technician_dashboard_screen.dart';
import '../../features/technician/incoming_job_requests/presentation/screens/incoming_job_request_screen.dart';

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
      GoRoute(
        path: '/technician/onboarding',
        builder: (context, state) => const OnboardingMainScreen(),
      ),

      GoRoute(
        path: '/technician/success',
        builder: (context, state) {
          final technician = state.extra as TechnicianEntity?;
          if (technician == null) {
            return const HomeScreen();
          }
          return RegistrationSuccessScreen(technician: technician);
        },
      ),

      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      // DEBUG: direct route — replace builder with a redirect guard once the
      // "technician approved" check endpoint is wired up.
      GoRoute(
        path: '/technician/dashboard',
        builder: (context, state) => const TechnicianDashboardScreen(),
      ),
      // List-route target for `job_new_request` events. Pushed by
      // `EventUrgencyRouter` on first arrival; subsequent arrivals stay in
      // place via the list-route nav guard. The screen reads the queue from
      // `IncomingJobQueueNotifier` — `state.extra` is intentionally unused.
      GoRoute(
        path: '/technician/incoming-job-request',
        builder: (context, state) => const IncomingJobRequestScreen(),
      ),
      GoRoute(
        path: '/addresses/map-picker',
        builder: (context, state) => const MapPickerScreen(),
      ),
      GoRoute(path: '/search', builder: (context, state) => const SearchPage()),
      GoRoute(
        path: '/discovery',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Discover';
          final query = state.uri.queryParameters['query'];
          final serviceId = int.tryParse(state.uri.queryParameters['serviceId'] ?? '');
          final subServiceId = int.tryParse(state.uri.queryParameters['subServiceId'] ?? '');
          final promotionId = int.tryParse(state.uri.queryParameters['promotionId'] ?? '');
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');

          return DiscoveryResultsScreen(
            title: title,
            query: query,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
            lat: lat,
            lng: lng,
          );
        },
      ),
      GoRoute(
        path: '/technician-profile/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final serviceId = int.tryParse(state.uri.queryParameters['serviceId'] ?? '');
          final subServiceId = int.tryParse(state.uri.queryParameters['subServiceId'] ?? '');
          final promotionId = int.tryParse(state.uri.queryParameters['promotionId'] ?? '');
          final lat = double.tryParse(state.uri.queryParameters['lat'] ?? '');
          final lng = double.tryParse(state.uri.queryParameters['lng'] ?? '');

          return TechnicianProfileScreen(
            technicianId: id,
            lat: lat,
            lng: lng,
            serviceId: serviceId,
            subServiceId: subServiceId,
            promotionId: promotionId,
          );
        },
      ),
    ],

    redirect: (context, state) {
      final path = state.matchedLocation;
      final isLoggingIn = path == '/login';
      final isVerifyingOtp = path.startsWith('/otp');
      final isSettingUpProfile = path == '/profile-setup';

      if (user == null) {
        if (isLoggingIn || isVerifyingOtp) return null;
        return '/login';
      }

      if (user.nameRequired) {
        if (isSettingUpProfile) return null;
        return '/profile-setup';
      }

      if (isLoggingIn || isVerifyingOtp || isSettingUpProfile) {
        return '/home';
      }

      return null;
    },
  );
});


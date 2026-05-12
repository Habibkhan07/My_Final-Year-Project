import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/customer/bookings/presentation/screens/customer_bookings_list_screen.dart';
import '../../features/orchestrator/presentation/screens/booking_orchestrator_screen.dart';
import '../../features/customer/home/presentation/screens/home_screen.dart';
import '../../features/customer/search/presentation/pages/search_page.dart';
import '../../features/customer/discovery/presentation/screens/discovery_results_screen.dart';
import '../../features/technician/onboarding/presentation/screens/onboarding_main_screen.dart';
import '../../features/technician/onboarding/presentation/screens/registration_success_screen.dart';
import '../../features/technician/onboarding/domain/entities/technician_entity.dart';
import '../../features/booking/presentation/screens/technician_profile_screen.dart';
import '../../features/customer/addresses/presentation/screens/map_picker_screen.dart';
import '../../features/technician/dashboard/presentation/screens/technician_dashboard_screen.dart';
import '../../features/technician/wallet/presentation/screens/wallet_screen.dart';
import '../realtime/presentation/providers/dependency_injection.dart';

// DEBUG — remove in end-of-UI cleanup pass. Controls where the post-auth
// redirect lands so two `flutter run -d chrome` tabs can sit on opposite
// sides of the same booking from a single dev_panel session:
//
//   flutter run -d chrome                                      → /home
//   flutter run -d chrome --dart-define=START_AS=technician    → /technician/dashboard
//
// String.fromEnvironment makes the value a compile-time const so unused
// branches tree-shake out of release builds.
const String _kStartAs = String.fromEnvironment('START_AS');
const String _kPostAuthLanding = _kStartAs == 'technician'
    ? '/technician/dashboard'
    : '/home';

final routerProvider = Provider<GoRouter>((ref) {
  // Accessing the user through the AsyncValue wrapper
  final user = ref.watch(authProvider.select((async) => async.value?.user));
  final navigatorKey = ref.watch(navigatorKeyProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
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
      // Note: `job_new_request` events do NOT have a route. They surface
      // via `IncomingJobSheetHost` (a global bottom-sheet overlay mounted
      // at the app shell) which watches `IncomingJobQueueNotifier`. The
      // sheet host is presentation; the queue notifier is state — together
      // they replace the previous router-pushed screen + list-route guard
      // pattern with a single state-driven surface.
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
          final serviceId = int.tryParse(
            state.uri.queryParameters['serviceId'] ?? '',
          );
          final subServiceId = int.tryParse(
            state.uri.queryParameters['subServiceId'] ?? '',
          );
          final promotionId = int.tryParse(
            state.uri.queryParameters['promotionId'] ?? '',
          );
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
      // Orchestrator screen — audience-shared (customer + technician).
      // Closes flag #26: this is the real detail UI that replaces the
      // pre-orchestrator placeholder at `/customer/booking/:job_id`.
      // Realtime banners and high-urgency events route here via
      // `EventUrgencyRouter`'s `:job_id` substitution.
      GoRoute(
        path: '/booking/:job_id',
        name: 'booking_orchestrator',
        builder: (context, state) {
          // Malformed job_id (e.g. /booking/abc from a typo'd deep link)
          // would silently fall back to 0 and trigger a server 404 →
          // generic "This booking does not exist." The user has no way
          // to tell whether the booking really vanished or the link was
          // bad. Surface an explicit invalid-link screen instead so the
          // distinction is clear and the back button is obvious.
          final raw = state.pathParameters['job_id'];
          final id = raw == null ? null : int.tryParse(raw);
          if (id == null || id <= 0) {
            return const _InvalidBookingLinkScreen();
          }
          return BookingOrchestratorScreen(jobId: id);
        },
      ),
      // My Bookings list. Primary surface is the home shell's bottom-nav
      // tab; this route exists for deep links (FCM "View your bookings"
      // notification taps, in-app /customer/bookings push) — when reached
      // directly we show the back arrow so the user can pop back.
      GoRoute(
        path: '/customer/bookings',
        builder: (context, state) =>
            const CustomerBookingsListScreen(showBackButton: true),
      ),
      // Placeholder destinations for low-urgency banner taps. The
      // realtime urgency router maps `chatMessage`/`paymentReceived`/
      // `walletLowBalance` to `/shared/chat` and `/shared/wallet`,
      // but the chat + wallet features ship in a future sprint. A
      // tap onto an unregistered route would throw GoRouter's "no
      // routes for location" error and either crash or surface a
      // navigator 404. Until the feature ships, render a "coming
      // soon" placeholder so the banner is harmless and informative.
      GoRoute(
        path: '/shared/chat',
        builder: (context, state) =>
            const _ComingSoonScreen(title: 'Chat', tag: 'chat'),
      ),
      GoRoute(
        path: '/shared/wallet',
        builder: (context, state) =>
            const _ComingSoonScreen(title: 'Wallet', tag: 'wallet'),
      ),
      // Real tech-only Wallet screen. The dashboard pill pushes here.
      // /shared/wallet (above) is kept as a no-link deadlink for any
      // legacy banner taps; the wallet event banner View button is
      // already suppressed by the urgency router (Bug 2 fix).
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/technician-profile/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final serviceId = int.tryParse(
            state.uri.queryParameters['serviceId'] ?? '',
          );
          final subServiceId = int.tryParse(
            state.uri.queryParameters['subServiceId'] ?? '',
          );
          final promotionId = int.tryParse(
            state.uri.queryParameters['promotionId'] ?? '',
          );
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
        return _kPostAuthLanding;
      }

      return null;
    },
  );
});

/// Surface for malformed `/booking/<not-a-number>` deep links. Distinct
/// from the orchestrator's "Not found" failure UI so the user can tell a
/// bad link from a missing booking — and reach Home with the visible
/// back-arrow without bouncing through a server 404.
class _InvalidBookingLinkScreen extends StatelessWidget {
  const _InvalidBookingLinkScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Invalid link')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 56, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                "This link isn't a valid booking.",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The booking id is missing or malformed. Try opening the booking from your bookings list instead.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => GoRouter.of(context).go('/home'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder destination for low-urgency event banners whose feature
/// (chat, wallet) hasn't shipped yet. The realtime banner is otherwise
/// dead-end and tapping it would crash `GoRouter` with
/// "no routes for location". This makes the tap a no-op + soft notice.
class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title, required this.tag});

  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tag == 'wallet' ? Icons.account_balance_wallet_outlined : Icons.chat_bubble_outline,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '$title is coming soon.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "We're rolling this out in a future update.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => GoRouter.of(context).go('/home'),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

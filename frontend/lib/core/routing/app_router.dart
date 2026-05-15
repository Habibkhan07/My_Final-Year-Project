import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_notifier.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/customer/bookings/presentation/screens/customer_bookings_list_screen.dart';
import '../../features/customer/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/orchestrator/presentation/screens/booking_orchestrator_screen.dart';
import '../../features/customer/home/presentation/screens/home_screen.dart';
import '../../features/customer/search/presentation/pages/search_page.dart';
import '../../features/customer/discovery/presentation/screens/discovery_results_screen.dart';
import '../../features/technician/onboarding/presentation/screens/onboarding_main_screen.dart';
import '../../features/technician/onboarding/presentation/screens/pending_approval_screen.dart';
import '../../features/technician/onboarding/presentation/screens/registration_success_screen.dart';
import '../../features/technician/onboarding/presentation/providers/technician_status_provider.dart';
import '../../features/technician/onboarding/domain/entities/technician_entity.dart';
import '../../features/technician/onboarding/domain/entities/technician_status.dart';
import '../../features/booking/presentation/screens/technician_profile_screen.dart';
import '../../features/customer/addresses/presentation/screens/map_picker_screen.dart';
import '../../features/technician/dashboard/presentation/screens/technician_dashboard_screen.dart';
import '../../features/technician/metrics/presentation/screens/metrics_screen.dart';
import '../../features/technician/wallet/presentation/screens/wallet_screen.dart';
import '../../features/technician/wallet/presentation/screens/withdrawal_history_screen.dart';
import '../realtime/presentation/providers/dependency_injection.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Accessing the user through the AsyncValue wrapper
  final user = ref.watch(authProvider.select((async) => async.value?.user));
  // Status is `AsyncValue<TechnicianStatus>`. We read .value here so the
  // redirect closure has the resolved status (or `null` while in flight).
  // The provider itself is `keepAlive: true`, so the fetch happens once
  // per login and re-runs only on explicit invalidate or auth change.
  final statusAsync = ref.watch(technicianStatusProvider);
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

      // Holding screen for PENDING / REJECTED technicians. The screen
      // watches `technicianStatusProvider` itself and renders the right
      // variant (loading shim, error+retry, pending, rejected). Routing
      // an APPROVED or NoProfile user here is a no-op — the redirect
      // below bounces them out on the next nav.
      GoRoute(
        path: '/technician/pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
      // Dispute chatbot — full-screen, persona-scoped to a single
      // booking. Pushed from the booking detail screen's "File a
      // dispute" action (visible on COMPLETED / COMPLETED_INSPECTION_ONLY
      // per the `show_dispute_button` server flag). Malformed bookingId
      // falls back to the invalid-link screen for the same reason
      // `/booking/:job_id` does — typo'd deep links should be visible.
      GoRoute(
        path: '/customer/bookings/:bookingId/dispute-chat',
        builder: (context, state) {
          final raw = state.pathParameters['bookingId'];
          final id = raw == null ? null : int.tryParse(raw);
          if (id == null || id <= 0) {
            return const _InvalidBookingLinkScreen();
          }
          return ChatbotScreen(personaKey: 'dispute', bookingId: id);
        },
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
      // Tech-only withdrawal request history. Pushed from the
      // wallet screen's "View withdrawal history" link and from the
      // PendingWithdrawalStrip tap.
      GoRoute(
        path: '/withdrawals/history',
        builder: (context, state) => const WithdrawalHistoryScreen(),
      ),
      // Tech-only Metrics screen. Reached from the bottom-nav "Metrics" tab.
      GoRoute(
        path: '/technician/metrics',
        builder: (context, state) => const MetricsScreen(),
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
      final isApplyingAsTech = path == '/technician/onboarding' ||
          path == '/technician/success';
      final isOnHoldingScreen = path == '/technician/pending';

      if (user == null) {
        if (isLoggingIn || isVerifyingOtp) return null;
        return '/login';
      }

      if (user.nameRequired) {
        if (isSettingUpProfile) return null;
        return '/profile-setup';
      }

      // Status is either AsyncLoading-no-value or AsyncError-no-value.
      // Choose the least-wrong placement using the cached
      // `user.isTechnician` flag from the auth payload:
      //  - real tech → holding screen (it owns retry + spinner UI)
      //  - pure customer → /home (status will resolve on next nav)
      // This eliminates the prior "land on /home, then flick to
      // /technician/pending after fetch resolves" jitter.
      if (!statusAsync.hasValue) {
        if (user.isTechnician) {
          if (isOnHoldingScreen || isApplyingAsTech) return null;
          return '/technician/pending';
        }
        if (isLoggingIn || isVerifyingOtp || isSettingUpProfile) {
          return '/home';
        }
        return null;
      }

      final statusValue = statusAsync.value!;

      // PENDING → holding screen, no reapply allowed. The backend
      // service raises 409 `duplicate_application` if a PENDING user
      // re-submits, so letting them re-enter the onboarding wizard
      // just leads to a wasted form fill.
      if (statusValue is TechnicianStatusPending) {
        if (isOnHoldingScreen) return null;
        // /technician/success is the post-finalize landing page —
        // also let it through so the success screen can render once
        // before redirecting away on the next nav.
        if (path == '/technician/success') return null;
        return '/technician/pending';
      }

      // REJECTED → holding screen, with reapply allowed. The backend
      // resets the existing row in place on finalize, so the wizard
      // is a legitimate exit. /technician/success is allowed for the
      // same reason as above.
      if (statusValue is TechnicianStatusRejected) {
        if (isOnHoldingScreen || isApplyingAsTech) return null;
        return '/technician/pending';
      }

      // Approved technicians: bounce auth/setup paths to the tech surface.
      if (statusValue is TechnicianStatusApproved) {
        if (isLoggingIn ||
            isVerifyingOtp ||
            isSettingUpProfile ||
            isOnHoldingScreen) {
          return '/technician/dashboard';
        }
        return null;
      }

      // NoProfile → customer flow.
      if (isLoggingIn ||
          isVerifyingOtp ||
          isSettingUpProfile ||
          isOnHoldingScreen) {
        return '/home';
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

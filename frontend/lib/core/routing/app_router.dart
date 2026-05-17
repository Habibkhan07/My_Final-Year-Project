import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/domain/entities/user_entity.dart';
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
import '../../features/technician/onboarding/presentation/providers/technician_status_provider.dart';
import '../../features/technician/onboarding/domain/entities/technician_status.dart';
import '../../features/booking/presentation/screens/technician_profile_screen.dart';
import '../../features/customer/addresses/presentation/screens/map_picker_screen.dart';
import '../../features/customer/profile/presentation/screens/about_karigar_screen.dart';
import '../../features/customer/profile/presentation/screens/customer_addresses_screen.dart';
import '../../features/customer/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/customer/profile/presentation/screens/terms_and_privacy_screen.dart';
import '../../features/technician/dashboard/presentation/screens/technician_dashboard_screen.dart';
import '../../features/technician/work_location/presentation/screens/work_location_picker_screen.dart';
import '../../features/technician/metrics/presentation/screens/metrics_screen.dart';
import '../../features/technician/profile/presentation/screens/add_skill_screen.dart';
import '../../features/technician/profile/presentation/screens/my_skills_screen.dart';
import '../../features/technician/profile/presentation/screens/technician_profile_tab_screen.dart';
import '../../features/technician/schedule/presentation/screens/schedule_screen.dart';
import '../../features/technician/wallet/presentation/screens/wallet_screen.dart';
import '../../features/technician/wallet/presentation/screens/withdrawal_history_screen.dart';
import '../realtime/presentation/providers/dependency_injection.dart';

/// Bridges Riverpod state changes (auth, tech status) to go_router's
/// `refreshListenable` so the redirect re-evaluates on every change
/// WITHOUT rebuilding [routerProvider] itself. Rebuilding the provider
/// would recreate the [GoRouter] instance, which forces a navigation
/// to `initialLocation: '/login'` and resets the route stack — that
/// caused the post-finalize "user stranded on /login" bug AND the
/// "Refresh on PendingApprovalScreen kicks the user back to /home" bug
/// (2026-05-17). With this notifier the same GoRouter persists across
/// the entire session; only the redirect closure re-runs.
class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  // ref.read (not watch): navigatorKeyProvider returns a stable
  // GlobalKey for the session — watching would needlessly rebuild this
  // provider if the key were ever recreated.
  final navigatorKey = ref.read(navigatorKeyProvider);

  // Wake the refresh notifier whenever auth or tech-status changes.
  // ref.listen does NOT cause this provider to rebuild — it only
  // triggers the side effect, which calls `notifyListeners` on the
  // notifier passed to GoRouter.refreshListenable. The GoRouter
  // instance therefore stays stable; only the redirect re-evaluates.
  final refresh = _RouterRefreshNotifier();
  ref.listen<UserEntity?>(
    authProvider.select((async) => async.value?.user),
    (prev, next) => refresh.refresh(),
  );
  ref.listen<AsyncValue<TechnicianStatus>>(
    technicianStatusProvider,
    (prev, next) {
      refresh.refresh();
      // Explicit navigation on status transitions. go_router's
      // refreshListenable re-evaluates the redirect but does not
      // reliably navigate to its return value (observed on go_router
      // 17.1.0). For state-driven transitions where the user MUST be
      // moved off their current screen (e.g. tech just got approved
      // and is sitting on the holding screen), drive the navigation
      // explicitly via the global navigator key.
      final prevStatus = prev?.value;
      final newStatus = next.value;
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      // PENDING → APPROVED: jump straight to the tech dashboard.
      // Suppress when already approved on the prev side so subsequent
      // refresh-of-Approved doesn't yank the user out of wherever they
      // navigated to.
      if (newStatus is TechnicianStatusApproved &&
          prevStatus is! TechnicianStatusApproved) {
        ctx.go('/technician/dashboard');
        return;
      }
      // APPROVED → REJECTED (admin revoked): bounce to holding screen.
      if (newStatus is TechnicianStatusRejected &&
          prevStatus is! TechnicianStatusRejected) {
        ctx.go('/technician/pending');
        return;
      }
    },
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    refreshListenable: refresh,
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

      // /technician/success used to land on a separate RegistrationSuccessScreen
      // and then bounce the user to /technician/pending. The two screens
      // were collapsed in 2026-05-17 — both routes now render the unified
      // PendingApprovalScreen with brand-consistent UI. The success route
      // is preserved so onboarding_main_screen's existing
      // ``context.go('/technician/success', ...)`` keeps working without
      // a wizard edit; onboarding's submit handler invalidates
      // ``technicianStatusProvider`` before navigating so the screen
      // reads the freshly-PENDING status on first frame instead of the
      // stale ``NoProfile`` cached before finalize.
      GoRoute(
        path: '/technician/success',
        builder: (context, state) =>
            const PendingApprovalScreen(justSubmitted: true),
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
      // ----------------------------------------------------------------
      // Customer profile feature — pushed from Profile tab.
      // ----------------------------------------------------------------
      GoRoute(
        path: '/customer/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/customer/addresses',
        builder: (context, state) => const CustomerAddressesScreen(),
      ),
      GoRoute(
        path: '/customer/about',
        builder: (context, state) => const AboutKarigarScreen(),
      ),
      GoRoute(
        path: '/customer/legal',
        builder: (context, state) => const TermsAndPrivacyScreen(),
      ),
      GoRoute(
        path: '/technician/work-location',
        builder: (context, state) => const WorkLocationPickerScreen(),
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
      // Tech-only Schedule screen. Reached from the bottom-nav
      // "Schedule" tab. Audience-flipped counterpart of /customer/bookings.
      GoRoute(
        path: '/technician/schedule',
        builder: (context, state) =>
            const ScheduleScreen(showBackButton: true),
      ),
      // Tech profile tab — pushed from bottom-nav "Profile" tap on the
      // dashboard. Mirrors the customer profile tab's visual language;
      // the /skills child routes own the CRUD surface.
      GoRoute(
        path: '/technician/profile',
        builder: (context, state) => const TechnicianProfileTabScreen(),
      ),
      GoRoute(
        path: '/technician/profile/skills',
        builder: (context, state) => const MySkillsScreen(),
      ),
      GoRoute(
        path: '/technician/profile/skills/add',
        builder: (context, state) => const AddSkillScreen(),
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
      // Read CURRENT auth + status values inside the redirect closure.
      // Closure-captured values would go stale because this GoRouter is
      // long-lived (built once, refreshed via _RouterRefreshNotifier).
      final user = ref.read(authProvider).value?.user;
      final statusAsync = ref.read(technicianStatusProvider);
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

      // PENDING → holding screen by default, but the user may freely
      // browse the customer surface while waiting (they're still a
      // customer too — unified User model). Only ``/technician/...``
      // routes get bounced back to the holding screen.
      //
      // The backend service raises 409 ``duplicate_application`` if a
      // PENDING user re-submits, so letting them re-enter the
      // onboarding wizard would just lead to a wasted form fill;
      // that path still redirects.
      if (statusValue is TechnicianStatusPending) {
        if (isOnHoldingScreen) return null;
        // /technician/success is the post-finalize landing page —
        // also let it through so the holding screen can render
        // once with the freshly-PENDING status before any further nav.
        if (path == '/technician/success') return null;
        // A logged-in user must never land on the auth surface. The
        // routerProvider rebuilds whenever authProvider/statusAsync
        // change, and the new `GoRouter` starts at `initialLocation:
        // '/login'`; without this guard the relaxation below would
        // allow /login through and strand the user on the auth screen
        // even though their session is alive.
        if (isLoggingIn || isVerifyingOtp || isSettingUpProfile) return '/home';
        // Customer-side routes are fine. Only tech routes redirect.
        if (!path.startsWith('/technician/')) return null;
        return '/technician/pending';
      }

      // REJECTED → same shape as PENDING but with re-apply allowed.
      // The backend resets the existing row in place on finalize, so
      // the wizard is a legitimate exit.
      if (statusValue is TechnicianStatusRejected) {
        if (isOnHoldingScreen || isApplyingAsTech) return null;
        // Same auth-surface guard as the PENDING branch above.
        if (isLoggingIn || isVerifyingOtp || isSettingUpProfile) return '/home';
        if (!path.startsWith('/technician/')) return null;
        return '/technician/pending';
      }

      // Approved technicians: bounce auth/setup paths AND the
      // onboarding wizard / post-submit success route to the tech
      // surface. ``isApplyingAsTech`` covers both ``/technician/onboarding``
      // and ``/technician/success`` — without it, a freshly-approved
      // tech who taps Refresh on the PendingApprovalScreen (rendered
      // at /technician/success) would stay put rendering a loading shim
      // (the screen treats Approved as transient), AND tapping
      // "Technician Mode" from the customer profile while the cached
      // ``user.isTechnician`` is still ``false`` would land them back
      // in the wizard.
      if (statusValue is TechnicianStatusApproved) {
        if (isLoggingIn ||
            isVerifyingOtp ||
            isSettingUpProfile ||
            isOnHoldingScreen ||
            isApplyingAsTech) {
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

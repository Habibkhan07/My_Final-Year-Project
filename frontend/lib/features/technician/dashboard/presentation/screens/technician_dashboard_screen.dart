import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/failures/technician_dashboard_failure.dart';
import '../notifiers/technician_dashboard_notifier.dart';
import '../providers/current_position_provider.dart';
import '../state/technician_dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/later_today_list.dart';
import '../widgets/lockout_banner.dart';
import '../widgets/up_next_job_card.dart';
import '../widgets/work_location_banner.dart';

class TechnicianDashboardScreen extends ConsumerWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surfaces toggle errors as a snackbar without triggering a full rebuild.
    // Only fires on the transition to AsyncError — not on every state change.
    ref.listen<AsyncValue<TechnicianDashboardState>>(
      technicianDashboardProvider,
      (prev, next) {
        final wasError = prev?.value?.toggleStatus is AsyncError;
        final isError = next.value?.toggleStatus is AsyncError;
        if (!wasError && isError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Status update failed. Please try again.'),
                backgroundColor: AppColors.error,
              ),
            );
        }
      },
    );

    final dashboardAsync = ref.watch(technicianDashboardProvider);
    final notifier = ref.read(technicianDashboardProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardAsync.when(
        loading: () {
          // If cached data is available during a background refresh, show the
          // full UI silently rather than flashing a skeleton.
          final cached = dashboardAsync.value;
          if (cached != null) {
            return _DashboardLayout(state: cached, notifier: notifier);
          }
          return const _DashboardSkeleton();
        },
        error: (error, _) =>
            _ErrorState(error: error, onRetry: notifier.refresh),
        data: (state) => _DashboardLayout(state: state, notifier: notifier),
      ),
      bottomNavigationBar: const _DashboardNavBar(),
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded layout — scroll content (header + up next + later today)
// ---------------------------------------------------------------------------

class _DashboardLayout extends ConsumerWidget {
  const _DashboardLayout({required this.state, required this.notifier});
  final TechnicianDashboardState state;
  final TechnicianDashboardNotifier notifier;

  Future<void> _onRefresh(WidgetRef ref) async {
    // Pull-to-refresh forces both a fresh dashboard fetch and a fresh GPS
    // fix — otherwise "X km away" would stay frozen for up to 5 minutes.
    ref.read(currentPositionProvider.notifier).invalidateCache();
    await notifier.refresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = state.dashboard;

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      color: AppColors.primaryContainer,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  dashboard: dashboard,
                  isToggleLoading: state.toggleStatus.isLoading,
                  isLocked: LockoutBanner.isLocked(dashboard.walletBalance),
                  onToggle: notifier.setOnline,
                ),
                // Lockout banner — only renders when wallet balance is
                // negative. Sits between the header (with disabled toggle)
                // and the up-next card so the tech sees BOTH the disabled
                // online pill AND the explainer copy on the same screen.
                if (LockoutBanner.isLocked(dashboard.walletBalance)) ...[
                  const SizedBox(height: AppSpacing.s3),
                  LockoutBanner(walletBalance: dashboard.walletBalance),
                ],
                // Work-location banner — gates discovery. Self-hiding
                // (renders as a quiet summary row once set), so it stays
                // useful as a re-edit affordance after the tech sets it.
                const SizedBox(height: AppSpacing.s2),
                WorkLocationBanner(
                  hasWorkLocation: dashboard.hasWorkLocation,
                  workAddressLabel: dashboard.workAddressLabel,
                ),
                const SizedBox(height: AppSpacing.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: UpNextJobCard(job: dashboard.upNextJob),
                ),
                const SizedBox(height: AppSpacing.s4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: LaterTodayList(jobs: dashboard.laterTodayJobs),
                ),
                const SizedBox(height: AppSpacing.s4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loader — mirrors the new layout, no FIELD_OPS block
// ---------------------------------------------------------------------------

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerHigh,
      highlightColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _ShimmerBox(height: 40, width: 40, radius: 20),
                    const SizedBox(width: 12),
                    Expanded(child: _ShimmerBox(height: 16, radius: 4)),
                    const SizedBox(width: 8),
                    const _ShimmerBox(
                      height: 26,
                      width: 70,
                      radius: AppShapes.radiusFull,
                    ),
                    const SizedBox(width: 8),
                    const _ShimmerBox(
                      height: 26,
                      width: 90,
                      radius: AppShapes.radiusFull,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                _ShimmerBox(height: 380, radius: AppShapes.radiusMD),
                const SizedBox(height: AppSpacing.s4),
                _ShimmerBox(height: 16, width: 100, radius: 4),
                const SizedBox(height: AppSpacing.s2),
                _ShimmerBox(height: 80, radius: AppShapes.radiusMD),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height, this.width, required this.radius});
  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      DashboardNetworkFailure() =>
        'No internet connection. Pull down to retry.',
      DashboardPermissionFailure() =>
        'You do not have permission to access the technician dashboard.',
      DashboardParsingFailure() =>
        'Could not read dashboard data. Please retry.',
      DashboardServerFailure(:final message) => message,
      _ => 'Something went wrong. Please retry.',
    };

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppShapes.radiusXL),
                  ),
                  minimumSize: const Size(160, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surfaceContainerLowest,
      selectedItemColor: AppColors.primaryContainer,
      unselectedItemColor: AppColors.outline,
      currentIndex: 0,
      elevation: 0,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      // Index 0 (Jobs) is the dashboard itself — no-op. Schedule,
      // Metrics, and Profile push their dedicated routes.
      onTap: (index) {
        if (index == 1) context.push('/technician/schedule');
        if (index == 2) context.push('/technician/metrics');
        if (index == 3) context.push('/technician/profile');
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.handyman_outlined),
          activeIcon: Icon(Icons.handyman),
          label: 'Jobs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Metrics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

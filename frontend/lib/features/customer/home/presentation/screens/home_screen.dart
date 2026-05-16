import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../addresses/presentation/providers/dependency_injection.dart';
import '../../../addresses/presentation/widgets/address_selector_sheet.dart';
import '../../../bookings/presentation/screens/customer_bookings_list_screen.dart';
import '../../../help/presentation/screens/help_screen.dart';
import '../../../profile/presentation/screens/profile_tab_screen.dart';
import '../../domain/failures/home_failure.dart';
import '../providers/current_tab_notifier.dart';
import '../providers/home_notifier.dart';
import '../providers/home_state.dart';
import '../widgets/category_grid.dart';
import '../widgets/fixed_gig_carousel.dart';
import '../widgets/home_skeleton_loader.dart';
import '../widgets/location_required_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/promo_banner_slider.dart';
import '../widgets/technician_carousel.dart';

/// Customer-side bottom-nav shell.
///
/// Lazy `IndexedStack`: tabs are built on first visit and kept mounted
/// after that. Scroll position, Riverpod state, and any in-flight async
/// work survive tab switches once a tab has been activated.
///
/// **Why not the standard eager IndexedStack:** the Help tab opens a
/// chatbot conversation on mount (its notifier's `build()` POSTs to
/// `/api/chat/general/start/`). Eager mounting would fire that network
/// call on every Home open — burning a backend conversation row even
/// for customers who never tap Help, and timing out widget tests that
/// don't override the chatbot data source.
///
/// Tabs:
///   0. Home feed (services, promos, top technicians)
///   1. Bookings (My Bookings list — `CustomerBookingsListScreen`)
///   2. Help     (AI chatbot — `general` persona of the chatbot framework)
///   3. Profile  (`ProfileTabScreen` — name, addresses, Technician Mode,
///               About, Sign out)
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Track which tabs the user has actually visited. Home (0) is always
  // visited on first build; others get added when their index becomes
  // the active tab via `ref.listen` below.
  final Set<int> _visited = <int>{0};

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(currentCustomerTabProvider);

    // Mark a tab as visited the first time it becomes active.
    ref.listen<int>(currentCustomerTabProvider, (_, next) {
      if (_visited.add(next)) setState(() {});
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: tab,
        children: [
          _visited.contains(0) ? const _HomeFeedTab() : const SizedBox.shrink(),
          _visited.contains(1)
              ? const CustomerBookingsListScreen()
              : const SizedBox.shrink(),
          _visited.contains(2) ? const HelpScreen() : const SizedBox.shrink(),
          _visited.contains(3)
              ? const ProfileTabScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _BottomNav(),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(currentCustomerTabProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceContainerLowest,
          elevation: 0,
          selectedItemColor: AppColors.primaryContainer,
          unselectedItemColor: AppColors.outline,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          currentIndex: tab,
          onTap: (i) => ref.read(currentCustomerTabProvider.notifier).set(i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent_outlined),
              activeIcon: Icon(Icons.support_agent),
              label: 'Help',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home feed tab — extracted from the previous HomeScreen body
// ---------------------------------------------------------------------------

class _HomeFeedTab extends ConsumerWidget {
  const _HomeFeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeProvider);

    return SafeArea(
      child: homeStateAsync.when(
        data: (state) => _buildContent(context, ref, state, false),
        error: (error, stack) {
          final state = homeStateAsync.value;
          // Tier 2 Cache Rule: If we have data but hit an error, show offline mode
          if (state?.homeFeed != null) {
            return _buildContent(context, ref, state!, true);
          }
          return _buildErrorState(context, ref, error);
        },
        loading: () {
          final state = homeStateAsync.value;
          if (state?.homeFeed != null) {
            // Refreshing silently in background
            return _buildContent(context, ref, state!, false);
          }
          return const HomeSkeletonLoader();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
    bool isOffline,
  ) {
    final feed = state.homeFeed;
    if (feed == null) return const SizedBox.shrink();

    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final hasAddress = defaultAddressAsync.value != null;

    return Column(
      children: [
        if (isOffline)
          OfflineBanner(
            onRetry: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
          ),

        // App Bar / Header — location selector only. The notification
        // bell that used to live here was a no-op stub: empty onPressed,
        // hardcoded red unread dot, no notification-list screen behind
        // it. The realtime event architecture (`SystemEventNotifier` for
        // in-app, FCM for backgrounded) is the canonical notification
        // surface, so a fake bell adds no functionality and reads as
        // dishonest UX.
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: _LocationHeader(),
        ),

        // Scrollable Body
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (!hasAddress) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AddressSelectorSheet(),
                          );
                          return;
                        }
                        context.push('/search');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText:
                                  'Try "AC not cooling" or "Leaky pipe"...',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Colors.blue),
                              suffixIcon: Icon(Icons.tune, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  PromoBannerSlider(promotions: feed.promotions),
                  const SizedBox(height: 24),

                  CategoryGrid(categories: feed.categories),
                  const SizedBox(height: 32),

                  FixedGigCarousel(fixedGigs: feed.fixedGigs),
                  const SizedBox(height: 32),

                  if (hasAddress)
                    TechnicianCarousel(technicians: feed.topTechnicians)
                  else
                    const LocationRequiredCard(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    String errorMessage = 'An unexpected error occurred.';
    if (error is HomeFailure) {
      errorMessage = switch (error) {
        HomeNetworkFailure() =>
          'No internet connection. Please check your settings.',
        HomeServerFailure(message: final msg) => msg,
        HomeParsingFailure() => 'Failed to load feed data correctly.',
      };
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Location Header — watches defaultAddressProvider and opens AddressSelectorSheet
// ---------------------------------------------------------------------------

class _LocationHeader extends ConsumerWidget {
  const _LocationHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defaultAddressAsync = ref.watch(defaultAddressProvider);

    return InkWell(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddressSelectorSheet(),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Location',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue.shade700, size: 18),
                const SizedBox(width: 4),
                defaultAddressAsync.when(
                  loading: () => const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF0051AE),
                    ),
                  ),
                  error: (_, _) => const Text(
                    'Location unavailable',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF727785),
                    ),
                  ),
                  data: (address) => Text(
                    address?.streetAddress ?? 'Set your location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: address != null
                          ? const Color(0xFF151C24)
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

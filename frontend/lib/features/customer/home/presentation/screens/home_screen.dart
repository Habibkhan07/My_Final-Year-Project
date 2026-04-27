import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/home_failure.dart';
import '../providers/home_notifier.dart';
import '../providers/home_state.dart';
import '../widgets/home_skeleton_loader.dart';
import '../widgets/offline_banner.dart';
import '../widgets/promo_banner_slider.dart';
import '../widgets/category_grid.dart';
import '../widgets/fixed_gig_carousel.dart';
import '../widgets/technician_carousel.dart';
import '../widgets/location_required_card.dart';
import '../../../../customer/addresses/presentation/providers/dependency_injection.dart';
import '../../../../customer/addresses/presentation/widgets/address_selector_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeStateAsync = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: homeStateAsync.when(
          data: (state) => _buildContent(context, ref, state, false),
          error: (error, stack) {
            final state = homeStateAsync.value;
            // Tier 2 Cache Rule: If we have data but hit an error, show offline mode
            if (state?.homeFeed != null) {
              return _buildContent(context, ref, state!, true);
            }

            // Otherwise, total failure
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
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Bookings"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      // DEBUG: temporary FABs for sprint routing — remove once nav is wired
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'debug_dashboard',
            onPressed: () => context.go('/technician/dashboard'),
            backgroundColor: Colors.green.shade700,
            icon: const Icon(Icons.dashboard, color: Colors.white),
            label: const Text('Tech Dashboard', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'debug_onboarding',
            onPressed: () => context.push('/technician/onboarding'),
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.handyman, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeState state, bool isOffline) {
    final feed = state.homeFeed;
    if (feed == null) return const SizedBox.shrink();

    // Check if we have a default address loaded
    final defaultAddressAsync = ref.watch(defaultAddressProvider);
    final hasAddress = defaultAddressAsync.value != null;

    return Column(
      children: [
        if (isOffline)
          OfflineBanner(
            onRetry: () => ref.read(homeProvider.notifier).fetchHomeFeed(),
          ),
        
        // App Bar / Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _LocationHeader(),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 28),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                              hintText: 'Try "AC not cooling" or "Leaky pipe"...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
    // Strict Error Propagation Pipeline: Dart 3 Pattern Matching on Sealed Classes
    String errorMessage = "An unexpected error occurred.";
    if (error is HomeFailure) {
      errorMessage = switch (error) {
        HomeNetworkFailure() => "No internet connection. Please check your settings.",
        HomeServerFailure(message: final msg) => msg,
        HomeParsingFailure() => "Failed to load feed data correctly.",
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
              label: const Text("Retry"),
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

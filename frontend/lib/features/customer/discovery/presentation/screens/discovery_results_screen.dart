import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures/discovery_failure.dart';
import '../providers/discovery_notifier.dart';
import '../widgets/discovery_empty_state.dart';
import '../widgets/discovery_error_view.dart';
import '../widgets/discovery_promo_banner.dart';
import '../widgets/technician_card.dart';

class DiscoveryResultsScreen extends ConsumerStatefulWidget {
  final String? query;
  final int? serviceId;
  final int? subServiceId;
  final int? promotionId;
  final double? lat;
  final double? lng;
  final String title;

  const DiscoveryResultsScreen({
    super.key,
    this.query,
    this.serviceId,
    this.subServiceId,
    this.promotionId,
    this.lat,
    this.lng,
    required this.title,
  });

  @override
  ConsumerState<DiscoveryResultsScreen> createState() => _DiscoveryResultsScreenState();
}

class _DiscoveryResultsScreenState extends ConsumerState<DiscoveryResultsScreen> {
  final ScrollController _scrollController = ScrollController();

  late final _provider = discoveryProvider(
    query: widget.query,
    serviceId: widget.serviceId,
    subServiceId: widget.subServiceId,
    promotionId: widget.promotionId,
    lat: widget.lat,
    lng: widget.lng,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Reached near the bottom, load more
      ref.read(_provider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for pagination errors to show a snackbar instead of destroying the list
    ref.listen(_provider, (previous, next) {
      if (next.hasError && previous?.hasValue == true) {
        final error = next.error;
        if (error is DiscoveryFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                error is DiscoveryNetworkFailure 
                    ? 'Network error. Please check your connection.' 
                    : 'Failed to load more results.',
              ),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => ref.read(_provider.notifier).loadMore(),
              ),
            ),
          );
        }
      }
    });

    final state = ref.watch(_provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: state.when(
        // We only want the whole screen to show loading on the initial fetch.
        // If we have data but are refreshing/paginating, skip this.
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // Handling initial build error (no previous data exists)
        error: (error, stackTrace) {
          // If we have data, we're likely showing an error from pagination.
          // The UI will still render the list via the data block below due to AsyncValue behavior.
          if (state.hasValue) {
             return _buildList(state.value!);
          }
          
          if (error is DiscoveryFailure) {
            return DiscoveryErrorView(
              failure: error,
              onRetry: () => ref.read(_provider.notifier).refresh(),
            );
          }
          return Center(child: Text('Unexpected Error: $error'));
        },
        
        data: (data) => _buildList(data),
      ),
    );
  }

  Widget _buildList(dynamic data) {
    final result = data.discoveryResult;
    
    // Safety check
    if (result == null) {
      return const SizedBox.shrink();
    }

    final technicians = result.results;

    if (technicians.isEmpty) {
      return DiscoveryEmptyState(
        onClearFilters: () => Navigator.of(context).pop(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(_provider.notifier).refresh(),
      child: Column(
        children: [
          // Dumb UI: Render Promo Banner if it exists
          if (result.uiPromoBannerText != null)
            DiscoveryPromoBanner(promoText: result.uiPromoBannerText!),
            
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: technicians.length + (data.isPaginationLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < technicians.length) {
                  final technician = technicians[index];
                  return TechnicianCard(
                    technician: technician,
                    onTap: () {
                      // TODO: Navigate to Technician Profile Screen
                    },
                  );
                } else {
                  // The pagination loading indicator at the bottom
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

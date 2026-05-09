import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/discovery_failure.dart';
import '../providers/discovery_notifier.dart';
import '../widgets/discovery_empty_state.dart';
import '../widgets/discovery_error_view.dart';
import '../widgets/discovery_promo_banner.dart';
import '../widgets/technician_card.dart';
import '../widgets/technician_card_skeleton.dart';

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
  ConsumerState<DiscoveryResultsScreen> createState() =>
      _DiscoveryResultsScreenState();
}

class _DiscoveryResultsScreenState
    extends ConsumerState<DiscoveryResultsScreen> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF151C24),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF151C24),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => ListView.builder(
          itemCount: 6,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemBuilder: (context, index) => const TechnicianCardSkeleton(),
        ),
        error: (error, stackTrace) {
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
      color: const Color(0xFF0051AE),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount:
            technicians.length +
            (data.isPaginationLoading ? 1 : 0) +
            (result.uiPromoBannerText != null ? 1 : 0),
        itemBuilder: (context, index) {
          // If promo banner exists, it occupies index 0
          if (result.uiPromoBannerText != null && index == 0) {
            return DiscoveryPromoBanner(promoText: result.uiPromoBannerText!);
          }

          // Adjust index if promo banner is shown
          final technicianIndex = result.uiPromoBannerText != null
              ? index - 1
              : index;

          if (technicianIndex < technicians.length) {
            final technician = technicians[technicianIndex];
            return TechnicianCard(
              technician: technician,
              onTap: () {
                final effectiveServiceId =
                    widget.serviceId ?? result.resolvedServiceId;
                final effectiveSubServiceId =
                    widget.subServiceId ?? result.resolvedSubServiceId;

                final uri = Uri(
                  path: '/technician-profile/${technician.id}',
                  queryParameters: {
                    if (widget.lat != null) 'lat': widget.lat.toString(),
                    if (widget.lng != null) 'lng': widget.lng.toString(),
                    if (effectiveServiceId != null)
                      'serviceId': effectiveServiceId.toString(),
                    if (effectiveSubServiceId != null)
                      'subServiceId': effectiveSubServiceId.toString(),
                    if (widget.promotionId != null)
                      'promotionId': widget.promotionId.toString(),
                  },
                );
                context.push(uri.toString());
              },
            );
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF0051AE),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

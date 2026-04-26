import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/discovery/domain/entities/discovery_entities.dart';
import 'package:frontend/features/customer/discovery/domain/failures/discovery_failure.dart';
import 'package:frontend/features/customer/discovery/presentation/providers/discovery_notifier.dart';
import 'package:frontend/features/customer/discovery/presentation/providers/discovery_state.dart';
import 'package:frontend/features/customer/discovery/presentation/screens/discovery_results_screen.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/technician_card.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/technician_card_skeleton.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/discovery_error_view.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/discovery_empty_state.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/discovery_promo_banner.dart';

class FakeDiscoveryNotifier extends DiscoveryNotifier {
  final AsyncValue<DiscoveryState> initialState;

  FakeDiscoveryNotifier(this.initialState);

  @override
  FutureOr<DiscoveryState> build({
    String? query,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
    double? lat,
    double? lng,
  }) {
    if (initialState.hasError) {
      throw initialState.error!;
    }
    if (initialState.isLoading) {
      return Completer<DiscoveryState>().future;
    }
    return initialState.requireValue;
  }

  // Override other methods to prevent them from hitting real usecases during tests
  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}
}

void main() {
  const tTechnician = DiscoveryTechnicianEntity(
    id: 1,
    fullName: 'Ali Raza',
    primaryCategory: 'Plumbing',
    city: 'LHR',
    profilePicture: null,
    ratingAverage: 4.9,
    reviewCount: 120,
    distanceKm: 2.4,
    bayesianScore: 4.8,
    isActive: true,
    uiRatingText: '4.9 (120)',
    primaryPrice: 'Rs. 500',
    priceContext: 'per visit',
    promoTag: null,
    uiSubtitleText: null,
  );

  const tResultWithPromo = DiscoveryResultEntity(
    count: 1,
    next: 'page=2',
    previous: null,
    uiPromoBannerText: 'Get 20% Off!',
    results: [tTechnician],
  );

  const tEmptyResult = DiscoveryResultEntity(
    count: 0,
    next: null,
    previous: null,
    uiPromoBannerText: null,
    results: [],
  );

  Widget createWidgetUnderTest({
    required AsyncValue<DiscoveryState> state,
  }) {
    return ProviderScope(
      overrides: [
        discoveryProvider(
          query: null,
          serviceId: 2,
          subServiceId: null,
          promotionId: null,
          lat: null,
          lng: null,
        ).overrideWith(
          () => FakeDiscoveryNotifier(state),
        ),
      ],
      child: const MaterialApp(
        home: DiscoveryResultsScreen(
          title: 'Electricians',
          serviceId: 2,
        ),
      ),
    );
  }

  group('DiscoveryResultsScreen Tests', () {
    testWidgets('should show skeleton on initial fetch', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(state: const AsyncLoading()));

      expect(find.byType(TechnicianCardSkeleton), findsWidgets);
    });

    testWidgets('should show DiscoveryErrorView on initial failure', (tester) async {
      const failure = DiscoveryNetworkFailure('No Internet');
      await tester.pumpWidget(createWidgetUnderTest(state: AsyncError(failure, StackTrace.empty)));
      await tester.pump(); // Pump again to let error state settle if needed

      expect(find.byType(DiscoveryErrorView), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
    });

    testWidgets('should render empty state when results are empty', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        state: const AsyncData(DiscoveryState(discoveryResult: tEmptyResult))
      ));
      await tester.pump();

      expect(find.byType(DiscoveryEmptyState), findsOneWidget);
      expect(find.text('No technicians found'), findsOneWidget);
    });

    testWidgets('should render list of technicians and promo banner', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        state: const AsyncData(DiscoveryState(discoveryResult: tResultWithPromo))
      ));
      await tester.pump();

      expect(find.byType(DiscoveryPromoBanner), findsOneWidget);
      expect(find.text('Get 20% Off!'), findsOneWidget);
      expect(find.byType(TechnicianCard), findsOneWidget);
      expect(find.text('Ali Raza'), findsOneWidget);
    });

    testWidgets('should render a bottom loader when isPaginationLoading is true', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        state: const AsyncData(DiscoveryState(
          discoveryResult: tResultWithPromo, 
          isPaginationLoading: true
        ))
      ));
      await tester.pump();

      expect(find.byType(TechnicianCard), findsOneWidget); // Data is preserved
      
      // Bottom loader check
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

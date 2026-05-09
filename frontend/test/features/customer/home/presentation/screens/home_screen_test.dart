import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/addresses/presentation/widgets/address_selector_sheet.dart';
import 'package:frontend/features/customer/home/domain/entities/home_feed_entity.dart';
import 'package:frontend/features/customer/home/presentation/providers/home_notifier.dart';
import 'package:frontend/features/customer/home/presentation/providers/home_state.dart';
import 'package:frontend/features/customer/home/presentation/screens/home_screen.dart';

class _FakeHomeNotifier extends HomeNotifier {
  final AsyncValue<HomeState> _initial;

  _FakeHomeNotifier(this._initial);

  @override
  FutureOr<HomeState> build() {
    if (_initial.hasError) throw _initial.error!;
    if (_initial.isLoading) return Completer<HomeState>().future;
    return _initial.requireValue;
  }

  @override
  Future<void> fetchHomeFeed({double? lat, double? lng}) async {}
}

void main() {
  // Minimal feed — all lists empty so no sub-widgets need network images
  const tFeed = HomeFeedEntity(
    categories: [],
    promotions: [],
    fixedGigs: [],
    topTechnicians: [],
  );
  const tHomeState = HomeState(homeFeed: tFeed);

  const tDefaultAddress = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: 'Gulberg III, Lahore',
    latitude: 31.5,
    longitude: 74.3,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  Widget createWidgetUnderTest({
    AsyncValue<HomeState> homeState = const AsyncData(tHomeState),
    required Future<CustomerAddressEntity?> Function(Ref) addressOverride,
    Future<List<CustomerAddressEntity>> Function(Ref)? addressesListOverride,
  }) {
    return ProviderScope(
      overrides: [
        homeProvider.overrideWith(() => _FakeHomeNotifier(homeState)),
        defaultAddressProvider.overrideWith(addressOverride),
        if (addressesListOverride != null)
          addressesProvider.overrideWith(addressesListOverride),
      ],
      child: const MaterialApp(home: HomeScreen()),
    );
  }

  group('HomeScreen — _LocationHeader', () {
    testWidgets(
      'shows small loading spinner while default address is loading',
      (tester) async {
        await tester.pumpWidget(
          createWidgetUnderTest(
            addressOverride: (_) => Completer<CustomerAddressEntity?>().future,
          ),
        );
        // Pump once — home data is ready, address is still loading
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('shows street address when a default address exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(addressOverride: (_) async => tDefaultAddress),
      );
      await tester.pump();

      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
    });

    testWidgets('shows "Set your location" when no default address is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(addressOverride: (_) async => null),
      );
      await tester.pump();

      expect(find.text('Set your location'), findsOneWidget);
    });

    testWidgets('shows "Location unavailable" on address provider error', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          addressOverride: (_) =>
              Future<CustomerAddressEntity?>.error(Exception('fail')),
        ),
      );
      // pumpAndSettle: lets the error propagate through Riverpod then rebuilds
      await tester.pumpAndSettle();

      expect(find.text('Location unavailable'), findsOneWidget);
    });

    testWidgets('tapping the header opens AddressSelectorSheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          addressOverride: (_) async => null,
          // AddressSelectorSheet watches addressesProvider — override to empty
          addressesListOverride: (_) async => [],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Set your location'));
      await tester.pumpAndSettle();

      expect(find.byType(AddressSelectorSheet), findsOneWidget);
      expect(find.text('Select Location'), findsOneWidget);
    });
  });
}

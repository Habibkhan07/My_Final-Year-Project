import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/presentation/providers/technician_profile_notifier.dart';
import 'package:frontend/features/booking/presentation/screens/technician_profile_screen.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

class MockTechnicianProfileNotifier extends TechnicianProfileNotifier {
  final AsyncValue<TechnicianProfileEntity> _mockState;

  MockTechnicianProfileNotifier(this._mockState);

  @override
  Future<TechnicianProfileEntity> build({
    required int id,
    double? lat,
    double? lng,
    int? serviceId,
    int? subServiceId,
    int? promotionId,
  }) async {
    if (_mockState is AsyncData) return _mockState.requireValue;
    if (_mockState is AsyncError) {
      throw _mockState.error!;
    }
    // AsyncLoading: never complete
    final completer = Completer<TechnicianProfileEntity>();
    return completer.future;
  }
}

void main() {
  const tProfile = TechnicianProfileEntity(
    id: 1,
    fullName: 'Ali Raza',
    city: 'LHR',
    profilePicture: 'https://example.com/pic.jpg',
    ratingAverage: 4.9,
    reviewCount: 120,
    distanceKm: 2.5,
    bayesianScore: 4.8,
    isActive: true,
    uiRatingText: '4.9',
    primaryPrice: 'Rs. 1,500',
    primaryPriceRaw: '1500.00',
    priceContext: 'Fixed Price',
    promoTag: '20% OFF',
    skills: [],
    recentReviews: [],
  );

  const tDefaultAddress = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: '123 Main St',
    latitude: 31.5204,
    longitude: 74.3587,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  Widget createWidgetUnderTest(AsyncValue<TechnicianProfileEntity> state) {
    return ProviderScope(
      overrides: [
        technicianProfileProvider(
          id: 1,
        ).overrideWith(() => MockTechnicianProfileNotifier(state)),
        addressesProvider.overrideWith(
          (ref) => Future.value([tDefaultAddress]),
        ),
      ],
      child: const MaterialApp(home: TechnicianProfileScreen(technicianId: 1)),
    );
  }

  testWidgets('shows loading indicator when state is loading', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest(const AsyncLoading()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error message when state is error', (tester) async {
    await tester.pumpWidget(
      createWidgetUnderTest(AsyncError('Test Error', StackTrace.empty)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load profile.'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });

  testWidgets('renders Dumb UI fields correctly on data state', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(tProfile)));
      await tester.pumpAndSettle();

      // Assert name
      expect(find.text('Ali Raza'), findsOneWidget);

      // Assert price info
      expect(find.text('Rs. 1,500'), findsOneWidget);
      expect(find.text('Fixed Price'), findsOneWidget);

      // Assert promo
      expect(find.text('20% OFF'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Service picker — the chip row that fixes the "Top Rated Near You" dead
  // end. Tests cover the three states the screen has to handle:
  //   * empty skills        → picker hidden, CTA disabled with explainer
  //   * single skill        → auto-pick, CTA enabled with the standard label
  //   * multiple, no route  → CTA disabled until a chip is tapped
  // ---------------------------------------------------------------------------
  group('service picker', () {
    const acRepair = TechnicianSkillEntity(
      name: 'AC Repair',
      iconName: 'ac_repair',
      serviceId: 3,
      subServiceId: 17,
    );
    const plumbing = TechnicianSkillEntity(
      name: 'Plumbing',
      iconName: 'plumbing',
      serviceId: 4,
      subServiceId: null,
    );

    TechnicianProfileEntity profileWith(List<TechnicianSkillEntity> skills) =>
        tProfile.copyWith(skills: skills);

    testWidgets(
      'no skills → CTA reads "Pick a service first" and is disabled',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            createWidgetUnderTest(const AsyncData(tProfile)),
          );
          await tester.pumpAndSettle();

          expect(find.text('Pick a service first'), findsOneWidget);
          expect(find.text('Select Time'), findsNothing);
        });
      },
    );

    testWidgets(
      'single skill → auto-pick, CTA enabled with "Select Time"',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            createWidgetUnderTest(AsyncData(profileWith(const [acRepair]))),
          );
          await tester.pumpAndSettle();

          expect(find.text('Select Time'), findsOneWidget);
          expect(find.text('Pick a service first'), findsNothing);
          // The picker chip is still rendered (so the customer can see
          // what they've been auto-picked into) under the "SERVICE" header.
          expect(find.text('SERVICE'), findsOneWidget);
          expect(find.text('AC Repair'), findsOneWidget);
        });
      },
    );

    testWidgets(
      'multiple skills, no route service → CTA disabled, prompt header reads '
      '"PICK A SERVICE", enables after chip tap',
      (tester) async {
        await mockNetworkImagesFor(() async {
          await tester.pumpWidget(
            createWidgetUnderTest(
              AsyncData(profileWith(const [acRepair, plumbing])),
            ),
          );
          await tester.pumpAndSettle();

          // Before any tap.
          expect(find.text('PICK A SERVICE'), findsOneWidget);
          expect(find.text('Pick a service first'), findsOneWidget);
          expect(find.text('Select Time'), findsNothing);

          // Tap one of the chips.
          await tester.tap(find.text('AC Repair'));
          await tester.pumpAndSettle();

          // After tap: prompt switches to "SERVICE", CTA flips.
          expect(find.text('SERVICE'), findsOneWidget);
          expect(find.text('Select Time'), findsOneWidget);
          expect(find.text('Pick a service first'), findsNothing);
        });
      },
    );
  });
}

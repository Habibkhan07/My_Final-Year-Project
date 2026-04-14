import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/presentation/providers/booking_notifier.dart';
import 'package:frontend/features/booking/presentation/widgets/review_booking_sheet.dart';

class MockInstantBookingNotifier extends InstantBookingNotifier {
  final AsyncValue<CreatedBookingEntity?> _mockState;

  MockInstantBookingNotifier(this._mockState);

  @override
  AsyncValue<CreatedBookingEntity?> build() {
    return _mockState;
  }
}

void main() {
  const tTechnician = TechnicianProfileEntity(
    id: 1,
    fullName: 'Ali Raza',
    city: 'LHR',
    profilePicture: null,
    ratingAverage: 4.9,
    reviewCount: 120,
    experienceYears: 5,
    bio: 'Test Bio',
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

  const tSlot = AvailabilitySlotEntity(
    timeString: '10:00 AM',
    isoStart: '2026-04-07T10:00:00+05:00',
    isoEnd: '2026-04-07T11:00:00+05:00',
    period: 'AM',
  );

  final tDate = DateTime(2026, 4, 7);

  Widget createWidgetUnderTest(AsyncValue<CreatedBookingEntity?> state) {
    return ProviderScope(
      overrides: [
        instantBookingProvider.overrideWith(
          () => MockInstantBookingNotifier(state),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ReviewBookingSheet(
            technician: tTechnician,
            selectedDate: tDate,
            selectedSlot: tSlot,
            addressId: 7,
            addressLabel: 'Home (Default Address)',
          ),
        ),
      ),
    );
  }

  testWidgets('renders correct booking summary details', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(null)));

      expect(find.text('Review Booking'), findsOneWidget);
      // Assert summary texts
      expect(find.text('DATE & TIME'), findsOneWidget);
      expect(find.textContaining('10:00 AM'), findsOneWidget);

      expect(find.text('TOTAL (FIXED PRICE)'), findsOneWidget);
      expect(find.text('Rs. 1,500'), findsOneWidget);

      expect(find.text('SERVICE ADDRESS'), findsOneWidget);
      expect(find.text('Home (Default Address)'), findsOneWidget);

      // Confirm button
      expect(find.text('Confirm & Lock'), findsOneWidget);
    });
  });

  testWidgets('shows loading indicator when submitting', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Confirm & Lock'), findsNothing); // It's hidden by loading indicator
    });
  });
}

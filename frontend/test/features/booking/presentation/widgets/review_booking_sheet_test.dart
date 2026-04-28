import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/domain/failures/booking_failure.dart';
import 'package:frontend/features/booking/presentation/providers/booking_notifier.dart';
import 'package:frontend/features/booking/presentation/widgets/review_booking_sheet.dart';
import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';

class MockInstantBookingNotifier extends InstantBookingNotifier {
  final AsyncValue<CreatedBookingEntity?> _mockState;

  MockInstantBookingNotifier(this._mockState);

  @override
  AsyncValue<CreatedBookingEntity?> build() {
    return _mockState;
  }

  /// Test-only: drive a state transition so `ref.listen` callbacks fire
  /// (ref.listen does not fire on the initial build value).
  void emit(AsyncValue<CreatedBookingEntity?> next) {
    state = next;
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

  const tDefaultAddress = CustomerAddressEntity(
    id: 7,
    label: 'Home',
    streetAddress: '123 Main St',
    latitude: 31.5204,
    longitude: 74.3587,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  Widget createWidgetUnderTest(AsyncValue<CreatedBookingEntity?> state) {
    return ProviderScope(
      overrides: [
        instantBookingProvider.overrideWith(
          () => MockInstantBookingNotifier(state),
        ),
        addressesProvider.overrideWith((ref) => Future.value([tDefaultAddress])),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ReviewBookingSheet(
            technician: tTechnician,
            selectedDate: tDate,
            selectedSlot: tSlot,
            serviceId: 3,
            subServiceId: 17,
          ),
        ),
      ),
    );
  }

  testWidgets('renders correct booking summary details', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncData(null)));
      await tester.pumpAndSettle(); // Allow future providers to resolve

      expect(find.text('Review Booking'), findsOneWidget);
      // Assert summary texts
      expect(find.text('DATE & TIME'), findsOneWidget);
      expect(find.textContaining('10:00 AM'), findsOneWidget);

      expect(find.text('TOTAL (FIXED PRICE)'), findsOneWidget);
      expect(find.text('Rs. 1,500'), findsOneWidget);

      expect(find.text('SERVICE ADDRESS'), findsOneWidget);
      expect(find.text('Home - 123 Main St'), findsOneWidget);

      // Confirm button
      expect(find.text('Confirm & Lock'), findsOneWidget);
    });
  });

  testWidgets('shows loading indicator when submitting', (tester) async {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(createWidgetUnderTest(const AsyncLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Confirm & Lock'), findsNothing); // It's hidden by loading indicator
    });
  });

  // ---------------------------------------------------------------------------
  // Field-level validation_error → user-friendly toast (BOOKINGS_API.md §2.2).
  // The server returns diagnostic-friendly text; the sheet maps each error
  // key to a fixed, user-friendly string via the local dictionary.
  // ---------------------------------------------------------------------------
  group('validation_error toast mapping', () {
    Future<void> pumpWithValidationError(
      WidgetTester tester,
      Map<String, List<String>> errors,
    ) async {
      // Build with AsyncData(null) first, then transition to AsyncError so
      // the ref.listen callback fires (it ignores the initial build value).
      final notifier = MockInstantBookingNotifier(const AsyncData(null));
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            instantBookingProvider.overrideWith(() => notifier),
            addressesProvider
                .overrideWith((ref) => Future.value([tDefaultAddress])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ReviewBookingSheet(
                technician: tTechnician,
                selectedDate: tDate,
                selectedSlot: tSlot,
                serviceId: 3,
                subServiceId: 17,
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        notifier.emit(AsyncError(
          BookingValidationFailure(
            message: 'Diagnostic-friendly server text',
            errors: errors,
          ),
          StackTrace.empty,
        ));
        await tester.pump(); // build SnackBar
        await tester.pump(const Duration(milliseconds: 300)); // animate in
      });
    }

    testWidgets('sub_service_id key → "This gig is no longer available" toast',
        (tester) async {
      await pumpWithValidationError(tester, {
        'sub_service_id': ['Sub-service does not belong to the supplied service.'],
      });

      expect(find.text('This gig is no longer available. Refresh and try again.'),
          findsOneWidget);
    });

    testWidgets('promotion_id key → "This gig already has a fixed price" toast',
        (tester) async {
      await pumpWithValidationError(tester, {
        'promotion_id': ['Discount stacking is not allowed on fixed-price sub-services.'],
      });

      expect(
          find.text("This gig already has a fixed price — promotions don't apply."),
          findsOneWidget);
    });

    testWidgets('price_amount key → "Pricing has updated" toast', (tester) async {
      await pumpWithValidationError(tester, {
        'price_amount': ['Expected 500.00, received 1.00.'],
      });

      expect(find.text('Pricing has updated. Please refresh and confirm again.'),
          findsOneWidget);
    });
  });
}

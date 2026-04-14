import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/booking/domain/entities/booking_entities.dart';
import 'package:frontend/features/booking/presentation/providers/availability_notifier.dart';
import 'package:frontend/features/booking/presentation/providers/availability_state.dart';
import 'package:frontend/features/booking/presentation/widgets/select_time_sheet.dart';

class MockAvailabilityNotifier extends AvailabilityNotifier {
  final AsyncValue<AvailabilityState> _mockState;

  MockAvailabilityNotifier(this._mockState);

  @override
  Future<AvailabilityState> build({
    required int technicianId,
    required String date,
    int? serviceId,
    int? subServiceId,
  }) async {
    if (_mockState is AsyncData) return _mockState.requireValue;
    if (_mockState is AsyncError) {
      throw _mockState.error!;
    }
    // AsyncLoading: never complete
    final completer = Completer<AvailabilityState>();
    return completer.future;
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

  final tSlots = [
    const AvailabilitySlotEntity(
      timeString: '9:00 AM',
      isoStart: '2026-04-07T09:00:00+05:00',
      isoEnd: '2026-04-07T10:00:00+05:00',
      period: 'AM',
    ),
    const AvailabilitySlotEntity(
      timeString: '2:00 PM',
      isoStart: '2026-04-07T14:00:00+05:00',
      isoEnd: '2026-04-07T15:00:00+05:00',
      period: 'PM',
    ),
  ];

  testWidgets('shows loading indicator when state is loading', (tester) async {
    // Because the widget generates `dateString` internally via DateTime.now(), 
    // it's tricky to override the exact Family without faking DateTime.
    // Instead, we just mount the widget and assert its initial default layout 
    // (which triggers a fetch and thus shows loading).
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SelectTimeSheet(technician: tTechnician),
        ),
      ),
    ));

    expect(find.text('Select a Time'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

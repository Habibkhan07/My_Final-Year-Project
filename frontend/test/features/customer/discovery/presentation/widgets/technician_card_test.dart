import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/discovery/domain/entities/discovery_entities.dart';
import 'package:frontend/features/customer/discovery/presentation/widgets/technician_card.dart';

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
    uiRatingText: '4.9 (120 jobs)',
    primaryPrice: 'Rs. 500',
    priceContext: 'Inspection Fee',
    promoTag: null,
    uiSubtitleText: 'PROMO: Get 20% OFF the total bill for Plumbing!',
  );

  Widget createWidgetUnderTest(DiscoveryTechnicianEntity tech) {
    return MaterialApp(
      home: Scaffold(
        body: TechnicianCard(
          technician: tech,
          onTap: () {},
        ),
      ),
    );
  }

  group('TechnicianCard Dumb UI Widget Tests', () {
    testWidgets('should render all basic backend-provided strings correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(tTechnician));

      expect(find.text('Ali Raza'), findsOneWidget);
      // Original Dumb UI behavior: render exactly what the backend provides
      expect(find.text('PROMO: Get 20% OFF the total bill for Plumbing!'), findsOneWidget); 
      expect(find.text('4.9 (120 jobs)'), findsOneWidget); // uiRatingText
      expect(find.text('2.4 km'), findsOneWidget); // distanceKm formatted
      expect(find.text('Rs. 500'), findsOneWidget); // primaryPrice
      expect(find.text('INSPECTION FEE'), findsOneWidget); // priceContext uppercased in bottom corner
    });

    testWidgets('should fall back to primaryCategory if uiSubtitleText is null', (tester) async {
      final fallbackTech = tTechnician.copyWith(uiSubtitleText: null);
      await tester.pumpWidget(createWidgetUnderTest(fallbackTech));

      expect(find.text('Plumbing'), findsOneWidget); 
    });

    testWidgets('should render promoTag badge when promoTag is provided', (tester) async {
      final promoTech = tTechnician.copyWith(promoTag: 'Save 20%');
      await tester.pumpWidget(createWidgetUnderTest(promoTech));

      expect(find.text('Save 20%'), findsOneWidget);
    });

    testWidgets('should not render distance if distanceKm is null', (tester) async {
      final noDistanceTech = tTechnician.copyWith(distanceKm: null, city: 'Lahore');
      await tester.pumpWidget(createWidgetUnderTest(noDistanceTech));

      expect(find.byIcon(Icons.location_on_rounded), findsNothing);
      expect(find.text('2.4 km'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      bool wasTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnicianCard(
              technician: tTechnician,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(wasTapped, true);
    });
  });
}

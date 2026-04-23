import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/addresses/presentation/widgets/address_selector_sheet.dart';

void main() {
  const tDefault = CustomerAddressEntity(
    id: 1,
    label: 'Home',
    streetAddress: 'Gulberg III, Lahore',
    latitude: 31.5,
    longitude: 74.3,
    isDefault: true,
    createdAt: '2024-01-01',
  );

  const tNonDefault = CustomerAddressEntity(
    id: 2,
    label: 'Office',
    streetAddress: 'DHA Phase 5, Lahore',
    latitude: 31.4,
    longitude: 74.2,
    isDefault: false,
    createdAt: '2024-01-02',
  );

  Widget createWidgetUnderTest(
    Future<List<CustomerAddressEntity>> Function(Ref) override,
  ) {
    return ProviderScope(
      overrides: [addressesProvider.overrideWith(override)],
      child: const MaterialApp(
        home: Scaffold(body: AddressSelectorSheet()),
      ),
    );
  }

  group('AddressSelectorSheet', () {
    testWidgets('shows loading indicator while addresses are loading',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          (_) => Completer<List<CustomerAddressEntity>>().future,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when addresses fail to load',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          (_) => Future.error(Exception('network failure')),
        ),
      );
      // pumpAndSettle: lets the error propagate through Riverpod then rebuilds
      await tester.pumpAndSettle();

      expect(find.text('Could not load addresses.'), findsOneWidget);
    });

    testWidgets('shows empty state when no addresses are saved', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest((_) async => []));
      await tester.pump();

      expect(find.text('No saved addresses yet.'), findsOneWidget);
    });

    testWidgets('renders a tile for each address with label and street',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest((_) async => [tDefault, tNonDefault]),
      );
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Gulberg III, Lahore'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('DHA Phase 5, Lahore'), findsOneWidget);
    });

    testWidgets('shows Default badge only on the default address',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest((_) async => [tDefault, tNonDefault]),
      );
      await tester.pump();

      // Exactly one badge
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('renders the Add New Address button in all states',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest((_) async => []));
      await tester.pump();

      expect(find.text('Add New Address'), findsOneWidget);
    });
  });
}

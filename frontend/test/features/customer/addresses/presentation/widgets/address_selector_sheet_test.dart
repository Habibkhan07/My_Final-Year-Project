import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/customer/addresses/domain/entities/address_entity.dart';
import 'package:frontend/features/customer/addresses/domain/use_cases/update_address_use_case.dart';
import 'package:frontend/features/customer/addresses/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/addresses/presentation/widgets/address_selector_sheet.dart';

class MockUpdateAddressUseCase extends Mock implements UpdateAddressUseCase {}

void main() {
  late MockUpdateAddressUseCase mockUpdateUseCase;

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

  setUp(() {
    mockUpdateUseCase = MockUpdateAddressUseCase();
  });

  Widget createWidgetUnderTest(
    Future<List<CustomerAddressEntity>> Function(Ref) override,
  ) {
    return ProviderScope(
      overrides: [
        addressesProvider.overrideWith(override),
        updateAddressUseCaseProvider.overrideWithValue(mockUpdateUseCase),
      ],
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
      await tester.pumpAndSettle();

      expect(find.text('Could not load addresses.'), findsOneWidget);
    });

    testWidgets('renders a tile for each address with correct state',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest((_) async => [tDefault, tNonDefault]),
      );
      await tester.pump();

      // Labels are now uppercase in the polished design
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text('OFFICE'), findsOneWidget);
      
      // Default address has a check circle
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      
      // Verify icon types (Home icon for Home label)
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    });

    testWidgets('tapping non-default address calls update and closes sheet',
        (tester) async {
      when(() => mockUpdateUseCase.call(
            id: any(named: 'id'),
            isDefault: any(named: 'isDefault'),
          )).thenAnswer((_) async => tNonDefault.copyWith(isDefault: true));

      await tester.pumpWidget(
        createWidgetUnderTest((_) async => [tDefault, tNonDefault]),
      );
      await tester.pump();

      // Tap the "OFFICE" tile (using text containment or case insensitive if possible, 
      // but here we know it's uppercase)
      await tester.tap(find.text('OFFICE'));
      await tester.pumpAndSettle();

      verify(() => mockUpdateUseCase.call(id: 2, isDefault: true)).called(1);
      
      // Verify sheet is dismissed
      expect(find.byType(AddressSelectorSheet), findsNothing);
    });

    testWidgets('tapping already default address does nothing',
        (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest((_) async => [tDefault, tNonDefault]),
      );
      await tester.pump();

      // Tap the "HOME" tile (already default)
      await tester.tap(find.text('HOME'));
      await tester.pump();

      verifyNever(() => mockUpdateUseCase.call(
            id: any(named: 'id'),
            isDefault: any(named: 'isDefault'),
          ));
      
      // Sheet should remain open
      expect(find.byType(AddressSelectorSheet), findsOneWidget);
    });
  });
}

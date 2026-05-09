import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/domain/entities/service_entity.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_3_primary_trade.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step3PrimaryTrade Widget Tests (Dumb UI)', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    const tServices = [
      ServiceEntity(id: 1, name: 'AC Repair', subServices: []),
      ServiceEntity(id: 2, name: 'Plumbing', subServices: []),
      ServiceEntity(id: 3, name: 'Electrician', subServices: []),
    ];

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(
        () => mockMetadataUseCase.execute(),
      ).thenAnswer((_) async => tServices);
    });

    testWidgets('should render list of categories from state metadata', (
      WidgetTester tester,
    ) async {
      final state = OnboardingState(services: tServices);

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(
            mockMetadataUseCase,
          ),
        ],
      );

      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(state);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: Step3PrimaryTrade())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Electrician'), findsOneWidget);

      container.dispose();
    });
  });
}

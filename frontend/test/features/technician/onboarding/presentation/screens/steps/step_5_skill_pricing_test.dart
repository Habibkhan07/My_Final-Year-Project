import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/domain/entities/service_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/skill_selection_entity.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_5_skill_pricing.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step5SkillPricing Widget Tests (Dumb UI)', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
    });
    
    // Hardcoded Entity Contract: We define exactly what the backend *would* have returned
    const tServices = [
      ServiceEntity(
        id: 1, 
        name: 'AC Repair', 
        subServices: [
          SubServiceEntity(id: 10, name: 'AC Wash', basePrice: '1500', maxPrice: '2500'),
          SubServiceEntity(id: 11, name: 'Gas Refill', basePrice: '3500', maxPrice: '5000'),
        ]
      )
    ];

    testWidgets('should render empty state message when no skills selected', (WidgetTester tester) async {
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => tServices);

      // 1. Arrange: Create a state with NO selected skills
      final emptyState = OnboardingState(
        services: tServices,
        selectedSkills: const [],
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      // Wait for initialization
      await container.read(onboardingProvider.future);
      // Manually inject the hardcoded state into the REAL notifier
      container.read(onboardingProvider.notifier).state = AsyncData(emptyState);

      // 2. Build the widget tree injected with the controlled container
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Step5SkillPricing(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Assert Visual Contract
      expect(find.text('Experience & Pricing'), findsOneWidget);
      expect(find.text('No services selected.'), findsOneWidget);
      
      container.dispose();
    });

    testWidgets('should render sub-service name and experience correctly', (WidgetTester tester) async {
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => tServices);

      // 1. Arrange: Create a state with ONE selected skill (id: 10, 5 years)
      final populatedState = OnboardingState(
        services: tServices,
        selectedSkills: const [
          SkillSelectionEntity(subServiceId: 10, yearsOfExperience: 5)
        ],
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(populatedState);

      // 2. Build the widget tree
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Step5SkillPricing(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 3. Assert Visual Contract (Dumb UI compliance)
      // The UI must have mapped subServiceId (10) -> "AC Wash" via the state.services metadata
      expect(find.text('AC Wash'), findsOneWidget);
      
      // The UI must accurately append " Years" to the experience integer
      expect(find.text('5 Years'), findsOneWidget);
      
      // The Slider should be present
      expect(find.byType(Slider), findsOneWidget);
      
      container.dispose();
    });
  });
}

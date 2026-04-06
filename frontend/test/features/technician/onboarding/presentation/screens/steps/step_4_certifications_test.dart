import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/domain/entities/service_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/skill_selection_entity.dart';
import 'package:frontend/features/technician/onboarding/domain/entities/category_license_entity.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_4_certifications.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step4Certifications Widget Tests (Dumb UI)', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

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

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => tServices);
    });

    testWidgets('should render warning message when no skills are selected', (WidgetTester tester) async {
      final state = OnboardingState(
        services: tServices,
        selectedSkills: const [], // No skills selected
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(state);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Step4Certifications()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please go back and select at least one service.'), findsOneWidget);
      expect(find.text('AC Repair License'), findsNothing);
      
      container.dispose();
    });

    testWidgets('should render upload card when a sub-service is selected', (WidgetTester tester) async {
      final state = OnboardingState(
        services: tServices,
        selectedSkills: const [
          SkillSelectionEntity(subServiceId: 10, yearsOfExperience: 0) // AC Wash Selected
        ]
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(state);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Step4Certifications()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Visual Contract: Should display the parent service name based on the selected skill
      expect(find.text('AC Repair License'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget); // Empty state icon
      
      container.dispose();
    });

    testWidgets('should render checkmark when category license is uploaded', (WidgetTester tester) async {
      final state = OnboardingState(
        services: tServices,
        categoryLicenses: const [
          CategoryLicenseEntity(serviceId: 1, mediaUuid: 'mock-uuid')
        ],
        selectedSkills: const [
          SkillSelectionEntity(subServiceId: 10, yearsOfExperience: 0) // AC Wash Selected
        ]
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(state);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Step4Certifications()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AC Repair License'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Uploaded state icon
      expect(find.textContaining('Upload Complete'), findsOneWidget);
      
      container.dispose();
    });
  });
}

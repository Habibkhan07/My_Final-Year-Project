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

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step4Certifications', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    const tServices = [
      ServiceEntity(
        id: 1,
        name: 'AC Repair',
        subServices: [
          SubServiceEntity(
            id: 10,
            name: 'AC Wash',
            basePrice: '1500',
            maxPrice: '2500',
          ),
          SubServiceEntity(
            id: 11,
            name: 'Gas Refill',
            basePrice: '3500',
            maxPrice: '5000',
          ),
        ],
      ),
    ];

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(
        () => mockMetadataUseCase.execute(),
      ).thenAnswer((_) async => tServices);
    });

    Future<ProviderContainer> seedScreen(
      WidgetTester tester,
      OnboardingState state,
    ) async {
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
          child: const MaterialApp(
            home: Scaffold(body: Step4Certifications()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('renders empty-state prompt when no skills are selected', (
      tester,
    ) async {
      final container = await seedScreen(
        tester,
        const OnboardingState(services: tServices, selectedSkills: []),
      );

      expect(
        find.textContaining('Pick at least one service'),
        findsOneWidget,
      );
      expect(find.text('AC Repair license'), findsNothing);

      container.dispose();
    });

    testWidgets('renders one license slot per parent service of selected skills',
        (tester) async {
      final container = await seedScreen(
        tester,
        const OnboardingState(
          services: tServices,
          selectedSkills: [SkillSelectionEntity(subServiceId: 10)],
        ),
      );

      expect(find.text('AC Repair license'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows uploaded affordance when a category license is staged',
        (tester) async {
      final container = await seedScreen(
        tester,
        const OnboardingState(
          services: tServices,
          selectedSkills: [SkillSelectionEntity(subServiceId: 10)],
          categoryLicenses: [
            CategoryLicenseEntity(serviceId: 1, mediaUuid: 'mock-uuid'),
          ],
        ),
      );

      expect(find.text('AC Repair license'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Tap to retake'), findsOneWidget);

      container.dispose();
    });
  });
}

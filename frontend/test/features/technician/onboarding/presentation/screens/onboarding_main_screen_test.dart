import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/onboarding_main_screen.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

void main() {
  group('OnboardingMainScreen (Orchestrator) Tests', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => []);
    });

    testWidgets('should render Next button on Step 0', (
      WidgetTester tester,
    ) async {
      final state = OnboardingState(currentStep: 0);

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
            home: Scaffold(body: OnboardingMainScreen()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Visual Contract: Navigation bounds
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Submit Application'), findsNothing);

      container.dispose();
    });

    testWidgets(
      'should render Submit Application button on final step (Step 5)',
      (WidgetTester tester) async {
        final state = OnboardingState(currentStep: 5);

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
              home: Scaffold(body: OnboardingMainScreen()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Visual Contract: Navigation bounds
        expect(find.text('Submit Application'), findsOneWidget);
        expect(find.text('Next'), findsNothing);

        container.dispose();
      },
    );
  });
}

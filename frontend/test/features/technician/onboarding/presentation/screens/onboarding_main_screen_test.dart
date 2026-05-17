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
  group('OnboardingMainScreen', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => []);
    });

    Future<ProviderContainer> seed(
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
            home: Scaffold(body: OnboardingMainScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('renders Continue button on Step 0', (tester) async {
      final container = await seed(
        tester,
        const OnboardingState(currentStep: 0),
      );

      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Submit application'), findsNothing);

      container.dispose();
    });

    testWidgets('renders Submit Application button on final step (Step 4)', (
      tester,
    ) async {
      final container = await seed(
        tester,
        const OnboardingState(currentStep: 4),
      );

      expect(find.text('Submit application'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);

      container.dispose();
    });

    testWidgets('progress chip reflects 5-step total', (tester) async {
      final container = await seed(
        tester,
        const OnboardingState(currentStep: 0),
      );

      expect(find.text('Step 1 of 5'), findsOneWidget);

      container.dispose();
    });
  });
}

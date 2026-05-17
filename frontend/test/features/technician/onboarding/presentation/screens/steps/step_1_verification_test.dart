import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_1_verification.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step1Verification', () {
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
          child: const MaterialApp(home: Scaffold(body: Step1Verification())),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('renders empty CNIC field and upload card prompt', (
      tester,
    ) async {
      final container = await seed(tester, const OnboardingState());

      expect(find.text('CNIC front'), findsOneWidget);
      expect(find.textContaining('Hold steady'), findsOneWidget);

      container.dispose();
    });

    testWidgets('renders success affordance when CNIC photo is staged', (
      tester,
    ) async {
      final container = await seed(
        tester,
        const OnboardingState(cnicPictureUuid: 'uuid-1234'),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Tap to retake'), findsOneWidget);

      container.dispose();
    });

    testWidgets('auto-inserts dashes when the user types CNIC digits', (
      tester,
    ) async {
      final container = await seed(tester, const OnboardingState());

      final field = find.byType(TextFormField);
      await tester.enterText(field, '3520245678901');
      await tester.pumpAndSettle();

      expect(find.text('35202-4567890-1'), findsOneWidget);
      container.dispose();
    });
  });
}

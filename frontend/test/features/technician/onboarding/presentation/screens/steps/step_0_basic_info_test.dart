import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_0_basic_info.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock
    implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step0BasicInfo', () {
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
          child: const MaterialApp(home: Scaffold(body: Step0BasicInfo())),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('renders empty fields and city chips when state is empty', (
      tester,
    ) async {
      final container = await seed(tester, const OnboardingState());

      // First name + Last name are the only text inputs on the screen now;
      // city is rendered as ChoiceChips, profile picture as an upload card.
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ChoiceChip), findsNWidgets(3));
      // Profile picture upload card subtitle (empty state).
      expect(find.textContaining('selfie'), findsOneWidget);

      container.dispose();
    });

    testWidgets('populates fields when state has data', (tester) async {
      final container = await seed(
        tester,
        const OnboardingState(
          firstName: 'Ali',
          lastName: 'Raza',
          city: 'LHR',
        ),
      );

      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Raza'), findsOneWidget);
      // The selected city chip retains its label; selection is rendered as a
      // brand-blue chip — but the label "Lahore" is present either way.
      expect(find.text('Lahore'), findsOneWidget);

      container.dispose();
    });
  });
}

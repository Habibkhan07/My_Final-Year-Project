import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_notifier.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/onboarding_state.dart';
import 'package:frontend/features/technician/onboarding/presentation/screens/steps/step_0_basic_info.dart';
import 'package:frontend/features/technician/onboarding/domain/usecases/get_onboarding_metadata_usecase.dart';
import 'package:frontend/features/technician/onboarding/presentation/providers/dependency_injection.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOnboardingMetadataUseCase extends Mock implements GetOnboardingMetadataUseCase {}

void main() {
  group('Step0BasicInfo Widget Tests (Dumb UI)', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => []);
    });

    testWidgets('should render empty form fields when state is empty', (WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Step0BasicInfo()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check if fields are present (First Name, Last Name)
      expect(find.byType(TextFormField), findsNWidgets(2)); 
      // City Dropdown
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      container.dispose();
    });

    testWidgets('should populate form fields when state has data', (WidgetTester tester) async {
      final populatedState = OnboardingState(
        firstName: 'Ali',
        lastName: 'Raza',
        city: 'LHR',
      );

      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(mockMetadataUseCase),
        ]
      );
      
      await container.read(onboardingProvider.future);
      container.read(onboardingProvider.notifier).state = AsyncData(populatedState);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Step0BasicInfo()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The dumb UI should render the text exactly as provided by the state
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Raza'), findsOneWidget);
      expect(find.text('Lahore'), findsOneWidget); // Dropdown displays the text 'Lahore' for 'LHR'
      
      container.dispose();
    });
  });
}

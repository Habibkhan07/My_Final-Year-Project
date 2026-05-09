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
  group('Step1Verification Widget Tests (Dumb UI)', () {
    late MockGetOnboardingMetadataUseCase mockMetadataUseCase;

    setUp(() {
      mockMetadataUseCase = MockGetOnboardingMetadataUseCase();
      when(() => mockMetadataUseCase.execute()).thenAnswer((_) async => []);
    });

    testWidgets('should render upload button when no CNIC UUID exists', (
      WidgetTester tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          getOnboardingMetadataUseCaseProvider.overrideWithValue(
            mockMetadataUseCase,
          ),
        ],
      );

      await container.read(onboardingProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: Step1Verification())),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CNIC (Front Side)'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      expect(find.text('Upload a clear picture of your ID.'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should render success indicator when CNIC UUID exists', (
      WidgetTester tester,
    ) async {
      final state = OnboardingState(cnicPictureUuid: 'uuid-1234');

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

      // Visual Contract: Check icon appears when image is successfully uploaded to memory
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('Upload Complete'), findsOneWidget);

      container.dispose();
    });
  });
}

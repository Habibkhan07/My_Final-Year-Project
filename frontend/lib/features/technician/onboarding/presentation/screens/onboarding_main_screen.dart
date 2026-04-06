import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 1. Imports for your Domain Failures & State
import '../../domain/failures/technician_failure.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';

// 2. Imports for the New 6-Step Widgets
import 'steps/step_0_basic_info.dart';
import 'steps/step_1_verification.dart';
import 'steps/step_2_professional_id.dart';
import 'steps/step_3_primary_trade.dart';
import 'steps/step_4_certifications.dart';
import 'steps/step_5_skill_pricing.dart';

class OnboardingMainScreen extends ConsumerStatefulWidget {
  const OnboardingMainScreen({super.key});

  @override
  ConsumerState<OnboardingMainScreen> createState() =>
      _OnboardingMainScreenState();
}

class _OnboardingMainScreenState extends ConsumerState<OnboardingMainScreen> {
  final PageController _pageController = PageController();
  final int _totalSteps = 6; 

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(Object error) {
    String message = "An unexpected error occurred.";
    VoidCallback? onAction;
    String? actionLabel;

    if (error is TechnicianFailure) {
      message = switch (error) {
        InvalidOnboardingInput(errors: final map) =>
          "Input Error: ${map.values.first.first}",
        OnboardingSessionExpired(message: final msg) => msg,
        OnboardingUnauthorized(message: final msg) => msg,
        DuplicateTechnician(message: final msg) => msg,
        OnboardingNetworkFailure(message: final msg) => msg,
        OnboardingParsingFailure(message: final msg) => "Data Error: $msg",
        OnboardingServerFailure(message: final msg) => "Server Error: $msg",
      };

      if (error is OnboardingSessionExpired ||
          error is OnboardingUnauthorized) {
        actionLabel = "Login";
        onAction = () => context.go('/login');
      }
    } else {
      message = error.toString();
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction!,
              )
            : null,
      ),
    );
  }

  bool _canAdvance(OnboardingState state) {
    switch (state.currentStep) {
      case 0:
        return state.firstName.trim().isNotEmpty &&
            state.lastName.trim().isNotEmpty &&
            state.city.isNotEmpty;
      case 1:
        return state.cnicNumber.length == 15 && state.cnicPictureUuid != null;
      case 2:
        return state.bio.trim().isNotEmpty && state.profilePictureUuid != null;
      case 3:
        return state.selectedSkills.isNotEmpty;
      case 4:
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(onboardingProvider);

    // ==========================================
    // PILLAR 1 & 2: ERRORS & SUBMISSION STATUS
    // ==========================================
    ref.listen<AsyncValue<OnboardingState>>(onboardingProvider, (previous, next) {
      // A. Catch top-level state errors (e.g. metadata failed to fetch)
      if (next.hasError && !next.isLoading) {
        if (previous == null || !previous.hasError) {
          _showErrorSnackBar(next.error!);
        }
      }

      // B. Catch Nested Submission Status Changes safely
      final prevSub = previous?.value?.submissionStatus;
      final nextSub = next.value?.submissionStatus;

      if (nextSub != null && nextSub != prevSub) {
        nextSub.whenOrNull(
          data: (technician) {
            if (technician != null) {
              context.go('/technician/success', extra: technician);
            }
          },
          error: (error, stack) => _showErrorSnackBar(error),
        );
      }
    });

    // ==========================================
    // PILLAR 3: PAGE NAVIGATION (UI State)
    // ==========================================
    ref.listen<AsyncValue<OnboardingState>>(onboardingProvider, (previous, next) {
      final prevStep = previous?.value?.currentStep;
      final nextStep = next.value?.currentStep;

      if (nextStep != null && nextStep != prevStep && _pageController.hasClients) {
        if (_pageController.page?.round() != nextStep) {
          _pageController.animateToPage(
            nextStep,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Technician Registration"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final step = stateAsync.value?.currentStep ?? 0;
            if (step > 0) {
              ref.read(onboardingProvider.notifier).previousStep();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                "Failed to load setup.",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(onboardingProvider.notifier).fetchMetadata(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Step ${state.currentStep + 1} of $_totalSteps",
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 8,
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        child: FractionallySizedBox(
                          widthFactor: (state.currentStep + 1) / _totalSteps,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Step0BasicInfo(),
                    Step1Verification(),
                    Step2ProfessionalId(),
                    Step3PrimaryTrade(),
                    Step4Certifications(),
                    Step5SkillPricing(),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (state.currentStep > 0)
                      TextButton(
                        onPressed: () => ref.read(onboardingProvider.notifier).previousStep(),
                        child: const Text("Back"),
                      )
                    else
                      const SizedBox(width: 64),

                    if (state.currentStep < (_totalSteps - 1))
                      ElevatedButton(
                        onPressed: _canAdvance(state)
                            ? () => ref.read(onboardingProvider.notifier).nextStep()
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: const Text("Next"),
                      )
                    else
                      ElevatedButton(
                        onPressed: (state.submissionStatus.isLoading || state.selectedSkills.isEmpty)
                            ? null
                            : () => ref.read(onboardingProvider.notifier).finalize(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: state.submissionStatus.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Submit Application"),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
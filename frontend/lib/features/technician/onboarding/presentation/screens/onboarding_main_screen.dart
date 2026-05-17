import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/failures/technician_failure.dart';
import '../providers/onboarding_notifier.dart';
import '../providers/onboarding_state.dart';
import '../providers/technician_status_provider.dart';
import 'steps/step_0_basic_info.dart';
import 'steps/step_1_verification.dart';
import 'steps/step_3_primary_trade.dart';
import 'steps/step_4_certifications.dart';
import 'steps/step_5_work_location.dart';

/// Tech-side onboarding wizard. 5 steps after the 2026-05-17 refactor:
///   0  Basic Info + profile picture (front camera)
///   1  Identity (CNIC# auto-dashed + back-camera photo)
///   2  Trade selection
///   3  Certifications (optional, back-camera)
///   4  Work location (search + map + reverse-geocode)
///
/// Old "Professional ID" (bio + experience years) and "Skill Pricing"
/// steps were dropped — see ``[[project_tech_onboarding_refactor]]`` and
/// the matching backend migrations 0013/0014.
class OnboardingMainScreen extends ConsumerStatefulWidget {
  const OnboardingMainScreen({super.key});

  @override
  ConsumerState<OnboardingMainScreen> createState() =>
      _OnboardingMainScreenState();
}

class _OnboardingMainScreenState extends ConsumerState<OnboardingMainScreen> {
  final PageController _pageController = PageController();
  static const int _totalSteps = 5;
  static const _brand = Color(0xFF0051AE);

  static const _titles = [
    'Basics',
    'Identity',
    'Trades',
    'Licenses',
    'Work area',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(Object error) {
    String message = 'Something went wrong.';
    VoidCallback? onAction;
    String? actionLabel;

    if (error is TechnicianFailure) {
      message = switch (error) {
        InvalidOnboardingInput(errors: final map) =>
          map.values.isNotEmpty && map.values.first.isNotEmpty
              ? map.values.first.first
              : 'Some details look invalid. Please review and try again.',
        OnboardingSessionExpired(message: final msg) => msg,
        OnboardingUnauthorized(message: final msg) => msg,
        DuplicateTechnician(message: final msg) => msg,
        DuplicateApplicationFailure(message: final msg) => msg,
        OnboardingNetworkFailure(message: final msg) => msg,
        OnboardingParsingFailure() =>
          "We received an unexpected response. Try again.",
        OnboardingServerFailure(message: final msg) => msg,
      };

      if (error is OnboardingSessionExpired ||
          error is OnboardingUnauthorized) {
        actionLabel = 'Log in';
        onAction = () => context.go('/login');
      } else if (error is DuplicateApplicationFailure) {
        actionLabel = error.applicationStatus == 'APPROVED'
            ? 'Open dashboard'
            : 'View status';
        onAction = () => context.go(
              error.applicationStatus == 'APPROVED'
                  ? '/technician/dashboard'
                  : '/technician/pending',
            );
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
            state.city.isNotEmpty &&
            state.profilePictureUuid != null;
      case 1:
        // CNIC is rendered as 15 chars (13 digits + 2 dashes).
        return state.cnicNumber.length == 15 && state.cnicPictureUuid != null;
      case 2:
        return state.selectedSkills.isNotEmpty;
      case 3:
        // Licenses are optional.
        return true;
      case 4:
        return state.baseLatitude != null && state.baseLongitude != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(onboardingProvider);

    ref.listen<AsyncValue<OnboardingState>>(onboardingProvider, (prev, next) {
      if (next.hasError && !next.isLoading) {
        if (prev == null || !prev.hasError) _showErrorSnackBar(next.error!);
      }
      final prevSub = prev?.value?.submissionStatus;
      final nextSub = next.value?.submissionStatus;
      if (nextSub != null && nextSub != prevSub) {
        nextSub.whenOrNull(
          data: (technician) {
            if (technician != null) {
              // Drop the stale ``NoProfile`` status cached before
              // finalize so the holding screen reads the freshly
              // PENDING status on first frame instead of bouncing
              // through a loading state.
              ref.invalidate(technicianStatusProvider);
              context.go('/technician/success');
            }
          },
          error: (error, stack) => _showErrorSnackBar(error),
        );
      }
    });

    ref.listen<AsyncValue<OnboardingState>>(onboardingProvider, (prev, next) {
      final prevStep = prev?.value?.currentStep;
      final nextStep = next.value?.currentStep;
      if (nextStep != null &&
          nextStep != prevStep &&
          _pageController.hasClients) {
        if (_pageController.page?.round() != nextStep) {
          _pageController.animateToPage(
            nextStep,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
          );
        }
      }
    });

    // Intercept Android system back so the gesture/button steps backward
    // through the wizard instead of popping the whole onboarding route.
    // canPop is true ONLY on step 0 — that's the one position where back
    // genuinely means "leave onboarding."
    final currentStep = stateAsync.value?.currentStep ?? 0;
    final canPopRoute = currentStep == 0;

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (currentStep > 0) {
          ref.read(onboardingProvider.notifier).previousStep();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: stateAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _brand),
          ),
          error: (err, stack) => _BootError(
            onRetry: () =>
                ref.read(onboardingProvider.notifier).fetchMetadata(),
          ),
          data: (state) => Column(
            children: [
              _Header(
                currentStep: state.currentStep,
                totalSteps: _totalSteps,
                title: _titles[state.currentStep],
                onBack: () {
                  if (state.currentStep > 0) {
                    ref.read(onboardingProvider.notifier).previousStep();
                  } else {
                    context.pop();
                  }
                },
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Step0BasicInfo(),
                    Step1Verification(),
                    Step3PrimaryTrade(),
                    Step4Certifications(),
                    Step5WorkLocation(),
                  ],
                ),
              ),
              _BottomBar(
                state: state,
                canAdvance: _canAdvance(state),
                onNext: () => ref.read(onboardingProvider.notifier).nextStep(),
                onSubmit: () =>
                    ref.read(onboardingProvider.notifier).finalize(),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final VoidCallback onBack;

  const _Header({
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.onBack,
  });

  static const _brand = Color(0xFF0051AE);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 24, 12),
      color: const Color(0xFFF6F8FC),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: const Color(0xFF151C24),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF151C24),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${currentStep + 1} of $totalSteps',
                  style: const TextStyle(
                    color: _brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: (currentStep + 1) / totalSteps,
                minHeight: 6,
                backgroundColor: const Color(0xFFE3E6EF),
                valueColor: const AlwaysStoppedAnimation(_brand),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final OnboardingState state;
  final bool canAdvance;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.state,
    required this.canAdvance,
    required this.onNext,
    required this.onSubmit,
  });

  static const _brand = Color(0xFF0051AE);
  static const _totalSteps = 5;

  @override
  Widget build(BuildContext context) {
    final isFinal = state.currentStep == _totalSteps - 1;
    final isSubmitting = state.submissionStatus.isLoading;
    final disabled = isSubmitting || !canAdvance;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        16 + MediaQuery.of(context).padding.bottom * 0.2,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: disabled ? null : (isFinal ? onSubmit : onNext),
          style: ElevatedButton.styleFrom(
            backgroundColor: _brand,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFC2C6D6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: disabled ? 0 : 4,
            shadowColor: const Color(0x660051AE),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isFinal ? 'Submit application' : 'Continue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isFinal
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  final VoidCallback onRetry;
  const _BootError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 14),
            const Text(
              'Failed to load setup.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

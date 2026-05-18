import 'package:flutter/material.dart';

import '../_palette/orchestrator_palette.dart';

/// Brand-styled submit button. Mirrors the booking-flow CTA language
/// from per the user's `feedback_ui_target_foodpanda` memory (visual
/// identity is the existing brand blue ElevatedButton, not Foodpanda's
/// orange).
///
/// Three visual states:
/// - **Disabled**: rating not picked yet → low-opacity background,
///   button non-interactive.
/// - **Loading**: submit in flight → spinner replaces label, button
///   non-interactive.
/// - **Enabled**: rating selected, not loading → full-saturation
///   background, button interactive.
class SubmitReviewButton extends StatelessWidget {
  const SubmitReviewButton({
    super.key,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canPress = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: OrchestratorPalette.brandPrimary,
          disabledBackgroundColor:
              OrchestratorPalette.brandPrimary.withValues(alpha: 0.32),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Submit review'),
      ),
    );
  }
}

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
    // Aligned with the orchestrator's brand CTA recipe used by
    // BookingOrchestratorActionButton, QuoteBuilderSheet, and
    // BookingActionPendingSheet: vertical padding 16 (≈ 56-px tall),
    // 16-radius rectangle, elevation 8 with brand-blue 40% shadow,
    // label fontSize 16 w700. Disabled bg lifted from 0.32 → 0.45
    // alpha + full-opacity white label so the disabled state passes AA
    // (the prior 0.32 + 0.7-opacity label was barely legible).
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPress ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: OrchestratorPalette.brandPrimary,
          disabledBackgroundColor:
              OrchestratorPalette.brandPrimary.withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 8,
          shadowColor:
              OrchestratorPalette.brandPrimary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
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

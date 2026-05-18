import 'package:flutter/material.dart';

import '../orchestrator_primary_button.dart';

/// Brand-styled review submit button. Thin wrapper around
/// [OrchestratorPrimaryButton] that preserves the review feature's
/// `enabled / loading / onPressed` call-site ergonomics while sourcing
/// the visual recipe (radius, padding, elevation, brand-blue, disabled
/// alpha, spinner) from the canonical primary CTA widget.
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
    return OrchestratorPrimaryButton(
      label: 'Submit review',
      onPressed: enabled ? onPressed : null,
      busy: loading,
    );
  }
}

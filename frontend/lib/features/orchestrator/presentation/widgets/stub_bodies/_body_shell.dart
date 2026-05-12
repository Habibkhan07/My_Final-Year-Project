import 'package:flutter/material.dart';

import '../_palette/orchestrator_palette.dart';

/// Elevated white-card wrapper for non-map orchestrator body stubs.
///
/// **Why this exists.** Pre-polish, each non-map body stub (Awaiting,
/// Confirmed, Inspecting, Quoted, ...) rendered the hero icon and the
/// server's `bodyText` directly on the screen's ambient tint with no
/// surface treatment. Read as "Material starter" next to the polished
/// summary card directly below it. This shell wraps them in the same
/// surface language as the summary card so the screen reads as one
/// cohesive container family:
///
///   * White surface (`theme.colorScheme.surface`).
///   * 16px rounded corners.
///   * `#0051AE` at 6% hairline border — felt-not-seen brand cue.
///   * Soft brand-blue drop shadow (palette `brandSoftShadow`).
///   * Internal padding for the hero + message stack.
///   * Subtle scale-in on first mount so AnimatedSwitcher (the body
///     swap when status flips) reads as intentional rather than a hard
///     cut.
///
/// **Not used for map bodies.** EN_ROUTE / ARRIVED bodies host
/// LiveTrackingMap which has its own ClipRRect surface — wrapping it
/// in another shell would double-card the map. They stay bare.
class BodyShell extends StatelessWidget {
  const BodyShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TweenAnimationBuilder<double>(
        // 0.96 → 1.0 over 240ms makes the inbound body feel like it
        // "settles" into place when AnimatedSwitcher swaps it in.
        // Curves.easeOutBack adds a single hair of overshoot that
        // matches the kinetic-but-composed feel of the rest of the
        // screen.
        tween: Tween(begin: 0.96, end: 1.0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // Slightly firmer than `brandPrimaryTint06` (10% vs 6%):
              // the shell is the largest surface on screen, so the
              // softer tint vanishes against the ambient page tint.
              color: OrchestratorPalette.brandPrimary.withValues(alpha: 0.10),
              width: 1,
            ),
            boxShadow: OrchestratorPalette.brandSoftShadow,
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: child,
        ),
      ),
    );
  }
}

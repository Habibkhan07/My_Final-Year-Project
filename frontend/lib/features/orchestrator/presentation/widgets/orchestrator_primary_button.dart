import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '_palette/orchestrator_palette.dart';

/// The orchestrator's canonical primary CTA recipe.
///
/// Single source of truth for the brand-blue (or destructive) elevated
/// button language. Replaces six near-identical inline
/// `ElevatedButton.styleFrom` blocks across the orchestrator surface
/// (the per-feature button recipes had drifted on radius, padding,
/// elevation, fontWeight, shadow alpha, and spinner size).
///
/// **Visual recipe:**
///   * Full-width, `padding: vertical: 16` (≈ 56 dp tall)
///   * 16-radius rectangle
///   * Elevation 8 (pressed 2)
///   * Background: `brandPrimary` or — when `isDestructive: true` —
///     `dangerBase` (brand-cool burgundy, NOT M3's pink-coral
///     `colorScheme.error` derivation)
///   * Pressed darkens to `brandPrimaryDeep` (or `dangerBase @ 86%`)
///   * Disabled: background falls to `bg @ 55%`; label stays white
///   * Shadow: `bg @ 40%`
///   * Ripple overlay: `white @ 10%`
///   * Label fontSize 16 w700 letterSpacing 0.2
///   * Optional 20-px leading icon (used by error-card "Try again")
///   * Light haptic on tap (`unawaited`, no-op under `flutter_test`)
///   * Busy: 22×22 white spinner replaces the label
///
/// **Usage:**
///   * `enabled` mode: pass an `onPressed` callback. `null` disables.
///   * `busy` mode: pass `busy: true`. Disables tap and shows spinner.
///   * `destructive` mode: pass `isDestructive: true`. Swaps brand-blue
///     for burgundy red.
///   * `icon` mode: pass an `IconData`. Renders before the label.
///
/// **Do not bypass.** New primary CTAs in the orchestrator must use
/// this widget — directly or via a thin feature-side wrapper — so the
/// recipe cannot drift again.
class OrchestratorPrimaryButton extends StatelessWidget {
  const OrchestratorPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.isDestructive = false,
    this.icon,
    this.hapticOnTap = true,
  });

  /// Button label. Server-driven for action-button call sites
  /// (`booking.ui.primaryAction.label`); literal for feature-side
  /// wrappers (e.g. "Submit review", "Try again").
  final String label;

  /// Tap callback. `null` disables the button; `busy: true` also
  /// disables (regardless of this value).
  final VoidCallback? onPressed;

  /// When true, replaces the label with a centered spinner and
  /// disables the tap. Use for inflight network calls.
  final bool busy;

  /// When true, renders the destructive (red) variant. Backed by
  /// `OrchestratorPalette.dangerBase` (cool burgundy) — NOT M3's
  /// pink-coral `colorScheme.error` derivation.
  final bool isDestructive;

  /// Optional leading icon. When non-null, the child becomes
  /// `[Icon, gap, label]`. Used by the error card's "Try again".
  final IconData? icon;

  /// Fire `HapticFeedback.lightImpact()` on tap. Defaults to true.
  /// Set false at call sites that fire their own haptic upstream
  /// (e.g. the orchestrator action button's classification router).
  final bool hapticOnTap;

  @override
  Widget build(BuildContext context) {
    final canPress = onPressed != null && !busy;
    final bgBase = isDestructive
        ? OrchestratorPalette.dangerBase
        : OrchestratorPalette.brandPrimary;
    final pressedBase = isDestructive
        ? OrchestratorPalette.dangerBase.withValues(alpha: 0.86)
        : OrchestratorPalette.brandPrimaryDeep;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canPress
            ? () {
                if (hapticOnTap) unawaited(HapticFeedback.lightImpact());
                onPressed!.call();
              }
            : null,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return pressedBase;
            if (states.contains(WidgetState.disabled)) {
              return bgBase.withValues(alpha: 0.55);
            }
            return bgBase;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 2;
            return 8;
          }),
          shadowColor:
              WidgetStatePropertyAll(bgBase.withValues(alpha: 0.4)),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.10),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : (icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  )
                : Text(label)),
      ),
    );
  }
}

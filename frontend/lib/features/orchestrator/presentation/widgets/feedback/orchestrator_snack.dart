import 'package:flutter/material.dart';

import '../_palette/orchestrator_palette.dart';

/// Toast/snack helper for the orchestrator screen.
///
/// **Why this exists.** Default `ScaffoldMessenger.showSnackBar` lands
/// at the bottom of the Scaffold body. The orchestrator's column-layout
/// (header / progress / timeline / Expanded body / summary card /
/// action bar) puts the action bar *inside* the body, so a fixed snack
/// paints right where the action bar lives — visually overlapping the
/// map's bottom edge. That's the "confirmation message appears above
/// the map" bug the user reported.
///
/// This helper:
///   * Uses `SnackBarBehavior.floating` so the snack is a free-floating
///     toast rather than anchored to the body edge.
///   * Reserves a bottom margin that clears the action bar AND the
///     device's gesture-nav inset — so the toast floats just above the
///     primary CTA, never overlapping it.
///   * Renders on-brand: brand-blue background for info, error tint
///     for errors, rounded 14px, 16px white icon prefix, white
///     semi-bold label. The same toast language across the whole
///     orchestrator surface.
///   * Caps duration to 3.5s — toast, not interruption.
///
/// Use `OrchestratorSnack.info(context, message)` /
/// `OrchestratorSnack.error(context, message)` from any orchestrator
/// widget. The text the user sees is exactly the `message` string —
/// callers control wording, the helper controls shape.
class OrchestratorSnack {
  const OrchestratorSnack._();

  /// Action-bar reservation. Matches the lifted action bar's intrinsic
  /// height (~84 with one button + padding) plus an 8px breathing gap.
  /// The actual gesture-nav inset is added on top of this at call time
  /// via `MediaQuery.viewPadding.bottom`.
  static const double _actionBarReservation = 92;

  /// Brand info snack — confirmation-style messages.
  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: OrchestratorPalette.brandPrimary,
      icon: Icons.info_rounded,
    );
  }

  /// Error snack — server/transport failures.
  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      background: Theme.of(context).colorScheme.error,
      icon: Icons.error_rounded,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color background,
    required IconData icon,
  }) {
    // Defensive: outside any ScaffoldMessenger (unusual but possible in
    // tests that mount a bare Widget). Fall back to a noop instead of
    // throwing — the alternative is the test isolate dying on a
    // ScaffoldMessenger lookup which never reaches production.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    final bottomInset = mediaQuery?.viewPadding.bottom ?? 0;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          // floating + custom margin = sits above the action bar
          // instead of underneath it.
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            _actionBarReservation + bottomInset,
          ),
          backgroundColor: background,
          elevation: 6,
          duration: const Duration(milliseconds: 3500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

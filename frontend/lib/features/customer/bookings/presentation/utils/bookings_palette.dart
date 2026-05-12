import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_ui_tone.dart';

/// Internal brand-token surface for the bookings list.
///
/// **Why this exists.** Mirrors `OrchestratorPalette` so the list screen
/// reads as one elevated surface family with the orchestrator (same
/// brand-blue shadow recipe, same #0051AE foreground, same tone vocab
/// for the leading accent bar). We do NOT import `OrchestratorPalette`
/// directly because its docstring forbids cross-feature import — and
/// importing across feature boundaries would invert the dependency
/// graph the orchestrator feature deliberately drew.
///
/// **Scope.** Constants + a tone resolver. NOT a theme refactor — per
/// `project_ui_cleanup_planned` memory the end-of-UI design pass will
/// fold this and `OrchestratorPalette` into one shared token surface
/// in a single sweep. Until then, the two files are intentionally
/// parallel.
class BookingsPalette {
  const BookingsPalette._();

  // ─── Brand identity ─────────────────────────────────────────────────

  /// Karigar deep blue — same hex as OrchestratorPalette.brandPrimary
  /// and the booking-flow ElevatedButton recipe.
  static const Color brandPrimary = Color(0xFF0051AE);

  static Color get brandPrimaryTint06 =>
      brandPrimary.withValues(alpha: 0.06);
  static Color get brandPrimaryTint12 =>
      brandPrimary.withValues(alpha: 0.12);

  // ─── Ink ────────────────────────────────────────────────────────────

  static const Color inkPrimary = Color(0xFF0A2540);
  static Color get inkSecondary => inkPrimary.withValues(alpha: 0.72);

  // ─── Shadow recipes ─────────────────────────────────────────────────

  /// Soft brand-blue drop shadow — the orchestrator-family elevated
  /// surface look. Replaces the previous black @ 5% which read as
  /// generic-Material on the bookings list.
  static List<BoxShadow> get brandSoftShadow => [
        BoxShadow(
          color: brandPrimary.withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── Tone accents (leading bar on the booking card) ─────────────────

  /// Colour for the 4px leading accent strip drawn on each card. Lets
  /// the user read status from the card's edge before they read any
  /// text. Picked from the same brand-cool family the orchestrator
  /// uses — positive/info both render brand-blue, warning amber,
  /// negative burgundy, neutral greys to the theme outline.
  static Color toneAccent(BookingUiTone tone) {
    switch (tone) {
      case BookingUiTone.positive:
      case BookingUiTone.info:
        return brandPrimary;
      case BookingUiTone.warning:
        return const Color(0xFFF59E0B); // amber-500
      case BookingUiTone.negative:
        return const Color(0xFFB91C1C); // red-700
      case BookingUiTone.neutral:
      case BookingUiTone.unknown:
        return AppColors.outlineVariant;
    }
  }
}

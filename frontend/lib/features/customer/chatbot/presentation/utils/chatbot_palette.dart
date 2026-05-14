import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Internal brand-token surface for the chatbot screen.
///
/// **Why this exists.** Mirrors `BookingsPalette` so the chatbot screen
/// reads as one elevated surface family with the booking flow — same
/// `#0051AE` foreground for primary actions, same brand-soft shadow
/// recipe on the composer, same ink hierarchy. We do NOT import
/// `BookingsPalette` directly because its docstring forbids cross-
/// feature import — importing across feature boundaries would invert
/// the dependency graph the bookings feature deliberately drew.
///
/// **Scope.** Constants only. NOT a theme refactor — per
/// `project_ui_cleanup_planned` memory the end-of-UI design pass will
/// fold this and `BookingsPalette` (and `OrchestratorPalette`) into one
/// shared token surface in a single sweep. Until then, the parallel
/// files are intentional.
class ChatbotPalette {
  const ChatbotPalette._();

  // ─── Brand identity ─────────────────────────────────────────────────

  /// Karigar deep blue — same hex as `BookingsPalette.brandPrimary` and
  /// the booking-flow `ElevatedButton` recipe. Used on the send-button
  /// fill, USER bubble background, and the closing-card CTA.
  static const Color brandPrimary = Color(0xFF0051AE);

  static Color get brandPrimaryTint06 => brandPrimary.withValues(alpha: 0.06);
  static Color get brandPrimaryTint12 => brandPrimary.withValues(alpha: 0.12);

  // ─── Bubble surfaces ────────────────────────────────────────────────

  /// USER bubble background. Solid brand-blue — same recipe as the
  /// booking-flow primary buttons. White text reads at AAA on this.
  static const Color userBubble = brandPrimary;
  static const Color userBubbleInk = Color(0xFFFFFFFF);

  /// BOT bubble background. Cool-grey surface that reads as a
  /// distinct-but-neutral counterpoint to the brand-blue user side.
  static const Color botBubble = Color(0xFFF1F4F8);
  static Color get botBubbleInk => AppColors.onSurface;

  /// SYSTEM messages render without a bubble — italic centered text
  /// in this muted color. Used for the closing "Ticket #N — we'll
  /// review within 3 working days" line the persona injects.
  static Color get systemInk => AppColors.onSurfaceVariant;

  // ─── Composer surface ───────────────────────────────────────────────

  /// Background of the composer strip below the transcript.
  static const Color composerSurface = Color(0xFFFFFFFF);

  /// Soft brand-blue drop shadow above the composer — same recipe as
  /// `BookingsPalette.brandSoftShadow`, kept parallel until the
  /// design-system unification pass.
  static List<BoxShadow> get composerSoftShadow => [
    BoxShadow(
      color: brandPrimary.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, -4),
    ),
  ];

  // ─── Affordances ────────────────────────────────────────────────────

  /// Closing-card check icon color. Material green-500 / Tailwind
  /// emerald-500. Reads as "filed" without being marketing-loud.
  static const Color successAccent = Color(0xFF10B981);

  /// Network-error inline banner background.
  static const Color networkBannerSurface = Color(0xFFFFF7E6);

  /// Network-error inline banner foreground (icon + text).
  static const Color networkBannerInk = Color(0xFFB45309);
}

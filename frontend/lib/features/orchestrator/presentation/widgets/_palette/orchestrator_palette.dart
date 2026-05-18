import 'package:flutter/material.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../../customer/bookings/domain/entities/booking_ui_tone.dart';
import '../../../domain/entities/booking_detail.dart';

/// Internal brand-token surface for the orchestrator screen.
///
/// **Why this exists.** The orchestrator's polish reaches for one
/// consistent visual identity — Karigar's deep-blue ElevatedButton
/// language from the booking flow. Before this file, the hex literal
/// `#0051AE` was duplicated across ~6 widget files and tone shifts
/// (e.g. a slightly darker stop for a gradient, a 6% tint for a soft
/// border) were each re-derived ad-hoc. That drift is the kind of
/// thing the user noticed when they asked whether the colors "fit the
/// app theme deep blue".
///
/// **Scope of this file is intentionally narrow.** This is NOT a theme
/// refactor — per `project_ui_cleanup_planned` memory the user plans a
/// dedicated end-of-UI design-system pass and explicitly does NOT want
/// theme churn mid-feature. So:
///   * Tokens are constants, not theme extension.
///   * Only orchestrator widgets import this. No global re-wiring.
///   * The end-of-UI pass can lift these into `AppColors` / a real
///     theme extension in one mechanical sweep.
///
/// Public surface is a static-only class so call-sites read like
/// `OrchestratorPalette.brandPrimary` — close enough to a token import
/// that the end-of-UI rename is a find/replace.
class OrchestratorPalette {
  const OrchestratorPalette._();

  // ─── Brand identity ─────────────────────────────────────────────────

  /// Karigar deep blue. Matches `features/booking/.../review_booking_sheet.dart`
  /// ElevatedButton recipe — the brand's recognised primary action color.
  static const Color brandPrimary = Color(0xFF0051AE);

  /// Darker stop for brand-blue gradients (action button, countdown
  /// fill). Picked so the gradient feels lit-from-the-top without
  /// drifting toward navy / black.
  static const Color brandPrimaryDeep = Color(0xFF003C7F);

  /// Brand-blue at 6% — used for hairline borders on light surfaces.
  /// Faint enough to be felt, not seen.
  static Color get brandPrimaryTint06 =>
      brandPrimary.withValues(alpha: 0.06);

  /// Brand-blue at 12% — soft fills (tinted call CTA, mini chips).
  static Color get brandPrimaryTint12 =>
      brandPrimary.withValues(alpha: 0.12);

  /// Brand-blue at 18% — pressed-state overlays.
  static Color get brandPrimaryTint18 =>
      brandPrimary.withValues(alpha: 0.18);

  /// Brand-blue at 22% — track behind the drained portion of the
  /// countdown button's fill.
  static Color get brandPrimaryTrack =>
      brandPrimary.withValues(alpha: 0.22);

  // ─── Ink / text ─────────────────────────────────────────────────────

  /// Cool charcoal — matches the literal `_titleText` used by the
  /// customer profile screen and the pending-approval onboarding
  /// screen. Previously the orchestrator used `#0A2540` (navy-leaning)
  /// which read as slightly cooler-than-blue next to the rest of the
  /// app's `#151C24`. Aligning so identity surfaces feel of-a-piece.
  static const Color inkPrimary = Color(0xFF151C24);

  /// Body / support text — literal `#424753`, mirrors the customer
  /// profile's `_bodyText`. Was previously `inkPrimary @ 72%`.
  static const Color inkSecondary = Color(0xFF424753);

  /// Captions / tertiary text — literal `#727785`, mirrors the
  /// customer profile's `_mutedText`. Was previously `inkPrimary @ 55%`.
  static const Color inkTertiary = Color(0xFF727785);

  // ─── Page background ────────────────────────────────────────────────

  /// Flat cool off-white used as the orchestrator screen's Scaffold
  /// background — matches the literal `_bg` token in the pending
  /// approval screen. Previously the screen used a per-status
  /// tone-tinted `alphaBlend` over `theme.colorScheme.surface`; that
  /// subtle wash is dropped in favor of visual parity with the rest
  /// of the app. The tone signal is still carried by the hero
  /// header's 4-px bottom stripe (post-Chunk-H) and the status chip.
  static const Color pageBackground = Color(0xFFF6F8FC);

  // ─── Semantic accents ───────────────────────────────────────────────

  /// Brand-blue's warning-state pair — used by the countdown button
  /// after the meeting window elapses.
  static const Color warningAmber = Color(0xFFF59E0B);

  /// Slightly deeper amber for the gradient bottom of the expired-state
  /// fill — same delta the brand uses (deep → bright top-down).
  static const Color warningAmberDeep = Color(0xFFD97706);

  /// On-brand success — a green retuned toward the brand's cool family
  /// rather than stock Material green. Reads as "yes, done" without
  /// fighting the deep-blue palette.
  static const Color successDeep = Color(0xFF1E6B36);

  /// Success surface — light green tint, retuned cool.
  static const Color successSurface = Color(0xFFE6F2EA);

  /// Rating gold — for star icons (review form, summary card rating
  /// chip). Distinct from `warningAmber`: gold reads as a celebratory
  /// "this is a star you tapped", amber reads as a warning. Matches the
  /// existing rating-chip recipe in `booking_summary_card.dart`.
  static const Color ratingGold = Color(0xFFFFB400);

  // ─── Shadow recipes ─────────────────────────────────────────────────

  /// Soft brand-blue drop shadow at 6% — used by body shells and the
  /// summary card so the whole screen reads as one elevated surface
  /// family rather than each card having a separate Material shadow.
  static List<BoxShadow> get brandSoftShadow => [
    BoxShadow(
      color: brandPrimary.withValues(alpha: 0.06),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  /// Stronger shadow for tap-active surfaces (the primary CTA).
  static List<BoxShadow> get brandActionShadow => [
    BoxShadow(
      color: brandPrimary.withValues(alpha: 0.32),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  // ─── Tone palette ───────────────────────────────────────────────────
  //
  // **Why this exists.** Material 3's auto-derived `tertiaryContainer`
  // and `errorContainer` from a deep-blue seed produce *pink-coral*
  // tints — when those leaked into the orchestrator's warning /
  // negative tone surfaces, the user noticed the page background going
  // pink on AWAITING / CANCELLED bookings. Pink doesn't fit Karigar's
  // deep-blue identity. These tone specs bypass M3's derivations and
  // land on explicit, brand-cool colors per tone.
  //
  // Numbers are deliberately low-alpha — the hero header's wash needs
  // to read as "this booking is in trouble" or "needs attention"
  // without alarming the user with full-saturation red.

  /// **Negative** (cancelled, rejected, disputed, no-show).
  /// Cool red — `#B91C1C` (red-700) for the gradient base, `#7F1D1D`
  /// (red-900) for the foreground. At low alpha this reads as
  /// "burgundy red wash", never as pink-coral.
  static const Color _negativeBase = Color(0xFFB91C1C);
  static const Color _negativeForeground = Color(0xFF7F1D1D);

  /// Public danger tokens for destructive surfaces (error banners,
  /// review error shells, cancel-confirm buttons). Bypasses M3's
  /// `colorScheme.error` which derives a pink-coral red from the
  /// brand-blue seed — see the docstring above this section.
  ///
  /// Usage:
  ///   * `dangerInk` — text / icon on a light dangerSurface
  ///   * `dangerBase` — solid bg for destructive primary buttons
  ///   * `dangerSurface` — light wash bg for inline error banners
  ///   * `dangerBorder` — hairline for error containers
  static const Color dangerInk = _negativeForeground;
  static const Color dangerBase = _negativeBase;
  static Color get dangerSurface => _negativeBase.withValues(alpha: 0.08);
  static Color get dangerBorder => _negativeBase.withValues(alpha: 0.24);

  /// **Warning** (awaiting tech-accept; arrived without ack).
  /// Amber (already our `warningAmber` token). Deep `#92400E`
  /// foreground for AA contrast on amber wash.
  static const Color _warningBase = warningAmber; // 0xFFF59E0B
  static const Color _warningForeground = Color(0xFF92400E);

  /// UI display tone for a given booking — may differ from the
  /// backend's `booking.ui.tone`.
  ///
  /// **Why a frontend-side remap exists.** The backend tags AWAITING as
  /// `warning` because it semantically "needs the tech's attention".
  /// But for the *customer* opening a freshly-placed booking, amber
  /// reads as "something is wrong" — there isn't, they're just
  /// waiting. UX-wise that flash of yellow before the tech accepts
  /// (and the tone flips to `positive`/blue) reads as a render glitch.
  ///
  /// So: when a booking is AWAITING and tagged `warning`, present it
  /// as `info` (calm brand-blue tint) instead. Every other status
  /// passes through unchanged. ARRIVED — which IS a "go outside now"
  /// state — stays `warning` (real amber). This is presentation-only;
  /// the wire contract is unchanged.
  static BookingUiTone effectiveTone(BookingDetail booking) {
    if (booking.status == BookingStatus.awaiting &&
        booking.ui.tone == BookingUiTone.warning) {
      return BookingUiTone.info;
    }
    return booking.ui.tone;
  }

  /// Resolve the orchestrator tone spec for a given [BookingUiTone].
  ///
  /// [colorScheme] is only consulted for the neutral / fallback path
  /// (uses theme surface containers). All other tones bypass M3's
  /// auto-derived containers entirely.
  static OrchestratorToneSpec toneSpec(
    BookingUiTone tone,
    ColorScheme colorScheme,
  ) {
    switch (tone) {
      case BookingUiTone.positive:
        return OrchestratorToneSpec(
          foreground: brandPrimary,
          gradientTop: brandPrimary.withValues(alpha: 0.18),
          gradientBottom: brandPrimary.withValues(alpha: 0.07),
          surfaceWash: brandPrimary.withValues(alpha: 0.04),
          pillBackground: colorScheme.surface,
        );
      case BookingUiTone.info:
        return OrchestratorToneSpec(
          foreground: brandPrimary,
          gradientTop: brandPrimary.withValues(alpha: 0.12),
          gradientBottom: brandPrimary.withValues(alpha: 0.05),
          surfaceWash: brandPrimary.withValues(alpha: 0.025),
          pillBackground: colorScheme.surface,
        );
      case BookingUiTone.warning:
        return OrchestratorToneSpec(
          foreground: _warningForeground,
          gradientTop: _warningBase.withValues(alpha: 0.22),
          gradientBottom: _warningBase.withValues(alpha: 0.09),
          surfaceWash: _warningBase.withValues(alpha: 0.05),
          pillBackground: colorScheme.surface,
        );
      case BookingUiTone.negative:
        return OrchestratorToneSpec(
          foreground: _negativeForeground,
          gradientTop: _negativeBase.withValues(alpha: 0.16),
          gradientBottom: _negativeBase.withValues(alpha: 0.06),
          surfaceWash: _negativeBase.withValues(alpha: 0.035),
          pillBackground: colorScheme.surface,
        );
      case BookingUiTone.neutral:
      case BookingUiTone.unknown:
        return OrchestratorToneSpec(
          foreground: colorScheme.onSurfaceVariant,
          gradientTop: colorScheme.surfaceContainerHigh,
          gradientBottom: colorScheme.surfaceContainerLow,
          surfaceWash: colorScheme.surface,
          pillBackground: colorScheme.surface,
        );
    }
  }
}

/// Tone palette spec used by both the hero header (gradient + pill +
/// foreground) and the screen's ambient surface tint (`surfaceWash`).
/// Keeping a single struct ensures the hero color family and the
/// page-background wash agree — the screen feels like one toned
/// surface, not two surfaces with mismatched accents.
class OrchestratorToneSpec {
  const OrchestratorToneSpec({
    required this.foreground,
    required this.gradientTop,
    required this.gradientBottom,
    required this.surfaceWash,
    required this.pillBackground,
  });

  /// Color for icons / text on the hero header. AA-contrast over the
  /// hero gradient.
  final Color foreground;

  /// Top stop of the hero header's vertical gradient.
  final Color gradientTop;

  /// Bottom stop of the hero header's vertical gradient.
  final Color gradientBottom;

  /// Whole-page ambient wash. Applied to the Scaffold background at
  /// the tone's faintest level.
  final Color surfaceWash;

  /// Background color of the surface chips inside the hero header
  /// (e.g. the status pill). Always the theme surface so the chip
  /// pops off the tinted hero.
  final Color pillBackground;
}


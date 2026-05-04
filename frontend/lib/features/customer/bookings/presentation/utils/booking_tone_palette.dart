import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/booking_ui_tone.dart';

/// Resolves a [BookingUiTone] into a (background, foreground) color pair
/// for status pills and tone-tinted strips.
///
/// The card widget switches on `booking.ui.badgeTone` (server-driven) and
/// asks this resolver for tokens — never on the raw [BookingStatus]. This
/// is the dumb-UI seam: server picks tone, client picks tokens.
///
/// Sources tokens directly from [AppColors] rather than the live
/// `ColorScheme` because the project's `MaterialApp.theme` uses
/// `ColorScheme.fromSeed(...)` — the seeded scheme drifts from the
/// canonical palette in `session_4_customer_bookings_list_ui.md` §3.1.
/// Reading [AppColors] gives us the exact specified tokens regardless of
/// the surrounding theme. When the global theme is migrated to explicit
/// M3 tokens (planned cleanup pass), this resolver can be ported to read
/// `Theme.of(context).colorScheme` without changing any callers.
class BookingTonePalette {
  final Color background;
  final Color foreground;
  final Color border;

  const BookingTonePalette({
    required this.background,
    required this.foreground,
    required this.border,
  });

  /// Returns the canonical (bg, fg, border) for [tone].
  ///
  /// [BookingUiTone.unknown] falls back to neutral so a forward-compat
  /// pill (server ships an unrecognized tone string in a future release)
  /// still renders cleanly.
  static BookingTonePalette of(BookingUiTone tone) {
    switch (tone) {
      case BookingUiTone.positive:
        return const BookingTonePalette(
          background: AppColors.secondaryContainer,
          foreground: AppColors.onSecondaryContainer,
          border: AppColors.onSecondaryContainer,
        );
      case BookingUiTone.warning:
        return BookingTonePalette(
          background: AppColors.tertiaryFixedDim.withValues(alpha: 0.20),
          foreground: AppColors.onTertiaryFixed,
          border: AppColors.tertiaryFixedDim.withValues(alpha: 0.40),
        );
      case BookingUiTone.negative:
        return BookingTonePalette(
          background: AppColors.errorContainer.withValues(alpha: 0.30),
          foreground: AppColors.onErrorContainer,
          border: AppColors.errorContainer.withValues(alpha: 0.50),
        );
      case BookingUiTone.info:
        return BookingTonePalette(
          background: AppColors.primaryContainer.withValues(alpha: 0.15),
          foreground: AppColors.primary,
          border: AppColors.primaryContainer.withValues(alpha: 0.30),
        );
      case BookingUiTone.neutral:
      case BookingUiTone.unknown:
        return const BookingTonePalette(
          background: AppColors.surfaceContainerHigh,
          foreground: AppColors.onSurfaceVariant,
          border: AppColors.outlineVariant,
        );
    }
  }
}

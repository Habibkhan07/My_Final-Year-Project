// Pure resolver — no widgets. Asserts each [BookingUiTone] yields the
// brief's §3.1 token pair. Locks the dumb-UI seam: the card switches on
// tone, this resolver translates tone → tokens, nothing else gets to
// invent its own colour mapping.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/customer/bookings/domain/entities/booking_ui_tone.dart';
import 'package:frontend/features/customer/bookings/presentation/utils/booking_tone_palette.dart';

void main() {
  group('BookingTonePalette.of', () {
    test('positive → secondaryContainer + onSecondaryContainer', () {
      final p = BookingTonePalette.of(BookingUiTone.positive);
      expect(p.background, AppColors.secondaryContainer);
      expect(p.foreground, AppColors.onSecondaryContainer);
    });

    test('warning → tertiaryFixedDim @20% + onTertiaryFixed', () {
      final p = BookingTonePalette.of(BookingUiTone.warning);
      expect(
        p.background,
        AppColors.tertiaryFixedDim.withValues(alpha: 0.20),
      );
      expect(p.foreground, AppColors.onTertiaryFixed);
    });

    test('negative → errorContainer @30% + onErrorContainer', () {
      final p = BookingTonePalette.of(BookingUiTone.negative);
      expect(
        p.background,
        AppColors.errorContainer.withValues(alpha: 0.30),
      );
      expect(p.foreground, AppColors.onErrorContainer);
    });

    test('info → primaryContainer @15% + primary', () {
      final p = BookingTonePalette.of(BookingUiTone.info);
      expect(
        p.background,
        AppColors.primaryContainer.withValues(alpha: 0.15),
      );
      expect(p.foreground, AppColors.primary);
    });

    test('neutral → surfaceContainerHigh + onSurfaceVariant', () {
      final p = BookingTonePalette.of(BookingUiTone.neutral);
      expect(p.background, AppColors.surfaceContainerHigh);
      expect(p.foreground, AppColors.onSurfaceVariant);
    });

    test('unknown falls back to neutral palette', () {
      // Forward-compat: a server-emitted tone string we don't recognise
      // must still render — never blank, never crash.
      final unknown = BookingTonePalette.of(BookingUiTone.unknown);
      final neutral = BookingTonePalette.of(BookingUiTone.neutral);
      expect(unknown.background, neutral.background);
      expect(unknown.foreground, neutral.foreground);
      expect(unknown.border, neutral.border);
    });

    test('every tone exposes a non-transparent border colour', () {
      for (final tone in BookingUiTone.values) {
        final p = BookingTonePalette.of(tone);
        expect(p.border, isA<Color>());
        // Borders may be alpha-blended but should never be fully clear.
        expect(p.border.a, greaterThan(0));
      }
    });
  });
}

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_shapes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../domain/entities/booking_ui_tone.dart';
import '../utils/booking_tone_palette.dart';

/// Status pill — uppercase tracking-wider label inside a fully-rounded,
/// tone-tinted capsule.
///
/// Geometry per session_4 §3.5:
///   * `8px` horizontal × `2px` vertical padding
///   * fully rounded
///   * `1px` solid border at higher alpha than the bg
///   * 12/16 weight 600, `0.05em` letter-spacing
///
/// Wrap in [AnimatedSwitcher] keyed on the badge text + tone when the
/// caller wants the pill to morph cleanly across realtime patches (e.g.
/// AWAITING → CONFIRMED). The pill itself is dumb.
class BookingStatusPill extends StatelessWidget {
  const BookingStatusPill({
    super.key,
    required this.text,
    required this.tone,
  });

  final String text;
  final BookingUiTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = BookingTonePalette.of(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppShapes.radiusFull),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: palette.foreground,
        ),
      ),
    );
  }
}

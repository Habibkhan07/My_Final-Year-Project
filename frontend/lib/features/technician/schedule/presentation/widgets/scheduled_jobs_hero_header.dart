import 'package:flutter/material.dart';

import '../../../../customer/bookings/presentation/utils/bookings_palette.dart';

/// Curved tone-tinted hero for the Schedule screen.
///
/// Same geometry + tokens as `BookingsHeroHeader` (customer side) — both
/// screens cut an identical 24px concave bottom curve and use the same
/// brand-blue wash. Re-implemented here rather than imported because the
/// customer widget hardcodes `My Bookings` and ships with `flutter_riverpod`
/// it doesn't need; the schedule version is intentionally smaller.
class ScheduledJobsHeroHeader extends StatelessWidget {
  const ScheduledJobsHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;

  /// Null hides the subtitle row entirely. Empty string treated the same.
  final String? subtitle;

  /// Null hides the back arrow (screen sits inside the dashboard nav as
  /// a tab destination). Non-null is the deep-link entry path.
  final VoidCallback? onBack;

  static const _curveHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    final hasBack = onBack != null;
    return ClipPath(
      clipper: const _HeaderClipper(curveHeight: _curveHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BookingsPalette.brandPrimary.withValues(alpha: 0.12),
              BookingsPalette.brandPrimary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              4,
              hasBack ? 4 : 12,
              4,
              _curveHeight + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasBack)
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: BookingsPalette.brandPrimary,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          height: 32 / 26,
                          fontWeight: FontWeight.w800,
                          color: BookingsPalette.brandPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 18 / 13,
                            fontWeight: FontWeight.w500,
                            color: BookingsPalette.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  const _HeaderClipper({required this.curveHeight});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curveHeight,
        size.width,
        size.height - curveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant _HeaderClipper old) =>
      old.curveHeight != curveHeight;
}

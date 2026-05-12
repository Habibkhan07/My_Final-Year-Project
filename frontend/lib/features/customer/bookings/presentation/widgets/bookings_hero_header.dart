import 'package:flutter/material.dart';

import '../utils/bookings_palette.dart';

/// Curved tone-tinted hero for the customer bookings list.
///
/// Replaces the previous plain Material `AppBar` so the bookings list
/// shares visual vocabulary with the orchestrator's hero header — same
/// 24px concave bottom curve, same brand-blue info-tone wash, same
/// `BookingsPalette.brandSoftShadow` family.
///
/// **Anatomy** (top → bottom):
///   1. Optional back arrow (when reached via deep link, not from the
///      tab bar).
///   2. Title — `My Bookings` — in brand foreground.
///   3. Optional subtitle — `2 upcoming · 5 past` when counts have
///      loaded.
///
/// **Curve.** 24px concave, identical geometry to
/// `OrchestratorHeroHeader`'s `_HeaderClipper` so the two screens cut
/// the same shape.
class BookingsHeroHeader extends StatelessWidget {
  const BookingsHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
  });

  final String title;

  /// Null hides the subtitle row entirely. Empty string is treated the
  /// same so callers can pass a `whenData` result without null checks.
  final String? subtitle;

  /// Null hides the back arrow (the screen sits inside the home-screen
  /// IndexedStack as a tab destination — no back arrow). Non-null is
  /// the deep-link entry path.
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
            padding: EdgeInsets.fromLTRB(4, hasBack ? 4 : 12, 4, _curveHeight + 12),
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

/// Concave bottom curve. Same geometry as
/// `OrchestratorHeroHeader._HeaderClipper` so both heroes cut an
/// identical curve when the user navigates between them.
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

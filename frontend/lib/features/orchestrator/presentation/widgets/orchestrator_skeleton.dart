import 'package:flutter/material.dart';

import '../../../../core/animations/loop_mode.dart';

/// Shimmer skeleton matching the orchestrator screen's layout.
///
/// Rendered during first-mount load (when `bookingDetailProvider` has no
/// prior value). Replaces the bare [CircularProgressIndicator] so users
/// see structure immediately — gives the perceived performance of a
/// pre-rendered page and tells them what to expect.
///
/// **Shape rules.** Each rectangle/circle here corresponds 1:1 to a real
/// element of the loaded screen:
///   * the curved top band ≈ [OrchestratorHeroHeader]'s tinted hero
///   * the row of small circles ≈ the [TimelineSlot] dots
///   * the big rounded block ≈ the body hero (`AnimatedStatusIcon` +
///     copy in `_AnimatedBody`)
///   * the lower wide block ≈ the [BookingSummaryCard]
///   * the bottom pill ≈ the primary action button
///
/// **Shimmer.** A single repeating [AnimationController] drives a
/// horizontal `LinearGradient` sweep across the screen. The same sweep
/// is applied to every block via a top-level [ShaderMask] — saves the
/// cost of one shader per block. Under `flutter_test` the controller is
/// stopped (avoids `pumpAndSettle` deadlock); shimmer is purely
/// cosmetic, so a static frozen skeleton is acceptable in tests.
class OrchestratorSkeleton extends StatefulWidget {
  const OrchestratorSkeleton({super.key});

  @override
  State<OrchestratorSkeleton> createState() => _OrchestratorSkeletonState();
}

class _OrchestratorSkeletonState extends State<OrchestratorSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (shouldLoopAnimations()) _shimmer.repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final highlight = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        final shift = _shimmer.value * 2 - 1; // -1 → 1 sweep position
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1 + shift * 1.5, 0),
              end: Alignment(1 + shift * 1.5, 0),
              colors: [base, highlight, base],
              stops: const [0.30, 0.50, 0.70],
            ).createShader(rect);
          },
          child: _SkeletonLayout(base: base),
        );
      },
    );
  }
}

/// Static layout that the shimmer sweeps over. Pulled out so the
/// `ShaderMask` can re-use the same widget tree on every frame.
///
/// The whole layout sits inside a non-scrollable [SingleChildScrollView]
/// so the skeleton tolerates narrow viewports gracefully — small
/// landscape test surfaces won't trip a flex overflow, and yet the
/// shimmer surface still reads as a single coherent page on real
/// portrait phones where the content fits naturally.
class _SkeletonLayout extends StatelessWidget {
  const _SkeletonLayout({required this.base});
  final Color base;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Curved header band.
          _CurvedBand(color: base, height: 132),
          const SizedBox(height: 18),
          // Timeline dot row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < 5; i++) ...[
                  _SkeletonCircle(diameter: 14, color: base),
                  if (i < 4) _SkeletonLine(color: base, height: 2),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero circle (matches AnimatedStatusIcon — slightly
                // smaller than the real 180 so the skeleton fits a
                // short viewport without overflowing).
                Center(child: _SkeletonCircle(diameter: 140, color: base)),
                const SizedBox(height: 24),
                _SkeletonLine(color: base, height: 14, widthFactor: 0.65),
                const SizedBox(height: 8),
                _SkeletonLine(color: base, height: 14, widthFactor: 0.50),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Summary card.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _SkeletonBlock(color: base, height: 130, radius: 16),
          ),
          // Primary action.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: _SkeletonBlock(color: base, height: 48, radius: 14),
          ),
        ],
      ),
    );
  }
}

class _CurvedBand extends StatelessWidget {
  const _CurvedBand({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const _SkeletonHeaderClipper(),
      child: Container(
        height: height,
        color: color,
      ),
    );
  }
}

class _SkeletonHeaderClipper extends CustomClipper<Path> {
  const _SkeletonHeaderClipper();

  @override
  Path getClip(Size size) {
    const curve = 24.0;
    return Path()
      ..lineTo(0, size.height - curve)
      ..quadraticBezierTo(
        size.width / 2,
        size.height + curve,
        size.width,
        size.height - curve,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.color,
    required this.height,
    this.widthFactor,
  });

  final Color color;
  final double height;
  final double? widthFactor;

  @override
  Widget build(BuildContext context) {
    final factor = widthFactor;
    final line = Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
    if (factor == null) return Expanded(child: line);
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(widthFactor: factor, child: line),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.color,
    required this.height,
    required this.radius,
  });

  final Color color;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

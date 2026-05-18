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
/// element of the loaded screen (dimensions kept in sync with the real
/// chrome so cold-load → data-arrival does not visually jump):
///   * the flat 70-px top band ≈ [OrchestratorHeroHeader]'s flat row
///     (was a 132-px curve before the header was flattened — chunk 5
///     dropped the curve clipper to match)
///   * the row of 6 small circles ≈ the [TimelineSlot] dots
///   * the big rounded block ≈ the body hero (`AnimatedStatusIcon` +
///     copy in `_AnimatedBody`)
///   * the 70-px summary card ≈ the slim [BookingSummaryCard]
///   * the 56-px primary action pill ≈ the canonical
///     [OrchestratorPrimaryButton] (radius 16)
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
          // Flat 70-px header band — matches the real
          // OrchestratorHeroHeader (the previous curved 132-px hero
          // was flattened to a single-row ~60-80 px band; the skeleton
          // mirrors that now so cold-load → data-arrival doesn't
          // visually jump from a curved tinted swoop to a flat strip).
          Container(height: 70, color: base),
          const SizedBox(height: 18),
          // Timeline dot row — 6 dots match TimelineSlot's six phases
          // (was 5 before the Booked/Confirmed split landed).
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                for (var i = 0; i < 6; i++) ...[
                  _SkeletonCircle(diameter: 14, color: base),
                  if (i < 5) _SkeletonLine(color: base, height: 2),
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
          // Summary card — height matches the real slim 64-70 px
          // BookingSummaryCard (was 130 — a relic from the pre-slim
          // design). Radius 14 matches `booking_summary_card.dart`.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _SkeletonBlock(color: base, height: 70, radius: 14),
          ),
          // Primary action — height 56 + radius 16 matches the
          // canonical OrchestratorPrimaryButton recipe (vertical
          // padding 16 ≈ 56 dp).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: _SkeletonBlock(color: base, height: 56, radius: 16),
          ),
        ],
      ),
    );
  }
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

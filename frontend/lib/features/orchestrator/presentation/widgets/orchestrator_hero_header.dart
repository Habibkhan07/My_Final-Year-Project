import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/booking_detail.dart';
import '_palette/orchestrator_palette.dart';

/// Curved tone-tinted hero header for the orchestrator screen.
///
/// **Replaces** the Material `AppBar` + the old `HeaderSlot` — those two
/// surfaces previously stacked, reading as two unrelated bars. This is
/// one cohesive piece: back arrow + booking tag + status pill (with
/// dynamic subtitle) + help button, all on a status-tone background
/// that softens into the body via a 24px concave curve.
///
/// **Anatomy** (top → bottom):
///   1. Top row — 44px — back arrow (left), booking tag (centered),
///      help button (right). Tinted to the tone's foreground.
///   2. Status pill — surface-on-tint chip with a coloured dot, the
///      server's `statusLabel`, and a status-derived subtitle ("Sent 3 min
///      ago", "Starts at 3:00 PM", "Tracking live", ...).
///   3. Optional reschedule callouts — single-line text rows for
///      `parentBookingId` ("Rescheduled from #N") and `childBookingId`
///      ("Continued on #N" — only on CANCELLED, navigates to the child).
///
/// **Curve.** A 24px concave bottom edge cut via [_HeaderClipper]. Body
/// content scrolls under that curve, hugged by the [ShaderMask] fade in
/// the screen.
///
/// **Scroll-aware elevation.** Caller passes `isScrolled = true` once
/// content has scrolled; the header animates in a soft shadow so it
/// reads as a "lifted" surface above moving content.
///
/// **Tone palette.** Same mapping as the old [HeaderSlot] palette, kept
/// here to preserve the visual contract for every status.
class OrchestratorHeroHeader extends StatelessWidget {
  const OrchestratorHeroHeader({
    super.key,
    required this.booking,
    required this.onBack,
    required this.onHelp,
    this.isScrolled = false,
  });

  final BookingDetail booking;
  final VoidCallback onBack;

  /// Null disables the help button (used while detail is loading / errored).
  final VoidCallback? onHelp;

  /// True once the scroll view has moved off zero. Drives the soft drop
  /// shadow under the curve.
  final bool isScrolled;

  static const _curveHeight = 24.0;
  static const _minContentHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Effective tone — AWAITING → info (calm blue), so the screen
    // doesn't open amber and "flash" to blue when the tech accepts.
    final tone = OrchestratorPalette.effectiveTone(booking);
    final palette = OrchestratorPalette.toneSpec(tone, theme.colorScheme);
    final hasParentCallout = booking.parentBookingId != null;
    final hasChildCallout = booking.childBookingId != null &&
        booking.status == BookingStatus.cancelled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: palette.foreground.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: ClipPath(
        clipper: const _HeaderClipper(curveHeight: _curveHeight),
        // AnimatedContainer tweens the gradient stops over 320ms when
        // the booking's tone changes — so an AWAITING → CONFIRMED
        // flip eases from info-blue to positive-blue instead of
        // cutting in a single frame.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                palette.gradientTop,
                palette.gradientBottom,
              ],
            ),
          ),
          child: SafeArea(
            top: true,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                4,
                4,
                4,
                _curveHeight + 8,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _minContentHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopRow(
                      bookingId: booking.id,
                      foreground: palette.foreground,
                      onBack: onBack,
                      onHelp: onHelp,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _StatusPill(
                        statusLabel: booking.ui.statusLabel,
                        subtitle: _dynamicSubtitle(booking),
                        isLive: _isLiveStatus(booking.status),
                        foreground: palette.foreground,
                        chipBackground: palette.pillBackground,
                      ),
                    ),
                    if (hasParentCallout || hasChildCallout) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasParentCallout)
                              Text(
                                'Rescheduled from #${booking.parentBookingId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.foreground.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            if (hasChildCallout)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: palette.foreground,
                                ),
                                // pushReplacement so the back arrow on
                                // the child screen doesn't return to a
                                // dead CANCELLED original — the reschedule
                                // logically replaces the original.
                                // Matches `BookingRescheduledNotifier`'s
                                // auto-nav behaviour for symmetry.
                                onPressed: () => GoRouter.of(context)
                                    .pushReplacement(
                                      '/booking/${booking.childBookingId}',
                                    ),
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                ),
                                label: Text(
                                  'Continued on #${booking.childBookingId}',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Compute a tiny subtitle that contextualises the current phase.
  ///
  /// Pure function — fed only by domain entity. Empty string means
  /// "no subtitle" and the pill collapses to a single line.
  static String _dynamicSubtitle(BookingDetail booking) {
    final ts = booking.phaseTimestamps;
    final now = DateTime.now();
    String ago(DateTime? when) {
      if (when == null) return '';
      final d = now.difference(when);
      if (d.inMinutes < 1) return 'just now';
      if (d.inMinutes < 60) return '${d.inMinutes} min ago';
      if (d.inHours < 24) return '${d.inHours} hr ago';
      return '${d.inDays}d ago';
    }

    String hhmm(DateTime when) {
      final hour12 = when.hour % 12 == 0 ? 12 : when.hour % 12;
      final mm = when.minute.toString().padLeft(2, '0');
      final ampm = when.hour < 12 ? 'AM' : 'PM';
      return '$hour12:$mm $ampm';
    }

    return switch (booking.status) {
      // AWAITING has no `createdAt` on the wire today and `scheduledStart`
      // is in the future — `ago(scheduledStart)` resolves to "just now"
      // forever, which lies after a few minutes. A static, accurate
      // subtitle sidesteps the staleness problem without plumbing
      // `created_at` through the orchestrator detail wire.
      BookingStatus.awaiting => 'Looking for a technician',
      BookingStatus.confirmed => 'Starts at ${hhmm(booking.scheduledStart)}',
      BookingStatus.enRoute => 'Tracking live',
      BookingStatus.arrived => ts.arrivedAt != null
          ? 'Arrived ${ago(ts.arrivedAt)}'
          : 'Tech is here',
      BookingStatus.inspecting => 'Inspecting now',
      BookingStatus.quoted => 'Quote ready for you',
      BookingStatus.inProgress => ts.workStartedAt != null
          ? 'Started ${ago(ts.workStartedAt)}'
          : 'In progress',
      BookingStatus.completed => ts.completedAt != null
          ? 'Finished ${ago(ts.completedAt)}'
          : 'Complete',
      BookingStatus.completedInspectionOnly => 'Inspection complete',
      BookingStatus.cancelled => 'Booking cancelled',
      BookingStatus.rejected => 'Booking rejected',
      BookingStatus.noShow => 'Marked as no-show',
      BookingStatus.disputed => 'Under review',
      BookingStatus.pending || BookingStatus.unknown => '',
    };
  }

  /// "Live" statuses get a pulsing dot in the pill — communicates that
  /// the booking is actively progressing without requiring the user to
  /// read the label.
  static bool _isLiveStatus(BookingStatus status) => switch (status) {
        BookingStatus.awaiting ||
        BookingStatus.enRoute ||
        BookingStatus.arrived ||
        BookingStatus.inspecting ||
        BookingStatus.inProgress =>
          true,
        _ => false,
      };

}

/// Top row inside the hero — back arrow (left), small booking tag
/// (centered), help icon (right). All foreground-tinted so they sit on
/// the gradient legibly without the heavy AppBar feel.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.bookingId,
    required this.foreground,
    required this.onBack,
    required this.onHelp,
  });

  final int bookingId;
  final Color foreground;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded, color: foreground),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Center(
              child: Text(
                'Booking #$bookingId',
                style: TextStyle(
                  color: foreground.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Help',
            onPressed: onHelp,
            icon: Icon(
              Icons.help_outline_rounded,
              color: onHelp == null
                  ? foreground.withValues(alpha: 0.35)
                  : foreground,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Status pill — surface chip with a coloured dot (pulses on live
/// statuses) + label + (optional) subtitle.
///
/// The pulse uses an internal [AnimationController]; opting into it via
/// the [isLive] flag rather than always-on so steady states feel
/// composed and live states feel kinetic.
class _StatusPill extends StatefulWidget {
  const _StatusPill({
    required this.statusLabel,
    required this.subtitle,
    required this.isLive,
    required this.foreground,
    required this.chipBackground,
  });

  final String statusLabel;
  final String subtitle;
  final bool isLive;
  final Color foreground;
  final Color chipBackground;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _StatusPill old) {
    super.didUpdateWidget(old);
    if (old.isLive != widget.isLive) _syncPulse();
  }

  void _syncPulse() {
    // Guard: never call .repeat() under flutter_test — the looping
    // controller stalls `pumpAndSettle`. The runtime check mirrors
    // `shouldLoopAnimations()` but is inlined here to keep the widget
    // self-contained (this widget will be widely tested via the screen).
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (widget.isLive && !isTest) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = widget.subtitle.isNotEmpty;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: hasSubtitle ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: widget.chipBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: widget.foreground.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(
            color: widget.foreground,
            controller: _pulse,
            isLive: widget.isLive,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.statusLabel,
                  style: TextStyle(
                    color: widget.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.foreground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.1,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 10px dot. When [isLive] is true a soft halo expands outward 0..1
/// driven by the parent's pulse controller — communicates "actively in
/// this state" without text.
class _PulsingDot extends StatelessWidget {
  const _PulsingDot({
    required this.color,
    required this.controller,
    required this.isLive,
  });

  final Color color;
  final AnimationController controller;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isLive)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final t = controller.value;
                return Opacity(
                  opacity: (1.0 - t) * 0.55,
                  child: Container(
                    width: 8 + (14 * t),
                    height: 8 + (14 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.55),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Concave bottom curve. Single quadratic bezier — equivalent to a soft
/// dish bottom. 24px is the user-approved curve depth.
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../customer/bookings/domain/entities/booking_status.dart';
import '../../domain/entities/booking_detail.dart';
import '../../domain/entities/booking_orchestrator_role.dart';
import '_palette/orchestrator_palette.dart';

/// Flat single-row header for the orchestrator screen.
///
/// **Replaces the previous 132-px curved gradient hero.** That design
/// consumed ~25% of viewport on a 720-px phone before the user saw any
/// actionable content. Chunk H flattens it: the chrome (curve + full
/// gradient wash + 132-px min content height) drops out; the surviving
/// tone signal becomes a 4-px colored bottom border. The status pill
/// stays — it's the load-bearing piece — but it now sits inline on the
/// top row next to the booking tag and help button instead of below
/// them on its own row.
///
/// **Anatomy** (single row, ~60-80 px depending on chip wrap):
///   * Back arrow (left, 48 px hit target)
///   * Booking tag ("Booking #N", deemphasized: 12 px / tertiary ink)
///   * Status chip (Flexible — grows to fill remaining horizontal
///     space): pulsing dot + bold label + optional subtitle stacked.
///     Subtitle wraps to a second line if the chip is too narrow for
///     a single-line layout (typical on small phones with long
///     status labels like "Inspection in progress").
///   * Help icon (right)
///
/// Below the top row (only when present): reschedule callouts
/// ("Rescheduled from #N" / "Continued on #N").
///
/// **Tone signal.** A 4-px bottom border colored by the same
/// `palette.foreground` the old gradient used. Visual weight is much
/// reduced; the chip carries most of the state communication. Same
/// AWAITING → info remap from the palette so the screen never opens
/// with a yellow flash.
///
/// **Scroll-aware shadow.** Caller passes `isScrolled = true` once
/// content has scrolled off zero; the header fades in a soft drop
/// shadow on its flat bottom edge.
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
  /// shadow on the flat bottom edge.
  final bool isScrolled;

  /// 4-px tone-colored stripe along the header's bottom edge.
  static const _toneStripeHeight = 4.0;

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
    final hasReschedule = hasParentCallout || hasChildCallout;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        // Tone stripe lives in the border so it never adds layout
        // computation cost; the AnimatedContainer transitions the
        // shadow color from foreground at 0 → 0.10 when scrolled.
        border: Border(
          bottom: BorderSide(
            color: palette.foreground.withValues(alpha: 0.32),
            width: _toneStripeHeight,
          ),
        ),
        boxShadow: isScrolled
            ? [
                BoxShadow(
                  color: palette.foreground.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderRow(
                statusLabel: booking.ui.statusLabel,
                subtitle: _dynamicSubtitle(booking),
                isLive: _isLiveStatus(booking.status),
                foreground: palette.foreground,
                chipBackground: palette.pillBackground,
                onBack: onBack,
                onHelp: onHelp,
              ),
              if (hasReschedule) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasParentCallout)
                        Text(
                          'Rescheduled from #${booking.parentBookingId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: OrchestratorPalette.inkSecondary,
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
                          // pushReplacement so the back arrow on the
                          // child screen doesn't return to a dead
                          // CANCELLED original — the reschedule
                          // logically replaces the original. Matches
                          // `BookingRescheduledNotifier`'s auto-nav
                          // behaviour for symmetry.
                          onPressed: () => GoRouter.of(context)
                              .pushReplacement(
                                '/booking/${booking.childBookingId}',
                              ),
                          icon: const Icon(Icons.arrow_forward, size: 16),
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
    );
  }

  /// Compute a tiny subtitle that contextualises the current phase.
  ///
  /// Pure function — fed only by domain entity. Empty string means
  /// "no subtitle" and the chip collapses to a single line.
  ///
  /// **Role awareness.** Several statuses describe a moment that is
  /// experienced differently by the two viewers — most notably AWAITING
  /// (customer is waiting; tech has been *offered* the job), QUOTED
  /// (customer is reviewing; tech sent the quote and is awaiting a
  /// reply), and INSPECTING (customer waits; tech is the one inspecting
  /// and the screen prompts them to build a quote next). Without
  /// branching, the customer-side copy ("Looking for a technician",
  /// "Quote ready for you") bleeds onto the technician's screen and
  /// reads as wrong-recipient prose. Branching keeps each role's
  /// subtitle anchored to *their* lived moment.
  static String _dynamicSubtitle(BookingDetail booking) {
    final ts = booking.phaseTimestamps;
    final isTech =
        booking.viewerRole == BookingOrchestratorRole.technician;
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
      // Karigar is pick-then-book — customer already chose this
      // specific tech in the discovery flow. AWAITING means waiting
      // on THAT tech's accept/decline, NOT marketplace search. Copy
      // must reflect "your tech is reviewing the booking" framing.
      BookingStatus.awaiting => isTech
          ? 'Accept or decline'
          : 'Waiting for approval',
      BookingStatus.confirmed => 'Starts at ${hhmm(booking.scheduledStart)}',
      BookingStatus.enRoute => 'Tracking live',
      BookingStatus.arrived => ts.arrivedAt != null
          ? 'Arrived ${ago(ts.arrivedAt)}'
          : 'Tech is here',
      BookingStatus.inspecting => isTech
          ? 'Build the quote next'
          : 'Tech is inspecting',
      BookingStatus.quoted => isTech
          ? 'Customer is reviewing'
          : 'Quote ready for you',
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

  /// "Live" statuses get a pulsing dot in the chip — communicates that
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

/// Single row containing back arrow + horizontally-centered status
/// chip + help icon.
///
/// The "Booking #N" engineering metadata that used to sit between the
/// back arrow and the chip was dropped — production tracking screens
/// (Foodpanda / InDrive / Uber) don't surface order IDs on the live
/// tracking surface. Support staff who need the booking ID can pull
/// it from the user's account rather than asking the customer to read
/// it off the screen.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.statusLabel,
    required this.subtitle,
    required this.isLive,
    required this.foreground,
    required this.chipBackground,
    required this.onBack,
    required this.onHelp,
  });

  final String statusLabel;
  final String subtitle;
  final bool isLive;
  final Color foreground;
  final Color chipBackground;
  final VoidCallback onBack;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: onBack,
          icon: Icon(
            Icons.arrow_back_rounded,
            color: OrchestratorPalette.inkPrimary,
          ),
          visualDensity: VisualDensity.compact,
        ),
        // Chip sits horizontally centered in the row between back +
        // help. Center wraps the chip so it shrink-wraps to its own
        // intrinsic width (label + dot + subtitle width) and floats
        // in the middle of the Expanded's space, not anchored to
        // the start.
        Expanded(
          child: Center(
            child: _StatusChip(
              statusLabel: statusLabel,
              subtitle: subtitle,
              isLive: isLive,
              foreground: foreground,
              chipBackground: chipBackground,
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Help',
          onPressed: onHelp,
          icon: Icon(
            Icons.help_outline_rounded,
            color: onHelp == null
                ? OrchestratorPalette.inkPrimary.withValues(alpha: 0.35)
                : OrchestratorPalette.inkPrimary,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// Status chip — pulsing dot + bold label + (optional) subtitle.
///
/// Sits inline in the header row inside an [Expanded], so on a wide
/// phone the chip can hold a single-line label+subtitle layout; on
/// narrow phones the chip shrinks horizontally and the inner Column
/// wraps the subtitle to a second line if needed. Header height grows
/// ~14 px in that edge case — still much shorter than the previous
/// 132-px hero.
///
/// The pulse uses an internal [AnimationController]; opting into it
/// via the [isLive] flag rather than always-on so steady states feel
/// composed and live states feel kinetic.
class _StatusChip extends StatefulWidget {
  const _StatusChip({
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
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
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
  void didUpdateWidget(covariant _StatusChip old) {
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
        horizontal: 12,
        vertical: hasSubtitle ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: widget.foreground.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingDot(
            color: widget.foreground,
            controller: _pulse,
            isLive: widget.isLive,
          ),
          const SizedBox(width: 8),
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
                    fontSize: 13,
                    letterSpacing: 0.2,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: 1),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.foreground.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.1,
                      height: 1.2,
                    ),
                    // 2 lines so a long subtitle on a narrow phone
                    // wraps cleanly instead of cutting load-bearing
                    // info ("Working for 24 min", "Customer is
                    // reviewing").
                    maxLines: 2,
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

/// 8-px dot. When [isLive] is true a soft halo expands outward 0..1
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
      width: 14,
      height: 14,
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
                    width: 6 + (10 * t),
                    height: 6 + (10 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.55),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 8,
            height: 8,
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

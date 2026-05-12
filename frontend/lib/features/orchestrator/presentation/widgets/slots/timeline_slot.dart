import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/animations/loop_mode.dart';
import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';

/// Animated horizontal phase progression. Foodpanda-style: connector
/// lines fill smoothly when a phase becomes "done", the current phase
/// pulses to convey "you are here", terminal states collapse to a
/// "Booking ended" pill instead of the dot row.
///
/// **Phase model (5 dots).**
///   * Confirmed (Confirmed)
///   * On the way (En route)
///   * Arrived (Arrived)
///   * Quote (Inspecting + Quoted both map here — the tech is at the
///     job site building / discussing the quote)
///   * Done (In progress + Completed + Completed-Inspection-Only)
///
/// **State derivation.** The `current` marker comes from [BookingStatus]
/// directly (not from timestamp presence) so a phase the user is in but
/// whose timestamp hasn't fired yet — INSPECTING with no quote submitted
/// — still shows a current marker. The `done` marker comes from the
/// matching timestamp being non-null AND the current status being past
/// that phase, so a stub fixture without timestamps still renders sensibly.
///
/// For terminal states (cancelled / rejected / no-show / disputed / pending
/// / unknown) we surface a single rounded pill summarising the outcome —
/// the dot row would be misleading because the user did NOT complete the
/// happy path.
class TimelineSlot extends StatelessWidget {
  const TimelineSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final terminal = _terminalLabel(booking.status);
    if (terminal != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Align(
          alignment: Alignment.center,
          child: _TerminalPill(label: terminal, status: booking.status),
        ),
      );
    }
    final phases = _phases();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < phases.length; i++) ...[
                _PhaseDot(phase: phases[i], colors: colors),
                if (i < phases.length - 1)
                  Expanded(
                    child: _Connector(
                      done: phases[i].state == _PhaseState.done,
                      colors: colors,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < phases.length; i++) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: i == 0
                        ? CrossAxisAlignment.start
                        : (i == phases.length - 1
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.center),
                    children: [
                      Text(
                        phases[i].label,
                        textAlign: i == 0
                            ? TextAlign.start
                            : (i == phases.length - 1
                                  ? TextAlign.end
                                  : TextAlign.center),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: phases[i].state == _PhaseState.idle
                              ? colors.outline
                              : colors.onSurfaceVariant,
                          fontWeight: phases[i].state == _PhaseState.current
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      // Foodpanda pattern — completed phases show the
                      // local time they happened, in a small grey caption
                      // beneath the label. Current and idle phases show no
                      // time (current is "now", idle hasn't happened).
                      // Phases with no timestamp render an empty SizedBox
                      // of the same height so the row's baseline doesn't
                      // jitter across statuses.
                      _PhaseTimestamp(
                        when: phases[i].state == _PhaseState.done
                            ? phases[i].timestamp
                            : null,
                        colors: colors,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build the five-phase view for the current booking. Index 0 = first
  /// (Confirmed); index 4 = last (Done). The `current` marker is derived
  /// from status, not from timestamp presence — see class doc.
  List<_PhaseSpec> _phases() {
    final ts = booking.phaseTimestamps;
    final currentPhase = _phaseIndexForStatus(booking.status);

    _PhaseState stateFor({required int index, required bool timestampSet}) {
      if (currentPhase == index) return _PhaseState.current;
      if (currentPhase == -1) {
        return timestampSet ? _PhaseState.done : _PhaseState.idle;
      }
      if (currentPhase > index) return _PhaseState.done;
      return _PhaseState.idle;
    }

    return [
      _PhaseSpec(
        label: 'Confirmed',
        state: stateFor(index: 0, timestampSet: ts.acceptedAt != null),
        timestamp: ts.acceptedAt,
      ),
      _PhaseSpec(
        label: 'On the way',
        state: stateFor(index: 1, timestampSet: ts.enRouteStartedAt != null),
        timestamp: ts.enRouteStartedAt,
      ),
      _PhaseSpec(
        label: 'Arrived',
        state: stateFor(index: 2, timestampSet: ts.arrivedAt != null),
        timestamp: ts.arrivedAt,
      ),
      _PhaseSpec(
        label: 'Quote',
        state: stateFor(
          index: 3,
          timestampSet: ts.quoteFirstSubmittedAt != null,
        ),
        timestamp: ts.quoteFirstSubmittedAt,
      ),
      _PhaseSpec(
        label: 'Done',
        state: stateFor(index: 4, timestampSet: ts.completedAt != null),
        timestamp: ts.completedAt,
      ),
    ];
  }

  /// Map each [BookingStatus] to the phase index it represents.
  /// Returns -1 for terminal/unknown states (handled by [_terminalLabel]).
  int _phaseIndexForStatus(BookingStatus status) => switch (status) {
    BookingStatus.awaiting => 0,
    BookingStatus.confirmed => 0,
    BookingStatus.enRoute => 1,
    BookingStatus.arrived => 2,
    BookingStatus.inspecting => 3,
    BookingStatus.quoted => 3,
    BookingStatus.inProgress => 4,
    BookingStatus.completed => 4,
    BookingStatus.completedInspectionOnly => 4,
    BookingStatus.cancelled ||
    BookingStatus.rejected ||
    BookingStatus.noShow ||
    BookingStatus.disputed ||
    BookingStatus.pending ||
    BookingStatus.unknown => -1,
  };

  /// Copy for the terminal pill. Returns null for non-terminal statuses
  /// (the dot row is rendered instead).
  String? _terminalLabel(BookingStatus status) => switch (status) {
    BookingStatus.cancelled => 'Booking cancelled',
    BookingStatus.rejected => 'Booking rejected',
    BookingStatus.noShow => 'Marked as no-show',
    BookingStatus.disputed => 'Under dispute review',
    BookingStatus.pending || BookingStatus.unknown => null,
    _ => null,
  };
}

enum _PhaseState { idle, current, done }

class _PhaseSpec {
  final String label;
  final _PhaseState state;

  /// Wall-clock time the phase began, when known. Rendered as a
  /// "h:mm a" caption beneath the label for completed phases.
  final DateTime? timestamp;
  const _PhaseSpec({
    required this.label,
    required this.state,
    this.timestamp,
  });
}

/// Small grey caption shown under a phase label. Reserves a fixed
/// height even when [when] is null so the row never reflows as
/// timestamps fill in.
class _PhaseTimestamp extends StatelessWidget {
  const _PhaseTimestamp({required this.when, required this.colors});

  final DateTime? when;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    // Reserve the height even when there's no timestamp so the row's
    // baseline doesn't shift as backend fills timestamps in.
    if (when == null) return const SizedBox(height: 14);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        DateFormat('h:mm a').format(when!.toLocal()),
        style: TextStyle(
          fontSize: 10,
          color: colors.outline,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Animated connector line between phase dots. The colour animates over
/// 500ms when a phase flips to `done`, so the user sees the line "fill".
class _Connector extends StatelessWidget {
  const _Connector({required this.done, required this.colors});
  final bool done;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: done
          ? colors.primary.withValues(alpha: 0.6)
          : colors.outlineVariant,
    );
  }
}

class _PhaseDot extends StatefulWidget {
  const _PhaseDot({required this.phase, required this.colors});
  final _PhaseSpec phase;
  final ColorScheme colors;

  @override
  State<_PhaseDot> createState() => _PhaseDotState();
}

class _PhaseDotState extends State<_PhaseDot>
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
  void didUpdateWidget(covariant _PhaseDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase.state != widget.phase.state) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    if (widget.phase.state == _PhaseState.current && shouldLoopAnimations()) {
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
    final colors = widget.colors;
    return switch (widget.phase.state) {
      _PhaseState.done => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(Icons.check, size: 11, color: colors.onPrimary),
      ),
      _PhaseState.current => SizedBox(
        width: 28,
        height: 28,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring — fades + grows.
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = _pulse.value;
                return Opacity(
                  opacity: (1.0 - t) * 0.65,
                  child: Container(
                    width: 12 + (16 * t),
                    height: 12 + (16 * t),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary.withValues(alpha: 0.30),
                    ),
                  ),
                );
              },
            ),
            // Inner solid dot.
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.45),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _PhaseState.idle => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outlineVariant, width: 2),
        ),
      ),
    };
  }
}

/// Replaces the dot row for terminal statuses. A single rounded pill so
/// the user immediately reads the outcome — no misleading progression.
class _TerminalPill extends StatelessWidget {
  const _TerminalPill({required this.label, required this.status});
  final String label;
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = switch (status) {
      BookingStatus.disputed => const Color(0xFFE89B25),
      _ => theme.colorScheme.outline,
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tint.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: tint),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../customer/bookings/domain/entities/booking_status.dart';
import '../../../domain/entities/booking_detail.dart';

/// Compact horizontal phase progression: dots connected by short lines.
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
/// / unknown), no dot is `current`; the timeline shows whichever phases
/// were reached as `done` and the body slot communicates the terminal
/// outcome.
class TimelineSlot extends StatelessWidget {
  const TimelineSlot({super.key, required this.booking});

  final BookingDetail booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final phases = _phases();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < phases.length; i++) ...[
                _PhaseDot(phase: phases[i], colors: colors),
                if (i < phases.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: phases[i].state == _PhaseState.done
                          ? colors.primary.withValues(alpha: 0.6)
                          : colors.outlineVariant,
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < phases.length; i++) ...[
                Expanded(
                  child: Text(
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
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
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
        // Terminal/unknown: no current marker, but show whichever phases
        // were actually reached as done so the user has some sense of
        // how far they got before the booking ended.
        return timestampSet ? _PhaseState.done : _PhaseState.idle;
      }
      if (currentPhase > index) return _PhaseState.done;
      return _PhaseState.idle;
    }

    return [
      _PhaseSpec(
        label: 'Confirmed',
        state: stateFor(index: 0, timestampSet: ts.acceptedAt != null),
      ),
      _PhaseSpec(
        label: 'On the way',
        state: stateFor(index: 1, timestampSet: ts.enRouteStartedAt != null),
      ),
      _PhaseSpec(
        label: 'Arrived',
        state: stateFor(index: 2, timestampSet: ts.arrivedAt != null),
      ),
      _PhaseSpec(
        label: 'Quote',
        // The Quote phase is "done" once a quote has been submitted; until
        // then we treat it as in-progress (timestamp not yet set).
        state: stateFor(
          index: 3,
          timestampSet: ts.quoteFirstSubmittedAt != null,
        ),
      ),
      _PhaseSpec(
        label: 'Done',
        state: stateFor(index: 4, timestampSet: ts.completedAt != null),
      ),
    ];
  }

  /// Map each [BookingStatus] to the phase index it represents.
  /// Returns -1 for terminal/unknown states (no current marker).
  ///
  ///   * 0 — confirmed (just accepted)
  ///   * 1 — enRoute (heading to site)
  ///   * 2 — arrived (at the door)
  ///   * 3 — inspecting | quoted (building / awaiting decision on quote)
  ///   * 4 — inProgress | completed | completedInspectionOnly (finishing
  ///     up or finished). Completed/completedInspectionOnly land at index
  ///     4 with `current` because the dot collapses to `done` only via
  ///     the `completedAt` timestamp anchor.
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
}

enum _PhaseState { idle, current, done }

class _PhaseSpec {
  final String label;
  final _PhaseState state;
  const _PhaseSpec({required this.label, required this.state});
}

class _PhaseDot extends StatelessWidget {
  const _PhaseDot({required this.phase, required this.colors});
  final _PhaseSpec phase;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return switch (phase.state) {
      _PhaseState.done => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, size: 10, color: colors.onPrimary),
      ),
      _PhaseState.current => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
          border: Border.all(
            color: colors.primary.withValues(alpha: 0.3),
            width: 4,
          ),
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

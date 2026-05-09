import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_phase_timestamps.freezed.dart';

/// Timestamps for the seven lifecycle anchors the timeline slot renders.
///
/// Every field is nullable — phases not yet reached have `null`. The
/// timeline slot fills dots up to the latest non-null timestamp; the
/// dot for the current phase pulses.
///
/// Wire shape (snake_case keys parsed in the mapper):
/// `accepted_at`, `en_route_started_at`, `arrived_at`,
/// `inspection_started_at`, `quote_first_submitted_at`, `work_started_at`,
/// `completed_at`. ISO-8601 strings on the wire; typed [DateTime] here.
@freezed
abstract class BookingPhaseTimestamps with _$BookingPhaseTimestamps {
  const factory BookingPhaseTimestamps({
    DateTime? acceptedAt,
    DateTime? enRouteStartedAt,
    DateTime? arrivedAt,
    DateTime? inspectionStartedAt,
    DateTime? quoteFirstSubmittedAt,
    DateTime? workStartedAt,
    DateTime? completedAt,
  }) = _BookingPhaseTimestamps;
}

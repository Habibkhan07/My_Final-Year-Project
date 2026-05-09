// Per-event payload Freezed models for events the orchestrator screen
// reacts to. Per CLAUDE.md "Per-event feature wiring" — payload models
// live with the consumer, never in `core/realtime`.
//
// Most events only need `job_id` for routing/refresh-filter, so they
// share [JobIdPayload]. Only events whose feature code consumes extra
// fields (`booking_rescheduled` needs `child_booking_id`,
// `quote_generated` carries `quote_id`) get bespoke shapes.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'booking_event_payloads.freezed.dart';
part 'booking_event_payloads.g.dart';

/// Shared shape for events the orchestrator screen filters / refreshes
/// based on `job_id` alone. Used by tech_en_route, tech_arrived,
/// quote_revision_requested, quote_declined, quote_approved,
/// payment_received, job_completed, booking_cancelled, booking_no_show,
/// dispute_opened, dispute_resolved.
@freezed
abstract class JobIdPayload with _$JobIdPayload {
  const factory JobIdPayload({
    @JsonKey(name: 'job_id') required int jobId,
  }) = _JobIdPayload;

  factory JobIdPayload.fromJson(Map<String, dynamic> json) =>
      _$JobIdPayloadFromJson(json);
}

/// `quote_generated` — backend §16. Carries quote_id + revision_number
/// + total_amount alongside the job_id. Total is wire-string Decimal.
@freezed
abstract class QuoteGeneratedPayload with _$QuoteGeneratedPayload {
  const factory QuoteGeneratedPayload({
    @JsonKey(name: 'job_id') required int jobId,
    @JsonKey(name: 'quote_id') required int quoteId,
    @JsonKey(name: 'revision_number') required int revisionNumber,
    @JsonKey(name: 'total_amount') required String totalAmount,
  }) = _QuoteGeneratedPayload;

  factory QuoteGeneratedPayload.fromJson(Map<String, dynamic> json) =>
      _$QuoteGeneratedPayloadFromJson(json);
}

/// `booking_rescheduled` — backend §16. Carries the child booking id so
/// the customer's screen can pushReplacement to the fresh booking
/// rather than viewing the now-CANCELLED original.
@freezed
abstract class BookingRescheduledPayload with _$BookingRescheduledPayload {
  const factory BookingRescheduledPayload({
    @JsonKey(name: 'job_id') required int jobId,
    @JsonKey(name: 'child_booking_id') required int childBookingId,
  }) = _BookingRescheduledPayload;

  factory BookingRescheduledPayload.fromJson(Map<String, dynamic> json) =>
      _$BookingRescheduledPayloadFromJson(json);
}

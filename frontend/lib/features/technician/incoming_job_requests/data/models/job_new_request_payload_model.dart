// Wire model for the `job_new_request` event payload.
// Source of truth: `backend/bookings/api/BOOKINGS_API.md` §1.2.
//
// `bookingType`, `payoutContext`, and `locationLabel` are all nullable on this
// model — §2.5 spec: pre-rollout `EventLog` rows replayed via
// `/api/events/sync/` predate one or more of these fields. The mapper applies
// the `null bookingType → laborGig` default; `locationLabel` is rendered only
// when non-null (no placeholder). This model stays faithful to the wire so
// deserializer tests can assert "fresh" vs "replayed" payloads round-trip
// correctly.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'job_new_request_payload_model.freezed.dart';
part 'job_new_request_payload_model.g.dart';

@freezed
abstract class JobNewRequestPayloadModel with _$JobNewRequestPayloadModel {
  const factory JobNewRequestPayloadModel({
    @JsonKey(name: 'job_id') required int jobId,
    @JsonKey(name: 'service_name') required String serviceName,
    @JsonKey(name: 'booking_type') required String? bookingType,
    @JsonKey(name: 'scheduled_start_iso') required String scheduledStartIso,

    /// Backend deliberately wires `payout` as an integer-string (e.g. `"1200"`)
    /// to avoid client-side float drift. The domain entity holds `int`; parsing
    /// happens in the mapper.
    required String payout,

    @JsonKey(name: 'payout_context') required String? payoutContext,
    @JsonKey(name: 'expires_in_seconds') required int expiresInSeconds,

    /// Pre-composed locality string (e.g. `"Gulberg, Lahore"`) sourced
    /// server-side from `JobBooking.address.locality_label`. Null on two
    /// paths: (a) the booking's address FK is SET_NULL, (b) the address
    /// pre-dates the locality columns and has not been backfilled. The
    /// technician's card hides the row entirely when null — never shows
    /// a placeholder. Full street address is never broadcast pre-accept.
    @JsonKey(name: 'ui_location_label') required String? locationLabel,
  }) = _JobNewRequestPayloadModel;

  factory JobNewRequestPayloadModel.fromJson(Map<String, dynamic> json) =>
      _$JobNewRequestPayloadModelFromJson(json);
}

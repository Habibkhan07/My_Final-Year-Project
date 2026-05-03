import 'package:freezed_annotation/freezed_annotation.dart';

part 'system_event_model.freezed.dart';
part 'system_event_model.g.dart';

/// JSON contract for real-time system events.
///
/// Fed by two backend sources:
///   - WebSocket frames from Django Channels (live push).
///   - `GET /api/events/sync/` and `GET /api/events/unacknowledged/`.
///
/// [timestamp] is kept as a raw ISO-8601 string here. Parsing to [DateTime]
/// is the mapper's job (wrapped in try/catch), so a malformed timestamp
/// from a single event can never crash the listener loop.
///
/// [kind] is the wire-level discriminator the [WsFrameDispatcher] uses to
/// route frames. For an event model it is always the literal `"event"` —
/// stream frames never reach this model because the dispatcher routes them
/// before deserialization. The field is required so any backend response
/// missing it fails fast at deserialization rather than silently entering
/// the event pipeline as ambiguous data.
///
/// [expiresAt] (optional, ISO-8601 string) is the server-stamped instant at
/// which the event becomes useless to act on (e.g. a `job_new_request`
/// whose SLA window has elapsed). The pipeline filter in
/// `SystemEventNotifier.processEvent` drops events whose `expiresAt` is in
/// the past relative to the server-time anchor. Optional for backwards
/// compatibility — null on legacy events / non-time-windowed events
/// (`payment_received`, `chat_message`). See flag #19.
///
/// [recipientUserId] (optional, integer) is the auth user id this event
/// was dispatched to. The pipeline drops events whose recipient does not
/// match the currently-authenticated user — defends against the
/// multi-account-device race where a notification queued for user A
/// arrives at user B's session after a logout/login. Optional for
/// backwards compatibility — null on legacy events. See flag #19.
@freezed
abstract class SystemEventModel with _$SystemEventModel {
  const factory SystemEventModel({
    required String kind,
    required String id,
    @JsonKey(name: 'rawType') required String rawType,
    @JsonKey(name: 'targetRole') required String targetRole,
    required String timestamp,
    required Map<String, dynamic> payload,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'recipient_user_id') int? recipientUserId,
  }) = _SystemEventModel;

  factory SystemEventModel.fromJson(Map<String, dynamic> json) =>
      _$SystemEventModelFromJson(json);
}

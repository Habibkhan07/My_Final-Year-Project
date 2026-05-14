// Side-effect handles produced by the conversation on close.
// Wire spec: `backend/chatbot/api/CHATBOT_API.md` §`output_refs`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'output_refs.freezed.dart';

/// Persistent rows the dispute persona produced when the conversation
/// closed. Today only [ticketId] is carried; the closing card renders
/// "Ticket #{id}" plus a "Back to booking" CTA.
///
/// The SLA disclosure is **not** in this struct — it is templated into
/// the final SYSTEM bubble in the transcript (see
/// `backend/chatbot/personas/dispute/prompts.py::closing_template`).
/// Keeping the canonical wording on the server side means support can
/// re-word it without a Flutter release.
///
/// `refund_intent_id` and `needs_review` exist on the SupportTicket
/// row server-side but are not exposed to the client — the client has
/// no UX use for either.
@freezed
abstract class OutputRefs with _$OutputRefs {
  const factory OutputRefs({
    required int ticketId,
  }) = _OutputRefs;
}

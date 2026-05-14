/// Sealed failure hierarchy for the chatbot feature.
///
/// Step 3 of the 4-step error pipeline (CLAUDE.md): the repository
/// translates `HttpFailure` wire codes (and `SocketException`) into
/// one of these typed subclasses; the screen's `ref.listen` on the
/// session notifier switches on the subclass to choose the UI
/// affordance.
///
/// Subclasses are arranged in roughly increasing severity:
///
///   * [ChatbotNetworkFailure] — `SocketException` mid-turn. Banner +
///     retry; nothing destructive happened server-side (turn was not
///     committed).
///
///   * [NotEligibleToStartFailure] — booking not in a state that
///     allows starting a dispute (terminal status / cooldown
///     window). Modal → back to booking detail.
///
///   * [ConversationNotFoundFailure] — wrong id, wrong user, or the
///     conversation was deleted server-side. Modal → drop session,
///     allow a fresh start.
///
///   * [ConversationClosedFailure] — turn arrived at a closed
///     conversation. Surface the closing card if [outputRefs] is
///     known, else navigate back.
///
///   * [LlmQuotaExceededFailure] — daily per-user LLM call budget
///     exhausted (HTTP 429). Soft-worded modal pointing to Help.
///
///   * [UnsupportedMessageKindFailure] — client sent a turn kind the
///     persona doesn't accept in its current phase. Indicates a
///     client bug; `assert(false)` in debug, neutral snackbar in
///     release.
///
///   * [AttachmentTooLargeFailure] — file exceeds
///     `CHATBOT_MAX_ATTACHMENT_MB` (HTTP 413). Inline error in the
///     attachment composer.
///
///   * [AttachmentCountExceededFailure] — already at
///     `CHATBOT_MAX_ATTACHMENTS`. Inline error in the attachment
///     composer.
///
///   * [FormValidationFailure] — the dynamic form's server-side
///     validation rejected the submission. [fieldErrors] is the
///     envelope's `errors` map; the form composer paints each
///     message under the matching field.
///
///   * [UnknownChatbotFailure] — catch-all. Generic snackbar, neutral
///     copy. Includes the upstream error string for log harvesting.
sealed class ChatbotFailure implements Exception {
  final String message;
  const ChatbotFailure(this.message);
}

/// `SocketException` during any turn. The turn was not committed on
/// the server — safe to retry once connectivity is back.
class ChatbotNetworkFailure extends ChatbotFailure {
  const ChatbotNetworkFailure([
    super.message = "You're offline. Reconnect and try again.",
  ]);
}

/// HTTP 400 / code `not_eligible_to_start`. The booking is in a state
/// that disallows a new dispute (e.g. AWAITING / already DISPUTED /
/// past the dispute-window cooldown — backend-defined; see
/// `disputes/services/eligibility.py`).
class NotEligibleToStartFailure extends ChatbotFailure {
  const NotEligibleToStartFailure([
    super.message = "You can't start a dispute for this booking right now.",
  ]);
}

/// HTTP 404 / code `conversation_not_found`. Returned for both
/// genuinely missing rows and **wrong-user** lookups (so the wire
/// shape does not confirm conversation existence to another user —
/// see views.py `# SECURITY:` comment).
class ConversationNotFoundFailure extends ChatbotFailure {
  const ConversationNotFoundFailure([
    super.message = 'This conversation is no longer available.',
  ]);
}

/// HTTP 409 / code `conversation_closed`. Turn or attachment was
/// attempted against an already-closed conversation. Idempotent close
/// does NOT surface as this — see [ConversationClosedFailure] is
/// only raised on writes.
class ConversationClosedFailure extends ChatbotFailure {
  const ConversationClosedFailure([
    super.message = 'This conversation has been closed.',
  ]);
}

/// HTTP 429 / code `llm_quota_exceeded`. Soft-worded modal copy lives
/// here; the screen renders [message] verbatim.
class LlmQuotaExceededFailure extends ChatbotFailure {
  const LlmQuotaExceededFailure([
    super.message =
        "You've reached today's AI assistant limit. "
        'Try again tomorrow, or use Help to file directly.',
  ]);
}

/// HTTP 400 / code `unsupported_message_kind`. Client tried to send a
/// kind the current phase doesn't accept (e.g. a text message during
/// the attachment-pending hand-off). Indicates client-side state
/// drift from the server — assert in debug, neutral snackbar in
/// release.
class UnsupportedMessageKindFailure extends ChatbotFailure {
  const UnsupportedMessageKindFailure([
    super.message = "We couldn't process that input here.",
  ]);
}

/// HTTP 413 / code `attachment_too_large`. [maxMb] is the limit
/// reported by the backend so the inline error can read
/// "Maximum size is X MB" rather than a hardcoded constant.
class AttachmentTooLargeFailure extends ChatbotFailure {
  final int maxMb;
  const AttachmentTooLargeFailure({
    required this.maxMb,
    String message = 'File is too large.',
  }) : super(message);
}

/// HTTP 400 / code `attachment_count_exceeded`. [maxCount] is the cap
/// reported by the backend (`CHATBOT_MAX_ATTACHMENTS`, default 10).
class AttachmentCountExceededFailure extends ChatbotFailure {
  final int maxCount;
  const AttachmentCountExceededFailure({
    required this.maxCount,
    String message = 'Maximum attachments reached.',
  }) : super(message);
}

/// HTTP 400 / code `validation_error` on a form submission. The
/// composer paints per-field errors from [fieldErrors]; the
/// [message] is the envelope summary, kept as a fallback toast.
class FormValidationFailure extends ChatbotFailure {
  /// Wire `errors` map. Keys are field names; values are arrays of
  /// error strings the backend produced.
  final Map<String, List<String>> fieldErrors;

  const FormValidationFailure({
    required this.fieldErrors,
    String message = 'Please correct the highlighted fields.',
  }) : super(message);
}

/// HTTP 404 / code `persona_not_found`. Programmer error — the client
/// passed a persona key the registry doesn't know. Surfaces as a
/// neutral snackbar; in debug, [message] carries the offending key
/// for log harvesting.
class PersonaNotFoundFailure extends ChatbotFailure {
  const PersonaNotFoundFailure([
    super.message = 'Chat assistant is not available.',
  ]);
}

/// Catch-all unclassified failure. Same UX as the server failure path
/// (retry surfaced, neutral copy). Carries the upstream error string
/// for log harvesting.
class UnknownChatbotFailure extends ChatbotFailure {
  const UnknownChatbotFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}

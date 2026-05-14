// Abstract contract for the chatbot feature's data layer.
// Implementations talk to the five `/api/chat/` endpoints (see
// `backend/chatbot/api/CHATBOT_API.md`).
//
// **Error pipeline contract.** Per CLAUDE.md, every failure surfaces
// as a typed `ChatbotFailure` — see `domain/failures/`. The repository
// catches `HttpFailure` + `SocketException` from the data sources and
// translates to the sealed hierarchy; the notifier is never exposed to
// wire-level error shapes.
//
// **Network model.** This feature is **online-only**. The chatbot
// requires an LLM round-trip on every UNDERSTAND turn and a
// transactional close on the final step — there is no useful local
// fallback. `SocketException` surfaces as `ChatbotNetworkFailure`
// across the board.
//
// The local data source is used **only** for:
//
//   * Tier-2 draft text caching (so backgrounding the app
//     mid-typing does not lose input). PAYOUT phase opts out — IBAN
//     never reaches SharedPreferences.
//
//   * Tier-3 active-conversation-id recovery key (so cold-booting
//     into the app rehydrates the same screen if the user had one
//     open).
//
// Neither of these is "offline-first" in the CLAUDE.md sense — the
// remote call is still required to render any turn.
import 'dart:typed_data';

import '../entities/chat_session.dart';
import '../entities/form_schema.dart';

/// The contract every chatbot data layer implementation upholds.
abstract class IChatbotRepository {
  /// `POST /api/chat/<personaKey>/start/`.
  ///
  /// Opens a new session **or** returns the existing open one if the
  /// persona deems the booking already has one in progress. The
  /// caller treats both cases identically.
  ///
  /// [context] is the persona-specific entry payload — for dispute,
  /// `{"booking_id": <int>}`.
  ///
  /// Throws [NotEligibleToStartFailure] / [PersonaNotFoundFailure] /
  /// [ChatbotNetworkFailure] / [UnknownChatbotFailure].
  Future<ChatSession> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  });

  /// `GET /api/chat/conversations/<id>/`.
  ///
  /// Hydrates a session by id — used by the Tier-3 recovery path on
  /// cold boot and by the screen's pull-to-refresh.
  ///
  /// Throws [ConversationNotFoundFailure] / [ChatbotNetworkFailure] /
  /// [UnknownChatbotFailure].
  Future<ChatSession> fetchConversation(int conversationId);

  /// `POST /api/chat/conversations/<id>/message/` with kind `text`.
  ///
  /// Sends one free-text turn. Returns the updated [ChatSession] with
  /// the appended bot reply (and any SYSTEM closing message) and the
  /// next [UiDirective].
  ///
  /// [bookingId] is needed so the repository can clear the
  /// per-booking recovery key when the persona auto-closes mid-turn.
  ///
  /// Throws [LlmQuotaExceededFailure] / [ConversationClosedFailure] /
  /// [UnsupportedMessageKindFailure] / [ChatbotNetworkFailure] /
  /// [UnknownChatbotFailure].
  Future<ChatSession> sendTextTurn({
    required int conversationId,
    required int bookingId,
    required String text,
  });

  /// `POST /api/chat/conversations/<id>/message/` with kind `form`.
  ///
  /// Submits the dynamic form for the current phase. [values] keys
  /// must match the field names from the [FormSchema] the previous
  /// turn returned — the server re-validates regardless.
  ///
  /// Throws [FormValidationFailure] (field-level errors in the
  /// envelope's `errors` map) on submission rejection. Other failures
  /// per the [sendTextTurn] contract.
  Future<ChatSession> submitFormTurn({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  });

  /// `POST /api/chat/conversations/<id>/attachments/` (multipart).
  ///
  /// Uploads a single image. Returns the updated attachments count
  /// reported by the server. The notifier reads this count for the
  /// composer's "X of Y" display.
  ///
  /// Bytes-based contract: caller passes the in-memory image bytes plus
  /// the original filename (used by the multipart `filename` field +
  /// content-type sniff). Required for web — `XFile.path` is a `blob:`
  /// URL there, not a filesystem path. Works identically on native via
  /// `XFile.readAsBytes()`.
  ///
  /// Throws [AttachmentTooLargeFailure] / [AttachmentCountExceededFailure] /
  /// [ConversationClosedFailure] / [ChatbotNetworkFailure] /
  /// [UnknownChatbotFailure].
  Future<int> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  });

  /// `POST /api/chat/conversations/<id>/message/` with kind
  /// `attachment_done`. Advances the persona out of the EVIDENCE
  /// phase (zero attachments is allowed — see plan §13).
  ///
  /// Failure modes identical to [sendTextTurn].
  Future<ChatSession> notifyAttachmentsDone({
    required int conversationId,
    required int bookingId,
  });

  /// `POST /api/chat/conversations/<id>/close/`.
  ///
  /// Idempotent: calling on an already-closed conversation returns
  /// the existing [ChatSession] (with its `output_refs`) — does NOT
  /// throw [ConversationClosedFailure].
  ///
  /// [bookingId] is required so the per-booking recovery key can be
  /// cleared on the same call.
  ///
  /// Throws [ConversationNotFoundFailure] / [ChatbotNetworkFailure] /
  /// [UnknownChatbotFailure].
  Future<ChatSession> closeConversation({
    required int conversationId,
    required int bookingId,
  });

  // ─── Local-only operations (Tier-2 / Tier-3) ──────────────────────

  /// Persist (or clear with `null` text) the free-text draft for
  /// [conversationId]. No-op when the conversation is in a phase
  /// that opts out of draft persistence (PAYOUT — see
  /// `FormDirective.persistDraft`).
  ///
  /// Caller is the debounced draft notifier.
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  });

  /// Read the persisted draft text for [conversationId], or `null`
  /// when none exists.
  Future<String?> loadDraftText(int conversationId);

  /// Mark [conversationId] as the active recovery target for the
  /// specific [bookingId]. Per-booking keying — a still-open dispute
  /// on booking A must NOT be rehydrated when the user opens the
  /// dispute help on booking B (cross-booking leak; see plan §C).
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  });

  /// The currently-active recovery target conversation id for
  /// [bookingId], or `null` when none.
  Future<int?> getActiveConversationId(int bookingId);
}

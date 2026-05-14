// Chatbot repository — step 2 of the 4-step error pipeline (CLAUDE.md):
// translates the data-source's [HttpFailure] / [SocketException] paths
// into the typed sealed [ChatbotFailure] hierarchy.
//
// **No offline fallback.** This feature is online-only by design (the
// LLM round-trip is mandatory on every UNDERSTAND turn; the close path
// commits side-effects atomically server-side). `SocketException`
// surfaces as [ChatbotNetworkFailure] regardless of cache state — the
// local data source exists for draft persistence + cold-boot recovery
// only, never as a wire fallback.
import 'dart:io';
import 'dart:typed_data';

import '../../../../../core/common/errors/http_failure.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/failures/chatbot_failure.dart';
import '../../domain/repositories/chatbot_repository.dart';
import '../data_sources/chatbot_local_data_source.dart';
import '../data_sources/chatbot_remote_data_source.dart';
import '../mappers/chatbot_mapper.dart';
import '../models/turn_result_model.dart';

class ChatbotRepositoryImpl implements IChatbotRepository {
  final IChatbotRemoteDataSource _remote;
  final IChatbotLocalDataSource _local;

  ChatbotRepositoryImpl({
    required IChatbotRemoteDataSource remote,
    required IChatbotLocalDataSource local,
  }) : _remote = remote,
       _local = local;

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<ChatSession> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) async {
    try {
      final model = await _remote.startConversation(
        personaKey: personaKey,
        context: context,
      );
      final session = ChatbotMapper.sessionFromStart(model);
      // Mark recovery target so a cold boot lands back in the chat.
      // The recovery key is per-booking (not a single global) — read
      // the booking id from the entry context so we don't leak this
      // session into a different booking's recovery slot.
      // Best-effort: if persistence fails, we still want to return
      // the session — the local layer logs and swallows.
      final bookingId = context['booking_id'];
      if (bookingId is int) {
        await _local.setActiveConversationId(
          bookingId: bookingId,
          conversationId: session.conversationId,
        );
      }
      return session;
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ChatbotNetworkFailure();
    } on ChatbotFailure {
      rethrow;
    } catch (e) {
      throw UnknownChatbotFailure(e.toString());
    }
  }

  @override
  Future<ChatSession> fetchConversation(int conversationId) async {
    try {
      final model = await _remote.getConversation(conversationId);
      return ChatbotMapper.sessionFromDetail(model);
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ChatbotNetworkFailure();
    } on ChatbotFailure {
      rethrow;
    } catch (e) {
      throw UnknownChatbotFailure(e.toString());
    }
  }

  @override
  Future<ChatSession> closeConversation({
    required int conversationId,
    required int bookingId,
  }) async {
    try {
      // The close response carries only `closed_at` + `output_refs`,
      // not the full transcript / phase / state-summary. To produce a
      // [ChatSession] for the notifier we follow with a detail GET —
      // the GET also serves as the idempotent re-close path (a second
      // call to `close` succeeds server-side; the detail GET picks up
      // the existing closed state either way).
      await _remote.closeConversation(conversationId);
      final detail = await _remote.getConversation(conversationId);
      final session = ChatbotMapper.sessionFromDetail(detail);
      // Clear recovery target — session is now terminal. Per-booking
      // keying means we need the bookingId to target the right slot.
      await _local.setActiveConversationId(
        bookingId: bookingId,
        conversationId: null,
      );
      // Drop any lingering draft for this conversation.
      await _local.saveDraftText(conversationId: conversationId, text: null);
      return session;
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ChatbotNetworkFailure();
    } on ChatbotFailure {
      rethrow;
    } catch (e) {
      throw UnknownChatbotFailure(e.toString());
    }
  }

  // ─── Turn writes ───────────────────────────────────────────────────────
  //
  // The wire turn response does NOT echo prior messages, so each of
  // these methods returns the [TurnResultModel] mapping ASSUMING the
  // notifier has its previous session in hand. The notifier composes
  // the appended messages (optimistic USER bubble + bot reply) and
  // passes them through `ChatbotMapper.sessionFromTurn` itself.
  //
  // To keep the repository's contract single-shot, each turn-write
  // method here takes the previous session as input and returns the
  // fully-merged next session — the notifier never touches the mapper
  // directly. This keeps the 4-step pipeline rule clean.

  @override
  Future<ChatSession> sendTextTurn({
    required int conversationId,
    required int bookingId,
    required String text,
  }) {
    return _runTurn(
      conversationId: conversationId,
      bookingId: bookingId,
      send: () =>
          _remote.sendTextMessage(conversationId: conversationId, text: text),
    );
  }

  @override
  Future<ChatSession> submitFormTurn({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  }) {
    return _runTurn(
      conversationId: conversationId,
      bookingId: bookingId,
      send: () =>
          _remote.submitForm(conversationId: conversationId, values: values),
    );
  }

  @override
  Future<ChatSession> notifyAttachmentsDone({
    required int conversationId,
    required int bookingId,
  }) {
    return _runTurn(
      conversationId: conversationId,
      bookingId: bookingId,
      send: () => _remote.notifyAttachmentsDone(conversationId),
    );
  }

  /// Shared envelope for the three turn-writes. Sends, refetches detail
  /// for the authoritative transcript (the wire turn response does not
  /// echo it), and merges turn-response + detail into a [ChatSession]
  /// via [ChatbotMapper.sessionFromTurnAndDetail].
  ///
  /// **Why both calls.** The detail GET is the only place the cumulative
  /// transcript lives (the turn response carries just the new bot
  /// reply). The turn response is the only place the next directive
  /// lives (`ui_input_kind`, `ui_form_schema`, `bot_message`, `ui_hint`).
  /// We need both — using detail alone discards the directive and
  /// breaks the PAYOUT phase (form schema is lost; composer falls back
  /// to text; submit hits `unsupported_message_kind`).
  ///
  /// The extra GET on every turn is a deliberate trade — it costs one
  /// network round-trip per turn but lets us avoid hand-rolling the
  /// "append user message + append bot message + maybe append system
  /// closing message" composition in the notifier, which is brittle
  /// (the persona may emit 0, 1, or 2 bot messages per turn). When
  /// latency becomes a problem we can switch to a wire-level transcript
  /// delta — until then, simplicity wins.
  Future<ChatSession> _runTurn({
    required int conversationId,
    required int bookingId,
    required Future<TurnResultModel> Function() send,
  }) async {
    try {
      final turn = await send();
      final detail = await _remote.getConversation(conversationId);
      final session = ChatbotMapper.sessionFromTurnAndDetail(
        turn: turn,
        detail: detail,
      );
      if (session.isClosed) {
        // Persona auto-advanced into terminal during the turn — clear
        // recovery target so a relaunch goes back to the booking.
        await _local.setActiveConversationId(
          bookingId: bookingId,
          conversationId: null,
        );
        await _local.saveDraftText(conversationId: conversationId, text: null);
      }
      return session;
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ChatbotNetworkFailure();
    } on ChatbotFailure {
      rethrow;
    } catch (e) {
      throw UnknownChatbotFailure(e.toString());
    }
  }

  // ─── Attachment upload ─────────────────────────────────────────────────

  @override
  Future<int> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) async {
    try {
      final m = await _remote.uploadAttachment(
        conversationId: conversationId,
        filename: filename,
        bytes: bytes,
      );
      return m.attachmentsCount;
    } on HttpFailure catch (e) {
      throw _mapHttpFailure(e);
    } on SocketException {
      throw const ChatbotNetworkFailure();
    } on ChatbotFailure {
      rethrow;
    } catch (e) {
      throw UnknownChatbotFailure(e.toString());
    }
  }

  // ─── Local-only operations ─────────────────────────────────────────────

  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) => _local.saveDraftText(conversationId: conversationId, text: text);

  @override
  Future<String?> loadDraftText(int conversationId) =>
      _local.loadDraftText(conversationId);

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) => _local.setActiveConversationId(
    bookingId: bookingId,
    conversationId: conversationId,
  );

  @override
  Future<int?> getActiveConversationId(int bookingId) =>
      _local.getActiveConversationId(bookingId);

  // ─── Error envelope → typed failure ────────────────────────────────────

  /// Centralised wire-code switch so every arm of the repository
  /// agrees on the mapping. Codes mirror the backend's `chatbot/
  /// exceptions.py` module — keep this in sync when a new
  /// ChatbotError code is added there.
  ChatbotFailure _mapHttpFailure(HttpFailure failure) {
    switch (failure.code) {
      case 'persona_not_found':
        return PersonaNotFoundFailure(failure.message);
      case 'not_eligible_to_start':
        return NotEligibleToStartFailure(failure.message);
      case 'conversation_not_found':
        return ConversationNotFoundFailure(failure.message);
      case 'conversation_closed':
        return ConversationClosedFailure(failure.message);
      case 'llm_quota_exceeded':
        return LlmQuotaExceededFailure(failure.message);
      case 'unsupported_message_kind':
        return UnsupportedMessageKindFailure(failure.message);
      case 'attachment_count_exceeded':
        return AttachmentCountExceededFailure(
          // Best-effort: the backend's envelope doesn't currently
          // surface the max in the error payload, so we use the
          // documented default. The composer's count display reads
          // the live cap from the directive when available.
          maxCount: _intFromErrors(failure.errors, 'max') ?? 10,
          message: failure.message,
        );
      case 'attachment_too_large':
        return AttachmentTooLargeFailure(
          maxMb: _intFromErrors(failure.errors, 'max_mb') ?? 10,
          message: failure.message,
        );
      case 'validation_error':
        return FormValidationFailure(
          fieldErrors: _fieldErrorsFromEnvelope(failure.errors),
          message: failure.message,
        );
    }

    // No matching code. 5xx vs other 4xx both fold to unknown for
    // now — the screen renders a neutral snackbar in either case.
    return UnknownChatbotFailure(failure.message);
  }

  /// Pulls an int out of the envelope's `errors` map. Tolerates the
  /// value being absent or a non-int — returns null in either case.
  /// Used to read potential `max_mb` / `max` hints if the backend
  /// adds them later.
  int? _intFromErrors(Map<String, dynamic> errors, String key) {
    final raw = errors[key];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Coerces `errors` map values into the `Map<String, List<String>>`
  /// shape the form composer paints. DRF's standard form errors are
  /// `List<String>` per field; anything else is normalised by
  /// stringifying.
  Map<String, List<String>> _fieldErrorsFromEnvelope(
    Map<String, dynamic> envelope,
  ) {
    final out = <String, List<String>>{};
    envelope.forEach((field, value) {
      if (value is List) {
        out[field] = value.map((v) => v.toString()).toList(growable: false);
      } else if (value is String) {
        out[field] = [value];
      } else {
        out[field] = [value.toString()];
      }
    });
    return out;
  }
}

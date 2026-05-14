// Wire model → domain entity translation for the chatbot feature.
//
// This is the type-discipline boundary (CLAUDE.md §Per-event feature
// wiring). Above this line, entities expose typed `DateTime`, typed
// `ChatPhase` / `ChatRole` / `UiDirective` subclasses, typed
// `OutputRefs`. Below this line, models are loose wire shapes the
// backend may evolve.
//
// Mapper is also where backwards-compat defaults live. If the backend
// adds a new `ui_input_kind` value, this mapper folds it to
// [TextDirective] with a synthetic hint so the screen stays usable
// pending the Flutter release.
import 'dart:developer';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_phase.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/entities/form_schema.dart';
import '../../domain/entities/output_refs.dart';
import '../../domain/entities/ui_directive.dart';
import '../models/attachment_model.dart';
import '../models/conversation_detail_model.dart';
import '../models/conversation_start_response_model.dart';
import '../models/form_schema_model.dart';
import '../models/message_model.dart';
import '../models/output_refs_model.dart';
import '../models/turn_result_model.dart';
import '../models/ui_input_kind.dart';

class ChatbotMapper {
  ChatbotMapper._();

  static const _logName = 'features.customer.chatbot.mapper';

  // ─── Top-level entry points ────────────────────────────────────────────

  /// Maps the `start` response. The initial response carries no
  /// transcript (the screen seeds the bot's first message from
  /// `bot_message` directly) and is never closed.
  static ChatSession sessionFromStart(
    ConversationStartResponseModel m,
  ) {
    final phase = ChatPhase.fromWire(m.currentPhase);
    final directive = _directiveFromWire(
      kindRaw: m.uiInputKind,
      formSchema: m.uiFormSchema,
      botMessage: m.botMessage,
      hint: m.uiHint,
      attachmentsCount: m.stateSummary.attachmentsCount,
      isClosed: false,
      outputRefs: const {},
      phase: phase,
    );

    return ChatSession(
      conversationId: m.conversationId,
      personaKey: m.personaKey,
      phase: phase,
      // No transcript on start (the bot's opening line is in
      // `bot_message`; the screen renders it via the directive).
      transcript: const [],
      directive: directive,
      attachmentsCount: m.stateSummary.attachmentsCount,
      isClosed: false,
    );
  }

  /// Merges a [TurnResultModel] into an existing [ChatSession]. The
  /// notifier keeps the cumulative transcript by hand (the wire turn
  /// response does NOT echo prior messages) and only the directive +
  /// phase + closed-ness come from the turn.
  ///
  /// [appendedMessages] is the list of bubbles that should be added on
  /// top of the previous session's transcript — typically the
  /// optimistic USER bubble + the new BOT bubble (+ a closing SYSTEM
  /// bubble when the conversation just closed). The notifier composes
  /// this list and passes it in; the mapper does not invent it.
  static ChatSession sessionFromTurn({
    required ChatSession previous,
    required TurnResultModel m,
    required List<ChatMessage> appendedMessages,
  }) {
    final phase = ChatPhase.fromWire(m.currentPhase);
    final directive = _directiveFromWire(
      kindRaw: m.uiInputKind,
      formSchema: m.uiFormSchema,
      botMessage: m.botMessage,
      hint: m.uiHint,
      attachmentsCount: m.stateSummary.attachmentsCount,
      isClosed: m.isClosed,
      outputRefs: m.outputRefs,
      phase: phase,
    );

    return previous.copyWith(
      phase: phase,
      transcript: [...previous.transcript, ...appendedMessages],
      directive: directive,
      attachmentsCount: m.stateSummary.attachmentsCount,
      isClosed: m.isClosed,
      outputRefs: m.isClosed ? _outputRefsFromWire(m.outputRefs) : null,
    );
  }

  /// Merges a turn response with a freshly-fetched detail GET. Used by
  /// the repository's `_runTurn` envelope (every turn-write — sendText,
  /// submitForm, notifyAttachmentsDone). The directive shape +
  /// closed-ness come from the turn response (the authoritative
  /// per-turn payload — only it carries `ui_input_kind` +
  /// `ui_form_schema`), while the transcript comes from the detail GET
  /// (the turn response does not echo prior messages — see the
  /// repository's `_runTurn` docstring).
  ///
  /// **Why this exists.** Using [sessionFromDetail] on the post-turn
  /// detail loses the directive, because the detail endpoint has no
  /// `ui_input_kind` field. Phases whose fallback in
  /// [_fallbackDirectiveForPhase] happens to match the persona's
  /// expected kind (UNDERSTAND, EVIDENCE) tolerated this; PAYOUT did
  /// not — the fallback returned [TextDirective] while the server
  /// expected a `form` kind, every PAYOUT submit failed with
  /// `unsupported_message_kind`.
  static ChatSession sessionFromTurnAndDetail({
    required TurnResultModel turn,
    required ConversationDetailModel detail,
  }) {
    final phase = ChatPhase.fromWire(turn.currentPhase);
    final directive = _directiveFromWire(
      kindRaw: turn.uiInputKind,
      formSchema: turn.uiFormSchema,
      botMessage: turn.botMessage,
      hint: turn.uiHint,
      attachmentsCount: turn.stateSummary.attachmentsCount,
      isClosed: turn.isClosed,
      outputRefs: turn.outputRefs,
      phase: phase,
    );
    final transcript = detail.messages
        .map(_messageFromWire)
        .toList(growable: false);
    return ChatSession(
      conversationId: detail.conversationId,
      personaKey: detail.personaKey,
      phase: phase,
      transcript: transcript,
      directive: directive,
      attachmentsCount: turn.stateSummary.attachmentsCount,
      isClosed: turn.isClosed,
      closedAt: _parseUtcOrNull(detail.closedAt),
      outputRefs: turn.isClosed
          ? _outputRefsFromWire(turn.outputRefs)
          : null,
    );
  }

  /// Maps `GET /api/chat/conversations/<id>/` — the cold-boot
  /// recovery + pull-to-refresh path. Different from
  /// [sessionFromStart] in that it carries the full transcript +
  /// attachments + closed state.
  static ChatSession sessionFromDetail(ConversationDetailModel m) {
    final phase = ChatPhase.fromWire(m.currentPhase);
    final transcript = m.messages.map(_messageFromWire).toList(growable: false);

    // GET does not echo `ui_input_kind` / `bot_message` / `ui_hint`
    // (those are turn outputs). When rehydrating, we synthesise a
    // directive based on whether the conversation is closed and the
    // current phase. The screen will replace this on the next real
    // turn — this is just enough to keep the composer mounted while
    // the user is waiting to type.
    //
    // EVIDENCE fallback carries the **real** attachment count from the
    // detail GET; otherwise a cold-boot mid-evidence renders "0 of 10"
    // until the next turn, ignoring images the user has already
    // uploaded.
    final directive = m.isClosed
        ? TerminalDirective(refs: _outputRefsFromWire(m.outputRefs))
        : _fallbackDirectiveForPhase(phase, m.attachments.length);

    return ChatSession(
      conversationId: m.conversationId,
      personaKey: m.personaKey,
      phase: phase,
      transcript: transcript,
      directive: directive,
      attachmentsCount: m.attachments.length,
      isClosed: m.isClosed,
      closedAt: _parseUtcOrNull(m.closedAt),
      outputRefs: m.isClosed ? _outputRefsFromWire(m.outputRefs) : null,
    );
  }

  // ─── Component mappers ─────────────────────────────────────────────────

  static ChatMessage _messageFromWire(MessageModel m) => ChatMessage(
    id: m.id,
    role: ChatRole.fromWire(m.role),
    text: m.text,
    createdAt: _parseUtcOrNow(m.createdAt),
    phase: ChatPhase.fromWire(m.phase),
  );

  /// Public for the notifier — it needs to construct optimistic
  /// USER bubbles before the server response arrives.
  static ChatMessage messageFromWire(MessageModel m) => _messageFromWire(m);

  /// Per-attachment mapping kept for symmetry. Not used in the screen
  /// today (the composer reads the attachment count from the directive
  /// and renders thumbnails directly from local files until upload
  /// completes), but exposed here so a future "review my evidence"
  /// view can hydrate from the detail response.
  static List<AttachmentModel> rawAttachments(ConversationDetailModel m) =>
      m.attachments;

  // ─── Directive translation ─────────────────────────────────────────────

  /// Translates the wire's `(ui_input_kind, ui_form_schema, hint,
  /// bot_message, is_closed, output_refs)` quintuple into the typed
  /// [UiDirective] sealed subclass the input renderer dispatches on.
  ///
  /// Defensive defaults: unknown `ui_input_kind` folds to
  /// [TextDirective] with a synthetic hint so the screen remains
  /// usable on backend rollout drift.
  static UiDirective _directiveFromWire({
    required String kindRaw,
    required FormSchemaModel? formSchema,
    required String botMessage,
    required String hint,
    required int attachmentsCount,
    required bool isClosed,
    required Map<String, dynamic> outputRefs,
    required ChatPhase phase,
  }) {
    if (isClosed) {
      return TerminalDirective(refs: _outputRefsFromWire(outputRefs));
    }
    final kind = UiInputKind.fromWire(kindRaw);
    switch (kind) {
      case UiInputKind.text:
        return TextDirective(botMessage: botMessage, hint: hint);
      case UiInputKind.form:
        if (formSchema == null) {
          // Server bug: form kind without a schema. Log and fall back
          // to text rather than mounting an empty form — the user
          // can at least continue narrating.
          log(
            'ui_input_kind=form but ui_form_schema is null '
            '(phase=$phase) — falling back to TextDirective',
            name: _logName,
          );
          return TextDirective(botMessage: botMessage, hint: hint);
        }
        return FormDirective(
          schema: _formSchemaFromWire(formSchema),
          // PAYOUT phase carries PII (IBAN) — never persist to disk.
          // Future form phases default-on; opt out per phase here.
          persistDraft: phase != ChatPhase.payout,
          botMessage: botMessage,
          hint: hint,
        );
      case UiInputKind.attachment:
        return AttachmentDirective(
          currentCount: attachmentsCount,
          // The backend doesn't echo `CHATBOT_MAX_ATTACHMENTS` per
          // turn — the cap is a server setting. Until it ships in
          // the payload we use the documented default; the server's
          // 413 envelope is the authoritative gate either way.
          maxAllowed: 10,
          botMessage: botMessage,
          hint: hint,
        );
      case UiInputKind.none:
      case UiInputKind.unknown:
        // `none` is sent by the backend on transitional turns where
        // the server is computing the next directive (rare); fold to
        // text so the user can keep typing. `unknown` is rollout
        // drift — same fallback.
        return TextDirective(
          botMessage: botMessage,
          hint: hint.isEmpty ? 'Please continue' : hint,
        );
    }
  }

  /// On cold-boot rehydrate we don't have the turn response's
  /// `ui_input_kind` so we pick a sensible default per phase. This is
  /// only used until the next real turn — at which point the wire
  /// directive replaces it.
  ///
  /// [attachmentsCount] is the detail GET's `attachments.length`. Only
  /// the EVIDENCE branch needs it (the composer reads `currentCount`
  /// from the directive); other phases ignore the value.
  static UiDirective _fallbackDirectiveForPhase(
    ChatPhase phase,
    int attachmentsCount,
  ) {
    switch (phase) {
      case ChatPhase.evidence:
        return AttachmentDirective(
          currentCount: attachmentsCount,
          maxAllowed: 10,
          botMessage: '',
          hint: 'Add photos as evidence (or tap Done)',
        );
      case ChatPhase.payout:
      case ChatPhase.confirm:
      case ChatPhase.understand:
      case ChatPhase.closed:
      case ChatPhase.unknown:
        return const TextDirective(botMessage: '', hint: 'Continue typing');
    }
  }

  static FormSchema _formSchemaFromWire(FormSchemaModel m) => FormSchema(
    fields: m.fields
        .map(
          (f) => FormFieldSpec(
            // Wire is `key`, domain is `name` — the rest of the
            // codebase (notifier, form composer) uses `name`.
            name: f.key,
            label: f.label,
            kind: FormFieldKind.fromWire(f.type),
            validationPattern: f.pattern,
          ),
        )
        .toList(growable: false),
  );

  static OutputRefs _outputRefsFromWire(Map<String, dynamic> wire) {
    // Defensive: a closed turn that somehow lacks `support_ticket_id`
    // is a server bug. Surface a clear log and fall back to id=0 so
    // the screen doesn't crash mid-render — the closing card will
    // show "Ticket #0" which is a more obvious bug signal than a
    // null-deref crash.
    OutputRefsModel parsed;
    try {
      parsed = OutputRefsModel.fromJson(wire);
    } catch (e, st) {
      log(
        'malformed output_refs: $wire',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      parsed = const OutputRefsModel();
    }
    final ticketId = parsed.supportTicketId;
    if (ticketId == null) {
      log(
        'output_refs missing support_ticket_id; rendering Ticket #0',
        name: _logName,
      );
      return const OutputRefs(ticketId: 0);
    }
    return OutputRefs(ticketId: ticketId);
  }

  // ─── Date helpers ──────────────────────────────────────────────────────

  static DateTime _parseUtcOrNow(String raw) {
    try {
      // Backend emits ISO-8601 with `+00:00` or `Z`; both parse fine.
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      log('failed to parse created_at: "$raw" — using DateTime.now()',
          name: _logName);
      return DateTime.now().toUtc();
    }
  }

  static DateTime? _parseUtcOrNull(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      log('failed to parse timestamp: "$raw"', name: _logName);
      return null;
    }
  }
}

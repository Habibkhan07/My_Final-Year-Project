// Aggregate root for a single chatbot conversation. The session
// notifier holds an `AsyncValue<ChatSession>`; every server turn
// returns a fully-replaced [ChatSession] — the screen never reaches
// into individual fields to do its own state math.
//
// Wire spec: composed from the responses of `start_view`,
// `message_view`, `get_view`, and `close_view` in
// `backend/chatbot/views.py`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_message.dart';
import 'chat_phase.dart';
import 'output_refs.dart';
import 'ui_directive.dart';

part 'chat_session.freezed.dart';

/// One end-to-end chat session.
///
/// [directive] is the polymorphic input renderer's only input — adding
/// a new phase to the backend ships with zero Flutter changes provided
/// it maps to one of the existing [UiDirective] subclasses. New
/// directive kinds (e.g. voice) need a new subclass and one new
/// composer widget; the rest of the feature stays put.
///
/// [transcript] is ordered ascending by `createdAt`. Append-only —
/// every turn-response returns the next 1–2 messages and the notifier
/// concatenates onto its existing list, avoiding a full refetch.
///
/// [outputRefs] is non-null only after the conversation closes
/// (either by explicit `close` or by the persona advancing into the
/// terminal phase).
@freezed
abstract class ChatSession with _$ChatSession {
  const factory ChatSession({
    required int conversationId,
    required String personaKey,
    required ChatPhase phase,
    required List<ChatMessage> transcript,
    required UiDirective directive,
    required int attachmentsCount,
    required bool isClosed,
    DateTime? closedAt,
    OutputRefs? outputRefs,
  }) = _ChatSession;
}

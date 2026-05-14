// One turn in the chatbot transcript. Append-only audit row.
// Wire spec: `backend/chatbot/api/CHATBOT_API.md` §`Conversation
// detail` and §`Message turn`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'chat_phase.dart';

part 'chat_message.freezed.dart';

/// Who authored a [ChatMessage]. The bot and system roles look visually
/// similar in the transcript today (SYSTEM is only used for the closing
/// "Ticket #N — we'll review within 3 working days" line) but the
/// distinction is preserved for two reasons:
///
///   * Admins reviewing transcripts via Django Admin need to see what
///     was authored by the model vs. what was injected by the server.
///
///   * A future per-role styling tweak (e.g. a system-event chip
///     instead of a bubble) can read the role enum directly without
///     a wire-shape change.
enum ChatRole {
  user,
  bot,
  system,
  unknown;

  static ChatRole fromWire(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'USER':
        return ChatRole.user;
      case 'BOT':
        return ChatRole.bot;
      case 'SYSTEM':
        return ChatRole.system;
      default:
        return ChatRole.unknown;
    }
  }
}

/// One bubble in the transcript.
///
/// [createdAt] is UTC (parsed from the ISO-8601 wire string). Widgets
/// call `.toLocal()` for display.
///
/// [phase] is the phase the conversation was in **when this message
/// was written**, not the conversation's current phase — see
/// [ChatPhase].
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required int id,
    required ChatRole role,
    required String text,
    required DateTime createdAt,
    required ChatPhase phase,
  }) = _ChatMessage;
}

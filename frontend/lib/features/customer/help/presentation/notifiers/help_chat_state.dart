// Help-tab chatbot state.
//
// Help is the customer-facing "general" persona — free-form Q&A about
// the platform (pricing, booking, becoming a technician, etc.). It uses
// the same backend chatbot framework as Dispute but with a much simpler
// FE contract: text-in / text-out, no forms, no attachments, no
// crash-recovery (each tab open starts fresh).
//
// We intentionally don't reuse `ChatSession` from the chatbot feature
// because that entity carries dispute-specific fields (`outputRefs`,
// `attachmentsCount`, `directive` sealed class). Help only needs an id
// + a transcript.
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../chatbot/domain/entities/chat_message.dart';

part 'help_chat_state.freezed.dart';

@freezed
abstract class HelpChatState with _$HelpChatState {
  const factory HelpChatState({
    required int conversationId,
    required List<ChatMessage> transcript,
    @Default(false) bool isSending,
  }) = _HelpChatState;
}

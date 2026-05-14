import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Closes the conversation. Idempotent — calling on an already-closed
/// session does NOT throw; it returns the existing terminal state
/// with the same `output_refs`.
///
/// Triggered from two places in the screen:
///   * The user taps the appbar's "Close conversation" escape hatch.
///   * The persona auto-closes when its terminal phase fires (the
///     close use case is then called by the notifier to commit the
///     final transition).
class CloseConversationUseCase {
  final IChatbotRepository _repository;

  const CloseConversationUseCase(this._repository);

  Future<ChatSession> call({
    required int conversationId,
    required int bookingId,
  }) => _repository.closeConversation(
    conversationId: conversationId,
    bookingId: bookingId,
  );
}

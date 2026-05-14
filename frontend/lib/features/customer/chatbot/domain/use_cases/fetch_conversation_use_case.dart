import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Rehydrates a chatbot session by id. Used by the cold-boot recovery
/// path (when an `active_conversation_id` is on disk) and by the
/// screen's pull-to-refresh.
class FetchConversationUseCase {
  final IChatbotRepository _repository;

  const FetchConversationUseCase(this._repository);

  Future<ChatSession> call(int conversationId) =>
      _repository.fetchConversation(conversationId);
}

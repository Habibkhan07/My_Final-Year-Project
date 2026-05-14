import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Opens (or resumes — backend decides) a chatbot conversation.
///
/// [personaKey] is the registry key (`"dispute"` for v1).
/// [context] is the persona-specific entry payload (for dispute,
/// `{"booking_id": <int>}` — see `backend/chatbot/api/CHATBOT_API.md`).
class StartConversationUseCase {
  final IChatbotRepository _repository;

  const StartConversationUseCase(this._repository);

  Future<ChatSession> call({
    required String personaKey,
    required Map<String, dynamic> context,
  }) => _repository.startConversation(personaKey: personaKey, context: context);
}

import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Sends one free-text turn. Backend appends the user's bubble + the
/// bot's reply (+ a SYSTEM closing bubble if the persona just closed)
/// to the transcript; the repository follows the POST with a detail
/// GET so the returned session has the authoritative ordering.
class SendTextTurnUseCase {
  final IChatbotRepository _repository;

  const SendTextTurnUseCase(this._repository);

  Future<ChatSession> call({
    required int conversationId,
    required int bookingId,
    required String text,
  }) => _repository.sendTextTurn(
    conversationId: conversationId,
    bookingId: bookingId,
    text: text,
  );
}

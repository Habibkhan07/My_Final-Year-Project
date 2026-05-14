import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Tells the backend the user has finished uploading attachments,
/// advancing the persona out of EVIDENCE phase.
///
/// Zero attachments is allowed — some disputes have no visual
/// evidence. The persona handles the empty case on the server side.
class NotifyAttachmentsDoneUseCase {
  final IChatbotRepository _repository;

  const NotifyAttachmentsDoneUseCase(this._repository);

  Future<ChatSession> call({
    required int conversationId,
    required int bookingId,
  }) => _repository.notifyAttachmentsDone(
    conversationId: conversationId,
    bookingId: bookingId,
  );
}

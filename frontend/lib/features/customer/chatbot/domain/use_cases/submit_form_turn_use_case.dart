import '../entities/chat_session.dart';
import '../repositories/chatbot_repository.dart';

/// Submits the current phase's dynamic form (PAYOUT in dispute v1).
///
/// [values] keys must match the field names from the `FormSchema`
/// the previous turn returned — the server re-validates regardless
/// and a mismatch surfaces as [FormValidationFailure] with field-
/// level errors.
class SubmitFormTurnUseCase {
  final IChatbotRepository _repository;

  const SubmitFormTurnUseCase(this._repository);

  Future<ChatSession> call({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  }) => _repository.submitFormTurn(
    conversationId: conversationId,
    bookingId: bookingId,
    values: values,
  );
}

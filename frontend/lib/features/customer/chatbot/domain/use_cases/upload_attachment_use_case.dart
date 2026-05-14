import 'dart:typed_data';

import '../repositories/chatbot_repository.dart';

/// Uploads a single image attachment.
///
/// Returns the **server-reported attachments count** after the upload
/// — the attachment composer reads this for its "X of Y" display so
/// the count stays consistent with the server's cap enforcement (the
/// composer's own local count is for in-flight UX only).
class UploadAttachmentUseCase {
  final IChatbotRepository _repository;

  const UploadAttachmentUseCase(this._repository);

  Future<int> call({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) => _repository.uploadAttachment(
    conversationId: conversationId,
    filename: filename,
    bytes: bytes,
  );
}

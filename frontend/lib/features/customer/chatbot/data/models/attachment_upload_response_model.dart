// Wire model for `POST /api/chat/conversations/<id>/attachments/`
// response. Source of truth: `backend/chatbot/views.py::attachment_view`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_upload_response_model.freezed.dart';
part 'attachment_upload_response_model.g.dart';

@freezed
abstract class AttachmentUploadResponseModel
    with _$AttachmentUploadResponseModel {
  const factory AttachmentUploadResponseModel({
    @JsonKey(name: 'attachment_id') required int attachmentId,
    @JsonKey(name: 'attachments_count') required int attachmentsCount,
  }) = _AttachmentUploadResponseModel;

  factory AttachmentUploadResponseModel.fromJson(Map<String, dynamic> json) =>
      _$AttachmentUploadResponseModelFromJson(json);
}

// Wire model for a single attachment (the `attachments` block returned
// by `GET /api/chat/conversations/<id>/`).
//
// Source of truth: `backend/chatbot/views.py::_serialize_conversation_detail`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment_model.freezed.dart';
part 'attachment_model.g.dart';

@freezed
abstract class AttachmentModel with _$AttachmentModel {
  const factory AttachmentModel({
    required int id,
    @Default('') String file,
    @JsonKey(name: 'mime_type') @Default('') String mimeType,
    @JsonKey(name: 'size_bytes') @Default(0) int sizeBytes,
  }) = _AttachmentModel;

  factory AttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$AttachmentModelFromJson(json);
}

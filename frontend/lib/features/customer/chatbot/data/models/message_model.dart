// Wire model for a single message in the transcript array (the
// `messages` block returned by `GET /api/chat/conversations/<id>/`).
//
// Source of truth: `backend/chatbot/views.py::_serialize_conversation_detail`.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required int id,
    required String role,
    @Default('') String text,
    @Default('') String phase,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}

// Wire model for `GET /api/chat/conversations/<id>/` response.
// Source of truth: `backend/chatbot/views.py::_serialize_conversation_detail`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'attachment_model.dart';
import 'message_model.dart';
import 'state_summary_model.dart';

part 'conversation_detail_model.freezed.dart';
part 'conversation_detail_model.g.dart';

@freezed
abstract class ConversationDetailModel with _$ConversationDetailModel {
  const factory ConversationDetailModel({
    @JsonKey(name: 'conversation_id') required int conversationId,
    @JsonKey(name: 'persona_key') required String personaKey,
    @JsonKey(name: 'current_phase') @Default('') String currentPhase,
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,
    @JsonKey(name: 'closed_at') String? closedAt,
    @JsonKey(name: 'state_summary')
    @Default(StateSummaryModel())
    StateSummaryModel stateSummary,
    @Default([]) List<MessageModel> messages,
    @Default([]) List<AttachmentModel> attachments,
    @JsonKey(name: 'output_refs') @Default({})
    Map<String, dynamic> outputRefs,
  }) = _ConversationDetailModel;

  factory ConversationDetailModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationDetailModelFromJson(json);
}

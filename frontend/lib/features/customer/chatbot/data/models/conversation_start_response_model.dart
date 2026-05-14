// Wire model for `POST /api/chat/<persona>/start/` response.
// Source of truth: `backend/chatbot/views.py::_serialize_conversation_start`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'form_schema_model.dart';
import 'state_summary_model.dart';

part 'conversation_start_response_model.freezed.dart';
part 'conversation_start_response_model.g.dart';

@freezed
abstract class ConversationStartResponseModel
    with _$ConversationStartResponseModel {
  const factory ConversationStartResponseModel({
    @JsonKey(name: 'conversation_id') required int conversationId,
    @JsonKey(name: 'persona_key') required String personaKey,
    @JsonKey(name: 'current_phase') @Default('') String currentPhase,
    @JsonKey(name: 'bot_message') @Default('') String botMessage,
    @JsonKey(name: 'ui_input_kind') @Default('text') String uiInputKind,
    @JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,
    @JsonKey(name: 'ui_hint') @Default('') String uiHint,
    @JsonKey(name: 'state_summary')
    @Default(StateSummaryModel())
    StateSummaryModel stateSummary,
  }) = _ConversationStartResponseModel;

  factory ConversationStartResponseModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationStartResponseModelFromJson(json);
}

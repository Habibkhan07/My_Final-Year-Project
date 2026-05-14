// Wire model for `POST /api/chat/conversations/<id>/message/` response.
// Source of truth: `backend/chatbot/views.py::_serialize_turn_result`.
import 'package:freezed_annotation/freezed_annotation.dart';

import 'form_schema_model.dart';
import 'state_summary_model.dart';

part 'turn_result_model.freezed.dart';
part 'turn_result_model.g.dart';

@freezed
abstract class TurnResultModel with _$TurnResultModel {
  const factory TurnResultModel({
    @JsonKey(name: 'conversation_id') required int conversationId,
    @JsonKey(name: 'current_phase') @Default('') String currentPhase,
    @JsonKey(name: 'bot_message') @Default('') String botMessage,
    @JsonKey(name: 'ui_input_kind') @Default('text') String uiInputKind,
    @JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,
    @JsonKey(name: 'ui_hint') @Default('') String uiHint,
    @JsonKey(name: 'state_summary')
    @Default(StateSummaryModel())
    StateSummaryModel stateSummary,
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,
    // Wire shape: `{"support_ticket_id": <int>}` once closed, else `{}`.
    // We carry the raw map because the model's caller (the mapper)
    // already knows how to read it through `OutputRefsModel.fromJson`.
    @JsonKey(name: 'output_refs') @Default({})
    Map<String, dynamic> outputRefs,
  }) = _TurnResultModel;

  factory TurnResultModel.fromJson(Map<String, dynamic> json) =>
      _$TurnResultModelFromJson(json);
}

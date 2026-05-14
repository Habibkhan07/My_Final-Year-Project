// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_start_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationStartResponseModel _$ConversationStartResponseModelFromJson(
  Map<String, dynamic> json,
) => _ConversationStartResponseModel(
  conversationId: (json['conversation_id'] as num).toInt(),
  personaKey: json['persona_key'] as String,
  currentPhase: json['current_phase'] as String? ?? '',
  botMessage: json['bot_message'] as String? ?? '',
  uiInputKind: json['ui_input_kind'] as String? ?? 'text',
  uiFormSchema: json['ui_form_schema'] == null
      ? null
      : FormSchemaModel.fromJson(
          json['ui_form_schema'] as Map<String, dynamic>,
        ),
  uiHint: json['ui_hint'] as String? ?? '',
  stateSummary: json['state_summary'] == null
      ? const StateSummaryModel()
      : StateSummaryModel.fromJson(
          json['state_summary'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ConversationStartResponseModelToJson(
  _ConversationStartResponseModel instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'persona_key': instance.personaKey,
  'current_phase': instance.currentPhase,
  'bot_message': instance.botMessage,
  'ui_input_kind': instance.uiInputKind,
  'ui_form_schema': instance.uiFormSchema,
  'ui_hint': instance.uiHint,
  'state_summary': instance.stateSummary,
};

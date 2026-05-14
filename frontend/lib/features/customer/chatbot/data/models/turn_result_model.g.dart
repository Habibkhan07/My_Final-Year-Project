// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turn_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TurnResultModel _$TurnResultModelFromJson(Map<String, dynamic> json) =>
    _TurnResultModel(
      conversationId: (json['conversation_id'] as num).toInt(),
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
      isClosed: json['is_closed'] as bool? ?? false,
      outputRefs: json['output_refs'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$TurnResultModelToJson(_TurnResultModel instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversationId,
      'current_phase': instance.currentPhase,
      'bot_message': instance.botMessage,
      'ui_input_kind': instance.uiInputKind,
      'ui_form_schema': instance.uiFormSchema,
      'ui_hint': instance.uiHint,
      'state_summary': instance.stateSummary,
      'is_closed': instance.isClosed,
      'output_refs': instance.outputRefs,
    };

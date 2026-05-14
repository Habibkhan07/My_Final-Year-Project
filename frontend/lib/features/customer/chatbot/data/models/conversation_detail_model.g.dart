// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ConversationDetailModel _$ConversationDetailModelFromJson(
  Map<String, dynamic> json,
) => _ConversationDetailModel(
  conversationId: (json['conversation_id'] as num).toInt(),
  personaKey: json['persona_key'] as String,
  currentPhase: json['current_phase'] as String? ?? '',
  isClosed: json['is_closed'] as bool? ?? false,
  closedAt: json['closed_at'] as String?,
  stateSummary: json['state_summary'] == null
      ? const StateSummaryModel()
      : StateSummaryModel.fromJson(
          json['state_summary'] as Map<String, dynamic>,
        ),
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  attachments:
      (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  outputRefs: json['output_refs'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ConversationDetailModelToJson(
  _ConversationDetailModel instance,
) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'persona_key': instance.personaKey,
  'current_phase': instance.currentPhase,
  'is_closed': instance.isClosed,
  'closed_at': instance.closedAt,
  'state_summary': instance.stateSummary,
  'messages': instance.messages,
  'attachments': instance.attachments,
  'output_refs': instance.outputRefs,
};

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageModel _$MessageModelFromJson(Map<String, dynamic> json) =>
    _MessageModel(
      id: (json['id'] as num).toInt(),
      role: json['role'] as String,
      text: json['text'] as String? ?? '',
      phase: json['phase'] as String? ?? '',
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$MessageModelToJson(_MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'text': instance.text,
      'phase': instance.phase,
      'created_at': instance.createdAt,
    };

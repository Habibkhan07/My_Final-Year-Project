// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'system_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SystemEventModel _$SystemEventModelFromJson(Map<String, dynamic> json) =>
    _SystemEventModel(
      kind: json['kind'] as String,
      id: json['id'] as String,
      rawType: json['rawType'] as String,
      targetRole: json['targetRole'] as String,
      timestamp: json['timestamp'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$SystemEventModelToJson(_SystemEventModel instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'id': instance.id,
      'rawType': instance.rawType,
      'targetRole': instance.targetRole,
      'timestamp': instance.timestamp,
      'payload': instance.payload,
    };

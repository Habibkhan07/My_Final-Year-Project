// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'close_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CloseResponseModel _$CloseResponseModelFromJson(Map<String, dynamic> json) =>
    _CloseResponseModel(
      closedAt: json['closed_at'] as String?,
      outputRefs: json['output_refs'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$CloseResponseModelToJson(_CloseResponseModel instance) =>
    <String, dynamic>{
      'closed_at': instance.closedAt,
      'output_refs': instance.outputRefs,
    };

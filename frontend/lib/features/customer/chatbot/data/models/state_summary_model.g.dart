// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StateSummaryModel _$StateSummaryModelFromJson(Map<String, dynamic> json) =>
    _StateSummaryModel(
      phase: json['phase'] as String? ?? '',
      capturedFields:
          json['captured_fields'] as Map<String, dynamic>? ?? const {},
      attachmentsCount: (json['attachments_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StateSummaryModelToJson(_StateSummaryModel instance) =>
    <String, dynamic>{
      'phase': instance.phase,
      'captured_fields': instance.capturedFields,
      'attachments_count': instance.attachmentsCount,
    };

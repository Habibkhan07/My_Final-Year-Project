// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_jobs_counts_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduledJobsCountsModel _$ScheduledJobsCountsModelFromJson(
  Map<String, dynamic> json,
) => _ScheduledJobsCountsModel(
  upcoming: (json['upcoming'] as num).toInt(),
  past: (json['past'] as num).toInt(),
  serverTime: json['server_time'] as String,
);

Map<String, dynamic> _$ScheduledJobsCountsModelToJson(
  _ScheduledJobsCountsModel instance,
) => <String, dynamic>{
  'upcoming': instance.upcoming,
  'past': instance.past,
  'server_time': instance.serverTime,
};

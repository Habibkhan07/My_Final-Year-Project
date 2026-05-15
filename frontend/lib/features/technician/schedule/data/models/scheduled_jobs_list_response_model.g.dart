// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_jobs_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduledJobsListResponseModel _$ScheduledJobsListResponseModelFromJson(
  Map<String, dynamic> json,
) => _ScheduledJobsListResponseModel(
  items: (json['items'] as List<dynamic>)
      .map((e) => ScheduledJobModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  hasMore: json['has_more'] as bool,
  serverTime: json['server_time'] as String,
);

Map<String, dynamic> _$ScheduledJobsListResponseModelToJson(
  _ScheduledJobsListResponseModel instance,
) => <String, dynamic>{
  'items': instance.items,
  'next_cursor': instance.nextCursor,
  'has_more': instance.hasMore,
  'server_time': instance.serverTime,
};

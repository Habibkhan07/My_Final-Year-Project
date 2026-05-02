// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_new_request_payload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobNewRequestPayloadModel _$JobNewRequestPayloadModelFromJson(
  Map<String, dynamic> json,
) => _JobNewRequestPayloadModel(
  jobId: (json['job_id'] as num).toInt(),
  serviceName: json['service_name'] as String,
  bookingType: json['booking_type'] as String?,
  scheduledStartIso: json['scheduled_start_iso'] as String,
  payout: json['payout'] as String,
  payoutContext: json['payout_context'] as String?,
  expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
  locationLabel: json['ui_location_label'] as String?,
);

Map<String, dynamic> _$JobNewRequestPayloadModelToJson(
  _JobNewRequestPayloadModel instance,
) => <String, dynamic>{
  'job_id': instance.jobId,
  'service_name': instance.serviceName,
  'booking_type': instance.bookingType,
  'scheduled_start_iso': instance.scheduledStartIso,
  'payout': instance.payout,
  'payout_context': instance.payoutContext,
  'expires_in_seconds': instance.expiresInSeconds,
  'ui_location_label': instance.locationLabel,
};

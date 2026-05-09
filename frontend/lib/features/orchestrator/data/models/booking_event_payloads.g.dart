// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_event_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JobIdPayload _$JobIdPayloadFromJson(Map<String, dynamic> json) =>
    _JobIdPayload(jobId: (json['job_id'] as num).toInt());

Map<String, dynamic> _$JobIdPayloadToJson(_JobIdPayload instance) =>
    <String, dynamic>{'job_id': instance.jobId};

_QuoteGeneratedPayload _$QuoteGeneratedPayloadFromJson(
  Map<String, dynamic> json,
) => _QuoteGeneratedPayload(
  jobId: (json['job_id'] as num).toInt(),
  quoteId: (json['quote_id'] as num).toInt(),
  revisionNumber: (json['revision_number'] as num).toInt(),
  totalAmount: json['total_amount'] as String,
);

Map<String, dynamic> _$QuoteGeneratedPayloadToJson(
  _QuoteGeneratedPayload instance,
) => <String, dynamic>{
  'job_id': instance.jobId,
  'quote_id': instance.quoteId,
  'revision_number': instance.revisionNumber,
  'total_amount': instance.totalAmount,
};

_BookingRescheduledPayload _$BookingRescheduledPayloadFromJson(
  Map<String, dynamic> json,
) => _BookingRescheduledPayload(
  jobId: (json['job_id'] as num).toInt(),
  childBookingId: (json['child_booking_id'] as num).toInt(),
);

Map<String, dynamic> _$BookingRescheduledPayloadToJson(
  _BookingRescheduledPayload instance,
) => <String, dynamic>{
  'job_id': instance.jobId,
  'child_booking_id': instance.childBookingId,
};

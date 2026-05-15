// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_job_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ScheduledJobModel _$ScheduledJobModelFromJson(Map<String, dynamic> json) =>
    _ScheduledJobModel(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      service: ScheduledJobServiceModel.fromJson(
        json['service'] as Map<String, dynamic>,
      ),
      customer: ScheduledJobCustomerModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      addressLabel: json['address_label'] as String?,
      scheduledStart: json['scheduled_start'] as String,
      scheduledEnd: json['scheduled_end'] as String,
      createdAt: json['created_at'] as String,
      payout: PayoutBlockModel.fromJson(json['payout'] as Map<String, dynamic>),
      ui: ScheduledJobUiModel.fromJson(json['ui'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ScheduledJobModelToJson(_ScheduledJobModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'service': instance.service,
      'customer': instance.customer,
      'address_label': instance.addressLabel,
      'scheduled_start': instance.scheduledStart,
      'scheduled_end': instance.scheduledEnd,
      'created_at': instance.createdAt,
      'payout': instance.payout,
      'ui': instance.ui,
    };

_ScheduledJobServiceModel _$ScheduledJobServiceModelFromJson(
  Map<String, dynamic> json,
) => _ScheduledJobServiceModel(
  name: json['name'] as String,
  iconName: json['icon_name'] as String,
);

Map<String, dynamic> _$ScheduledJobServiceModelToJson(
  _ScheduledJobServiceModel instance,
) => <String, dynamic>{'name': instance.name, 'icon_name': instance.iconName};

_ScheduledJobCustomerModel _$ScheduledJobCustomerModelFromJson(
  Map<String, dynamic> json,
) => _ScheduledJobCustomerModel(
  id: (json['id'] as num).toInt(),
  displayName: json['display_name'] as String,
  profilePictureUrl: json['profile_picture_url'] as String?,
);

Map<String, dynamic> _$ScheduledJobCustomerModelToJson(
  _ScheduledJobCustomerModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'profile_picture_url': instance.profilePictureUrl,
};

_PayoutBlockModel _$PayoutBlockModelFromJson(Map<String, dynamic> json) =>
    _PayoutBlockModel(
      amount: (json['amount'] as num).toInt(),
      context: json['context'] as String,
      uiLabel: json['ui_label'] as String,
    );

Map<String, dynamic> _$PayoutBlockModelToJson(_PayoutBlockModel instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'context': instance.context,
      'ui_label': instance.uiLabel,
    };

_ScheduledJobUiModel _$ScheduledJobUiModelFromJson(Map<String, dynamic> json) =>
    _ScheduledJobUiModel(
      badgeText: json['badge_text'] as String,
      badgeTone: json['badge_tone'] as String,
      headline: json['headline'] as String,
    );

Map<String, dynamic> _$ScheduledJobUiModelToJson(
  _ScheduledJobUiModel instance,
) => <String, dynamic>{
  'badge_text': instance.badgeText,
  'badge_tone': instance.badgeTone,
  'headline': instance.headline,
};

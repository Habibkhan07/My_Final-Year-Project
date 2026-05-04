// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerBookingModel _$CustomerBookingModelFromJson(
  Map<String, dynamic> json,
) => _CustomerBookingModel(
  id: (json['id'] as num).toInt(),
  status: json['status'] as String,
  service: BookingServiceModel.fromJson(
    json['service'] as Map<String, dynamic>,
  ),
  technician: BookingTechnicianModel.fromJson(
    json['technician'] as Map<String, dynamic>,
  ),
  addressLabel: json['address_label'] as String?,
  scheduledStart: json['scheduled_start'] as String,
  scheduledEnd: json['scheduled_end'] as String,
  createdAt: json['created_at'] as String,
  price: BookingPriceModel.fromJson(json['price'] as Map<String, dynamic>),
  ui: BookingUiModel.fromJson(json['ui'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CustomerBookingModelToJson(
  _CustomerBookingModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'service': instance.service,
  'technician': instance.technician,
  'address_label': instance.addressLabel,
  'scheduled_start': instance.scheduledStart,
  'scheduled_end': instance.scheduledEnd,
  'created_at': instance.createdAt,
  'price': instance.price,
  'ui': instance.ui,
};

_BookingServiceModel _$BookingServiceModelFromJson(Map<String, dynamic> json) =>
    _BookingServiceModel(
      name: json['name'] as String,
      iconName: json['icon_name'] as String,
    );

Map<String, dynamic> _$BookingServiceModelToJson(
  _BookingServiceModel instance,
) => <String, dynamic>{'name': instance.name, 'icon_name': instance.iconName};

_BookingTechnicianModel _$BookingTechnicianModelFromJson(
  Map<String, dynamic> json,
) => _BookingTechnicianModel(
  id: (json['id'] as num).toInt(),
  displayName: json['display_name'] as String,
  profilePictureUrl: json['profile_picture_url'] as String?,
);

Map<String, dynamic> _$BookingTechnicianModelToJson(
  _BookingTechnicianModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'profile_picture_url': instance.profilePictureUrl,
};

_BookingPriceModel _$BookingPriceModelFromJson(Map<String, dynamic> json) =>
    _BookingPriceModel(
      amount: (json['amount'] as num).toInt(),
      context: json['context'] as String,
      uiLabel: json['ui_label'] as String,
    );

Map<String, dynamic> _$BookingPriceModelToJson(_BookingPriceModel instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'context': instance.context,
      'ui_label': instance.uiLabel,
    };

_BookingUiModel _$BookingUiModelFromJson(Map<String, dynamic> json) =>
    _BookingUiModel(
      badgeText: json['badge_text'] as String,
      badgeTone: json['badge_tone'] as String,
      headline: json['headline'] as String,
    );

Map<String, dynamic> _$BookingUiModelToJson(_BookingUiModel instance) =>
    <String, dynamic>{
      'badge_text': instance.badgeText,
      'badge_tone': instance.badgeTone,
      'headline': instance.headline,
    };

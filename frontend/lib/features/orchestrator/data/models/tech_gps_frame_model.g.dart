// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tech_gps_frame_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechGpsFrameModel _$TechGpsFrameModelFromJson(Map<String, dynamic> json) =>
    _TechGpsFrameModel(
      bookingId: (json['booking_id'] as num).toInt(),
      lat: _doubleFromJson(json['lat']),
      lng: _doubleFromJson(json['lng']),
      accuracyMeters: _nullableDoubleFromJson(json['accuracy_meters']),
      heading: _nullableDoubleFromJson(json['heading']),
    );

Map<String, dynamic> _$TechGpsFrameModelToJson(_TechGpsFrameModel instance) =>
    <String, dynamic>{
      'booking_id': instance.bookingId,
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy_meters': instance.accuracyMeters,
      'heading': instance.heading,
    };

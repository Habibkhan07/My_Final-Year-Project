// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tech_location_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TechLocationRequestModel _$TechLocationRequestModelFromJson(
  Map<String, dynamic> json,
) => _TechLocationRequestModel(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
  heading: (json['heading'] as num?)?.toDouble(),
);

Map<String, dynamic> _$TechLocationRequestModelToJson(
  _TechLocationRequestModel instance,
) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
  'accuracy_meters': instance.accuracyMeters,
  'heading': instance.heading,
};

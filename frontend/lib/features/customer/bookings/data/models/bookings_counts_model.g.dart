// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_counts_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingsCountsModel _$BookingsCountsModelFromJson(Map<String, dynamic> json) =>
    _BookingsCountsModel(
      upcoming: (json['upcoming'] as num).toInt(),
      past: (json['past'] as num).toInt(),
      serverTime: json['server_time'] as String,
    );

Map<String, dynamic> _$BookingsCountsModelToJson(
  _BookingsCountsModel instance,
) => <String, dynamic>{
  'upcoming': instance.upcoming,
  'past': instance.past,
  'server_time': instance.serverTime,
};

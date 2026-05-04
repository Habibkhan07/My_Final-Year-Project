// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookings_list_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingsListResponseModel _$BookingsListResponseModelFromJson(
  Map<String, dynamic> json,
) => _BookingsListResponseModel(
  items: (json['items'] as List<dynamic>)
      .map((e) => CustomerBookingModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  nextCursor: json['next_cursor'] as String?,
  hasMore: json['has_more'] as bool,
  serverTime: json['server_time'] as String,
);

Map<String, dynamic> _$BookingsListResponseModelToJson(
  _BookingsListResponseModel instance,
) => <String, dynamic>{
  'items': instance.items,
  'next_cursor': instance.nextCursor,
  'has_more': instance.hasMore,
  'server_time': instance.serverTime,
};

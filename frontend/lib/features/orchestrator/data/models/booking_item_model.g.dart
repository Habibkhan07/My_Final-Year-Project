// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingItemModel _$BookingItemModelFromJson(Map<String, dynamic> json) =>
    _BookingItemModel(
      id: (json['id'] as num).toInt(),
      subServiceId: (json['sub_service_id'] as num).toInt(),
      subServiceName: json['sub_service_name'] as String,
      quantity: (json['quantity'] as num).toInt(),
      priceCharged: json['price_charged'] as String,
      lineTotal: json['line_total'] as String,
      sourcedQuoteId: (json['sourced_quote_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookingItemModelToJson(_BookingItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sub_service_id': instance.subServiceId,
      'sub_service_name': instance.subServiceName,
      'quantity': instance.quantity,
      'price_charged': instance.priceCharged,
      'line_total': instance.lineTotal,
      'sourced_quote_id': instance.sourcedQuoteId,
    };

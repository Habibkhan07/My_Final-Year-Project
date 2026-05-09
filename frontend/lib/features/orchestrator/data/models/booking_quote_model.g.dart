// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_quote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingQuoteModel _$BookingQuoteModelFromJson(Map<String, dynamic> json) =>
    _BookingQuoteModel(
      id: (json['id'] as num).toInt(),
      bookingId: (json['booking_id'] as num).toInt(),
      revisionNumber: (json['revision_number'] as num).toInt(),
      status: json['status'] as String,
      totalAmount: json['total_amount'] as String,
      isUpsell: json['is_upsell'] as bool,
      lineItems: (json['line_items'] as List<dynamic>)
          .map(
            (e) =>
                BookingQuoteLineItemModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      submittedAt: json['submitted_at'] as String?,
    );

Map<String, dynamic> _$BookingQuoteModelToJson(_BookingQuoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'booking_id': instance.bookingId,
      'revision_number': instance.revisionNumber,
      'status': instance.status,
      'total_amount': instance.totalAmount,
      'is_upsell': instance.isUpsell,
      'line_items': instance.lineItems,
      'submitted_at': instance.submittedAt,
    };

_BookingQuoteLineItemModel _$BookingQuoteLineItemModelFromJson(
  Map<String, dynamic> json,
) => _BookingQuoteLineItemModel(
  id: (json['id'] as num).toInt(),
  subServiceId: (json['sub_service_id'] as num).toInt(),
  subServiceName: json['sub_service_name'] as String,
  quantity: (json['quantity'] as num).toInt(),
  pricedAt: json['priced_at'] as String,
  lineTotal: json['line_total'] as String,
);

Map<String, dynamic> _$BookingQuoteLineItemModelToJson(
  _BookingQuoteLineItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'sub_service_id': instance.subServiceId,
  'sub_service_name': instance.subServiceName,
  'quantity': instance.quantity,
  'priced_at': instance.pricedAt,
  'line_total': instance.lineTotal,
};

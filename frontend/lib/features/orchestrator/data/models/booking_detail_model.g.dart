// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_detail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookingDetailModel _$BookingDetailModelFromJson(Map<String, dynamic> json) =>
    _BookingDetailModel(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      service: BookingDetailServiceModel.fromJson(
        json['service'] as Map<String, dynamic>,
      ),
      subService: json['sub_service'] == null
          ? null
          : BookingDetailSubServiceModel.fromJson(
              json['sub_service'] as Map<String, dynamic>,
            ),
      technician: BookingDetailTechnicianModel.fromJson(
        json['technician'] as Map<String, dynamic>,
      ),
      customer: BookingDetailCustomerModel.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      address: json['address'] == null
          ? null
          : BookingDetailAddressModel.fromJson(
              json['address'] as Map<String, dynamic>,
            ),
      addressSnapshot: json['address_snapshot'] as String,
      scheduledStart: json['scheduled_start'] as String,
      scheduledEnd: json['scheduled_end'] as String,
      phaseTimestamps: BookingDetailPhaseTimestampsModel.fromJson(
        json['phase_timestamps'] as Map<String, dynamic>,
      ),
      pricing: BookingDetailPricingModel.fromJson(
        json['pricing'] as Map<String, dynamic>,
      ),
      cashCollection: BookingDetailCashCollectionModel.fromJson(
        json['cash_collection'] as Map<String, dynamic>,
      ),
      parentBookingId: (json['parent_booking_id'] as num?)?.toInt(),
      childBookingId: (json['child_booking_id'] as num?)?.toInt(),
      cancelReason: json['cancel_reason'] as String?,
      noShowActor: json['no_show_actor'] as String?,
      activeQuote: json['active_quote'] == null
          ? null
          : BookingQuoteModel.fromJson(
              json['active_quote'] as Map<String, dynamic>,
            ),
      bookingItems:
          (json['booking_items'] as List<dynamic>?)
              ?.map((e) => BookingItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BookingItemModel>[],
      openTicketsCount: (json['open_tickets_count'] as num?)?.toInt() ?? 0,
      ui: BookingUiBlockModel.fromJson(json['ui'] as Map<String, dynamic>),
      availableTransitions:
          (json['available_transitions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$BookingDetailModelToJson(_BookingDetailModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'service': instance.service,
      'sub_service': instance.subService,
      'technician': instance.technician,
      'customer': instance.customer,
      'address': instance.address,
      'address_snapshot': instance.addressSnapshot,
      'scheduled_start': instance.scheduledStart,
      'scheduled_end': instance.scheduledEnd,
      'phase_timestamps': instance.phaseTimestamps,
      'pricing': instance.pricing,
      'cash_collection': instance.cashCollection,
      'parent_booking_id': instance.parentBookingId,
      'child_booking_id': instance.childBookingId,
      'cancel_reason': instance.cancelReason,
      'no_show_actor': instance.noShowActor,
      'active_quote': instance.activeQuote,
      'booking_items': instance.bookingItems,
      'open_tickets_count': instance.openTicketsCount,
      'ui': instance.ui,
      'available_transitions': instance.availableTransitions,
    };

_BookingDetailServiceModel _$BookingDetailServiceModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailServiceModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  iconName: json['icon_name'] as String,
);

Map<String, dynamic> _$BookingDetailServiceModelToJson(
  _BookingDetailServiceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'icon_name': instance.iconName,
};

_BookingDetailSubServiceModel _$BookingDetailSubServiceModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailSubServiceModel(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  isFixedPrice: json['is_fixed_price'] as bool,
  basePrice: json['base_price'] as String,
  maxPrice: json['max_price'] as String?,
);

Map<String, dynamic> _$BookingDetailSubServiceModelToJson(
  _BookingDetailSubServiceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'is_fixed_price': instance.isFixedPrice,
  'base_price': instance.basePrice,
  'max_price': instance.maxPrice,
};

_BookingDetailTechnicianModel _$BookingDetailTechnicianModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailTechnicianModel(
  id: (json['id'] as num).toInt(),
  displayName: json['display_name'] as String,
  profilePictureUrl: json['profile_picture_url'] as String?,
);

Map<String, dynamic> _$BookingDetailTechnicianModelToJson(
  _BookingDetailTechnicianModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'profile_picture_url': instance.profilePictureUrl,
};

_BookingDetailCustomerModel _$BookingDetailCustomerModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailCustomerModel(
  id: (json['id'] as num).toInt(),
  fullName: json['full_name'] as String,
  phoneNo: json['phone_no'] as String,
);

Map<String, dynamic> _$BookingDetailCustomerModelToJson(
  _BookingDetailCustomerModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'phone_no': instance.phoneNo,
};

_BookingDetailAddressModel _$BookingDetailAddressModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailAddressModel(
  label: json['label'] as String,
  latitude: json['latitude'] as String,
  longitude: json['longitude'] as String,
  addressText: json['address_text'] as String,
);

Map<String, dynamic> _$BookingDetailAddressModelToJson(
  _BookingDetailAddressModel instance,
) => <String, dynamic>{
  'label': instance.label,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address_text': instance.addressText,
};

_BookingDetailPhaseTimestampsModel _$BookingDetailPhaseTimestampsModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailPhaseTimestampsModel(
  acceptedAt: json['accepted_at'] as String?,
  enRouteStartedAt: json['en_route_started_at'] as String?,
  arrivedAt: json['arrived_at'] as String?,
  inspectionStartedAt: json['inspection_started_at'] as String?,
  quoteFirstSubmittedAt: json['quote_first_submitted_at'] as String?,
  workStartedAt: json['work_started_at'] as String?,
  completedAt: json['completed_at'] as String?,
);

Map<String, dynamic> _$BookingDetailPhaseTimestampsModelToJson(
  _BookingDetailPhaseTimestampsModel instance,
) => <String, dynamic>{
  'accepted_at': instance.acceptedAt,
  'en_route_started_at': instance.enRouteStartedAt,
  'arrived_at': instance.arrivedAt,
  'inspection_started_at': instance.inspectionStartedAt,
  'quote_first_submitted_at': instance.quoteFirstSubmittedAt,
  'work_started_at': instance.workStartedAt,
  'completed_at': instance.completedAt,
};

_BookingDetailPricingModel _$BookingDetailPricingModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailPricingModel(
  inspectionFee: json['inspection_fee'] as String?,
  baseServicesTotal: json['base_services_total'] as String?,
  discountApplied: json['discount_applied'] as String?,
  finalCashToCollect: json['final_cash_to_collect'] as String?,
  promoCodeSnapshot: json['promo_code_snapshot'] as String?,
  promoDiscountSnapshot: json['promo_discount_snapshot'] as String?,
);

Map<String, dynamic> _$BookingDetailPricingModelToJson(
  _BookingDetailPricingModel instance,
) => <String, dynamic>{
  'inspection_fee': instance.inspectionFee,
  'base_services_total': instance.baseServicesTotal,
  'discount_applied': instance.discountApplied,
  'final_cash_to_collect': instance.finalCashToCollect,
  'promo_code_snapshot': instance.promoCodeSnapshot,
  'promo_discount_snapshot': instance.promoDiscountSnapshot,
};

_BookingDetailCashCollectionModel _$BookingDetailCashCollectionModelFromJson(
  Map<String, dynamic> json,
) => _BookingDetailCashCollectionModel(
  amount: json['amount'] as String?,
  at: json['at'] as String?,
  method: json['method'] as String? ?? 'cash',
);

Map<String, dynamic> _$BookingDetailCashCollectionModelToJson(
  _BookingDetailCashCollectionModel instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'at': instance.at,
  'method': instance.method,
};

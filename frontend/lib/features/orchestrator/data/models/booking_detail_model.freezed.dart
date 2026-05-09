// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_detail_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingDetailModel {

 int get id; String get status; BookingDetailServiceModel get service;@JsonKey(name: 'sub_service') BookingDetailSubServiceModel? get subService; BookingDetailTechnicianModel get technician; BookingDetailCustomerModel get customer; BookingDetailAddressModel? get address;@JsonKey(name: 'address_snapshot') String get addressSnapshot;@JsonKey(name: 'scheduled_start') String get scheduledStart;@JsonKey(name: 'scheduled_end') String get scheduledEnd;@JsonKey(name: 'phase_timestamps') BookingDetailPhaseTimestampsModel get phaseTimestamps; BookingDetailPricingModel get pricing;@JsonKey(name: 'cash_collection') BookingDetailCashCollectionModel get cashCollection;@JsonKey(name: 'parent_booking_id') int? get parentBookingId;@JsonKey(name: 'child_booking_id') int? get childBookingId;@JsonKey(name: 'cancel_reason') String? get cancelReason;@JsonKey(name: 'no_show_actor') String? get noShowActor;@JsonKey(name: 'active_quote') BookingQuoteModel? get activeQuote;@JsonKey(name: 'booking_items') List<BookingItemModel> get bookingItems;@JsonKey(name: 'open_tickets_count') int get openTicketsCount; BookingUiBlockModel get ui;@JsonKey(name: 'available_transitions') List<String> get availableTransitions;
/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailModelCopyWith<BookingDetailModel> get copyWith => _$BookingDetailModelCopyWithImpl<BookingDetailModel>(this as BookingDetailModel, _$identity);

  /// Serializes this BookingDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subService, subService) || other.subService == subService)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressSnapshot, addressSnapshot) || other.addressSnapshot == addressSnapshot)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.phaseTimestamps, phaseTimestamps) || other.phaseTimestamps == phaseTimestamps)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.cashCollection, cashCollection) || other.cashCollection == cashCollection)&&(identical(other.parentBookingId, parentBookingId) || other.parentBookingId == parentBookingId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.noShowActor, noShowActor) || other.noShowActor == noShowActor)&&(identical(other.activeQuote, activeQuote) || other.activeQuote == activeQuote)&&const DeepCollectionEquality().equals(other.bookingItems, bookingItems)&&(identical(other.openTicketsCount, openTicketsCount) || other.openTicketsCount == openTicketsCount)&&(identical(other.ui, ui) || other.ui == ui)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,service,subService,technician,customer,address,addressSnapshot,scheduledStart,scheduledEnd,phaseTimestamps,pricing,cashCollection,parentBookingId,childBookingId,cancelReason,noShowActor,activeQuote,const DeepCollectionEquality().hash(bookingItems),openTicketsCount,ui,const DeepCollectionEquality().hash(availableTransitions)]);

@override
String toString() {
  return 'BookingDetailModel(id: $id, status: $status, service: $service, subService: $subService, technician: $technician, customer: $customer, address: $address, addressSnapshot: $addressSnapshot, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, phaseTimestamps: $phaseTimestamps, pricing: $pricing, cashCollection: $cashCollection, parentBookingId: $parentBookingId, childBookingId: $childBookingId, cancelReason: $cancelReason, noShowActor: $noShowActor, activeQuote: $activeQuote, bookingItems: $bookingItems, openTicketsCount: $openTicketsCount, ui: $ui, availableTransitions: $availableTransitions)';
}


}

/// @nodoc
abstract mixin class $BookingDetailModelCopyWith<$Res>  {
  factory $BookingDetailModelCopyWith(BookingDetailModel value, $Res Function(BookingDetailModel) _then) = _$BookingDetailModelCopyWithImpl;
@useResult
$Res call({
 int id, String status, BookingDetailServiceModel service,@JsonKey(name: 'sub_service') BookingDetailSubServiceModel? subService, BookingDetailTechnicianModel technician, BookingDetailCustomerModel customer, BookingDetailAddressModel? address,@JsonKey(name: 'address_snapshot') String addressSnapshot,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'phase_timestamps') BookingDetailPhaseTimestampsModel phaseTimestamps, BookingDetailPricingModel pricing,@JsonKey(name: 'cash_collection') BookingDetailCashCollectionModel cashCollection,@JsonKey(name: 'parent_booking_id') int? parentBookingId,@JsonKey(name: 'child_booking_id') int? childBookingId,@JsonKey(name: 'cancel_reason') String? cancelReason,@JsonKey(name: 'no_show_actor') String? noShowActor,@JsonKey(name: 'active_quote') BookingQuoteModel? activeQuote,@JsonKey(name: 'booking_items') List<BookingItemModel> bookingItems,@JsonKey(name: 'open_tickets_count') int openTicketsCount, BookingUiBlockModel ui,@JsonKey(name: 'available_transitions') List<String> availableTransitions
});


$BookingDetailServiceModelCopyWith<$Res> get service;$BookingDetailSubServiceModelCopyWith<$Res>? get subService;$BookingDetailTechnicianModelCopyWith<$Res> get technician;$BookingDetailCustomerModelCopyWith<$Res> get customer;$BookingDetailAddressModelCopyWith<$Res>? get address;$BookingDetailPhaseTimestampsModelCopyWith<$Res> get phaseTimestamps;$BookingDetailPricingModelCopyWith<$Res> get pricing;$BookingDetailCashCollectionModelCopyWith<$Res> get cashCollection;$BookingQuoteModelCopyWith<$Res>? get activeQuote;$BookingUiBlockModelCopyWith<$Res> get ui;

}
/// @nodoc
class _$BookingDetailModelCopyWithImpl<$Res>
    implements $BookingDetailModelCopyWith<$Res> {
  _$BookingDetailModelCopyWithImpl(this._self, this._then);

  final BookingDetailModel _self;
  final $Res Function(BookingDetailModel) _then;

/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? subService = freezed,Object? technician = null,Object? customer = null,Object? address = freezed,Object? addressSnapshot = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? phaseTimestamps = null,Object? pricing = null,Object? cashCollection = null,Object? parentBookingId = freezed,Object? childBookingId = freezed,Object? cancelReason = freezed,Object? noShowActor = freezed,Object? activeQuote = freezed,Object? bookingItems = null,Object? openTicketsCount = null,Object? ui = null,Object? availableTransitions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingDetailServiceModel,subService: freezed == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as BookingDetailSubServiceModel?,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingDetailTechnicianModel,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BookingDetailCustomerModel,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as BookingDetailAddressModel?,addressSnapshot: null == addressSnapshot ? _self.addressSnapshot : addressSnapshot // ignore: cast_nullable_to_non_nullable
as String,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,phaseTimestamps: null == phaseTimestamps ? _self.phaseTimestamps : phaseTimestamps // ignore: cast_nullable_to_non_nullable
as BookingDetailPhaseTimestampsModel,pricing: null == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as BookingDetailPricingModel,cashCollection: null == cashCollection ? _self.cashCollection : cashCollection // ignore: cast_nullable_to_non_nullable
as BookingDetailCashCollectionModel,parentBookingId: freezed == parentBookingId ? _self.parentBookingId : parentBookingId // ignore: cast_nullable_to_non_nullable
as int?,childBookingId: freezed == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,noShowActor: freezed == noShowActor ? _self.noShowActor : noShowActor // ignore: cast_nullable_to_non_nullable
as String?,activeQuote: freezed == activeQuote ? _self.activeQuote : activeQuote // ignore: cast_nullable_to_non_nullable
as BookingQuoteModel?,bookingItems: null == bookingItems ? _self.bookingItems : bookingItems // ignore: cast_nullable_to_non_nullable
as List<BookingItemModel>,openTicketsCount: null == openTicketsCount ? _self.openTicketsCount : openTicketsCount // ignore: cast_nullable_to_non_nullable
as int,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiBlockModel,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailServiceModelCopyWith<$Res> get service {
  
  return $BookingDetailServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailSubServiceModelCopyWith<$Res>? get subService {
    if (_self.subService == null) {
    return null;
  }

  return $BookingDetailSubServiceModelCopyWith<$Res>(_self.subService!, (value) {
    return _then(_self.copyWith(subService: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailTechnicianModelCopyWith<$Res> get technician {
  
  return $BookingDetailTechnicianModelCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailCustomerModelCopyWith<$Res> get customer {
  
  return $BookingDetailCustomerModelCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailAddressModelCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $BookingDetailAddressModelCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailPhaseTimestampsModelCopyWith<$Res> get phaseTimestamps {
  
  return $BookingDetailPhaseTimestampsModelCopyWith<$Res>(_self.phaseTimestamps, (value) {
    return _then(_self.copyWith(phaseTimestamps: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailPricingModelCopyWith<$Res> get pricing {
  
  return $BookingDetailPricingModelCopyWith<$Res>(_self.pricing, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailCashCollectionModelCopyWith<$Res> get cashCollection {
  
  return $BookingDetailCashCollectionModelCopyWith<$Res>(_self.cashCollection, (value) {
    return _then(_self.copyWith(cashCollection: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingQuoteModelCopyWith<$Res>? get activeQuote {
    if (_self.activeQuote == null) {
    return null;
  }

  return $BookingQuoteModelCopyWith<$Res>(_self.activeQuote!, (value) {
    return _then(_self.copyWith(activeQuote: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiBlockModelCopyWith<$Res> get ui {
  
  return $BookingUiBlockModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingDetailModel].
extension BookingDetailModelPatterns on BookingDetailModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String status,  BookingDetailServiceModel service, @JsonKey(name: 'sub_service')  BookingDetailSubServiceModel? subService,  BookingDetailTechnicianModel technician,  BookingDetailCustomerModel customer,  BookingDetailAddressModel? address, @JsonKey(name: 'address_snapshot')  String addressSnapshot, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'phase_timestamps')  BookingDetailPhaseTimestampsModel phaseTimestamps,  BookingDetailPricingModel pricing, @JsonKey(name: 'cash_collection')  BookingDetailCashCollectionModel cashCollection, @JsonKey(name: 'parent_booking_id')  int? parentBookingId, @JsonKey(name: 'child_booking_id')  int? childBookingId, @JsonKey(name: 'cancel_reason')  String? cancelReason, @JsonKey(name: 'no_show_actor')  String? noShowActor, @JsonKey(name: 'active_quote')  BookingQuoteModel? activeQuote, @JsonKey(name: 'booking_items')  List<BookingItemModel> bookingItems, @JsonKey(name: 'open_tickets_count')  int openTicketsCount,  BookingUiBlockModel ui, @JsonKey(name: 'available_transitions')  List<String> availableTransitions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailModel() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String status,  BookingDetailServiceModel service, @JsonKey(name: 'sub_service')  BookingDetailSubServiceModel? subService,  BookingDetailTechnicianModel technician,  BookingDetailCustomerModel customer,  BookingDetailAddressModel? address, @JsonKey(name: 'address_snapshot')  String addressSnapshot, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'phase_timestamps')  BookingDetailPhaseTimestampsModel phaseTimestamps,  BookingDetailPricingModel pricing, @JsonKey(name: 'cash_collection')  BookingDetailCashCollectionModel cashCollection, @JsonKey(name: 'parent_booking_id')  int? parentBookingId, @JsonKey(name: 'child_booking_id')  int? childBookingId, @JsonKey(name: 'cancel_reason')  String? cancelReason, @JsonKey(name: 'no_show_actor')  String? noShowActor, @JsonKey(name: 'active_quote')  BookingQuoteModel? activeQuote, @JsonKey(name: 'booking_items')  List<BookingItemModel> bookingItems, @JsonKey(name: 'open_tickets_count')  int openTicketsCount,  BookingUiBlockModel ui, @JsonKey(name: 'available_transitions')  List<String> availableTransitions)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailModel():
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String status,  BookingDetailServiceModel service, @JsonKey(name: 'sub_service')  BookingDetailSubServiceModel? subService,  BookingDetailTechnicianModel technician,  BookingDetailCustomerModel customer,  BookingDetailAddressModel? address, @JsonKey(name: 'address_snapshot')  String addressSnapshot, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'phase_timestamps')  BookingDetailPhaseTimestampsModel phaseTimestamps,  BookingDetailPricingModel pricing, @JsonKey(name: 'cash_collection')  BookingDetailCashCollectionModel cashCollection, @JsonKey(name: 'parent_booking_id')  int? parentBookingId, @JsonKey(name: 'child_booking_id')  int? childBookingId, @JsonKey(name: 'cancel_reason')  String? cancelReason, @JsonKey(name: 'no_show_actor')  String? noShowActor, @JsonKey(name: 'active_quote')  BookingQuoteModel? activeQuote, @JsonKey(name: 'booking_items')  List<BookingItemModel> bookingItems, @JsonKey(name: 'open_tickets_count')  int openTicketsCount,  BookingUiBlockModel ui, @JsonKey(name: 'available_transitions')  List<String> availableTransitions)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailModel() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailModel implements BookingDetailModel {
  const _BookingDetailModel({required this.id, required this.status, required this.service, @JsonKey(name: 'sub_service') this.subService, required this.technician, required this.customer, this.address, @JsonKey(name: 'address_snapshot') required this.addressSnapshot, @JsonKey(name: 'scheduled_start') required this.scheduledStart, @JsonKey(name: 'scheduled_end') required this.scheduledEnd, @JsonKey(name: 'phase_timestamps') required this.phaseTimestamps, required this.pricing, @JsonKey(name: 'cash_collection') required this.cashCollection, @JsonKey(name: 'parent_booking_id') this.parentBookingId, @JsonKey(name: 'child_booking_id') this.childBookingId, @JsonKey(name: 'cancel_reason') this.cancelReason, @JsonKey(name: 'no_show_actor') this.noShowActor, @JsonKey(name: 'active_quote') this.activeQuote, @JsonKey(name: 'booking_items') final  List<BookingItemModel> bookingItems = const <BookingItemModel>[], @JsonKey(name: 'open_tickets_count') this.openTicketsCount = 0, required this.ui, @JsonKey(name: 'available_transitions') final  List<String> availableTransitions = const <String>[]}): _bookingItems = bookingItems,_availableTransitions = availableTransitions;
  factory _BookingDetailModel.fromJson(Map<String, dynamic> json) => _$BookingDetailModelFromJson(json);

@override final  int id;
@override final  String status;
@override final  BookingDetailServiceModel service;
@override@JsonKey(name: 'sub_service') final  BookingDetailSubServiceModel? subService;
@override final  BookingDetailTechnicianModel technician;
@override final  BookingDetailCustomerModel customer;
@override final  BookingDetailAddressModel? address;
@override@JsonKey(name: 'address_snapshot') final  String addressSnapshot;
@override@JsonKey(name: 'scheduled_start') final  String scheduledStart;
@override@JsonKey(name: 'scheduled_end') final  String scheduledEnd;
@override@JsonKey(name: 'phase_timestamps') final  BookingDetailPhaseTimestampsModel phaseTimestamps;
@override final  BookingDetailPricingModel pricing;
@override@JsonKey(name: 'cash_collection') final  BookingDetailCashCollectionModel cashCollection;
@override@JsonKey(name: 'parent_booking_id') final  int? parentBookingId;
@override@JsonKey(name: 'child_booking_id') final  int? childBookingId;
@override@JsonKey(name: 'cancel_reason') final  String? cancelReason;
@override@JsonKey(name: 'no_show_actor') final  String? noShowActor;
@override@JsonKey(name: 'active_quote') final  BookingQuoteModel? activeQuote;
 final  List<BookingItemModel> _bookingItems;
@override@JsonKey(name: 'booking_items') List<BookingItemModel> get bookingItems {
  if (_bookingItems is EqualUnmodifiableListView) return _bookingItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookingItems);
}

@override@JsonKey(name: 'open_tickets_count') final  int openTicketsCount;
@override final  BookingUiBlockModel ui;
 final  List<String> _availableTransitions;
@override@JsonKey(name: 'available_transitions') List<String> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}


/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailModelCopyWith<_BookingDetailModel> get copyWith => __$BookingDetailModelCopyWithImpl<_BookingDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subService, subService) || other.subService == subService)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressSnapshot, addressSnapshot) || other.addressSnapshot == addressSnapshot)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.phaseTimestamps, phaseTimestamps) || other.phaseTimestamps == phaseTimestamps)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.cashCollection, cashCollection) || other.cashCollection == cashCollection)&&(identical(other.parentBookingId, parentBookingId) || other.parentBookingId == parentBookingId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.noShowActor, noShowActor) || other.noShowActor == noShowActor)&&(identical(other.activeQuote, activeQuote) || other.activeQuote == activeQuote)&&const DeepCollectionEquality().equals(other._bookingItems, _bookingItems)&&(identical(other.openTicketsCount, openTicketsCount) || other.openTicketsCount == openTicketsCount)&&(identical(other.ui, ui) || other.ui == ui)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,service,subService,technician,customer,address,addressSnapshot,scheduledStart,scheduledEnd,phaseTimestamps,pricing,cashCollection,parentBookingId,childBookingId,cancelReason,noShowActor,activeQuote,const DeepCollectionEquality().hash(_bookingItems),openTicketsCount,ui,const DeepCollectionEquality().hash(_availableTransitions)]);

@override
String toString() {
  return 'BookingDetailModel(id: $id, status: $status, service: $service, subService: $subService, technician: $technician, customer: $customer, address: $address, addressSnapshot: $addressSnapshot, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, phaseTimestamps: $phaseTimestamps, pricing: $pricing, cashCollection: $cashCollection, parentBookingId: $parentBookingId, childBookingId: $childBookingId, cancelReason: $cancelReason, noShowActor: $noShowActor, activeQuote: $activeQuote, bookingItems: $bookingItems, openTicketsCount: $openTicketsCount, ui: $ui, availableTransitions: $availableTransitions)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailModelCopyWith<$Res> implements $BookingDetailModelCopyWith<$Res> {
  factory _$BookingDetailModelCopyWith(_BookingDetailModel value, $Res Function(_BookingDetailModel) _then) = __$BookingDetailModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String status, BookingDetailServiceModel service,@JsonKey(name: 'sub_service') BookingDetailSubServiceModel? subService, BookingDetailTechnicianModel technician, BookingDetailCustomerModel customer, BookingDetailAddressModel? address,@JsonKey(name: 'address_snapshot') String addressSnapshot,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'phase_timestamps') BookingDetailPhaseTimestampsModel phaseTimestamps, BookingDetailPricingModel pricing,@JsonKey(name: 'cash_collection') BookingDetailCashCollectionModel cashCollection,@JsonKey(name: 'parent_booking_id') int? parentBookingId,@JsonKey(name: 'child_booking_id') int? childBookingId,@JsonKey(name: 'cancel_reason') String? cancelReason,@JsonKey(name: 'no_show_actor') String? noShowActor,@JsonKey(name: 'active_quote') BookingQuoteModel? activeQuote,@JsonKey(name: 'booking_items') List<BookingItemModel> bookingItems,@JsonKey(name: 'open_tickets_count') int openTicketsCount, BookingUiBlockModel ui,@JsonKey(name: 'available_transitions') List<String> availableTransitions
});


@override $BookingDetailServiceModelCopyWith<$Res> get service;@override $BookingDetailSubServiceModelCopyWith<$Res>? get subService;@override $BookingDetailTechnicianModelCopyWith<$Res> get technician;@override $BookingDetailCustomerModelCopyWith<$Res> get customer;@override $BookingDetailAddressModelCopyWith<$Res>? get address;@override $BookingDetailPhaseTimestampsModelCopyWith<$Res> get phaseTimestamps;@override $BookingDetailPricingModelCopyWith<$Res> get pricing;@override $BookingDetailCashCollectionModelCopyWith<$Res> get cashCollection;@override $BookingQuoteModelCopyWith<$Res>? get activeQuote;@override $BookingUiBlockModelCopyWith<$Res> get ui;

}
/// @nodoc
class __$BookingDetailModelCopyWithImpl<$Res>
    implements _$BookingDetailModelCopyWith<$Res> {
  __$BookingDetailModelCopyWithImpl(this._self, this._then);

  final _BookingDetailModel _self;
  final $Res Function(_BookingDetailModel) _then;

/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? subService = freezed,Object? technician = null,Object? customer = null,Object? address = freezed,Object? addressSnapshot = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? phaseTimestamps = null,Object? pricing = null,Object? cashCollection = null,Object? parentBookingId = freezed,Object? childBookingId = freezed,Object? cancelReason = freezed,Object? noShowActor = freezed,Object? activeQuote = freezed,Object? bookingItems = null,Object? openTicketsCount = null,Object? ui = null,Object? availableTransitions = null,}) {
  return _then(_BookingDetailModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingDetailServiceModel,subService: freezed == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as BookingDetailSubServiceModel?,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingDetailTechnicianModel,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BookingDetailCustomerModel,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as BookingDetailAddressModel?,addressSnapshot: null == addressSnapshot ? _self.addressSnapshot : addressSnapshot // ignore: cast_nullable_to_non_nullable
as String,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,phaseTimestamps: null == phaseTimestamps ? _self.phaseTimestamps : phaseTimestamps // ignore: cast_nullable_to_non_nullable
as BookingDetailPhaseTimestampsModel,pricing: null == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as BookingDetailPricingModel,cashCollection: null == cashCollection ? _self.cashCollection : cashCollection // ignore: cast_nullable_to_non_nullable
as BookingDetailCashCollectionModel,parentBookingId: freezed == parentBookingId ? _self.parentBookingId : parentBookingId // ignore: cast_nullable_to_non_nullable
as int?,childBookingId: freezed == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,noShowActor: freezed == noShowActor ? _self.noShowActor : noShowActor // ignore: cast_nullable_to_non_nullable
as String?,activeQuote: freezed == activeQuote ? _self.activeQuote : activeQuote // ignore: cast_nullable_to_non_nullable
as BookingQuoteModel?,bookingItems: null == bookingItems ? _self._bookingItems : bookingItems // ignore: cast_nullable_to_non_nullable
as List<BookingItemModel>,openTicketsCount: null == openTicketsCount ? _self.openTicketsCount : openTicketsCount // ignore: cast_nullable_to_non_nullable
as int,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiBlockModel,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailServiceModelCopyWith<$Res> get service {
  
  return $BookingDetailServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailSubServiceModelCopyWith<$Res>? get subService {
    if (_self.subService == null) {
    return null;
  }

  return $BookingDetailSubServiceModelCopyWith<$Res>(_self.subService!, (value) {
    return _then(_self.copyWith(subService: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailTechnicianModelCopyWith<$Res> get technician {
  
  return $BookingDetailTechnicianModelCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailCustomerModelCopyWith<$Res> get customer {
  
  return $BookingDetailCustomerModelCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailAddressModelCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $BookingDetailAddressModelCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailPhaseTimestampsModelCopyWith<$Res> get phaseTimestamps {
  
  return $BookingDetailPhaseTimestampsModelCopyWith<$Res>(_self.phaseTimestamps, (value) {
    return _then(_self.copyWith(phaseTimestamps: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailPricingModelCopyWith<$Res> get pricing {
  
  return $BookingDetailPricingModelCopyWith<$Res>(_self.pricing, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingDetailCashCollectionModelCopyWith<$Res> get cashCollection {
  
  return $BookingDetailCashCollectionModelCopyWith<$Res>(_self.cashCollection, (value) {
    return _then(_self.copyWith(cashCollection: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingQuoteModelCopyWith<$Res>? get activeQuote {
    if (_self.activeQuote == null) {
    return null;
  }

  return $BookingQuoteModelCopyWith<$Res>(_self.activeQuote!, (value) {
    return _then(_self.copyWith(activeQuote: value));
  });
}/// Create a copy of BookingDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiBlockModelCopyWith<$Res> get ui {
  
  return $BookingUiBlockModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// @nodoc
mixin _$BookingDetailServiceModel {

 int get id; String get name;@JsonKey(name: 'icon_name') String get iconName;
/// Create a copy of BookingDetailServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailServiceModelCopyWith<BookingDetailServiceModel> get copyWith => _$BookingDetailServiceModelCopyWithImpl<BookingDetailServiceModel>(this as BookingDetailServiceModel, _$identity);

  /// Serializes this BookingDetailServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'BookingDetailServiceModel(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $BookingDetailServiceModelCopyWith<$Res>  {
  factory $BookingDetailServiceModelCopyWith(BookingDetailServiceModel value, $Res Function(BookingDetailServiceModel) _then) = _$BookingDetailServiceModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class _$BookingDetailServiceModelCopyWithImpl<$Res>
    implements $BookingDetailServiceModelCopyWith<$Res> {
  _$BookingDetailServiceModelCopyWithImpl(this._self, this._then);

  final BookingDetailServiceModel _self;
  final $Res Function(BookingDetailServiceModel) _then;

/// Create a copy of BookingDetailServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailServiceModel].
extension BookingDetailServiceModelPatterns on BookingDetailServiceModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailServiceModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailServiceModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailServiceModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'icon_name')  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'icon_name')  String iconName)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailServiceModel():
return $default(_that.id,_that.name,_that.iconName);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'icon_name')  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailServiceModel implements BookingDetailServiceModel {
  const _BookingDetailServiceModel({required this.id, required this.name, @JsonKey(name: 'icon_name') required this.iconName});
  factory _BookingDetailServiceModel.fromJson(Map<String, dynamic> json) => _$BookingDetailServiceModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'icon_name') final  String iconName;

/// Create a copy of BookingDetailServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailServiceModelCopyWith<_BookingDetailServiceModel> get copyWith => __$BookingDetailServiceModelCopyWithImpl<_BookingDetailServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'BookingDetailServiceModel(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailServiceModelCopyWith<$Res> implements $BookingDetailServiceModelCopyWith<$Res> {
  factory _$BookingDetailServiceModelCopyWith(_BookingDetailServiceModel value, $Res Function(_BookingDetailServiceModel) _then) = __$BookingDetailServiceModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class __$BookingDetailServiceModelCopyWithImpl<$Res>
    implements _$BookingDetailServiceModelCopyWith<$Res> {
  __$BookingDetailServiceModelCopyWithImpl(this._self, this._then);

  final _BookingDetailServiceModel _self;
  final $Res Function(_BookingDetailServiceModel) _then;

/// Create a copy of BookingDetailServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = null,}) {
  return _then(_BookingDetailServiceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingDetailSubServiceModel {

 int get id; String get name;@JsonKey(name: 'is_fixed_price') bool get isFixedPrice;// Decimal on the wire (e.g. "500.00"). Mapper coerces to int rupees.
@JsonKey(name: 'base_price') String get basePrice;@JsonKey(name: 'max_price') String? get maxPrice;
/// Create a copy of BookingDetailSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailSubServiceModelCopyWith<BookingDetailSubServiceModel> get copyWith => _$BookingDetailSubServiceModelCopyWithImpl<BookingDetailSubServiceModel>(this as BookingDetailSubServiceModel, _$identity);

  /// Serializes this BookingDetailSubServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailSubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isFixedPrice,basePrice,maxPrice);

@override
String toString() {
  return 'BookingDetailSubServiceModel(id: $id, name: $name, isFixedPrice: $isFixedPrice, basePrice: $basePrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class $BookingDetailSubServiceModelCopyWith<$Res>  {
  factory $BookingDetailSubServiceModelCopyWith(BookingDetailSubServiceModel value, $Res Function(BookingDetailSubServiceModel) _then) = _$BookingDetailSubServiceModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_fixed_price') bool isFixedPrice,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice
});




}
/// @nodoc
class _$BookingDetailSubServiceModelCopyWithImpl<$Res>
    implements $BookingDetailSubServiceModelCopyWith<$Res> {
  _$BookingDetailSubServiceModelCopyWithImpl(this._self, this._then);

  final BookingDetailSubServiceModel _self;
  final $Res Function(BookingDetailSubServiceModel) _then;

/// Create a copy of BookingDetailSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isFixedPrice = null,Object? basePrice = null,Object? maxPrice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailSubServiceModel].
extension BookingDetailSubServiceModelPatterns on BookingDetailSubServiceModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailSubServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailSubServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailSubServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.isFixedPrice,_that.basePrice,_that.maxPrice);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel():
return $default(_that.id,_that.name,_that.isFixedPrice,_that.basePrice,_that.maxPrice);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailSubServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.isFixedPrice,_that.basePrice,_that.maxPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailSubServiceModel implements BookingDetailSubServiceModel {
  const _BookingDetailSubServiceModel({required this.id, required this.name, @JsonKey(name: 'is_fixed_price') required this.isFixedPrice, @JsonKey(name: 'base_price') required this.basePrice, @JsonKey(name: 'max_price') this.maxPrice});
  factory _BookingDetailSubServiceModel.fromJson(Map<String, dynamic> json) => _$BookingDetailSubServiceModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'is_fixed_price') final  bool isFixedPrice;
// Decimal on the wire (e.g. "500.00"). Mapper coerces to int rupees.
@override@JsonKey(name: 'base_price') final  String basePrice;
@override@JsonKey(name: 'max_price') final  String? maxPrice;

/// Create a copy of BookingDetailSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailSubServiceModelCopyWith<_BookingDetailSubServiceModel> get copyWith => __$BookingDetailSubServiceModelCopyWithImpl<_BookingDetailSubServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailSubServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailSubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isFixedPrice,basePrice,maxPrice);

@override
String toString() {
  return 'BookingDetailSubServiceModel(id: $id, name: $name, isFixedPrice: $isFixedPrice, basePrice: $basePrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailSubServiceModelCopyWith<$Res> implements $BookingDetailSubServiceModelCopyWith<$Res> {
  factory _$BookingDetailSubServiceModelCopyWith(_BookingDetailSubServiceModel value, $Res Function(_BookingDetailSubServiceModel) _then) = __$BookingDetailSubServiceModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_fixed_price') bool isFixedPrice,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice
});




}
/// @nodoc
class __$BookingDetailSubServiceModelCopyWithImpl<$Res>
    implements _$BookingDetailSubServiceModelCopyWith<$Res> {
  __$BookingDetailSubServiceModelCopyWithImpl(this._self, this._then);

  final _BookingDetailSubServiceModel _self;
  final $Res Function(_BookingDetailSubServiceModel) _then;

/// Create a copy of BookingDetailSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isFixedPrice = null,Object? basePrice = null,Object? maxPrice = freezed,}) {
  return _then(_BookingDetailSubServiceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingDetailTechnicianModel {

 int get id;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'profile_picture_url') String? get profilePictureUrl;
/// Create a copy of BookingDetailTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailTechnicianModelCopyWith<BookingDetailTechnicianModel> get copyWith => _$BookingDetailTechnicianModelCopyWithImpl<BookingDetailTechnicianModel>(this as BookingDetailTechnicianModel, _$identity);

  /// Serializes this BookingDetailTechnicianModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailTechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingDetailTechnicianModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $BookingDetailTechnicianModelCopyWith<$Res>  {
  factory $BookingDetailTechnicianModelCopyWith(BookingDetailTechnicianModel value, $Res Function(BookingDetailTechnicianModel) _then) = _$BookingDetailTechnicianModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class _$BookingDetailTechnicianModelCopyWithImpl<$Res>
    implements $BookingDetailTechnicianModelCopyWith<$Res> {
  _$BookingDetailTechnicianModelCopyWithImpl(this._self, this._then);

  final BookingDetailTechnicianModel _self;
  final $Res Function(BookingDetailTechnicianModel) _then;

/// Create a copy of BookingDetailTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailTechnicianModel].
extension BookingDetailTechnicianModelPatterns on BookingDetailTechnicianModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailTechnicianModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailTechnicianModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailTechnicianModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel():
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'profile_picture_url')  String? profilePictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailTechnicianModel() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailTechnicianModel implements BookingDetailTechnicianModel {
  const _BookingDetailTechnicianModel({required this.id, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'profile_picture_url') this.profilePictureUrl});
  factory _BookingDetailTechnicianModel.fromJson(Map<String, dynamic> json) => _$BookingDetailTechnicianModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'profile_picture_url') final  String? profilePictureUrl;

/// Create a copy of BookingDetailTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailTechnicianModelCopyWith<_BookingDetailTechnicianModel> get copyWith => __$BookingDetailTechnicianModelCopyWithImpl<_BookingDetailTechnicianModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailTechnicianModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailTechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingDetailTechnicianModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailTechnicianModelCopyWith<$Res> implements $BookingDetailTechnicianModelCopyWith<$Res> {
  factory _$BookingDetailTechnicianModelCopyWith(_BookingDetailTechnicianModel value, $Res Function(_BookingDetailTechnicianModel) _then) = __$BookingDetailTechnicianModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class __$BookingDetailTechnicianModelCopyWithImpl<$Res>
    implements _$BookingDetailTechnicianModelCopyWith<$Res> {
  __$BookingDetailTechnicianModelCopyWithImpl(this._self, this._then);

  final _BookingDetailTechnicianModel _self;
  final $Res Function(_BookingDetailTechnicianModel) _then;

/// Create a copy of BookingDetailTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_BookingDetailTechnicianModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingDetailCustomerModel {

 int get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'phone_no') String get phoneNo;
/// Create a copy of BookingDetailCustomerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailCustomerModelCopyWith<BookingDetailCustomerModel> get copyWith => _$BookingDetailCustomerModelCopyWithImpl<BookingDetailCustomerModel>(this as BookingDetailCustomerModel, _$identity);

  /// Serializes this BookingDetailCustomerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailCustomerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNo, phoneNo) || other.phoneNo == phoneNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNo);

@override
String toString() {
  return 'BookingDetailCustomerModel(id: $id, fullName: $fullName, phoneNo: $phoneNo)';
}


}

/// @nodoc
abstract mixin class $BookingDetailCustomerModelCopyWith<$Res>  {
  factory $BookingDetailCustomerModelCopyWith(BookingDetailCustomerModel value, $Res Function(BookingDetailCustomerModel) _then) = _$BookingDetailCustomerModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_no') String phoneNo
});




}
/// @nodoc
class _$BookingDetailCustomerModelCopyWithImpl<$Res>
    implements $BookingDetailCustomerModelCopyWith<$Res> {
  _$BookingDetailCustomerModelCopyWithImpl(this._self, this._then);

  final BookingDetailCustomerModel _self;
  final $Res Function(BookingDetailCustomerModel) _then;

/// Create a copy of BookingDetailCustomerModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? phoneNo = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNo: null == phoneNo ? _self.phoneNo : phoneNo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailCustomerModel].
extension BookingDetailCustomerModelPatterns on BookingDetailCustomerModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailCustomerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailCustomerModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailCustomerModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailCustomerModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailCustomerModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailCustomerModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_no')  String phoneNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailCustomerModel() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_no')  String phoneNo)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailCustomerModel():
return $default(_that.id,_that.fullName,_that.phoneNo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'phone_no')  String phoneNo)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailCustomerModel() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailCustomerModel implements BookingDetailCustomerModel {
  const _BookingDetailCustomerModel({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'phone_no') required this.phoneNo});
  factory _BookingDetailCustomerModel.fromJson(Map<String, dynamic> json) => _$BookingDetailCustomerModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'phone_no') final  String phoneNo;

/// Create a copy of BookingDetailCustomerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailCustomerModelCopyWith<_BookingDetailCustomerModel> get copyWith => __$BookingDetailCustomerModelCopyWithImpl<_BookingDetailCustomerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailCustomerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailCustomerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNo, phoneNo) || other.phoneNo == phoneNo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNo);

@override
String toString() {
  return 'BookingDetailCustomerModel(id: $id, fullName: $fullName, phoneNo: $phoneNo)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailCustomerModelCopyWith<$Res> implements $BookingDetailCustomerModelCopyWith<$Res> {
  factory _$BookingDetailCustomerModelCopyWith(_BookingDetailCustomerModel value, $Res Function(_BookingDetailCustomerModel) _then) = __$BookingDetailCustomerModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'phone_no') String phoneNo
});




}
/// @nodoc
class __$BookingDetailCustomerModelCopyWithImpl<$Res>
    implements _$BookingDetailCustomerModelCopyWith<$Res> {
  __$BookingDetailCustomerModelCopyWithImpl(this._self, this._then);

  final _BookingDetailCustomerModel _self;
  final $Res Function(_BookingDetailCustomerModel) _then;

/// Create a copy of BookingDetailCustomerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneNo = null,}) {
  return _then(_BookingDetailCustomerModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNo: null == phoneNo ? _self.phoneNo : phoneNo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingDetailAddressModel {

 String get label;// Lat/lng are Decimal-strings on the wire (`"31.520400"`). Parsed
// to double in the mapper.
 String get latitude; String get longitude;@JsonKey(name: 'address_text') String get addressText;
/// Create a copy of BookingDetailAddressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailAddressModelCopyWith<BookingDetailAddressModel> get copyWith => _$BookingDetailAddressModelCopyWithImpl<BookingDetailAddressModel>(this as BookingDetailAddressModel, _$identity);

  /// Serializes this BookingDetailAddressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailAddressModel&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude,addressText);

@override
String toString() {
  return 'BookingDetailAddressModel(label: $label, latitude: $latitude, longitude: $longitude, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class $BookingDetailAddressModelCopyWith<$Res>  {
  factory $BookingDetailAddressModelCopyWith(BookingDetailAddressModel value, $Res Function(BookingDetailAddressModel) _then) = _$BookingDetailAddressModelCopyWithImpl;
@useResult
$Res call({
 String label, String latitude, String longitude,@JsonKey(name: 'address_text') String addressText
});




}
/// @nodoc
class _$BookingDetailAddressModelCopyWithImpl<$Res>
    implements $BookingDetailAddressModelCopyWith<$Res> {
  _$BookingDetailAddressModelCopyWithImpl(this._self, this._then);

  final BookingDetailAddressModel _self;
  final $Res Function(BookingDetailAddressModel) _then;

/// Create a copy of BookingDetailAddressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,Object? addressText = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailAddressModel].
extension BookingDetailAddressModelPatterns on BookingDetailAddressModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailAddressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailAddressModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailAddressModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailAddressModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailAddressModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailAddressModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String latitude,  String longitude, @JsonKey(name: 'address_text')  String addressText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailAddressModel() when $default != null:
return $default(_that.label,_that.latitude,_that.longitude,_that.addressText);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String latitude,  String longitude, @JsonKey(name: 'address_text')  String addressText)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailAddressModel():
return $default(_that.label,_that.latitude,_that.longitude,_that.addressText);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String latitude,  String longitude, @JsonKey(name: 'address_text')  String addressText)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailAddressModel() when $default != null:
return $default(_that.label,_that.latitude,_that.longitude,_that.addressText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailAddressModel implements BookingDetailAddressModel {
  const _BookingDetailAddressModel({required this.label, required this.latitude, required this.longitude, @JsonKey(name: 'address_text') required this.addressText});
  factory _BookingDetailAddressModel.fromJson(Map<String, dynamic> json) => _$BookingDetailAddressModelFromJson(json);

@override final  String label;
// Lat/lng are Decimal-strings on the wire (`"31.520400"`). Parsed
// to double in the mapper.
@override final  String latitude;
@override final  String longitude;
@override@JsonKey(name: 'address_text') final  String addressText;

/// Create a copy of BookingDetailAddressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailAddressModelCopyWith<_BookingDetailAddressModel> get copyWith => __$BookingDetailAddressModelCopyWithImpl<_BookingDetailAddressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailAddressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailAddressModel&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude,addressText);

@override
String toString() {
  return 'BookingDetailAddressModel(label: $label, latitude: $latitude, longitude: $longitude, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailAddressModelCopyWith<$Res> implements $BookingDetailAddressModelCopyWith<$Res> {
  factory _$BookingDetailAddressModelCopyWith(_BookingDetailAddressModel value, $Res Function(_BookingDetailAddressModel) _then) = __$BookingDetailAddressModelCopyWithImpl;
@override @useResult
$Res call({
 String label, String latitude, String longitude,@JsonKey(name: 'address_text') String addressText
});




}
/// @nodoc
class __$BookingDetailAddressModelCopyWithImpl<$Res>
    implements _$BookingDetailAddressModelCopyWith<$Res> {
  __$BookingDetailAddressModelCopyWithImpl(this._self, this._then);

  final _BookingDetailAddressModel _self;
  final $Res Function(_BookingDetailAddressModel) _then;

/// Create a copy of BookingDetailAddressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,Object? addressText = null,}) {
  return _then(_BookingDetailAddressModel(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingDetailPhaseTimestampsModel {

@JsonKey(name: 'accepted_at') String? get acceptedAt;@JsonKey(name: 'en_route_started_at') String? get enRouteStartedAt;@JsonKey(name: 'arrived_at') String? get arrivedAt;@JsonKey(name: 'inspection_started_at') String? get inspectionStartedAt;@JsonKey(name: 'quote_first_submitted_at') String? get quoteFirstSubmittedAt;@JsonKey(name: 'work_started_at') String? get workStartedAt;@JsonKey(name: 'completed_at') String? get completedAt;
/// Create a copy of BookingDetailPhaseTimestampsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailPhaseTimestampsModelCopyWith<BookingDetailPhaseTimestampsModel> get copyWith => _$BookingDetailPhaseTimestampsModelCopyWithImpl<BookingDetailPhaseTimestampsModel>(this as BookingDetailPhaseTimestampsModel, _$identity);

  /// Serializes this BookingDetailPhaseTimestampsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailPhaseTimestampsModel&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteStartedAt, enRouteStartedAt) || other.enRouteStartedAt == enRouteStartedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.inspectionStartedAt, inspectionStartedAt) || other.inspectionStartedAt == inspectionStartedAt)&&(identical(other.quoteFirstSubmittedAt, quoteFirstSubmittedAt) || other.quoteFirstSubmittedAt == quoteFirstSubmittedAt)&&(identical(other.workStartedAt, workStartedAt) || other.workStartedAt == workStartedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptedAt,enRouteStartedAt,arrivedAt,inspectionStartedAt,quoteFirstSubmittedAt,workStartedAt,completedAt);

@override
String toString() {
  return 'BookingDetailPhaseTimestampsModel(acceptedAt: $acceptedAt, enRouteStartedAt: $enRouteStartedAt, arrivedAt: $arrivedAt, inspectionStartedAt: $inspectionStartedAt, quoteFirstSubmittedAt: $quoteFirstSubmittedAt, workStartedAt: $workStartedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $BookingDetailPhaseTimestampsModelCopyWith<$Res>  {
  factory $BookingDetailPhaseTimestampsModelCopyWith(BookingDetailPhaseTimestampsModel value, $Res Function(BookingDetailPhaseTimestampsModel) _then) = _$BookingDetailPhaseTimestampsModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'accepted_at') String? acceptedAt,@JsonKey(name: 'en_route_started_at') String? enRouteStartedAt,@JsonKey(name: 'arrived_at') String? arrivedAt,@JsonKey(name: 'inspection_started_at') String? inspectionStartedAt,@JsonKey(name: 'quote_first_submitted_at') String? quoteFirstSubmittedAt,@JsonKey(name: 'work_started_at') String? workStartedAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class _$BookingDetailPhaseTimestampsModelCopyWithImpl<$Res>
    implements $BookingDetailPhaseTimestampsModelCopyWith<$Res> {
  _$BookingDetailPhaseTimestampsModelCopyWithImpl(this._self, this._then);

  final BookingDetailPhaseTimestampsModel _self;
  final $Res Function(BookingDetailPhaseTimestampsModel) _then;

/// Create a copy of BookingDetailPhaseTimestampsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acceptedAt = freezed,Object? enRouteStartedAt = freezed,Object? arrivedAt = freezed,Object? inspectionStartedAt = freezed,Object? quoteFirstSubmittedAt = freezed,Object? workStartedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,enRouteStartedAt: freezed == enRouteStartedAt ? _self.enRouteStartedAt : enRouteStartedAt // ignore: cast_nullable_to_non_nullable
as String?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as String?,inspectionStartedAt: freezed == inspectionStartedAt ? _self.inspectionStartedAt : inspectionStartedAt // ignore: cast_nullable_to_non_nullable
as String?,quoteFirstSubmittedAt: freezed == quoteFirstSubmittedAt ? _self.quoteFirstSubmittedAt : quoteFirstSubmittedAt // ignore: cast_nullable_to_non_nullable
as String?,workStartedAt: freezed == workStartedAt ? _self.workStartedAt : workStartedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailPhaseTimestampsModel].
extension BookingDetailPhaseTimestampsModelPatterns on BookingDetailPhaseTimestampsModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailPhaseTimestampsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailPhaseTimestampsModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailPhaseTimestampsModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'en_route_started_at')  String? enRouteStartedAt, @JsonKey(name: 'arrived_at')  String? arrivedAt, @JsonKey(name: 'inspection_started_at')  String? inspectionStartedAt, @JsonKey(name: 'quote_first_submitted_at')  String? quoteFirstSubmittedAt, @JsonKey(name: 'work_started_at')  String? workStartedAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel() when $default != null:
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'en_route_started_at')  String? enRouteStartedAt, @JsonKey(name: 'arrived_at')  String? arrivedAt, @JsonKey(name: 'inspection_started_at')  String? inspectionStartedAt, @JsonKey(name: 'quote_first_submitted_at')  String? quoteFirstSubmittedAt, @JsonKey(name: 'work_started_at')  String? workStartedAt, @JsonKey(name: 'completed_at')  String? completedAt)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel():
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'accepted_at')  String? acceptedAt, @JsonKey(name: 'en_route_started_at')  String? enRouteStartedAt, @JsonKey(name: 'arrived_at')  String? arrivedAt, @JsonKey(name: 'inspection_started_at')  String? inspectionStartedAt, @JsonKey(name: 'quote_first_submitted_at')  String? quoteFirstSubmittedAt, @JsonKey(name: 'work_started_at')  String? workStartedAt, @JsonKey(name: 'completed_at')  String? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailPhaseTimestampsModel() when $default != null:
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailPhaseTimestampsModel implements BookingDetailPhaseTimestampsModel {
  const _BookingDetailPhaseTimestampsModel({@JsonKey(name: 'accepted_at') this.acceptedAt, @JsonKey(name: 'en_route_started_at') this.enRouteStartedAt, @JsonKey(name: 'arrived_at') this.arrivedAt, @JsonKey(name: 'inspection_started_at') this.inspectionStartedAt, @JsonKey(name: 'quote_first_submitted_at') this.quoteFirstSubmittedAt, @JsonKey(name: 'work_started_at') this.workStartedAt, @JsonKey(name: 'completed_at') this.completedAt});
  factory _BookingDetailPhaseTimestampsModel.fromJson(Map<String, dynamic> json) => _$BookingDetailPhaseTimestampsModelFromJson(json);

@override@JsonKey(name: 'accepted_at') final  String? acceptedAt;
@override@JsonKey(name: 'en_route_started_at') final  String? enRouteStartedAt;
@override@JsonKey(name: 'arrived_at') final  String? arrivedAt;
@override@JsonKey(name: 'inspection_started_at') final  String? inspectionStartedAt;
@override@JsonKey(name: 'quote_first_submitted_at') final  String? quoteFirstSubmittedAt;
@override@JsonKey(name: 'work_started_at') final  String? workStartedAt;
@override@JsonKey(name: 'completed_at') final  String? completedAt;

/// Create a copy of BookingDetailPhaseTimestampsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailPhaseTimestampsModelCopyWith<_BookingDetailPhaseTimestampsModel> get copyWith => __$BookingDetailPhaseTimestampsModelCopyWithImpl<_BookingDetailPhaseTimestampsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailPhaseTimestampsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailPhaseTimestampsModel&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteStartedAt, enRouteStartedAt) || other.enRouteStartedAt == enRouteStartedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.inspectionStartedAt, inspectionStartedAt) || other.inspectionStartedAt == inspectionStartedAt)&&(identical(other.quoteFirstSubmittedAt, quoteFirstSubmittedAt) || other.quoteFirstSubmittedAt == quoteFirstSubmittedAt)&&(identical(other.workStartedAt, workStartedAt) || other.workStartedAt == workStartedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acceptedAt,enRouteStartedAt,arrivedAt,inspectionStartedAt,quoteFirstSubmittedAt,workStartedAt,completedAt);

@override
String toString() {
  return 'BookingDetailPhaseTimestampsModel(acceptedAt: $acceptedAt, enRouteStartedAt: $enRouteStartedAt, arrivedAt: $arrivedAt, inspectionStartedAt: $inspectionStartedAt, quoteFirstSubmittedAt: $quoteFirstSubmittedAt, workStartedAt: $workStartedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailPhaseTimestampsModelCopyWith<$Res> implements $BookingDetailPhaseTimestampsModelCopyWith<$Res> {
  factory _$BookingDetailPhaseTimestampsModelCopyWith(_BookingDetailPhaseTimestampsModel value, $Res Function(_BookingDetailPhaseTimestampsModel) _then) = __$BookingDetailPhaseTimestampsModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'accepted_at') String? acceptedAt,@JsonKey(name: 'en_route_started_at') String? enRouteStartedAt,@JsonKey(name: 'arrived_at') String? arrivedAt,@JsonKey(name: 'inspection_started_at') String? inspectionStartedAt,@JsonKey(name: 'quote_first_submitted_at') String? quoteFirstSubmittedAt,@JsonKey(name: 'work_started_at') String? workStartedAt,@JsonKey(name: 'completed_at') String? completedAt
});




}
/// @nodoc
class __$BookingDetailPhaseTimestampsModelCopyWithImpl<$Res>
    implements _$BookingDetailPhaseTimestampsModelCopyWith<$Res> {
  __$BookingDetailPhaseTimestampsModelCopyWithImpl(this._self, this._then);

  final _BookingDetailPhaseTimestampsModel _self;
  final $Res Function(_BookingDetailPhaseTimestampsModel) _then;

/// Create a copy of BookingDetailPhaseTimestampsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acceptedAt = freezed,Object? enRouteStartedAt = freezed,Object? arrivedAt = freezed,Object? inspectionStartedAt = freezed,Object? quoteFirstSubmittedAt = freezed,Object? workStartedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_BookingDetailPhaseTimestampsModel(
acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as String?,enRouteStartedAt: freezed == enRouteStartedAt ? _self.enRouteStartedAt : enRouteStartedAt // ignore: cast_nullable_to_non_nullable
as String?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as String?,inspectionStartedAt: freezed == inspectionStartedAt ? _self.inspectionStartedAt : inspectionStartedAt // ignore: cast_nullable_to_non_nullable
as String?,quoteFirstSubmittedAt: freezed == quoteFirstSubmittedAt ? _self.quoteFirstSubmittedAt : quoteFirstSubmittedAt // ignore: cast_nullable_to_non_nullable
as String?,workStartedAt: freezed == workStartedAt ? _self.workStartedAt : workStartedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingDetailPricingModel {

@JsonKey(name: 'inspection_fee') String? get inspectionFee;@JsonKey(name: 'base_services_total') String? get baseServicesTotal;@JsonKey(name: 'discount_applied') String? get discountApplied;@JsonKey(name: 'final_cash_to_collect') String? get finalCashToCollect;@JsonKey(name: 'promo_code_snapshot') String? get promoCodeSnapshot;@JsonKey(name: 'promo_discount_snapshot') String? get promoDiscountSnapshot;
/// Create a copy of BookingDetailPricingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailPricingModelCopyWith<BookingDetailPricingModel> get copyWith => _$BookingDetailPricingModelCopyWithImpl<BookingDetailPricingModel>(this as BookingDetailPricingModel, _$identity);

  /// Serializes this BookingDetailPricingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailPricingModel&&(identical(other.inspectionFee, inspectionFee) || other.inspectionFee == inspectionFee)&&(identical(other.baseServicesTotal, baseServicesTotal) || other.baseServicesTotal == baseServicesTotal)&&(identical(other.discountApplied, discountApplied) || other.discountApplied == discountApplied)&&(identical(other.finalCashToCollect, finalCashToCollect) || other.finalCashToCollect == finalCashToCollect)&&(identical(other.promoCodeSnapshot, promoCodeSnapshot) || other.promoCodeSnapshot == promoCodeSnapshot)&&(identical(other.promoDiscountSnapshot, promoDiscountSnapshot) || other.promoDiscountSnapshot == promoDiscountSnapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inspectionFee,baseServicesTotal,discountApplied,finalCashToCollect,promoCodeSnapshot,promoDiscountSnapshot);

@override
String toString() {
  return 'BookingDetailPricingModel(inspectionFee: $inspectionFee, baseServicesTotal: $baseServicesTotal, discountApplied: $discountApplied, finalCashToCollect: $finalCashToCollect, promoCodeSnapshot: $promoCodeSnapshot, promoDiscountSnapshot: $promoDiscountSnapshot)';
}


}

/// @nodoc
abstract mixin class $BookingDetailPricingModelCopyWith<$Res>  {
  factory $BookingDetailPricingModelCopyWith(BookingDetailPricingModel value, $Res Function(BookingDetailPricingModel) _then) = _$BookingDetailPricingModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'inspection_fee') String? inspectionFee,@JsonKey(name: 'base_services_total') String? baseServicesTotal,@JsonKey(name: 'discount_applied') String? discountApplied,@JsonKey(name: 'final_cash_to_collect') String? finalCashToCollect,@JsonKey(name: 'promo_code_snapshot') String? promoCodeSnapshot,@JsonKey(name: 'promo_discount_snapshot') String? promoDiscountSnapshot
});




}
/// @nodoc
class _$BookingDetailPricingModelCopyWithImpl<$Res>
    implements $BookingDetailPricingModelCopyWith<$Res> {
  _$BookingDetailPricingModelCopyWithImpl(this._self, this._then);

  final BookingDetailPricingModel _self;
  final $Res Function(BookingDetailPricingModel) _then;

/// Create a copy of BookingDetailPricingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inspectionFee = freezed,Object? baseServicesTotal = freezed,Object? discountApplied = freezed,Object? finalCashToCollect = freezed,Object? promoCodeSnapshot = freezed,Object? promoDiscountSnapshot = freezed,}) {
  return _then(_self.copyWith(
inspectionFee: freezed == inspectionFee ? _self.inspectionFee : inspectionFee // ignore: cast_nullable_to_non_nullable
as String?,baseServicesTotal: freezed == baseServicesTotal ? _self.baseServicesTotal : baseServicesTotal // ignore: cast_nullable_to_non_nullable
as String?,discountApplied: freezed == discountApplied ? _self.discountApplied : discountApplied // ignore: cast_nullable_to_non_nullable
as String?,finalCashToCollect: freezed == finalCashToCollect ? _self.finalCashToCollect : finalCashToCollect // ignore: cast_nullable_to_non_nullable
as String?,promoCodeSnapshot: freezed == promoCodeSnapshot ? _self.promoCodeSnapshot : promoCodeSnapshot // ignore: cast_nullable_to_non_nullable
as String?,promoDiscountSnapshot: freezed == promoDiscountSnapshot ? _self.promoDiscountSnapshot : promoDiscountSnapshot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailPricingModel].
extension BookingDetailPricingModelPatterns on BookingDetailPricingModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailPricingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailPricingModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailPricingModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailPricingModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailPricingModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailPricingModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'inspection_fee')  String? inspectionFee, @JsonKey(name: 'base_services_total')  String? baseServicesTotal, @JsonKey(name: 'discount_applied')  String? discountApplied, @JsonKey(name: 'final_cash_to_collect')  String? finalCashToCollect, @JsonKey(name: 'promo_code_snapshot')  String? promoCodeSnapshot, @JsonKey(name: 'promo_discount_snapshot')  String? promoDiscountSnapshot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailPricingModel() when $default != null:
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'inspection_fee')  String? inspectionFee, @JsonKey(name: 'base_services_total')  String? baseServicesTotal, @JsonKey(name: 'discount_applied')  String? discountApplied, @JsonKey(name: 'final_cash_to_collect')  String? finalCashToCollect, @JsonKey(name: 'promo_code_snapshot')  String? promoCodeSnapshot, @JsonKey(name: 'promo_discount_snapshot')  String? promoDiscountSnapshot)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailPricingModel():
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'inspection_fee')  String? inspectionFee, @JsonKey(name: 'base_services_total')  String? baseServicesTotal, @JsonKey(name: 'discount_applied')  String? discountApplied, @JsonKey(name: 'final_cash_to_collect')  String? finalCashToCollect, @JsonKey(name: 'promo_code_snapshot')  String? promoCodeSnapshot, @JsonKey(name: 'promo_discount_snapshot')  String? promoDiscountSnapshot)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailPricingModel() when $default != null:
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailPricingModel implements BookingDetailPricingModel {
  const _BookingDetailPricingModel({@JsonKey(name: 'inspection_fee') this.inspectionFee, @JsonKey(name: 'base_services_total') this.baseServicesTotal, @JsonKey(name: 'discount_applied') this.discountApplied, @JsonKey(name: 'final_cash_to_collect') this.finalCashToCollect, @JsonKey(name: 'promo_code_snapshot') this.promoCodeSnapshot, @JsonKey(name: 'promo_discount_snapshot') this.promoDiscountSnapshot});
  factory _BookingDetailPricingModel.fromJson(Map<String, dynamic> json) => _$BookingDetailPricingModelFromJson(json);

@override@JsonKey(name: 'inspection_fee') final  String? inspectionFee;
@override@JsonKey(name: 'base_services_total') final  String? baseServicesTotal;
@override@JsonKey(name: 'discount_applied') final  String? discountApplied;
@override@JsonKey(name: 'final_cash_to_collect') final  String? finalCashToCollect;
@override@JsonKey(name: 'promo_code_snapshot') final  String? promoCodeSnapshot;
@override@JsonKey(name: 'promo_discount_snapshot') final  String? promoDiscountSnapshot;

/// Create a copy of BookingDetailPricingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailPricingModelCopyWith<_BookingDetailPricingModel> get copyWith => __$BookingDetailPricingModelCopyWithImpl<_BookingDetailPricingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailPricingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailPricingModel&&(identical(other.inspectionFee, inspectionFee) || other.inspectionFee == inspectionFee)&&(identical(other.baseServicesTotal, baseServicesTotal) || other.baseServicesTotal == baseServicesTotal)&&(identical(other.discountApplied, discountApplied) || other.discountApplied == discountApplied)&&(identical(other.finalCashToCollect, finalCashToCollect) || other.finalCashToCollect == finalCashToCollect)&&(identical(other.promoCodeSnapshot, promoCodeSnapshot) || other.promoCodeSnapshot == promoCodeSnapshot)&&(identical(other.promoDiscountSnapshot, promoDiscountSnapshot) || other.promoDiscountSnapshot == promoDiscountSnapshot));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inspectionFee,baseServicesTotal,discountApplied,finalCashToCollect,promoCodeSnapshot,promoDiscountSnapshot);

@override
String toString() {
  return 'BookingDetailPricingModel(inspectionFee: $inspectionFee, baseServicesTotal: $baseServicesTotal, discountApplied: $discountApplied, finalCashToCollect: $finalCashToCollect, promoCodeSnapshot: $promoCodeSnapshot, promoDiscountSnapshot: $promoDiscountSnapshot)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailPricingModelCopyWith<$Res> implements $BookingDetailPricingModelCopyWith<$Res> {
  factory _$BookingDetailPricingModelCopyWith(_BookingDetailPricingModel value, $Res Function(_BookingDetailPricingModel) _then) = __$BookingDetailPricingModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'inspection_fee') String? inspectionFee,@JsonKey(name: 'base_services_total') String? baseServicesTotal,@JsonKey(name: 'discount_applied') String? discountApplied,@JsonKey(name: 'final_cash_to_collect') String? finalCashToCollect,@JsonKey(name: 'promo_code_snapshot') String? promoCodeSnapshot,@JsonKey(name: 'promo_discount_snapshot') String? promoDiscountSnapshot
});




}
/// @nodoc
class __$BookingDetailPricingModelCopyWithImpl<$Res>
    implements _$BookingDetailPricingModelCopyWith<$Res> {
  __$BookingDetailPricingModelCopyWithImpl(this._self, this._then);

  final _BookingDetailPricingModel _self;
  final $Res Function(_BookingDetailPricingModel) _then;

/// Create a copy of BookingDetailPricingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inspectionFee = freezed,Object? baseServicesTotal = freezed,Object? discountApplied = freezed,Object? finalCashToCollect = freezed,Object? promoCodeSnapshot = freezed,Object? promoDiscountSnapshot = freezed,}) {
  return _then(_BookingDetailPricingModel(
inspectionFee: freezed == inspectionFee ? _self.inspectionFee : inspectionFee // ignore: cast_nullable_to_non_nullable
as String?,baseServicesTotal: freezed == baseServicesTotal ? _self.baseServicesTotal : baseServicesTotal // ignore: cast_nullable_to_non_nullable
as String?,discountApplied: freezed == discountApplied ? _self.discountApplied : discountApplied // ignore: cast_nullable_to_non_nullable
as String?,finalCashToCollect: freezed == finalCashToCollect ? _self.finalCashToCollect : finalCashToCollect // ignore: cast_nullable_to_non_nullable
as String?,promoCodeSnapshot: freezed == promoCodeSnapshot ? _self.promoCodeSnapshot : promoCodeSnapshot // ignore: cast_nullable_to_non_nullable
as String?,promoDiscountSnapshot: freezed == promoDiscountSnapshot ? _self.promoDiscountSnapshot : promoDiscountSnapshot // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingDetailCashCollectionModel {

 String? get amount; String? get at; String get method;
/// Create a copy of BookingDetailCashCollectionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailCashCollectionModelCopyWith<BookingDetailCashCollectionModel> get copyWith => _$BookingDetailCashCollectionModelCopyWithImpl<BookingDetailCashCollectionModel>(this as BookingDetailCashCollectionModel, _$identity);

  /// Serializes this BookingDetailCashCollectionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetailCashCollectionModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at)&&(identical(other.method, method) || other.method == method));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,at,method);

@override
String toString() {
  return 'BookingDetailCashCollectionModel(amount: $amount, at: $at, method: $method)';
}


}

/// @nodoc
abstract mixin class $BookingDetailCashCollectionModelCopyWith<$Res>  {
  factory $BookingDetailCashCollectionModelCopyWith(BookingDetailCashCollectionModel value, $Res Function(BookingDetailCashCollectionModel) _then) = _$BookingDetailCashCollectionModelCopyWithImpl;
@useResult
$Res call({
 String? amount, String? at, String method
});




}
/// @nodoc
class _$BookingDetailCashCollectionModelCopyWithImpl<$Res>
    implements $BookingDetailCashCollectionModelCopyWith<$Res> {
  _$BookingDetailCashCollectionModelCopyWithImpl(this._self, this._then);

  final BookingDetailCashCollectionModel _self;
  final $Res Function(BookingDetailCashCollectionModel) _then;

/// Create a copy of BookingDetailCashCollectionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? at = freezed,Object? method = null,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingDetailCashCollectionModel].
extension BookingDetailCashCollectionModelPatterns on BookingDetailCashCollectionModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetailCashCollectionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetailCashCollectionModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetailCashCollectionModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? amount,  String? at,  String method)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel() when $default != null:
return $default(_that.amount,_that.at,_that.method);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? amount,  String? at,  String method)  $default,) {final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel():
return $default(_that.amount,_that.at,_that.method);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? amount,  String? at,  String method)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetailCashCollectionModel() when $default != null:
return $default(_that.amount,_that.at,_that.method);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingDetailCashCollectionModel implements BookingDetailCashCollectionModel {
  const _BookingDetailCashCollectionModel({this.amount, this.at, this.method = 'cash'});
  factory _BookingDetailCashCollectionModel.fromJson(Map<String, dynamic> json) => _$BookingDetailCashCollectionModelFromJson(json);

@override final  String? amount;
@override final  String? at;
@override@JsonKey() final  String method;

/// Create a copy of BookingDetailCashCollectionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailCashCollectionModelCopyWith<_BookingDetailCashCollectionModel> get copyWith => __$BookingDetailCashCollectionModelCopyWithImpl<_BookingDetailCashCollectionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingDetailCashCollectionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetailCashCollectionModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at)&&(identical(other.method, method) || other.method == method));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,at,method);

@override
String toString() {
  return 'BookingDetailCashCollectionModel(amount: $amount, at: $at, method: $method)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailCashCollectionModelCopyWith<$Res> implements $BookingDetailCashCollectionModelCopyWith<$Res> {
  factory _$BookingDetailCashCollectionModelCopyWith(_BookingDetailCashCollectionModel value, $Res Function(_BookingDetailCashCollectionModel) _then) = __$BookingDetailCashCollectionModelCopyWithImpl;
@override @useResult
$Res call({
 String? amount, String? at, String method
});




}
/// @nodoc
class __$BookingDetailCashCollectionModelCopyWithImpl<$Res>
    implements _$BookingDetailCashCollectionModelCopyWith<$Res> {
  __$BookingDetailCashCollectionModelCopyWithImpl(this._self, this._then);

  final _BookingDetailCashCollectionModel _self;
  final $Res Function(_BookingDetailCashCollectionModel) _then;

/// Create a copy of BookingDetailCashCollectionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? at = freezed,Object? method = null,}) {
  return _then(_BookingDetailCashCollectionModel(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as String?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

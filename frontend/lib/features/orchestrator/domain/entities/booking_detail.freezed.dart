// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingDetail {

 int get id; BookingStatus get status; BookingService get service; BookingSubService? get subService; BookingTechnician get technician; BookingCustomer get customer; BookingAddress? get address; String get addressSnapshot; DateTime get scheduledStart; DateTime get scheduledEnd; BookingPhaseTimestamps get phaseTimestamps; BookingPricing get pricing; BookingCashCollection get cashCollection; int? get parentBookingId; int? get childBookingId; String? get cancelReason; String? get noShowActor; BookingQuote? get activeQuote; List<BookingItem> get bookingItems; int get openTicketsCount; BookingUiBlock get ui; List<String> get availableTransitions; BookingOrchestratorRole get viewerRole;
/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingDetailCopyWith<BookingDetail> get copyWith => _$BookingDetailCopyWithImpl<BookingDetail>(this as BookingDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subService, subService) || other.subService == subService)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressSnapshot, addressSnapshot) || other.addressSnapshot == addressSnapshot)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.phaseTimestamps, phaseTimestamps) || other.phaseTimestamps == phaseTimestamps)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.cashCollection, cashCollection) || other.cashCollection == cashCollection)&&(identical(other.parentBookingId, parentBookingId) || other.parentBookingId == parentBookingId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.noShowActor, noShowActor) || other.noShowActor == noShowActor)&&(identical(other.activeQuote, activeQuote) || other.activeQuote == activeQuote)&&const DeepCollectionEquality().equals(other.bookingItems, bookingItems)&&(identical(other.openTicketsCount, openTicketsCount) || other.openTicketsCount == openTicketsCount)&&(identical(other.ui, ui) || other.ui == ui)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions)&&(identical(other.viewerRole, viewerRole) || other.viewerRole == viewerRole));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,status,service,subService,technician,customer,address,addressSnapshot,scheduledStart,scheduledEnd,phaseTimestamps,pricing,cashCollection,parentBookingId,childBookingId,cancelReason,noShowActor,activeQuote,const DeepCollectionEquality().hash(bookingItems),openTicketsCount,ui,const DeepCollectionEquality().hash(availableTransitions),viewerRole]);

@override
String toString() {
  return 'BookingDetail(id: $id, status: $status, service: $service, subService: $subService, technician: $technician, customer: $customer, address: $address, addressSnapshot: $addressSnapshot, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, phaseTimestamps: $phaseTimestamps, pricing: $pricing, cashCollection: $cashCollection, parentBookingId: $parentBookingId, childBookingId: $childBookingId, cancelReason: $cancelReason, noShowActor: $noShowActor, activeQuote: $activeQuote, bookingItems: $bookingItems, openTicketsCount: $openTicketsCount, ui: $ui, availableTransitions: $availableTransitions, viewerRole: $viewerRole)';
}


}

/// @nodoc
abstract mixin class $BookingDetailCopyWith<$Res>  {
  factory $BookingDetailCopyWith(BookingDetail value, $Res Function(BookingDetail) _then) = _$BookingDetailCopyWithImpl;
@useResult
$Res call({
 int id, BookingStatus status, BookingService service, BookingSubService? subService, BookingTechnician technician, BookingCustomer customer, BookingAddress? address, String addressSnapshot, DateTime scheduledStart, DateTime scheduledEnd, BookingPhaseTimestamps phaseTimestamps, BookingPricing pricing, BookingCashCollection cashCollection, int? parentBookingId, int? childBookingId, String? cancelReason, String? noShowActor, BookingQuote? activeQuote, List<BookingItem> bookingItems, int openTicketsCount, BookingUiBlock ui, List<String> availableTransitions, BookingOrchestratorRole viewerRole
});


$BookingServiceCopyWith<$Res> get service;$BookingSubServiceCopyWith<$Res>? get subService;$BookingTechnicianCopyWith<$Res> get technician;$BookingCustomerCopyWith<$Res> get customer;$BookingAddressCopyWith<$Res>? get address;$BookingPhaseTimestampsCopyWith<$Res> get phaseTimestamps;$BookingPricingCopyWith<$Res> get pricing;$BookingCashCollectionCopyWith<$Res> get cashCollection;$BookingQuoteCopyWith<$Res>? get activeQuote;$BookingUiBlockCopyWith<$Res> get ui;

}
/// @nodoc
class _$BookingDetailCopyWithImpl<$Res>
    implements $BookingDetailCopyWith<$Res> {
  _$BookingDetailCopyWithImpl(this._self, this._then);

  final BookingDetail _self;
  final $Res Function(BookingDetail) _then;

/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? subService = freezed,Object? technician = null,Object? customer = null,Object? address = freezed,Object? addressSnapshot = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? phaseTimestamps = null,Object? pricing = null,Object? cashCollection = null,Object? parentBookingId = freezed,Object? childBookingId = freezed,Object? cancelReason = freezed,Object? noShowActor = freezed,Object? activeQuote = freezed,Object? bookingItems = null,Object? openTicketsCount = null,Object? ui = null,Object? availableTransitions = null,Object? viewerRole = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingService,subService: freezed == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as BookingSubService?,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnician,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BookingCustomer,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as BookingAddress?,addressSnapshot: null == addressSnapshot ? _self.addressSnapshot : addressSnapshot // ignore: cast_nullable_to_non_nullable
as String,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,phaseTimestamps: null == phaseTimestamps ? _self.phaseTimestamps : phaseTimestamps // ignore: cast_nullable_to_non_nullable
as BookingPhaseTimestamps,pricing: null == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as BookingPricing,cashCollection: null == cashCollection ? _self.cashCollection : cashCollection // ignore: cast_nullable_to_non_nullable
as BookingCashCollection,parentBookingId: freezed == parentBookingId ? _self.parentBookingId : parentBookingId // ignore: cast_nullable_to_non_nullable
as int?,childBookingId: freezed == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,noShowActor: freezed == noShowActor ? _self.noShowActor : noShowActor // ignore: cast_nullable_to_non_nullable
as String?,activeQuote: freezed == activeQuote ? _self.activeQuote : activeQuote // ignore: cast_nullable_to_non_nullable
as BookingQuote?,bookingItems: null == bookingItems ? _self.bookingItems : bookingItems // ignore: cast_nullable_to_non_nullable
as List<BookingItem>,openTicketsCount: null == openTicketsCount ? _self.openTicketsCount : openTicketsCount // ignore: cast_nullable_to_non_nullable
as int,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiBlock,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<String>,viewerRole: null == viewerRole ? _self.viewerRole : viewerRole // ignore: cast_nullable_to_non_nullable
as BookingOrchestratorRole,
  ));
}
/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<$Res> get service {
  
  return $BookingServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingSubServiceCopyWith<$Res>? get subService {
    if (_self.subService == null) {
    return null;
  }

  return $BookingSubServiceCopyWith<$Res>(_self.subService!, (value) {
    return _then(_self.copyWith(subService: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianCopyWith<$Res> get technician {
  
  return $BookingTechnicianCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingCustomerCopyWith<$Res> get customer {
  
  return $BookingCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingAddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $BookingAddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPhaseTimestampsCopyWith<$Res> get phaseTimestamps {
  
  return $BookingPhaseTimestampsCopyWith<$Res>(_self.phaseTimestamps, (value) {
    return _then(_self.copyWith(phaseTimestamps: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPricingCopyWith<$Res> get pricing {
  
  return $BookingPricingCopyWith<$Res>(_self.pricing, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingCashCollectionCopyWith<$Res> get cashCollection {
  
  return $BookingCashCollectionCopyWith<$Res>(_self.cashCollection, (value) {
    return _then(_self.copyWith(cashCollection: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingQuoteCopyWith<$Res>? get activeQuote {
    if (_self.activeQuote == null) {
    return null;
  }

  return $BookingQuoteCopyWith<$Res>(_self.activeQuote!, (value) {
    return _then(_self.copyWith(activeQuote: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiBlockCopyWith<$Res> get ui {
  
  return $BookingUiBlockCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingDetail].
extension BookingDetailPatterns on BookingDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingDetail value)  $default,){
final _that = this;
switch (_that) {
case _BookingDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingDetail value)?  $default,){
final _that = this;
switch (_that) {
case _BookingDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  BookingService service,  BookingSubService? subService,  BookingTechnician technician,  BookingCustomer customer,  BookingAddress? address,  String addressSnapshot,  DateTime scheduledStart,  DateTime scheduledEnd,  BookingPhaseTimestamps phaseTimestamps,  BookingPricing pricing,  BookingCashCollection cashCollection,  int? parentBookingId,  int? childBookingId,  String? cancelReason,  String? noShowActor,  BookingQuote? activeQuote,  List<BookingItem> bookingItems,  int openTicketsCount,  BookingUiBlock ui,  List<String> availableTransitions,  BookingOrchestratorRole viewerRole)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingDetail() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions,_that.viewerRole);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  BookingService service,  BookingSubService? subService,  BookingTechnician technician,  BookingCustomer customer,  BookingAddress? address,  String addressSnapshot,  DateTime scheduledStart,  DateTime scheduledEnd,  BookingPhaseTimestamps phaseTimestamps,  BookingPricing pricing,  BookingCashCollection cashCollection,  int? parentBookingId,  int? childBookingId,  String? cancelReason,  String? noShowActor,  BookingQuote? activeQuote,  List<BookingItem> bookingItems,  int openTicketsCount,  BookingUiBlock ui,  List<String> availableTransitions,  BookingOrchestratorRole viewerRole)  $default,) {final _that = this;
switch (_that) {
case _BookingDetail():
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions,_that.viewerRole);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  BookingStatus status,  BookingService service,  BookingSubService? subService,  BookingTechnician technician,  BookingCustomer customer,  BookingAddress? address,  String addressSnapshot,  DateTime scheduledStart,  DateTime scheduledEnd,  BookingPhaseTimestamps phaseTimestamps,  BookingPricing pricing,  BookingCashCollection cashCollection,  int? parentBookingId,  int? childBookingId,  String? cancelReason,  String? noShowActor,  BookingQuote? activeQuote,  List<BookingItem> bookingItems,  int openTicketsCount,  BookingUiBlock ui,  List<String> availableTransitions,  BookingOrchestratorRole viewerRole)?  $default,) {final _that = this;
switch (_that) {
case _BookingDetail() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.subService,_that.technician,_that.customer,_that.address,_that.addressSnapshot,_that.scheduledStart,_that.scheduledEnd,_that.phaseTimestamps,_that.pricing,_that.cashCollection,_that.parentBookingId,_that.childBookingId,_that.cancelReason,_that.noShowActor,_that.activeQuote,_that.bookingItems,_that.openTicketsCount,_that.ui,_that.availableTransitions,_that.viewerRole);case _:
  return null;

}
}

}

/// @nodoc


class _BookingDetail implements BookingDetail {
  const _BookingDetail({required this.id, required this.status, required this.service, this.subService, required this.technician, required this.customer, this.address, required this.addressSnapshot, required this.scheduledStart, required this.scheduledEnd, required this.phaseTimestamps, required this.pricing, required this.cashCollection, this.parentBookingId, this.childBookingId, this.cancelReason, this.noShowActor, this.activeQuote, final  List<BookingItem> bookingItems = const [], this.openTicketsCount = 0, required this.ui, final  List<String> availableTransitions = const [], required this.viewerRole}): _bookingItems = bookingItems,_availableTransitions = availableTransitions;
  

@override final  int id;
@override final  BookingStatus status;
@override final  BookingService service;
@override final  BookingSubService? subService;
@override final  BookingTechnician technician;
@override final  BookingCustomer customer;
@override final  BookingAddress? address;
@override final  String addressSnapshot;
@override final  DateTime scheduledStart;
@override final  DateTime scheduledEnd;
@override final  BookingPhaseTimestamps phaseTimestamps;
@override final  BookingPricing pricing;
@override final  BookingCashCollection cashCollection;
@override final  int? parentBookingId;
@override final  int? childBookingId;
@override final  String? cancelReason;
@override final  String? noShowActor;
@override final  BookingQuote? activeQuote;
 final  List<BookingItem> _bookingItems;
@override@JsonKey() List<BookingItem> get bookingItems {
  if (_bookingItems is EqualUnmodifiableListView) return _bookingItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookingItems);
}

@override@JsonKey() final  int openTicketsCount;
@override final  BookingUiBlock ui;
 final  List<String> _availableTransitions;
@override@JsonKey() List<String> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}

@override final  BookingOrchestratorRole viewerRole;

/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingDetailCopyWith<_BookingDetail> get copyWith => __$BookingDetailCopyWithImpl<_BookingDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.subService, subService) || other.subService == subService)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.address, address) || other.address == address)&&(identical(other.addressSnapshot, addressSnapshot) || other.addressSnapshot == addressSnapshot)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.phaseTimestamps, phaseTimestamps) || other.phaseTimestamps == phaseTimestamps)&&(identical(other.pricing, pricing) || other.pricing == pricing)&&(identical(other.cashCollection, cashCollection) || other.cashCollection == cashCollection)&&(identical(other.parentBookingId, parentBookingId) || other.parentBookingId == parentBookingId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId)&&(identical(other.cancelReason, cancelReason) || other.cancelReason == cancelReason)&&(identical(other.noShowActor, noShowActor) || other.noShowActor == noShowActor)&&(identical(other.activeQuote, activeQuote) || other.activeQuote == activeQuote)&&const DeepCollectionEquality().equals(other._bookingItems, _bookingItems)&&(identical(other.openTicketsCount, openTicketsCount) || other.openTicketsCount == openTicketsCount)&&(identical(other.ui, ui) || other.ui == ui)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions)&&(identical(other.viewerRole, viewerRole) || other.viewerRole == viewerRole));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,status,service,subService,technician,customer,address,addressSnapshot,scheduledStart,scheduledEnd,phaseTimestamps,pricing,cashCollection,parentBookingId,childBookingId,cancelReason,noShowActor,activeQuote,const DeepCollectionEquality().hash(_bookingItems),openTicketsCount,ui,const DeepCollectionEquality().hash(_availableTransitions),viewerRole]);

@override
String toString() {
  return 'BookingDetail(id: $id, status: $status, service: $service, subService: $subService, technician: $technician, customer: $customer, address: $address, addressSnapshot: $addressSnapshot, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, phaseTimestamps: $phaseTimestamps, pricing: $pricing, cashCollection: $cashCollection, parentBookingId: $parentBookingId, childBookingId: $childBookingId, cancelReason: $cancelReason, noShowActor: $noShowActor, activeQuote: $activeQuote, bookingItems: $bookingItems, openTicketsCount: $openTicketsCount, ui: $ui, availableTransitions: $availableTransitions, viewerRole: $viewerRole)';
}


}

/// @nodoc
abstract mixin class _$BookingDetailCopyWith<$Res> implements $BookingDetailCopyWith<$Res> {
  factory _$BookingDetailCopyWith(_BookingDetail value, $Res Function(_BookingDetail) _then) = __$BookingDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, BookingStatus status, BookingService service, BookingSubService? subService, BookingTechnician technician, BookingCustomer customer, BookingAddress? address, String addressSnapshot, DateTime scheduledStart, DateTime scheduledEnd, BookingPhaseTimestamps phaseTimestamps, BookingPricing pricing, BookingCashCollection cashCollection, int? parentBookingId, int? childBookingId, String? cancelReason, String? noShowActor, BookingQuote? activeQuote, List<BookingItem> bookingItems, int openTicketsCount, BookingUiBlock ui, List<String> availableTransitions, BookingOrchestratorRole viewerRole
});


@override $BookingServiceCopyWith<$Res> get service;@override $BookingSubServiceCopyWith<$Res>? get subService;@override $BookingTechnicianCopyWith<$Res> get technician;@override $BookingCustomerCopyWith<$Res> get customer;@override $BookingAddressCopyWith<$Res>? get address;@override $BookingPhaseTimestampsCopyWith<$Res> get phaseTimestamps;@override $BookingPricingCopyWith<$Res> get pricing;@override $BookingCashCollectionCopyWith<$Res> get cashCollection;@override $BookingQuoteCopyWith<$Res>? get activeQuote;@override $BookingUiBlockCopyWith<$Res> get ui;

}
/// @nodoc
class __$BookingDetailCopyWithImpl<$Res>
    implements _$BookingDetailCopyWith<$Res> {
  __$BookingDetailCopyWithImpl(this._self, this._then);

  final _BookingDetail _self;
  final $Res Function(_BookingDetail) _then;

/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? subService = freezed,Object? technician = null,Object? customer = null,Object? address = freezed,Object? addressSnapshot = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? phaseTimestamps = null,Object? pricing = null,Object? cashCollection = null,Object? parentBookingId = freezed,Object? childBookingId = freezed,Object? cancelReason = freezed,Object? noShowActor = freezed,Object? activeQuote = freezed,Object? bookingItems = null,Object? openTicketsCount = null,Object? ui = null,Object? availableTransitions = null,Object? viewerRole = null,}) {
  return _then(_BookingDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingService,subService: freezed == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as BookingSubService?,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnician,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as BookingCustomer,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as BookingAddress?,addressSnapshot: null == addressSnapshot ? _self.addressSnapshot : addressSnapshot // ignore: cast_nullable_to_non_nullable
as String,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,phaseTimestamps: null == phaseTimestamps ? _self.phaseTimestamps : phaseTimestamps // ignore: cast_nullable_to_non_nullable
as BookingPhaseTimestamps,pricing: null == pricing ? _self.pricing : pricing // ignore: cast_nullable_to_non_nullable
as BookingPricing,cashCollection: null == cashCollection ? _self.cashCollection : cashCollection // ignore: cast_nullable_to_non_nullable
as BookingCashCollection,parentBookingId: freezed == parentBookingId ? _self.parentBookingId : parentBookingId // ignore: cast_nullable_to_non_nullable
as int?,childBookingId: freezed == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int?,cancelReason: freezed == cancelReason ? _self.cancelReason : cancelReason // ignore: cast_nullable_to_non_nullable
as String?,noShowActor: freezed == noShowActor ? _self.noShowActor : noShowActor // ignore: cast_nullable_to_non_nullable
as String?,activeQuote: freezed == activeQuote ? _self.activeQuote : activeQuote // ignore: cast_nullable_to_non_nullable
as BookingQuote?,bookingItems: null == bookingItems ? _self._bookingItems : bookingItems // ignore: cast_nullable_to_non_nullable
as List<BookingItem>,openTicketsCount: null == openTicketsCount ? _self.openTicketsCount : openTicketsCount // ignore: cast_nullable_to_non_nullable
as int,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiBlock,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<String>,viewerRole: null == viewerRole ? _self.viewerRole : viewerRole // ignore: cast_nullable_to_non_nullable
as BookingOrchestratorRole,
  ));
}

/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<$Res> get service {
  
  return $BookingServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingSubServiceCopyWith<$Res>? get subService {
    if (_self.subService == null) {
    return null;
  }

  return $BookingSubServiceCopyWith<$Res>(_self.subService!, (value) {
    return _then(_self.copyWith(subService: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianCopyWith<$Res> get technician {
  
  return $BookingTechnicianCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingCustomerCopyWith<$Res> get customer {
  
  return $BookingCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingAddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $BookingAddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPhaseTimestampsCopyWith<$Res> get phaseTimestamps {
  
  return $BookingPhaseTimestampsCopyWith<$Res>(_self.phaseTimestamps, (value) {
    return _then(_self.copyWith(phaseTimestamps: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPricingCopyWith<$Res> get pricing {
  
  return $BookingPricingCopyWith<$Res>(_self.pricing, (value) {
    return _then(_self.copyWith(pricing: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingCashCollectionCopyWith<$Res> get cashCollection {
  
  return $BookingCashCollectionCopyWith<$Res>(_self.cashCollection, (value) {
    return _then(_self.copyWith(cashCollection: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingQuoteCopyWith<$Res>? get activeQuote {
    if (_self.activeQuote == null) {
    return null;
  }

  return $BookingQuoteCopyWith<$Res>(_self.activeQuote!, (value) {
    return _then(_self.copyWith(activeQuote: value));
  });
}/// Create a copy of BookingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiBlockCopyWith<$Res> get ui {
  
  return $BookingUiBlockCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}

/// @nodoc
mixin _$BookingService {

 int get id; String get name; String get iconName;
/// Create a copy of BookingService
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<BookingService> get copyWith => _$BookingServiceCopyWithImpl<BookingService>(this as BookingService, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingService&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'BookingService(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $BookingServiceCopyWith<$Res>  {
  factory $BookingServiceCopyWith(BookingService value, $Res Function(BookingService) _then) = _$BookingServiceCopyWithImpl;
@useResult
$Res call({
 int id, String name, String iconName
});




}
/// @nodoc
class _$BookingServiceCopyWithImpl<$Res>
    implements $BookingServiceCopyWith<$Res> {
  _$BookingServiceCopyWithImpl(this._self, this._then);

  final BookingService _self;
  final $Res Function(BookingService) _then;

/// Create a copy of BookingService
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


/// Adds pattern-matching-related methods to [BookingService].
extension BookingServicePatterns on BookingService {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingService value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingService() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingService value)  $default,){
final _that = this;
switch (_that) {
case _BookingService():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingService value)?  $default,){
final _that = this;
switch (_that) {
case _BookingService() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingService() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String iconName)  $default,) {final _that = this;
switch (_that) {
case _BookingService():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _BookingService() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _BookingService implements BookingService {
  const _BookingService({required this.id, required this.name, required this.iconName});
  

@override final  int id;
@override final  String name;
@override final  String iconName;

/// Create a copy of BookingService
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingServiceCopyWith<_BookingService> get copyWith => __$BookingServiceCopyWithImpl<_BookingService>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingService&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'BookingService(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$BookingServiceCopyWith<$Res> implements $BookingServiceCopyWith<$Res> {
  factory _$BookingServiceCopyWith(_BookingService value, $Res Function(_BookingService) _then) = __$BookingServiceCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String iconName
});




}
/// @nodoc
class __$BookingServiceCopyWithImpl<$Res>
    implements _$BookingServiceCopyWith<$Res> {
  __$BookingServiceCopyWithImpl(this._self, this._then);

  final _BookingService _self;
  final $Res Function(_BookingService) _then;

/// Create a copy of BookingService
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = null,}) {
  return _then(_BookingService(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BookingSubService {

 int get id; String get name; bool get isFixedPrice; int get basePrice; int? get maxPrice;
/// Create a copy of BookingSubService
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingSubServiceCopyWith<BookingSubService> get copyWith => _$BookingSubServiceCopyWithImpl<BookingSubService>(this as BookingSubService, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingSubService&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isFixedPrice,basePrice,maxPrice);

@override
String toString() {
  return 'BookingSubService(id: $id, name: $name, isFixedPrice: $isFixedPrice, basePrice: $basePrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class $BookingSubServiceCopyWith<$Res>  {
  factory $BookingSubServiceCopyWith(BookingSubService value, $Res Function(BookingSubService) _then) = _$BookingSubServiceCopyWithImpl;
@useResult
$Res call({
 int id, String name, bool isFixedPrice, int basePrice, int? maxPrice
});




}
/// @nodoc
class _$BookingSubServiceCopyWithImpl<$Res>
    implements $BookingSubServiceCopyWith<$Res> {
  _$BookingSubServiceCopyWithImpl(this._self, this._then);

  final BookingSubService _self;
  final $Res Function(BookingSubService) _then;

/// Create a copy of BookingSubService
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isFixedPrice = null,Object? basePrice = null,Object? maxPrice = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingSubService].
extension BookingSubServicePatterns on BookingSubService {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingSubService value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingSubService() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingSubService value)  $default,){
final _that = this;
switch (_that) {
case _BookingSubService():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingSubService value)?  $default,){
final _that = this;
switch (_that) {
case _BookingSubService() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  bool isFixedPrice,  int basePrice,  int? maxPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingSubService() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  bool isFixedPrice,  int basePrice,  int? maxPrice)  $default,) {final _that = this;
switch (_that) {
case _BookingSubService():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  bool isFixedPrice,  int basePrice,  int? maxPrice)?  $default,) {final _that = this;
switch (_that) {
case _BookingSubService() when $default != null:
return $default(_that.id,_that.name,_that.isFixedPrice,_that.basePrice,_that.maxPrice);case _:
  return null;

}
}

}

/// @nodoc


class _BookingSubService implements BookingSubService {
  const _BookingSubService({required this.id, required this.name, required this.isFixedPrice, required this.basePrice, this.maxPrice});
  

@override final  int id;
@override final  String name;
@override final  bool isFixedPrice;
@override final  int basePrice;
@override final  int? maxPrice;

/// Create a copy of BookingSubService
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingSubServiceCopyWith<_BookingSubService> get copyWith => __$BookingSubServiceCopyWithImpl<_BookingSubService>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingSubService&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,isFixedPrice,basePrice,maxPrice);

@override
String toString() {
  return 'BookingSubService(id: $id, name: $name, isFixedPrice: $isFixedPrice, basePrice: $basePrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class _$BookingSubServiceCopyWith<$Res> implements $BookingSubServiceCopyWith<$Res> {
  factory _$BookingSubServiceCopyWith(_BookingSubService value, $Res Function(_BookingSubService) _then) = __$BookingSubServiceCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, bool isFixedPrice, int basePrice, int? maxPrice
});




}
/// @nodoc
class __$BookingSubServiceCopyWithImpl<$Res>
    implements _$BookingSubServiceCopyWith<$Res> {
  __$BookingSubServiceCopyWithImpl(this._self, this._then);

  final _BookingSubService _self;
  final $Res Function(_BookingSubService) _then;

/// Create a copy of BookingSubService
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isFixedPrice = null,Object? basePrice = null,Object? maxPrice = freezed,}) {
  return _then(_BookingSubService(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as int,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$BookingTechnician {

 int get id; String get displayName; String? get profilePictureUrl;
/// Create a copy of BookingTechnician
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingTechnicianCopyWith<BookingTechnician> get copyWith => _$BookingTechnicianCopyWithImpl<BookingTechnician>(this as BookingTechnician, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingTechnician&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingTechnician(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $BookingTechnicianCopyWith<$Res>  {
  factory $BookingTechnicianCopyWith(BookingTechnician value, $Res Function(BookingTechnician) _then) = _$BookingTechnicianCopyWithImpl;
@useResult
$Res call({
 int id, String displayName, String? profilePictureUrl
});




}
/// @nodoc
class _$BookingTechnicianCopyWithImpl<$Res>
    implements $BookingTechnicianCopyWith<$Res> {
  _$BookingTechnicianCopyWithImpl(this._self, this._then);

  final BookingTechnician _self;
  final $Res Function(BookingTechnician) _then;

/// Create a copy of BookingTechnician
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


/// Adds pattern-matching-related methods to [BookingTechnician].
extension BookingTechnicianPatterns on BookingTechnician {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingTechnician value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingTechnician() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingTechnician value)  $default,){
final _that = this;
switch (_that) {
case _BookingTechnician():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingTechnician value)?  $default,){
final _that = this;
switch (_that) {
case _BookingTechnician() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String displayName,  String? profilePictureUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingTechnician() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String displayName,  String? profilePictureUrl)  $default,) {final _that = this;
switch (_that) {
case _BookingTechnician():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String displayName,  String? profilePictureUrl)?  $default,) {final _that = this;
switch (_that) {
case _BookingTechnician() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc


class _BookingTechnician implements BookingTechnician {
  const _BookingTechnician({required this.id, required this.displayName, this.profilePictureUrl});
  

@override final  int id;
@override final  String displayName;
@override final  String? profilePictureUrl;

/// Create a copy of BookingTechnician
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingTechnicianCopyWith<_BookingTechnician> get copyWith => __$BookingTechnicianCopyWithImpl<_BookingTechnician>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingTechnician&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingTechnician(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$BookingTechnicianCopyWith<$Res> implements $BookingTechnicianCopyWith<$Res> {
  factory _$BookingTechnicianCopyWith(_BookingTechnician value, $Res Function(_BookingTechnician) _then) = __$BookingTechnicianCopyWithImpl;
@override @useResult
$Res call({
 int id, String displayName, String? profilePictureUrl
});




}
/// @nodoc
class __$BookingTechnicianCopyWithImpl<$Res>
    implements _$BookingTechnicianCopyWith<$Res> {
  __$BookingTechnicianCopyWithImpl(this._self, this._then);

  final _BookingTechnician _self;
  final $Res Function(_BookingTechnician) _then;

/// Create a copy of BookingTechnician
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_BookingTechnician(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$BookingCustomer {

 int get id; String get fullName; String get phoneNo;
/// Create a copy of BookingCustomer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCustomerCopyWith<BookingCustomer> get copyWith => _$BookingCustomerCopyWithImpl<BookingCustomer>(this as BookingCustomer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNo, phoneNo) || other.phoneNo == phoneNo));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNo);

@override
String toString() {
  return 'BookingCustomer(id: $id, fullName: $fullName, phoneNo: $phoneNo)';
}


}

/// @nodoc
abstract mixin class $BookingCustomerCopyWith<$Res>  {
  factory $BookingCustomerCopyWith(BookingCustomer value, $Res Function(BookingCustomer) _then) = _$BookingCustomerCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, String phoneNo
});




}
/// @nodoc
class _$BookingCustomerCopyWithImpl<$Res>
    implements $BookingCustomerCopyWith<$Res> {
  _$BookingCustomerCopyWithImpl(this._self, this._then);

  final BookingCustomer _self;
  final $Res Function(BookingCustomer) _then;

/// Create a copy of BookingCustomer
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


/// Adds pattern-matching-related methods to [BookingCustomer].
extension BookingCustomerPatterns on BookingCustomer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingCustomer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingCustomer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingCustomer value)  $default,){
final _that = this;
switch (_that) {
case _BookingCustomer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingCustomer value)?  $default,){
final _that = this;
switch (_that) {
case _BookingCustomer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  String phoneNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingCustomer() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  String phoneNo)  $default,) {final _that = this;
switch (_that) {
case _BookingCustomer():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  String phoneNo)?  $default,) {final _that = this;
switch (_that) {
case _BookingCustomer() when $default != null:
return $default(_that.id,_that.fullName,_that.phoneNo);case _:
  return null;

}
}

}

/// @nodoc


class _BookingCustomer implements BookingCustomer {
  const _BookingCustomer({required this.id, required this.fullName, required this.phoneNo});
  

@override final  int id;
@override final  String fullName;
@override final  String phoneNo;

/// Create a copy of BookingCustomer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCustomerCopyWith<_BookingCustomer> get copyWith => __$BookingCustomerCopyWithImpl<_BookingCustomer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phoneNo, phoneNo) || other.phoneNo == phoneNo));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,phoneNo);

@override
String toString() {
  return 'BookingCustomer(id: $id, fullName: $fullName, phoneNo: $phoneNo)';
}


}

/// @nodoc
abstract mixin class _$BookingCustomerCopyWith<$Res> implements $BookingCustomerCopyWith<$Res> {
  factory _$BookingCustomerCopyWith(_BookingCustomer value, $Res Function(_BookingCustomer) _then) = __$BookingCustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, String phoneNo
});




}
/// @nodoc
class __$BookingCustomerCopyWithImpl<$Res>
    implements _$BookingCustomerCopyWith<$Res> {
  __$BookingCustomerCopyWithImpl(this._self, this._then);

  final _BookingCustomer _self;
  final $Res Function(_BookingCustomer) _then;

/// Create a copy of BookingCustomer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? phoneNo = null,}) {
  return _then(_BookingCustomer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phoneNo: null == phoneNo ? _self.phoneNo : phoneNo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BookingAddress {

 String get label; double get latitude; double get longitude; String get addressText;
/// Create a copy of BookingAddress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingAddressCopyWith<BookingAddress> get copyWith => _$BookingAddressCopyWithImpl<BookingAddress>(this as BookingAddress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingAddress&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}


@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude,addressText);

@override
String toString() {
  return 'BookingAddress(label: $label, latitude: $latitude, longitude: $longitude, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class $BookingAddressCopyWith<$Res>  {
  factory $BookingAddressCopyWith(BookingAddress value, $Res Function(BookingAddress) _then) = _$BookingAddressCopyWithImpl;
@useResult
$Res call({
 String label, double latitude, double longitude, String addressText
});




}
/// @nodoc
class _$BookingAddressCopyWithImpl<$Res>
    implements $BookingAddressCopyWith<$Res> {
  _$BookingAddressCopyWithImpl(this._self, this._then);

  final BookingAddress _self;
  final $Res Function(BookingAddress) _then;

/// Create a copy of BookingAddress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,Object? addressText = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingAddress].
extension BookingAddressPatterns on BookingAddress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingAddress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingAddress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingAddress value)  $default,){
final _that = this;
switch (_that) {
case _BookingAddress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingAddress value)?  $default,){
final _that = this;
switch (_that) {
case _BookingAddress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  double latitude,  double longitude,  String addressText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingAddress() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  double latitude,  double longitude,  String addressText)  $default,) {final _that = this;
switch (_that) {
case _BookingAddress():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  double latitude,  double longitude,  String addressText)?  $default,) {final _that = this;
switch (_that) {
case _BookingAddress() when $default != null:
return $default(_that.label,_that.latitude,_that.longitude,_that.addressText);case _:
  return null;

}
}

}

/// @nodoc


class _BookingAddress implements BookingAddress {
  const _BookingAddress({required this.label, required this.latitude, required this.longitude, required this.addressText});
  

@override final  String label;
@override final  double latitude;
@override final  double longitude;
@override final  String addressText;

/// Create a copy of BookingAddress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingAddressCopyWith<_BookingAddress> get copyWith => __$BookingAddressCopyWithImpl<_BookingAddress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingAddress&&(identical(other.label, label) || other.label == label)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}


@override
int get hashCode => Object.hash(runtimeType,label,latitude,longitude,addressText);

@override
String toString() {
  return 'BookingAddress(label: $label, latitude: $latitude, longitude: $longitude, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class _$BookingAddressCopyWith<$Res> implements $BookingAddressCopyWith<$Res> {
  factory _$BookingAddressCopyWith(_BookingAddress value, $Res Function(_BookingAddress) _then) = __$BookingAddressCopyWithImpl;
@override @useResult
$Res call({
 String label, double latitude, double longitude, String addressText
});




}
/// @nodoc
class __$BookingAddressCopyWithImpl<$Res>
    implements _$BookingAddressCopyWith<$Res> {
  __$BookingAddressCopyWithImpl(this._self, this._then);

  final _BookingAddress _self;
  final $Res Function(_BookingAddress) _then;

/// Create a copy of BookingAddress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? latitude = null,Object? longitude = null,Object? addressText = null,}) {
  return _then(_BookingAddress(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

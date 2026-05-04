// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_booking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerBooking {

 int get id; BookingStatus get status; BookingService get service; BookingTechnician get technician; String? get addressLabel; DateTime get scheduledStart; DateTime get scheduledEnd; DateTime get createdAt; BookingPrice get price; BookingUi get ui;
/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerBookingCopyWith<CustomerBooking> get copyWith => _$CustomerBookingCopyWithImpl<CustomerBooking>(this as CustomerBooking, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.price, price) || other.price == price)&&(identical(other.ui, ui) || other.ui == ui));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,service,technician,addressLabel,scheduledStart,scheduledEnd,createdAt,price,ui);

@override
String toString() {
  return 'CustomerBooking(id: $id, status: $status, service: $service, technician: $technician, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, price: $price, ui: $ui)';
}


}

/// @nodoc
abstract mixin class $CustomerBookingCopyWith<$Res>  {
  factory $CustomerBookingCopyWith(CustomerBooking value, $Res Function(CustomerBooking) _then) = _$CustomerBookingCopyWithImpl;
@useResult
$Res call({
 int id, BookingStatus status, BookingService service, BookingTechnician technician, String? addressLabel, DateTime scheduledStart, DateTime scheduledEnd, DateTime createdAt, BookingPrice price, BookingUi ui
});


$BookingServiceCopyWith<$Res> get service;$BookingTechnicianCopyWith<$Res> get technician;$BookingPriceCopyWith<$Res> get price;$BookingUiCopyWith<$Res> get ui;

}
/// @nodoc
class _$CustomerBookingCopyWithImpl<$Res>
    implements $CustomerBookingCopyWith<$Res> {
  _$CustomerBookingCopyWithImpl(this._self, this._then);

  final CustomerBooking _self;
  final $Res Function(CustomerBooking) _then;

/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? technician = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? price = null,Object? ui = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingService,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnician,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as BookingPrice,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUi,
  ));
}
/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<$Res> get service {
  
  return $BookingServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianCopyWith<$Res> get technician {
  
  return $BookingTechnicianCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPriceCopyWith<$Res> get price {
  
  return $BookingPriceCopyWith<$Res>(_self.price, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiCopyWith<$Res> get ui {
  
  return $BookingUiCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerBooking].
extension CustomerBookingPatterns on CustomerBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerBooking value)  $default,){
final _that = this;
switch (_that) {
case _CustomerBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerBooking value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  BookingService service,  BookingTechnician technician,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  BookingPrice price,  BookingUi ui)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerBooking() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.technician,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.price,_that.ui);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  BookingService service,  BookingTechnician technician,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  BookingPrice price,  BookingUi ui)  $default,) {final _that = this;
switch (_that) {
case _CustomerBooking():
return $default(_that.id,_that.status,_that.service,_that.technician,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.price,_that.ui);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  BookingStatus status,  BookingService service,  BookingTechnician technician,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  BookingPrice price,  BookingUi ui)?  $default,) {final _that = this;
switch (_that) {
case _CustomerBooking() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.technician,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.price,_that.ui);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerBooking implements CustomerBooking {
  const _CustomerBooking({required this.id, required this.status, required this.service, required this.technician, required this.addressLabel, required this.scheduledStart, required this.scheduledEnd, required this.createdAt, required this.price, required this.ui});
  

@override final  int id;
@override final  BookingStatus status;
@override final  BookingService service;
@override final  BookingTechnician technician;
@override final  String? addressLabel;
@override final  DateTime scheduledStart;
@override final  DateTime scheduledEnd;
@override final  DateTime createdAt;
@override final  BookingPrice price;
@override final  BookingUi ui;

/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerBookingCopyWith<_CustomerBooking> get copyWith => __$CustomerBookingCopyWithImpl<_CustomerBooking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.price, price) || other.price == price)&&(identical(other.ui, ui) || other.ui == ui));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,service,technician,addressLabel,scheduledStart,scheduledEnd,createdAt,price,ui);

@override
String toString() {
  return 'CustomerBooking(id: $id, status: $status, service: $service, technician: $technician, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, price: $price, ui: $ui)';
}


}

/// @nodoc
abstract mixin class _$CustomerBookingCopyWith<$Res> implements $CustomerBookingCopyWith<$Res> {
  factory _$CustomerBookingCopyWith(_CustomerBooking value, $Res Function(_CustomerBooking) _then) = __$CustomerBookingCopyWithImpl;
@override @useResult
$Res call({
 int id, BookingStatus status, BookingService service, BookingTechnician technician, String? addressLabel, DateTime scheduledStart, DateTime scheduledEnd, DateTime createdAt, BookingPrice price, BookingUi ui
});


@override $BookingServiceCopyWith<$Res> get service;@override $BookingTechnicianCopyWith<$Res> get technician;@override $BookingPriceCopyWith<$Res> get price;@override $BookingUiCopyWith<$Res> get ui;

}
/// @nodoc
class __$CustomerBookingCopyWithImpl<$Res>
    implements _$CustomerBookingCopyWith<$Res> {
  __$CustomerBookingCopyWithImpl(this._self, this._then);

  final _CustomerBooking _self;
  final $Res Function(_CustomerBooking) _then;

/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? technician = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? price = null,Object? ui = null,}) {
  return _then(_CustomerBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingService,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnician,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as BookingPrice,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUi,
  ));
}

/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<$Res> get service {
  
  return $BookingServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianCopyWith<$Res> get technician {
  
  return $BookingTechnicianCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPriceCopyWith<$Res> get price {
  
  return $BookingPriceCopyWith<$Res>(_self.price, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of CustomerBooking
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiCopyWith<$Res> get ui {
  
  return $BookingUiCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}

/// @nodoc
mixin _$BookingService {

 String get name; String get iconName;
/// Create a copy of BookingService
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingServiceCopyWith<BookingService> get copyWith => _$BookingServiceCopyWithImpl<BookingService>(this as BookingService, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingService&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'BookingService(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $BookingServiceCopyWith<$Res>  {
  factory $BookingServiceCopyWith(BookingService value, $Res Function(BookingService) _then) = _$BookingServiceCopyWithImpl;
@useResult
$Res call({
 String name, String iconName
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
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingService() when $default != null:
return $default(_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String iconName)  $default,) {final _that = this;
switch (_that) {
case _BookingService():
return $default(_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _BookingService() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _BookingService implements BookingService {
  const _BookingService({required this.name, required this.iconName});
  

@override final  String name;
@override final  String iconName;

/// Create a copy of BookingService
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingServiceCopyWith<_BookingService> get copyWith => __$BookingServiceCopyWithImpl<_BookingService>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingService&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'BookingService(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$BookingServiceCopyWith<$Res> implements $BookingServiceCopyWith<$Res> {
  factory _$BookingServiceCopyWith(_BookingService value, $Res Function(_BookingService) _then) = __$BookingServiceCopyWithImpl;
@override @useResult
$Res call({
 String name, String iconName
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
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_BookingService(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
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
  const _BookingTechnician({required this.id, required this.displayName, required this.profilePictureUrl});
  

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
mixin _$BookingPrice {

 int get amount; String get context; String get uiLabel;
/// Create a copy of BookingPrice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingPriceCopyWith<BookingPrice> get copyWith => _$BookingPriceCopyWithImpl<BookingPrice>(this as BookingPrice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingPrice&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}


@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'BookingPrice(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class $BookingPriceCopyWith<$Res>  {
  factory $BookingPriceCopyWith(BookingPrice value, $Res Function(BookingPrice) _then) = _$BookingPriceCopyWithImpl;
@useResult
$Res call({
 int amount, String context, String uiLabel
});




}
/// @nodoc
class _$BookingPriceCopyWithImpl<$Res>
    implements $BookingPriceCopyWith<$Res> {
  _$BookingPriceCopyWithImpl(this._self, this._then);

  final BookingPrice _self;
  final $Res Function(BookingPrice) _then;

/// Create a copy of BookingPrice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = null,Object? context = null,Object? uiLabel = null,}) {
  return _then(_self.copyWith(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,uiLabel: null == uiLabel ? _self.uiLabel : uiLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingPrice].
extension BookingPricePatterns on BookingPrice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingPrice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingPrice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingPrice value)  $default,){
final _that = this;
switch (_that) {
case _BookingPrice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingPrice value)?  $default,){
final _that = this;
switch (_that) {
case _BookingPrice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amount,  String context,  String uiLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingPrice() when $default != null:
return $default(_that.amount,_that.context,_that.uiLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amount,  String context,  String uiLabel)  $default,) {final _that = this;
switch (_that) {
case _BookingPrice():
return $default(_that.amount,_that.context,_that.uiLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amount,  String context,  String uiLabel)?  $default,) {final _that = this;
switch (_that) {
case _BookingPrice() when $default != null:
return $default(_that.amount,_that.context,_that.uiLabel);case _:
  return null;

}
}

}

/// @nodoc


class _BookingPrice implements BookingPrice {
  const _BookingPrice({required this.amount, required this.context, required this.uiLabel});
  

@override final  int amount;
@override final  String context;
@override final  String uiLabel;

/// Create a copy of BookingPrice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingPriceCopyWith<_BookingPrice> get copyWith => __$BookingPriceCopyWithImpl<_BookingPrice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingPrice&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}


@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'BookingPrice(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class _$BookingPriceCopyWith<$Res> implements $BookingPriceCopyWith<$Res> {
  factory _$BookingPriceCopyWith(_BookingPrice value, $Res Function(_BookingPrice) _then) = __$BookingPriceCopyWithImpl;
@override @useResult
$Res call({
 int amount, String context, String uiLabel
});




}
/// @nodoc
class __$BookingPriceCopyWithImpl<$Res>
    implements _$BookingPriceCopyWith<$Res> {
  __$BookingPriceCopyWithImpl(this._self, this._then);

  final _BookingPrice _self;
  final $Res Function(_BookingPrice) _then;

/// Create a copy of BookingPrice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? context = null,Object? uiLabel = null,}) {
  return _then(_BookingPrice(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,uiLabel: null == uiLabel ? _self.uiLabel : uiLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$BookingUi {

 String get badgeText; BookingUiTone get badgeTone; String get headline;
/// Create a copy of BookingUi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiCopyWith<BookingUi> get copyWith => _$BookingUiCopyWithImpl<BookingUi>(this as BookingUi, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUi&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}


@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'BookingUi(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $BookingUiCopyWith<$Res>  {
  factory $BookingUiCopyWith(BookingUi value, $Res Function(BookingUi) _then) = _$BookingUiCopyWithImpl;
@useResult
$Res call({
 String badgeText, BookingUiTone badgeTone, String headline
});




}
/// @nodoc
class _$BookingUiCopyWithImpl<$Res>
    implements $BookingUiCopyWith<$Res> {
  _$BookingUiCopyWithImpl(this._self, this._then);

  final BookingUi _self;
  final $Res Function(BookingUi) _then;

/// Create a copy of BookingUi
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_self.copyWith(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as BookingUiTone,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingUi].
extension BookingUiPatterns on BookingUi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUi value)  $default,){
final _that = this;
switch (_that) {
case _BookingUi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUi value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUi() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String badgeText,  BookingUiTone badgeTone,  String headline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingUi() when $default != null:
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String badgeText,  BookingUiTone badgeTone,  String headline)  $default,) {final _that = this;
switch (_that) {
case _BookingUi():
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String badgeText,  BookingUiTone badgeTone,  String headline)?  $default,) {final _that = this;
switch (_that) {
case _BookingUi() when $default != null:
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
  return null;

}
}

}

/// @nodoc


class _BookingUi implements BookingUi {
  const _BookingUi({required this.badgeText, required this.badgeTone, required this.headline});
  

@override final  String badgeText;
@override final  BookingUiTone badgeTone;
@override final  String headline;

/// Create a copy of BookingUi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiCopyWith<_BookingUi> get copyWith => __$BookingUiCopyWithImpl<_BookingUi>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUi&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}


@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'BookingUi(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$BookingUiCopyWith<$Res> implements $BookingUiCopyWith<$Res> {
  factory _$BookingUiCopyWith(_BookingUi value, $Res Function(_BookingUi) _then) = __$BookingUiCopyWithImpl;
@override @useResult
$Res call({
 String badgeText, BookingUiTone badgeTone, String headline
});




}
/// @nodoc
class __$BookingUiCopyWithImpl<$Res>
    implements _$BookingUiCopyWith<$Res> {
  __$BookingUiCopyWithImpl(this._self, this._then);

  final _BookingUi _self;
  final $Res Function(_BookingUi) _then;

/// Create a copy of BookingUi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_BookingUi(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as BookingUiTone,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

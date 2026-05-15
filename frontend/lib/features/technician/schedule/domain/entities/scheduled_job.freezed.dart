// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduledJob {

 int get id; BookingStatus get status; ScheduledJobService get service; ScheduledJobCustomer get customer; String? get addressLabel; DateTime get scheduledStart; DateTime get scheduledEnd; DateTime get createdAt; PayoutBlock get payout; ScheduledJobUi get ui;
/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobCopyWith<ScheduledJob> get copyWith => _$ScheduledJobCopyWithImpl<ScheduledJob>(this as ScheduledJob, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.ui, ui) || other.ui == ui));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,service,customer,addressLabel,scheduledStart,scheduledEnd,createdAt,payout,ui);

@override
String toString() {
  return 'ScheduledJob(id: $id, status: $status, service: $service, customer: $customer, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, payout: $payout, ui: $ui)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobCopyWith<$Res>  {
  factory $ScheduledJobCopyWith(ScheduledJob value, $Res Function(ScheduledJob) _then) = _$ScheduledJobCopyWithImpl;
@useResult
$Res call({
 int id, BookingStatus status, ScheduledJobService service, ScheduledJobCustomer customer, String? addressLabel, DateTime scheduledStart, DateTime scheduledEnd, DateTime createdAt, PayoutBlock payout, ScheduledJobUi ui
});


$ScheduledJobServiceCopyWith<$Res> get service;$ScheduledJobCustomerCopyWith<$Res> get customer;$PayoutBlockCopyWith<$Res> get payout;$ScheduledJobUiCopyWith<$Res> get ui;

}
/// @nodoc
class _$ScheduledJobCopyWithImpl<$Res>
    implements $ScheduledJobCopyWith<$Res> {
  _$ScheduledJobCopyWithImpl(this._self, this._then);

  final ScheduledJob _self;
  final $Res Function(ScheduledJob) _then;

/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? customer = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? payout = null,Object? ui = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ScheduledJobService,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ScheduledJobCustomer,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as PayoutBlock,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as ScheduledJobUi,
  ));
}
/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobServiceCopyWith<$Res> get service {
  
  return $ScheduledJobServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobCustomerCopyWith<$Res> get customer {
  
  return $ScheduledJobCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutBlockCopyWith<$Res> get payout {
  
  return $PayoutBlockCopyWith<$Res>(_self.payout, (value) {
    return _then(_self.copyWith(payout: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobUiCopyWith<$Res> get ui {
  
  return $ScheduledJobUiCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScheduledJob].
extension ScheduledJobPatterns on ScheduledJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJob value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJob value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  ScheduledJobService service,  ScheduledJobCustomer customer,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  PayoutBlock payout,  ScheduledJobUi ui)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJob() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.customer,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.payout,_that.ui);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  BookingStatus status,  ScheduledJobService service,  ScheduledJobCustomer customer,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  PayoutBlock payout,  ScheduledJobUi ui)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJob():
return $default(_that.id,_that.status,_that.service,_that.customer,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.payout,_that.ui);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  BookingStatus status,  ScheduledJobService service,  ScheduledJobCustomer customer,  String? addressLabel,  DateTime scheduledStart,  DateTime scheduledEnd,  DateTime createdAt,  PayoutBlock payout,  ScheduledJobUi ui)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJob() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.customer,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.payout,_that.ui);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJob implements ScheduledJob {
  const _ScheduledJob({required this.id, required this.status, required this.service, required this.customer, required this.addressLabel, required this.scheduledStart, required this.scheduledEnd, required this.createdAt, required this.payout, required this.ui});
  

@override final  int id;
@override final  BookingStatus status;
@override final  ScheduledJobService service;
@override final  ScheduledJobCustomer customer;
@override final  String? addressLabel;
@override final  DateTime scheduledStart;
@override final  DateTime scheduledEnd;
@override final  DateTime createdAt;
@override final  PayoutBlock payout;
@override final  ScheduledJobUi ui;

/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobCopyWith<_ScheduledJob> get copyWith => __$ScheduledJobCopyWithImpl<_ScheduledJob>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.ui, ui) || other.ui == ui));
}


@override
int get hashCode => Object.hash(runtimeType,id,status,service,customer,addressLabel,scheduledStart,scheduledEnd,createdAt,payout,ui);

@override
String toString() {
  return 'ScheduledJob(id: $id, status: $status, service: $service, customer: $customer, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, payout: $payout, ui: $ui)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobCopyWith<$Res> implements $ScheduledJobCopyWith<$Res> {
  factory _$ScheduledJobCopyWith(_ScheduledJob value, $Res Function(_ScheduledJob) _then) = __$ScheduledJobCopyWithImpl;
@override @useResult
$Res call({
 int id, BookingStatus status, ScheduledJobService service, ScheduledJobCustomer customer, String? addressLabel, DateTime scheduledStart, DateTime scheduledEnd, DateTime createdAt, PayoutBlock payout, ScheduledJobUi ui
});


@override $ScheduledJobServiceCopyWith<$Res> get service;@override $ScheduledJobCustomerCopyWith<$Res> get customer;@override $PayoutBlockCopyWith<$Res> get payout;@override $ScheduledJobUiCopyWith<$Res> get ui;

}
/// @nodoc
class __$ScheduledJobCopyWithImpl<$Res>
    implements _$ScheduledJobCopyWith<$Res> {
  __$ScheduledJobCopyWithImpl(this._self, this._then);

  final _ScheduledJob _self;
  final $Res Function(_ScheduledJob) _then;

/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? customer = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? payout = null,Object? ui = null,}) {
  return _then(_ScheduledJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingStatus,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ScheduledJobService,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ScheduledJobCustomer,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as PayoutBlock,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as ScheduledJobUi,
  ));
}

/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobServiceCopyWith<$Res> get service {
  
  return $ScheduledJobServiceCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobCustomerCopyWith<$Res> get customer {
  
  return $ScheduledJobCustomerCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutBlockCopyWith<$Res> get payout {
  
  return $PayoutBlockCopyWith<$Res>(_self.payout, (value) {
    return _then(_self.copyWith(payout: value));
  });
}/// Create a copy of ScheduledJob
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobUiCopyWith<$Res> get ui {
  
  return $ScheduledJobUiCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}

/// @nodoc
mixin _$ScheduledJobService {

 String get name; String get iconName;
/// Create a copy of ScheduledJobService
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobServiceCopyWith<ScheduledJobService> get copyWith => _$ScheduledJobServiceCopyWithImpl<ScheduledJobService>(this as ScheduledJobService, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobService&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'ScheduledJobService(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobServiceCopyWith<$Res>  {
  factory $ScheduledJobServiceCopyWith(ScheduledJobService value, $Res Function(ScheduledJobService) _then) = _$ScheduledJobServiceCopyWithImpl;
@useResult
$Res call({
 String name, String iconName
});




}
/// @nodoc
class _$ScheduledJobServiceCopyWithImpl<$Res>
    implements $ScheduledJobServiceCopyWith<$Res> {
  _$ScheduledJobServiceCopyWithImpl(this._self, this._then);

  final ScheduledJobService _self;
  final $Res Function(ScheduledJobService) _then;

/// Create a copy of ScheduledJobService
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledJobService].
extension ScheduledJobServicePatterns on ScheduledJobService {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobService value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobService() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobService value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobService():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobService value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobService() when $default != null:
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
case _ScheduledJobService() when $default != null:
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
case _ScheduledJobService():
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
case _ScheduledJobService() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJobService implements ScheduledJobService {
  const _ScheduledJobService({required this.name, required this.iconName});
  

@override final  String name;
@override final  String iconName;

/// Create a copy of ScheduledJobService
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobServiceCopyWith<_ScheduledJobService> get copyWith => __$ScheduledJobServiceCopyWithImpl<_ScheduledJobService>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobService&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'ScheduledJobService(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobServiceCopyWith<$Res> implements $ScheduledJobServiceCopyWith<$Res> {
  factory _$ScheduledJobServiceCopyWith(_ScheduledJobService value, $Res Function(_ScheduledJobService) _then) = __$ScheduledJobServiceCopyWithImpl;
@override @useResult
$Res call({
 String name, String iconName
});




}
/// @nodoc
class __$ScheduledJobServiceCopyWithImpl<$Res>
    implements _$ScheduledJobServiceCopyWith<$Res> {
  __$ScheduledJobServiceCopyWithImpl(this._self, this._then);

  final _ScheduledJobService _self;
  final $Res Function(_ScheduledJobService) _then;

/// Create a copy of ScheduledJobService
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_ScheduledJobService(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ScheduledJobCustomer {

 int get id; String get displayName; String? get profilePictureUrl;
/// Create a copy of ScheduledJobCustomer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobCustomerCopyWith<ScheduledJobCustomer> get copyWith => _$ScheduledJobCustomerCopyWithImpl<ScheduledJobCustomer>(this as ScheduledJobCustomer, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'ScheduledJobCustomer(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobCustomerCopyWith<$Res>  {
  factory $ScheduledJobCustomerCopyWith(ScheduledJobCustomer value, $Res Function(ScheduledJobCustomer) _then) = _$ScheduledJobCustomerCopyWithImpl;
@useResult
$Res call({
 int id, String displayName, String? profilePictureUrl
});




}
/// @nodoc
class _$ScheduledJobCustomerCopyWithImpl<$Res>
    implements $ScheduledJobCustomerCopyWith<$Res> {
  _$ScheduledJobCustomerCopyWithImpl(this._self, this._then);

  final ScheduledJobCustomer _self;
  final $Res Function(ScheduledJobCustomer) _then;

/// Create a copy of ScheduledJobCustomer
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


/// Adds pattern-matching-related methods to [ScheduledJobCustomer].
extension ScheduledJobCustomerPatterns on ScheduledJobCustomer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobCustomer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobCustomer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobCustomer value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobCustomer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobCustomer value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobCustomer() when $default != null:
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
case _ScheduledJobCustomer() when $default != null:
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
case _ScheduledJobCustomer():
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
case _ScheduledJobCustomer() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJobCustomer implements ScheduledJobCustomer {
  const _ScheduledJobCustomer({required this.id, required this.displayName, required this.profilePictureUrl});
  

@override final  int id;
@override final  String displayName;
@override final  String? profilePictureUrl;

/// Create a copy of ScheduledJobCustomer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobCustomerCopyWith<_ScheduledJobCustomer> get copyWith => __$ScheduledJobCustomerCopyWithImpl<_ScheduledJobCustomer>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'ScheduledJobCustomer(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobCustomerCopyWith<$Res> implements $ScheduledJobCustomerCopyWith<$Res> {
  factory _$ScheduledJobCustomerCopyWith(_ScheduledJobCustomer value, $Res Function(_ScheduledJobCustomer) _then) = __$ScheduledJobCustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String displayName, String? profilePictureUrl
});




}
/// @nodoc
class __$ScheduledJobCustomerCopyWithImpl<$Res>
    implements _$ScheduledJobCustomerCopyWith<$Res> {
  __$ScheduledJobCustomerCopyWithImpl(this._self, this._then);

  final _ScheduledJobCustomer _self;
  final $Res Function(_ScheduledJobCustomer) _then;

/// Create a copy of ScheduledJobCustomer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_ScheduledJobCustomer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PayoutBlock {

 int get amount; String get context; String get uiLabel;
/// Create a copy of PayoutBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutBlockCopyWith<PayoutBlock> get copyWith => _$PayoutBlockCopyWithImpl<PayoutBlock>(this as PayoutBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayoutBlock&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}


@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'PayoutBlock(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class $PayoutBlockCopyWith<$Res>  {
  factory $PayoutBlockCopyWith(PayoutBlock value, $Res Function(PayoutBlock) _then) = _$PayoutBlockCopyWithImpl;
@useResult
$Res call({
 int amount, String context, String uiLabel
});




}
/// @nodoc
class _$PayoutBlockCopyWithImpl<$Res>
    implements $PayoutBlockCopyWith<$Res> {
  _$PayoutBlockCopyWithImpl(this._self, this._then);

  final PayoutBlock _self;
  final $Res Function(PayoutBlock) _then;

/// Create a copy of PayoutBlock
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


/// Adds pattern-matching-related methods to [PayoutBlock].
extension PayoutBlockPatterns on PayoutBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayoutBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayoutBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayoutBlock value)  $default,){
final _that = this;
switch (_that) {
case _PayoutBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayoutBlock value)?  $default,){
final _that = this;
switch (_that) {
case _PayoutBlock() when $default != null:
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
case _PayoutBlock() when $default != null:
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
case _PayoutBlock():
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
case _PayoutBlock() when $default != null:
return $default(_that.amount,_that.context,_that.uiLabel);case _:
  return null;

}
}

}

/// @nodoc


class _PayoutBlock implements PayoutBlock {
  const _PayoutBlock({required this.amount, required this.context, required this.uiLabel});
  

@override final  int amount;
@override final  String context;
@override final  String uiLabel;

/// Create a copy of PayoutBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutBlockCopyWith<_PayoutBlock> get copyWith => __$PayoutBlockCopyWithImpl<_PayoutBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayoutBlock&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}


@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'PayoutBlock(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class _$PayoutBlockCopyWith<$Res> implements $PayoutBlockCopyWith<$Res> {
  factory _$PayoutBlockCopyWith(_PayoutBlock value, $Res Function(_PayoutBlock) _then) = __$PayoutBlockCopyWithImpl;
@override @useResult
$Res call({
 int amount, String context, String uiLabel
});




}
/// @nodoc
class __$PayoutBlockCopyWithImpl<$Res>
    implements _$PayoutBlockCopyWith<$Res> {
  __$PayoutBlockCopyWithImpl(this._self, this._then);

  final _PayoutBlock _self;
  final $Res Function(_PayoutBlock) _then;

/// Create a copy of PayoutBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? context = null,Object? uiLabel = null,}) {
  return _then(_PayoutBlock(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,uiLabel: null == uiLabel ? _self.uiLabel : uiLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ScheduledJobUi {

 String get badgeText; BookingUiTone get badgeTone; String get headline;
/// Create a copy of ScheduledJobUi
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobUiCopyWith<ScheduledJobUi> get copyWith => _$ScheduledJobUiCopyWithImpl<ScheduledJobUi>(this as ScheduledJobUi, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobUi&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}


@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'ScheduledJobUi(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobUiCopyWith<$Res>  {
  factory $ScheduledJobUiCopyWith(ScheduledJobUi value, $Res Function(ScheduledJobUi) _then) = _$ScheduledJobUiCopyWithImpl;
@useResult
$Res call({
 String badgeText, BookingUiTone badgeTone, String headline
});




}
/// @nodoc
class _$ScheduledJobUiCopyWithImpl<$Res>
    implements $ScheduledJobUiCopyWith<$Res> {
  _$ScheduledJobUiCopyWithImpl(this._self, this._then);

  final ScheduledJobUi _self;
  final $Res Function(ScheduledJobUi) _then;

/// Create a copy of ScheduledJobUi
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


/// Adds pattern-matching-related methods to [ScheduledJobUi].
extension ScheduledJobUiPatterns on ScheduledJobUi {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobUi value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobUi() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobUi value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobUi():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobUi value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobUi() when $default != null:
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
case _ScheduledJobUi() when $default != null:
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
case _ScheduledJobUi():
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
case _ScheduledJobUi() when $default != null:
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJobUi implements ScheduledJobUi {
  const _ScheduledJobUi({required this.badgeText, required this.badgeTone, required this.headline});
  

@override final  String badgeText;
@override final  BookingUiTone badgeTone;
@override final  String headline;

/// Create a copy of ScheduledJobUi
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobUiCopyWith<_ScheduledJobUi> get copyWith => __$ScheduledJobUiCopyWithImpl<_ScheduledJobUi>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobUi&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}


@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'ScheduledJobUi(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobUiCopyWith<$Res> implements $ScheduledJobUiCopyWith<$Res> {
  factory _$ScheduledJobUiCopyWith(_ScheduledJobUi value, $Res Function(_ScheduledJobUi) _then) = __$ScheduledJobUiCopyWithImpl;
@override @useResult
$Res call({
 String badgeText, BookingUiTone badgeTone, String headline
});




}
/// @nodoc
class __$ScheduledJobUiCopyWithImpl<$Res>
    implements _$ScheduledJobUiCopyWith<$Res> {
  __$ScheduledJobUiCopyWithImpl(this._self, this._then);

  final _ScheduledJobUi _self;
  final $Res Function(_ScheduledJobUi) _then;

/// Create a copy of ScheduledJobUi
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_ScheduledJobUi(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as BookingUiTone,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

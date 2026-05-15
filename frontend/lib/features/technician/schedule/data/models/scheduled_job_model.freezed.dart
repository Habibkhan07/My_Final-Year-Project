// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduledJobModel {

 int get id; String get status; ScheduledJobServiceModel get service; ScheduledJobCustomerModel get customer;@JsonKey(name: 'address_label') String? get addressLabel;@JsonKey(name: 'scheduled_start') String get scheduledStart;@JsonKey(name: 'scheduled_end') String get scheduledEnd;@JsonKey(name: 'created_at') String get createdAt; PayoutBlockModel get payout; ScheduledJobUiModel get ui;
/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobModelCopyWith<ScheduledJobModel> get copyWith => _$ScheduledJobModelCopyWithImpl<ScheduledJobModel>(this as ScheduledJobModel, _$identity);

  /// Serializes this ScheduledJobModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.ui, ui) || other.ui == ui));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,service,customer,addressLabel,scheduledStart,scheduledEnd,createdAt,payout,ui);

@override
String toString() {
  return 'ScheduledJobModel(id: $id, status: $status, service: $service, customer: $customer, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, payout: $payout, ui: $ui)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobModelCopyWith<$Res>  {
  factory $ScheduledJobModelCopyWith(ScheduledJobModel value, $Res Function(ScheduledJobModel) _then) = _$ScheduledJobModelCopyWithImpl;
@useResult
$Res call({
 int id, String status, ScheduledJobServiceModel service, ScheduledJobCustomerModel customer,@JsonKey(name: 'address_label') String? addressLabel,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'created_at') String createdAt, PayoutBlockModel payout, ScheduledJobUiModel ui
});


$ScheduledJobServiceModelCopyWith<$Res> get service;$ScheduledJobCustomerModelCopyWith<$Res> get customer;$PayoutBlockModelCopyWith<$Res> get payout;$ScheduledJobUiModelCopyWith<$Res> get ui;

}
/// @nodoc
class _$ScheduledJobModelCopyWithImpl<$Res>
    implements $ScheduledJobModelCopyWith<$Res> {
  _$ScheduledJobModelCopyWithImpl(this._self, this._then);

  final ScheduledJobModel _self;
  final $Res Function(ScheduledJobModel) _then;

/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? customer = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? payout = null,Object? ui = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ScheduledJobServiceModel,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ScheduledJobCustomerModel,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as PayoutBlockModel,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as ScheduledJobUiModel,
  ));
}
/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobServiceModelCopyWith<$Res> get service {
  
  return $ScheduledJobServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobCustomerModelCopyWith<$Res> get customer {
  
  return $ScheduledJobCustomerModelCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutBlockModelCopyWith<$Res> get payout {
  
  return $PayoutBlockModelCopyWith<$Res>(_self.payout, (value) {
    return _then(_self.copyWith(payout: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobUiModelCopyWith<$Res> get ui {
  
  return $ScheduledJobUiModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScheduledJobModel].
extension ScheduledJobModelPatterns on ScheduledJobModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobModel value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobModel value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String status,  ScheduledJobServiceModel service,  ScheduledJobCustomerModel customer, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  PayoutBlockModel payout,  ScheduledJobUiModel ui)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJobModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String status,  ScheduledJobServiceModel service,  ScheduledJobCustomerModel customer, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  PayoutBlockModel payout,  ScheduledJobUiModel ui)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String status,  ScheduledJobServiceModel service,  ScheduledJobCustomerModel customer, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  PayoutBlockModel payout,  ScheduledJobUiModel ui)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobModel() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.customer,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.payout,_that.ui);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledJobModel implements ScheduledJobModel {
  const _ScheduledJobModel({required this.id, required this.status, required this.service, required this.customer, @JsonKey(name: 'address_label') required this.addressLabel, @JsonKey(name: 'scheduled_start') required this.scheduledStart, @JsonKey(name: 'scheduled_end') required this.scheduledEnd, @JsonKey(name: 'created_at') required this.createdAt, required this.payout, required this.ui});
  factory _ScheduledJobModel.fromJson(Map<String, dynamic> json) => _$ScheduledJobModelFromJson(json);

@override final  int id;
@override final  String status;
@override final  ScheduledJobServiceModel service;
@override final  ScheduledJobCustomerModel customer;
@override@JsonKey(name: 'address_label') final  String? addressLabel;
@override@JsonKey(name: 'scheduled_start') final  String scheduledStart;
@override@JsonKey(name: 'scheduled_end') final  String scheduledEnd;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override final  PayoutBlockModel payout;
@override final  ScheduledJobUiModel ui;

/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobModelCopyWith<_ScheduledJobModel> get copyWith => __$ScheduledJobModelCopyWithImpl<_ScheduledJobModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledJobModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.ui, ui) || other.ui == ui));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,service,customer,addressLabel,scheduledStart,scheduledEnd,createdAt,payout,ui);

@override
String toString() {
  return 'ScheduledJobModel(id: $id, status: $status, service: $service, customer: $customer, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, payout: $payout, ui: $ui)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobModelCopyWith<$Res> implements $ScheduledJobModelCopyWith<$Res> {
  factory _$ScheduledJobModelCopyWith(_ScheduledJobModel value, $Res Function(_ScheduledJobModel) _then) = __$ScheduledJobModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String status, ScheduledJobServiceModel service, ScheduledJobCustomerModel customer,@JsonKey(name: 'address_label') String? addressLabel,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'created_at') String createdAt, PayoutBlockModel payout, ScheduledJobUiModel ui
});


@override $ScheduledJobServiceModelCopyWith<$Res> get service;@override $ScheduledJobCustomerModelCopyWith<$Res> get customer;@override $PayoutBlockModelCopyWith<$Res> get payout;@override $ScheduledJobUiModelCopyWith<$Res> get ui;

}
/// @nodoc
class __$ScheduledJobModelCopyWithImpl<$Res>
    implements _$ScheduledJobModelCopyWith<$Res> {
  __$ScheduledJobModelCopyWithImpl(this._self, this._then);

  final _ScheduledJobModel _self;
  final $Res Function(_ScheduledJobModel) _then;

/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? customer = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? payout = null,Object? ui = null,}) {
  return _then(_ScheduledJobModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ScheduledJobServiceModel,customer: null == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ScheduledJobCustomerModel,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as PayoutBlockModel,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as ScheduledJobUiModel,
  ));
}

/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobServiceModelCopyWith<$Res> get service {
  
  return $ScheduledJobServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobCustomerModelCopyWith<$Res> get customer {
  
  return $ScheduledJobCustomerModelCopyWith<$Res>(_self.customer, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PayoutBlockModelCopyWith<$Res> get payout {
  
  return $PayoutBlockModelCopyWith<$Res>(_self.payout, (value) {
    return _then(_self.copyWith(payout: value));
  });
}/// Create a copy of ScheduledJobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScheduledJobUiModelCopyWith<$Res> get ui {
  
  return $ScheduledJobUiModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// @nodoc
mixin _$ScheduledJobServiceModel {

 String get name;@JsonKey(name: 'icon_name') String get iconName;
/// Create a copy of ScheduledJobServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobServiceModelCopyWith<ScheduledJobServiceModel> get copyWith => _$ScheduledJobServiceModelCopyWithImpl<ScheduledJobServiceModel>(this as ScheduledJobServiceModel, _$identity);

  /// Serializes this ScheduledJobServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobServiceModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'ScheduledJobServiceModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobServiceModelCopyWith<$Res>  {
  factory $ScheduledJobServiceModelCopyWith(ScheduledJobServiceModel value, $Res Function(ScheduledJobServiceModel) _then) = _$ScheduledJobServiceModelCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class _$ScheduledJobServiceModelCopyWithImpl<$Res>
    implements $ScheduledJobServiceModelCopyWith<$Res> {
  _$ScheduledJobServiceModelCopyWithImpl(this._self, this._then);

  final ScheduledJobServiceModel _self;
  final $Res Function(ScheduledJobServiceModel) _then;

/// Create a copy of ScheduledJobServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledJobServiceModel].
extension ScheduledJobServiceModelPatterns on ScheduledJobServiceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobServiceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobServiceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobServiceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'icon_name')  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJobServiceModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'icon_name')  String iconName)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobServiceModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'icon_name')  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobServiceModel() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledJobServiceModel implements ScheduledJobServiceModel {
  const _ScheduledJobServiceModel({required this.name, @JsonKey(name: 'icon_name') required this.iconName});
  factory _ScheduledJobServiceModel.fromJson(Map<String, dynamic> json) => _$ScheduledJobServiceModelFromJson(json);

@override final  String name;
@override@JsonKey(name: 'icon_name') final  String iconName;

/// Create a copy of ScheduledJobServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobServiceModelCopyWith<_ScheduledJobServiceModel> get copyWith => __$ScheduledJobServiceModelCopyWithImpl<_ScheduledJobServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledJobServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobServiceModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'ScheduledJobServiceModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobServiceModelCopyWith<$Res> implements $ScheduledJobServiceModelCopyWith<$Res> {
  factory _$ScheduledJobServiceModelCopyWith(_ScheduledJobServiceModel value, $Res Function(_ScheduledJobServiceModel) _then) = __$ScheduledJobServiceModelCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class __$ScheduledJobServiceModelCopyWithImpl<$Res>
    implements _$ScheduledJobServiceModelCopyWith<$Res> {
  __$ScheduledJobServiceModelCopyWithImpl(this._self, this._then);

  final _ScheduledJobServiceModel _self;
  final $Res Function(_ScheduledJobServiceModel) _then;

/// Create a copy of ScheduledJobServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_ScheduledJobServiceModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ScheduledJobCustomerModel {

 int get id;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'profile_picture_url') String? get profilePictureUrl;
/// Create a copy of ScheduledJobCustomerModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobCustomerModelCopyWith<ScheduledJobCustomerModel> get copyWith => _$ScheduledJobCustomerModelCopyWithImpl<ScheduledJobCustomerModel>(this as ScheduledJobCustomerModel, _$identity);

  /// Serializes this ScheduledJobCustomerModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobCustomerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'ScheduledJobCustomerModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobCustomerModelCopyWith<$Res>  {
  factory $ScheduledJobCustomerModelCopyWith(ScheduledJobCustomerModel value, $Res Function(ScheduledJobCustomerModel) _then) = _$ScheduledJobCustomerModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class _$ScheduledJobCustomerModelCopyWithImpl<$Res>
    implements $ScheduledJobCustomerModelCopyWith<$Res> {
  _$ScheduledJobCustomerModelCopyWithImpl(this._self, this._then);

  final ScheduledJobCustomerModel _self;
  final $Res Function(ScheduledJobCustomerModel) _then;

/// Create a copy of ScheduledJobCustomerModel
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


/// Adds pattern-matching-related methods to [ScheduledJobCustomerModel].
extension ScheduledJobCustomerModelPatterns on ScheduledJobCustomerModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobCustomerModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobCustomerModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobCustomerModel value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobCustomerModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobCustomerModel value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobCustomerModel() when $default != null:
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
case _ScheduledJobCustomerModel() when $default != null:
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
case _ScheduledJobCustomerModel():
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
case _ScheduledJobCustomerModel() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledJobCustomerModel implements ScheduledJobCustomerModel {
  const _ScheduledJobCustomerModel({required this.id, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'profile_picture_url') required this.profilePictureUrl});
  factory _ScheduledJobCustomerModel.fromJson(Map<String, dynamic> json) => _$ScheduledJobCustomerModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'profile_picture_url') final  String? profilePictureUrl;

/// Create a copy of ScheduledJobCustomerModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobCustomerModelCopyWith<_ScheduledJobCustomerModel> get copyWith => __$ScheduledJobCustomerModelCopyWithImpl<_ScheduledJobCustomerModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledJobCustomerModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobCustomerModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'ScheduledJobCustomerModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobCustomerModelCopyWith<$Res> implements $ScheduledJobCustomerModelCopyWith<$Res> {
  factory _$ScheduledJobCustomerModelCopyWith(_ScheduledJobCustomerModel value, $Res Function(_ScheduledJobCustomerModel) _then) = __$ScheduledJobCustomerModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class __$ScheduledJobCustomerModelCopyWithImpl<$Res>
    implements _$ScheduledJobCustomerModelCopyWith<$Res> {
  __$ScheduledJobCustomerModelCopyWithImpl(this._self, this._then);

  final _ScheduledJobCustomerModel _self;
  final $Res Function(_ScheduledJobCustomerModel) _then;

/// Create a copy of ScheduledJobCustomerModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_ScheduledJobCustomerModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PayoutBlockModel {

 int get amount; String get context;@JsonKey(name: 'ui_label') String get uiLabel;
/// Create a copy of PayoutBlockModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PayoutBlockModelCopyWith<PayoutBlockModel> get copyWith => _$PayoutBlockModelCopyWithImpl<PayoutBlockModel>(this as PayoutBlockModel, _$identity);

  /// Serializes this PayoutBlockModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PayoutBlockModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'PayoutBlockModel(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class $PayoutBlockModelCopyWith<$Res>  {
  factory $PayoutBlockModelCopyWith(PayoutBlockModel value, $Res Function(PayoutBlockModel) _then) = _$PayoutBlockModelCopyWithImpl;
@useResult
$Res call({
 int amount, String context,@JsonKey(name: 'ui_label') String uiLabel
});




}
/// @nodoc
class _$PayoutBlockModelCopyWithImpl<$Res>
    implements $PayoutBlockModelCopyWith<$Res> {
  _$PayoutBlockModelCopyWithImpl(this._self, this._then);

  final PayoutBlockModel _self;
  final $Res Function(PayoutBlockModel) _then;

/// Create a copy of PayoutBlockModel
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


/// Adds pattern-matching-related methods to [PayoutBlockModel].
extension PayoutBlockModelPatterns on PayoutBlockModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PayoutBlockModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PayoutBlockModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PayoutBlockModel value)  $default,){
final _that = this;
switch (_that) {
case _PayoutBlockModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PayoutBlockModel value)?  $default,){
final _that = this;
switch (_that) {
case _PayoutBlockModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int amount,  String context, @JsonKey(name: 'ui_label')  String uiLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PayoutBlockModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int amount,  String context, @JsonKey(name: 'ui_label')  String uiLabel)  $default,) {final _that = this;
switch (_that) {
case _PayoutBlockModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int amount,  String context, @JsonKey(name: 'ui_label')  String uiLabel)?  $default,) {final _that = this;
switch (_that) {
case _PayoutBlockModel() when $default != null:
return $default(_that.amount,_that.context,_that.uiLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PayoutBlockModel implements PayoutBlockModel {
  const _PayoutBlockModel({required this.amount, required this.context, @JsonKey(name: 'ui_label') required this.uiLabel});
  factory _PayoutBlockModel.fromJson(Map<String, dynamic> json) => _$PayoutBlockModelFromJson(json);

@override final  int amount;
@override final  String context;
@override@JsonKey(name: 'ui_label') final  String uiLabel;

/// Create a copy of PayoutBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PayoutBlockModelCopyWith<_PayoutBlockModel> get copyWith => __$PayoutBlockModelCopyWithImpl<_PayoutBlockModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PayoutBlockModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PayoutBlockModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'PayoutBlockModel(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class _$PayoutBlockModelCopyWith<$Res> implements $PayoutBlockModelCopyWith<$Res> {
  factory _$PayoutBlockModelCopyWith(_PayoutBlockModel value, $Res Function(_PayoutBlockModel) _then) = __$PayoutBlockModelCopyWithImpl;
@override @useResult
$Res call({
 int amount, String context,@JsonKey(name: 'ui_label') String uiLabel
});




}
/// @nodoc
class __$PayoutBlockModelCopyWithImpl<$Res>
    implements _$PayoutBlockModelCopyWith<$Res> {
  __$PayoutBlockModelCopyWithImpl(this._self, this._then);

  final _PayoutBlockModel _self;
  final $Res Function(_PayoutBlockModel) _then;

/// Create a copy of PayoutBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? context = null,Object? uiLabel = null,}) {
  return _then(_PayoutBlockModel(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,uiLabel: null == uiLabel ? _self.uiLabel : uiLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ScheduledJobUiModel {

@JsonKey(name: 'badge_text') String get badgeText;@JsonKey(name: 'badge_tone') String get badgeTone; String get headline;
/// Create a copy of ScheduledJobUiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobUiModelCopyWith<ScheduledJobUiModel> get copyWith => _$ScheduledJobUiModelCopyWithImpl<ScheduledJobUiModel>(this as ScheduledJobUiModel, _$identity);

  /// Serializes this ScheduledJobUiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobUiModel&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'ScheduledJobUiModel(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobUiModelCopyWith<$Res>  {
  factory $ScheduledJobUiModelCopyWith(ScheduledJobUiModel value, $Res Function(ScheduledJobUiModel) _then) = _$ScheduledJobUiModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'badge_text') String badgeText,@JsonKey(name: 'badge_tone') String badgeTone, String headline
});




}
/// @nodoc
class _$ScheduledJobUiModelCopyWithImpl<$Res>
    implements $ScheduledJobUiModelCopyWith<$Res> {
  _$ScheduledJobUiModelCopyWithImpl(this._self, this._then);

  final ScheduledJobUiModel _self;
  final $Res Function(ScheduledJobUiModel) _then;

/// Create a copy of ScheduledJobUiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_self.copyWith(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as String,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledJobUiModel].
extension ScheduledJobUiModelPatterns on ScheduledJobUiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobUiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobUiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobUiModel value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobUiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobUiModel value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobUiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'badge_text')  String badgeText, @JsonKey(name: 'badge_tone')  String badgeTone,  String headline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJobUiModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'badge_text')  String badgeText, @JsonKey(name: 'badge_tone')  String badgeTone,  String headline)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobUiModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'badge_text')  String badgeText, @JsonKey(name: 'badge_tone')  String badgeTone,  String headline)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobUiModel() when $default != null:
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduledJobUiModel implements ScheduledJobUiModel {
  const _ScheduledJobUiModel({@JsonKey(name: 'badge_text') required this.badgeText, @JsonKey(name: 'badge_tone') required this.badgeTone, required this.headline});
  factory _ScheduledJobUiModel.fromJson(Map<String, dynamic> json) => _$ScheduledJobUiModelFromJson(json);

@override@JsonKey(name: 'badge_text') final  String badgeText;
@override@JsonKey(name: 'badge_tone') final  String badgeTone;
@override final  String headline;

/// Create a copy of ScheduledJobUiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobUiModelCopyWith<_ScheduledJobUiModel> get copyWith => __$ScheduledJobUiModelCopyWithImpl<_ScheduledJobUiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduledJobUiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobUiModel&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'ScheduledJobUiModel(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobUiModelCopyWith<$Res> implements $ScheduledJobUiModelCopyWith<$Res> {
  factory _$ScheduledJobUiModelCopyWith(_ScheduledJobUiModel value, $Res Function(_ScheduledJobUiModel) _then) = __$ScheduledJobUiModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'badge_text') String badgeText,@JsonKey(name: 'badge_tone') String badgeTone, String headline
});




}
/// @nodoc
class __$ScheduledJobUiModelCopyWithImpl<$Res>
    implements _$ScheduledJobUiModelCopyWith<$Res> {
  __$ScheduledJobUiModelCopyWithImpl(this._self, this._then);

  final _ScheduledJobUiModel _self;
  final $Res Function(_ScheduledJobUiModel) _then;

/// Create a copy of ScheduledJobUiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_ScheduledJobUiModel(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as String,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

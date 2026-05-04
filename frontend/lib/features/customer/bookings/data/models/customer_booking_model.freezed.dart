// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerBookingModel {

 int get id; String get status; BookingServiceModel get service; BookingTechnicianModel get technician;@JsonKey(name: 'address_label') String? get addressLabel;@JsonKey(name: 'scheduled_start') String get scheduledStart;@JsonKey(name: 'scheduled_end') String get scheduledEnd;@JsonKey(name: 'created_at') String get createdAt; BookingPriceModel get price; BookingUiModel get ui;
/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerBookingModelCopyWith<CustomerBookingModel> get copyWith => _$CustomerBookingModelCopyWithImpl<CustomerBookingModel>(this as CustomerBookingModel, _$identity);

  /// Serializes this CustomerBookingModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerBookingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.price, price) || other.price == price)&&(identical(other.ui, ui) || other.ui == ui));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,service,technician,addressLabel,scheduledStart,scheduledEnd,createdAt,price,ui);

@override
String toString() {
  return 'CustomerBookingModel(id: $id, status: $status, service: $service, technician: $technician, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, price: $price, ui: $ui)';
}


}

/// @nodoc
abstract mixin class $CustomerBookingModelCopyWith<$Res>  {
  factory $CustomerBookingModelCopyWith(CustomerBookingModel value, $Res Function(CustomerBookingModel) _then) = _$CustomerBookingModelCopyWithImpl;
@useResult
$Res call({
 int id, String status, BookingServiceModel service, BookingTechnicianModel technician,@JsonKey(name: 'address_label') String? addressLabel,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'created_at') String createdAt, BookingPriceModel price, BookingUiModel ui
});


$BookingServiceModelCopyWith<$Res> get service;$BookingTechnicianModelCopyWith<$Res> get technician;$BookingPriceModelCopyWith<$Res> get price;$BookingUiModelCopyWith<$Res> get ui;

}
/// @nodoc
class _$CustomerBookingModelCopyWithImpl<$Res>
    implements $CustomerBookingModelCopyWith<$Res> {
  _$CustomerBookingModelCopyWithImpl(this._self, this._then);

  final CustomerBookingModel _self;
  final $Res Function(CustomerBookingModel) _then;

/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? service = null,Object? technician = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? price = null,Object? ui = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingServiceModel,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnicianModel,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as BookingPriceModel,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiModel,
  ));
}
/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceModelCopyWith<$Res> get service {
  
  return $BookingServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianModelCopyWith<$Res> get technician {
  
  return $BookingTechnicianModelCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPriceModelCopyWith<$Res> get price {
  
  return $BookingPriceModelCopyWith<$Res>(_self.price, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiModelCopyWith<$Res> get ui {
  
  return $BookingUiModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// Adds pattern-matching-related methods to [CustomerBookingModel].
extension CustomerBookingModelPatterns on CustomerBookingModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerBookingModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerBookingModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerBookingModel value)  $default,){
final _that = this;
switch (_that) {
case _CustomerBookingModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerBookingModel value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerBookingModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String status,  BookingServiceModel service,  BookingTechnicianModel technician, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  BookingPriceModel price,  BookingUiModel ui)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerBookingModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String status,  BookingServiceModel service,  BookingTechnicianModel technician, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  BookingPriceModel price,  BookingUiModel ui)  $default,) {final _that = this;
switch (_that) {
case _CustomerBookingModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String status,  BookingServiceModel service,  BookingTechnicianModel technician, @JsonKey(name: 'address_label')  String? addressLabel, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'created_at')  String createdAt,  BookingPriceModel price,  BookingUiModel ui)?  $default,) {final _that = this;
switch (_that) {
case _CustomerBookingModel() when $default != null:
return $default(_that.id,_that.status,_that.service,_that.technician,_that.addressLabel,_that.scheduledStart,_that.scheduledEnd,_that.createdAt,_that.price,_that.ui);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerBookingModel implements CustomerBookingModel {
  const _CustomerBookingModel({required this.id, required this.status, required this.service, required this.technician, @JsonKey(name: 'address_label') required this.addressLabel, @JsonKey(name: 'scheduled_start') required this.scheduledStart, @JsonKey(name: 'scheduled_end') required this.scheduledEnd, @JsonKey(name: 'created_at') required this.createdAt, required this.price, required this.ui});
  factory _CustomerBookingModel.fromJson(Map<String, dynamic> json) => _$CustomerBookingModelFromJson(json);

@override final  int id;
@override final  String status;
@override final  BookingServiceModel service;
@override final  BookingTechnicianModel technician;
@override@JsonKey(name: 'address_label') final  String? addressLabel;
@override@JsonKey(name: 'scheduled_start') final  String scheduledStart;
@override@JsonKey(name: 'scheduled_end') final  String scheduledEnd;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override final  BookingPriceModel price;
@override final  BookingUiModel ui;

/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerBookingModelCopyWith<_CustomerBookingModel> get copyWith => __$CustomerBookingModelCopyWithImpl<_CustomerBookingModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerBookingModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerBookingModel&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.service, service) || other.service == service)&&(identical(other.technician, technician) || other.technician == technician)&&(identical(other.addressLabel, addressLabel) || other.addressLabel == addressLabel)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.price, price) || other.price == price)&&(identical(other.ui, ui) || other.ui == ui));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,service,technician,addressLabel,scheduledStart,scheduledEnd,createdAt,price,ui);

@override
String toString() {
  return 'CustomerBookingModel(id: $id, status: $status, service: $service, technician: $technician, addressLabel: $addressLabel, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, createdAt: $createdAt, price: $price, ui: $ui)';
}


}

/// @nodoc
abstract mixin class _$CustomerBookingModelCopyWith<$Res> implements $CustomerBookingModelCopyWith<$Res> {
  factory _$CustomerBookingModelCopyWith(_CustomerBookingModel value, $Res Function(_CustomerBookingModel) _then) = __$CustomerBookingModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String status, BookingServiceModel service, BookingTechnicianModel technician,@JsonKey(name: 'address_label') String? addressLabel,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'created_at') String createdAt, BookingPriceModel price, BookingUiModel ui
});


@override $BookingServiceModelCopyWith<$Res> get service;@override $BookingTechnicianModelCopyWith<$Res> get technician;@override $BookingPriceModelCopyWith<$Res> get price;@override $BookingUiModelCopyWith<$Res> get ui;

}
/// @nodoc
class __$CustomerBookingModelCopyWithImpl<$Res>
    implements _$CustomerBookingModelCopyWith<$Res> {
  __$CustomerBookingModelCopyWithImpl(this._self, this._then);

  final _CustomerBookingModel _self;
  final $Res Function(_CustomerBookingModel) _then;

/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? service = null,Object? technician = null,Object? addressLabel = freezed,Object? scheduledStart = null,Object? scheduledEnd = null,Object? createdAt = null,Object? price = null,Object? ui = null,}) {
  return _then(_CustomerBookingModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as BookingServiceModel,technician: null == technician ? _self.technician : technician // ignore: cast_nullable_to_non_nullable
as BookingTechnicianModel,addressLabel: freezed == addressLabel ? _self.addressLabel : addressLabel // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as BookingPriceModel,ui: null == ui ? _self.ui : ui // ignore: cast_nullable_to_non_nullable
as BookingUiModel,
  ));
}

/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingServiceModelCopyWith<$Res> get service {
  
  return $BookingServiceModelCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingTechnicianModelCopyWith<$Res> get technician {
  
  return $BookingTechnicianModelCopyWith<$Res>(_self.technician, (value) {
    return _then(_self.copyWith(technician: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingPriceModelCopyWith<$Res> get price {
  
  return $BookingPriceModelCopyWith<$Res>(_self.price, (value) {
    return _then(_self.copyWith(price: value));
  });
}/// Create a copy of CustomerBookingModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiModelCopyWith<$Res> get ui {
  
  return $BookingUiModelCopyWith<$Res>(_self.ui, (value) {
    return _then(_self.copyWith(ui: value));
  });
}
}


/// @nodoc
mixin _$BookingServiceModel {

 String get name;@JsonKey(name: 'icon_name') String get iconName;
/// Create a copy of BookingServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingServiceModelCopyWith<BookingServiceModel> get copyWith => _$BookingServiceModelCopyWithImpl<BookingServiceModel>(this as BookingServiceModel, _$identity);

  /// Serializes this BookingServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingServiceModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'BookingServiceModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $BookingServiceModelCopyWith<$Res>  {
  factory $BookingServiceModelCopyWith(BookingServiceModel value, $Res Function(BookingServiceModel) _then) = _$BookingServiceModelCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class _$BookingServiceModelCopyWithImpl<$Res>
    implements $BookingServiceModelCopyWith<$Res> {
  _$BookingServiceModelCopyWithImpl(this._self, this._then);

  final BookingServiceModel _self;
  final $Res Function(BookingServiceModel) _then;

/// Create a copy of BookingServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingServiceModel].
extension BookingServiceModelPatterns on BookingServiceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingServiceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingServiceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingServiceModel() when $default != null:
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
case _BookingServiceModel() when $default != null:
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
case _BookingServiceModel():
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
case _BookingServiceModel() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingServiceModel implements BookingServiceModel {
  const _BookingServiceModel({required this.name, @JsonKey(name: 'icon_name') required this.iconName});
  factory _BookingServiceModel.fromJson(Map<String, dynamic> json) => _$BookingServiceModelFromJson(json);

@override final  String name;
@override@JsonKey(name: 'icon_name') final  String iconName;

/// Create a copy of BookingServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingServiceModelCopyWith<_BookingServiceModel> get copyWith => __$BookingServiceModelCopyWithImpl<_BookingServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingServiceModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'BookingServiceModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$BookingServiceModelCopyWith<$Res> implements $BookingServiceModelCopyWith<$Res> {
  factory _$BookingServiceModelCopyWith(_BookingServiceModel value, $Res Function(_BookingServiceModel) _then) = __$BookingServiceModelCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String iconName
});




}
/// @nodoc
class __$BookingServiceModelCopyWithImpl<$Res>
    implements _$BookingServiceModelCopyWith<$Res> {
  __$BookingServiceModelCopyWithImpl(this._self, this._then);

  final _BookingServiceModel _self;
  final $Res Function(_BookingServiceModel) _then;

/// Create a copy of BookingServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = null,}) {
  return _then(_BookingServiceModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingTechnicianModel {

 int get id;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'profile_picture_url') String? get profilePictureUrl;
/// Create a copy of BookingTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingTechnicianModelCopyWith<BookingTechnicianModel> get copyWith => _$BookingTechnicianModelCopyWithImpl<BookingTechnicianModel>(this as BookingTechnicianModel, _$identity);

  /// Serializes this BookingTechnicianModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingTechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingTechnicianModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class $BookingTechnicianModelCopyWith<$Res>  {
  factory $BookingTechnicianModelCopyWith(BookingTechnicianModel value, $Res Function(BookingTechnicianModel) _then) = _$BookingTechnicianModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class _$BookingTechnicianModelCopyWithImpl<$Res>
    implements $BookingTechnicianModelCopyWith<$Res> {
  _$BookingTechnicianModelCopyWithImpl(this._self, this._then);

  final BookingTechnicianModel _self;
  final $Res Function(BookingTechnicianModel) _then;

/// Create a copy of BookingTechnicianModel
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


/// Adds pattern-matching-related methods to [BookingTechnicianModel].
extension BookingTechnicianModelPatterns on BookingTechnicianModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingTechnicianModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingTechnicianModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingTechnicianModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingTechnicianModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingTechnicianModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingTechnicianModel() when $default != null:
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
case _BookingTechnicianModel() when $default != null:
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
case _BookingTechnicianModel():
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
case _BookingTechnicianModel() when $default != null:
return $default(_that.id,_that.displayName,_that.profilePictureUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingTechnicianModel implements BookingTechnicianModel {
  const _BookingTechnicianModel({required this.id, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'profile_picture_url') required this.profilePictureUrl});
  factory _BookingTechnicianModel.fromJson(Map<String, dynamic> json) => _$BookingTechnicianModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'profile_picture_url') final  String? profilePictureUrl;

/// Create a copy of BookingTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingTechnicianModelCopyWith<_BookingTechnicianModel> get copyWith => __$BookingTechnicianModelCopyWithImpl<_BookingTechnicianModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingTechnicianModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingTechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profilePictureUrl, profilePictureUrl) || other.profilePictureUrl == profilePictureUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,profilePictureUrl);

@override
String toString() {
  return 'BookingTechnicianModel(id: $id, displayName: $displayName, profilePictureUrl: $profilePictureUrl)';
}


}

/// @nodoc
abstract mixin class _$BookingTechnicianModelCopyWith<$Res> implements $BookingTechnicianModelCopyWith<$Res> {
  factory _$BookingTechnicianModelCopyWith(_BookingTechnicianModel value, $Res Function(_BookingTechnicianModel) _then) = __$BookingTechnicianModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'profile_picture_url') String? profilePictureUrl
});




}
/// @nodoc
class __$BookingTechnicianModelCopyWithImpl<$Res>
    implements _$BookingTechnicianModelCopyWith<$Res> {
  __$BookingTechnicianModelCopyWithImpl(this._self, this._then);

  final _BookingTechnicianModel _self;
  final $Res Function(_BookingTechnicianModel) _then;

/// Create a copy of BookingTechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? profilePictureUrl = freezed,}) {
  return _then(_BookingTechnicianModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,profilePictureUrl: freezed == profilePictureUrl ? _self.profilePictureUrl : profilePictureUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingPriceModel {

 int get amount; String get context;@JsonKey(name: 'ui_label') String get uiLabel;
/// Create a copy of BookingPriceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingPriceModelCopyWith<BookingPriceModel> get copyWith => _$BookingPriceModelCopyWithImpl<BookingPriceModel>(this as BookingPriceModel, _$identity);

  /// Serializes this BookingPriceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingPriceModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'BookingPriceModel(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class $BookingPriceModelCopyWith<$Res>  {
  factory $BookingPriceModelCopyWith(BookingPriceModel value, $Res Function(BookingPriceModel) _then) = _$BookingPriceModelCopyWithImpl;
@useResult
$Res call({
 int amount, String context,@JsonKey(name: 'ui_label') String uiLabel
});




}
/// @nodoc
class _$BookingPriceModelCopyWithImpl<$Res>
    implements $BookingPriceModelCopyWith<$Res> {
  _$BookingPriceModelCopyWithImpl(this._self, this._then);

  final BookingPriceModel _self;
  final $Res Function(BookingPriceModel) _then;

/// Create a copy of BookingPriceModel
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


/// Adds pattern-matching-related methods to [BookingPriceModel].
extension BookingPriceModelPatterns on BookingPriceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingPriceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingPriceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingPriceModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingPriceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingPriceModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingPriceModel() when $default != null:
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
case _BookingPriceModel() when $default != null:
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
case _BookingPriceModel():
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
case _BookingPriceModel() when $default != null:
return $default(_that.amount,_that.context,_that.uiLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingPriceModel implements BookingPriceModel {
  const _BookingPriceModel({required this.amount, required this.context, @JsonKey(name: 'ui_label') required this.uiLabel});
  factory _BookingPriceModel.fromJson(Map<String, dynamic> json) => _$BookingPriceModelFromJson(json);

@override final  int amount;
@override final  String context;
@override@JsonKey(name: 'ui_label') final  String uiLabel;

/// Create a copy of BookingPriceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingPriceModelCopyWith<_BookingPriceModel> get copyWith => __$BookingPriceModelCopyWithImpl<_BookingPriceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingPriceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingPriceModel&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.context, context) || other.context == context)&&(identical(other.uiLabel, uiLabel) || other.uiLabel == uiLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,amount,context,uiLabel);

@override
String toString() {
  return 'BookingPriceModel(amount: $amount, context: $context, uiLabel: $uiLabel)';
}


}

/// @nodoc
abstract mixin class _$BookingPriceModelCopyWith<$Res> implements $BookingPriceModelCopyWith<$Res> {
  factory _$BookingPriceModelCopyWith(_BookingPriceModel value, $Res Function(_BookingPriceModel) _then) = __$BookingPriceModelCopyWithImpl;
@override @useResult
$Res call({
 int amount, String context,@JsonKey(name: 'ui_label') String uiLabel
});




}
/// @nodoc
class __$BookingPriceModelCopyWithImpl<$Res>
    implements _$BookingPriceModelCopyWith<$Res> {
  __$BookingPriceModelCopyWithImpl(this._self, this._then);

  final _BookingPriceModel _self;
  final $Res Function(_BookingPriceModel) _then;

/// Create a copy of BookingPriceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = null,Object? context = null,Object? uiLabel = null,}) {
  return _then(_BookingPriceModel(
amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as String,uiLabel: null == uiLabel ? _self.uiLabel : uiLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingUiModel {

@JsonKey(name: 'badge_text') String get badgeText;@JsonKey(name: 'badge_tone') String get badgeTone; String get headline;
/// Create a copy of BookingUiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiModelCopyWith<BookingUiModel> get copyWith => _$BookingUiModelCopyWithImpl<BookingUiModel>(this as BookingUiModel, _$identity);

  /// Serializes this BookingUiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUiModel&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'BookingUiModel(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class $BookingUiModelCopyWith<$Res>  {
  factory $BookingUiModelCopyWith(BookingUiModel value, $Res Function(BookingUiModel) _then) = _$BookingUiModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'badge_text') String badgeText,@JsonKey(name: 'badge_tone') String badgeTone, String headline
});




}
/// @nodoc
class _$BookingUiModelCopyWithImpl<$Res>
    implements $BookingUiModelCopyWith<$Res> {
  _$BookingUiModelCopyWithImpl(this._self, this._then);

  final BookingUiModel _self;
  final $Res Function(BookingUiModel) _then;

/// Create a copy of BookingUiModel
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


/// Adds pattern-matching-related methods to [BookingUiModel].
extension BookingUiModelPatterns on BookingUiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUiModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingUiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUiModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUiModel() when $default != null:
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
case _BookingUiModel() when $default != null:
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
case _BookingUiModel():
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
case _BookingUiModel() when $default != null:
return $default(_that.badgeText,_that.badgeTone,_that.headline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingUiModel implements BookingUiModel {
  const _BookingUiModel({@JsonKey(name: 'badge_text') required this.badgeText, @JsonKey(name: 'badge_tone') required this.badgeTone, required this.headline});
  factory _BookingUiModel.fromJson(Map<String, dynamic> json) => _$BookingUiModelFromJson(json);

@override@JsonKey(name: 'badge_text') final  String badgeText;
@override@JsonKey(name: 'badge_tone') final  String badgeTone;
@override final  String headline;

/// Create a copy of BookingUiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiModelCopyWith<_BookingUiModel> get copyWith => __$BookingUiModelCopyWithImpl<_BookingUiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingUiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUiModel&&(identical(other.badgeText, badgeText) || other.badgeText == badgeText)&&(identical(other.badgeTone, badgeTone) || other.badgeTone == badgeTone)&&(identical(other.headline, headline) || other.headline == headline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,badgeText,badgeTone,headline);

@override
String toString() {
  return 'BookingUiModel(badgeText: $badgeText, badgeTone: $badgeTone, headline: $headline)';
}


}

/// @nodoc
abstract mixin class _$BookingUiModelCopyWith<$Res> implements $BookingUiModelCopyWith<$Res> {
  factory _$BookingUiModelCopyWith(_BookingUiModel value, $Res Function(_BookingUiModel) _then) = __$BookingUiModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'badge_text') String badgeText,@JsonKey(name: 'badge_tone') String badgeTone, String headline
});




}
/// @nodoc
class __$BookingUiModelCopyWithImpl<$Res>
    implements _$BookingUiModelCopyWith<$Res> {
  __$BookingUiModelCopyWithImpl(this._self, this._then);

  final _BookingUiModel _self;
  final $Res Function(_BookingUiModel) _then;

/// Create a copy of BookingUiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? badgeText = null,Object? badgeTone = null,Object? headline = null,}) {
  return _then(_BookingUiModel(
badgeText: null == badgeText ? _self.badgeText : badgeText // ignore: cast_nullable_to_non_nullable
as String,badgeTone: null == badgeTone ? _self.badgeTone : badgeTone // ignore: cast_nullable_to_non_nullable
as String,headline: null == headline ? _self.headline : headline // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

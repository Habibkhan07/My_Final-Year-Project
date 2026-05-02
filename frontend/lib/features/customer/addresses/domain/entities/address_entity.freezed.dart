// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'address_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerAddressEntity {

 int get id; String get label; String get streetAddress; double get latitude; double get longitude; bool get isDefault; String get createdAt; String? get neighborhood; String? get suburb; String? get city; String? get state; String? get country; String? get postalCode; String? get localityLabel;
/// Create a copy of CustomerAddressEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerAddressEntityCopyWith<CustomerAddressEntity> get copyWith => _$CustomerAddressEntityCopyWithImpl<CustomerAddressEntity>(this as CustomerAddressEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerAddressEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.suburb, suburb) || other.suburb == suburb)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.localityLabel, localityLabel) || other.localityLabel == localityLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,streetAddress,latitude,longitude,isDefault,createdAt,neighborhood,suburb,city,state,country,postalCode,localityLabel);

@override
String toString() {
  return 'CustomerAddressEntity(id: $id, label: $label, streetAddress: $streetAddress, latitude: $latitude, longitude: $longitude, isDefault: $isDefault, createdAt: $createdAt, neighborhood: $neighborhood, suburb: $suburb, city: $city, state: $state, country: $country, postalCode: $postalCode, localityLabel: $localityLabel)';
}


}

/// @nodoc
abstract mixin class $CustomerAddressEntityCopyWith<$Res>  {
  factory $CustomerAddressEntityCopyWith(CustomerAddressEntity value, $Res Function(CustomerAddressEntity) _then) = _$CustomerAddressEntityCopyWithImpl;
@useResult
$Res call({
 int id, String label, String streetAddress, double latitude, double longitude, bool isDefault, String createdAt, String? neighborhood, String? suburb, String? city, String? state, String? country, String? postalCode, String? localityLabel
});




}
/// @nodoc
class _$CustomerAddressEntityCopyWithImpl<$Res>
    implements $CustomerAddressEntityCopyWith<$Res> {
  _$CustomerAddressEntityCopyWithImpl(this._self, this._then);

  final CustomerAddressEntity _self;
  final $Res Function(CustomerAddressEntity) _then;

/// Create a copy of CustomerAddressEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? streetAddress = null,Object? latitude = null,Object? longitude = null,Object? isDefault = null,Object? createdAt = null,Object? neighborhood = freezed,Object? suburb = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,Object? localityLabel = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,suburb: freezed == suburb ? _self.suburb : suburb // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,localityLabel: freezed == localityLabel ? _self.localityLabel : localityLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerAddressEntity].
extension CustomerAddressEntityPatterns on CustomerAddressEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerAddressEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerAddressEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerAddressEntity value)  $default,){
final _that = this;
switch (_that) {
case _CustomerAddressEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerAddressEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerAddressEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label,  String streetAddress,  double latitude,  double longitude,  bool isDefault,  String createdAt,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode,  String? localityLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerAddressEntity() when $default != null:
return $default(_that.id,_that.label,_that.streetAddress,_that.latitude,_that.longitude,_that.isDefault,_that.createdAt,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode,_that.localityLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label,  String streetAddress,  double latitude,  double longitude,  bool isDefault,  String createdAt,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode,  String? localityLabel)  $default,) {final _that = this;
switch (_that) {
case _CustomerAddressEntity():
return $default(_that.id,_that.label,_that.streetAddress,_that.latitude,_that.longitude,_that.isDefault,_that.createdAt,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode,_that.localityLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label,  String streetAddress,  double latitude,  double longitude,  bool isDefault,  String createdAt,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode,  String? localityLabel)?  $default,) {final _that = this;
switch (_that) {
case _CustomerAddressEntity() when $default != null:
return $default(_that.id,_that.label,_that.streetAddress,_that.latitude,_that.longitude,_that.isDefault,_that.createdAt,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode,_that.localityLabel);case _:
  return null;

}
}

}

/// @nodoc


class _CustomerAddressEntity implements CustomerAddressEntity {
  const _CustomerAddressEntity({required this.id, required this.label, required this.streetAddress, required this.latitude, required this.longitude, required this.isDefault, required this.createdAt, this.neighborhood, this.suburb, this.city, this.state, this.country, this.postalCode, this.localityLabel});
  

@override final  int id;
@override final  String label;
@override final  String streetAddress;
@override final  double latitude;
@override final  double longitude;
@override final  bool isDefault;
@override final  String createdAt;
@override final  String? neighborhood;
@override final  String? suburb;
@override final  String? city;
@override final  String? state;
@override final  String? country;
@override final  String? postalCode;
@override final  String? localityLabel;

/// Create a copy of CustomerAddressEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerAddressEntityCopyWith<_CustomerAddressEntity> get copyWith => __$CustomerAddressEntityCopyWithImpl<_CustomerAddressEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerAddressEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.isDefault, isDefault) || other.isDefault == isDefault)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.suburb, suburb) || other.suburb == suburb)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode)&&(identical(other.localityLabel, localityLabel) || other.localityLabel == localityLabel));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,streetAddress,latitude,longitude,isDefault,createdAt,neighborhood,suburb,city,state,country,postalCode,localityLabel);

@override
String toString() {
  return 'CustomerAddressEntity(id: $id, label: $label, streetAddress: $streetAddress, latitude: $latitude, longitude: $longitude, isDefault: $isDefault, createdAt: $createdAt, neighborhood: $neighborhood, suburb: $suburb, city: $city, state: $state, country: $country, postalCode: $postalCode, localityLabel: $localityLabel)';
}


}

/// @nodoc
abstract mixin class _$CustomerAddressEntityCopyWith<$Res> implements $CustomerAddressEntityCopyWith<$Res> {
  factory _$CustomerAddressEntityCopyWith(_CustomerAddressEntity value, $Res Function(_CustomerAddressEntity) _then) = __$CustomerAddressEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, String streetAddress, double latitude, double longitude, bool isDefault, String createdAt, String? neighborhood, String? suburb, String? city, String? state, String? country, String? postalCode, String? localityLabel
});




}
/// @nodoc
class __$CustomerAddressEntityCopyWithImpl<$Res>
    implements _$CustomerAddressEntityCopyWith<$Res> {
  __$CustomerAddressEntityCopyWithImpl(this._self, this._then);

  final _CustomerAddressEntity _self;
  final $Res Function(_CustomerAddressEntity) _then;

/// Create a copy of CustomerAddressEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? streetAddress = null,Object? latitude = null,Object? longitude = null,Object? isDefault = null,Object? createdAt = null,Object? neighborhood = freezed,Object? suburb = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,Object? localityLabel = freezed,}) {
  return _then(_CustomerAddressEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,isDefault: null == isDefault ? _self.isDefault : isDefault // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,suburb: freezed == suburb ? _self.suburb : suburb // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,localityLabel: freezed == localityLabel ? _self.localityLabel : localityLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

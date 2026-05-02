// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_details.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceDetails {

 String get formattedAddress; double get latitude; double get longitude; String? get neighborhood; String? get suburb; String? get city; String? get state; String? get country; String? get postalCode;
/// Create a copy of PlaceDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceDetailsCopyWith<PlaceDetails> get copyWith => _$PlaceDetailsCopyWithImpl<PlaceDetails>(this as PlaceDetails, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceDetails&&(identical(other.formattedAddress, formattedAddress) || other.formattedAddress == formattedAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.suburb, suburb) || other.suburb == suburb)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode));
}


@override
int get hashCode => Object.hash(runtimeType,formattedAddress,latitude,longitude,neighborhood,suburb,city,state,country,postalCode);

@override
String toString() {
  return 'PlaceDetails(formattedAddress: $formattedAddress, latitude: $latitude, longitude: $longitude, neighborhood: $neighborhood, suburb: $suburb, city: $city, state: $state, country: $country, postalCode: $postalCode)';
}


}

/// @nodoc
abstract mixin class $PlaceDetailsCopyWith<$Res>  {
  factory $PlaceDetailsCopyWith(PlaceDetails value, $Res Function(PlaceDetails) _then) = _$PlaceDetailsCopyWithImpl;
@useResult
$Res call({
 String formattedAddress, double latitude, double longitude, String? neighborhood, String? suburb, String? city, String? state, String? country, String? postalCode
});




}
/// @nodoc
class _$PlaceDetailsCopyWithImpl<$Res>
    implements $PlaceDetailsCopyWith<$Res> {
  _$PlaceDetailsCopyWithImpl(this._self, this._then);

  final PlaceDetails _self;
  final $Res Function(PlaceDetails) _then;

/// Create a copy of PlaceDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? formattedAddress = null,Object? latitude = null,Object? longitude = null,Object? neighborhood = freezed,Object? suburb = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,}) {
  return _then(_self.copyWith(
formattedAddress: null == formattedAddress ? _self.formattedAddress : formattedAddress // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,suburb: freezed == suburb ? _self.suburb : suburb // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceDetails].
extension PlaceDetailsPatterns on PlaceDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceDetails value)  $default,){
final _that = this;
switch (_that) {
case _PlaceDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceDetails value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String formattedAddress,  double latitude,  double longitude,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceDetails() when $default != null:
return $default(_that.formattedAddress,_that.latitude,_that.longitude,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String formattedAddress,  double latitude,  double longitude,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode)  $default,) {final _that = this;
switch (_that) {
case _PlaceDetails():
return $default(_that.formattedAddress,_that.latitude,_that.longitude,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String formattedAddress,  double latitude,  double longitude,  String? neighborhood,  String? suburb,  String? city,  String? state,  String? country,  String? postalCode)?  $default,) {final _that = this;
switch (_that) {
case _PlaceDetails() when $default != null:
return $default(_that.formattedAddress,_that.latitude,_that.longitude,_that.neighborhood,_that.suburb,_that.city,_that.state,_that.country,_that.postalCode);case _:
  return null;

}
}

}

/// @nodoc


class _PlaceDetails extends PlaceDetails {
  const _PlaceDetails({required this.formattedAddress, required this.latitude, required this.longitude, this.neighborhood, this.suburb, this.city, this.state, this.country, this.postalCode}): super._();
  

@override final  String formattedAddress;
@override final  double latitude;
@override final  double longitude;
@override final  String? neighborhood;
@override final  String? suburb;
@override final  String? city;
@override final  String? state;
@override final  String? country;
@override final  String? postalCode;

/// Create a copy of PlaceDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceDetailsCopyWith<_PlaceDetails> get copyWith => __$PlaceDetailsCopyWithImpl<_PlaceDetails>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceDetails&&(identical(other.formattedAddress, formattedAddress) || other.formattedAddress == formattedAddress)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.neighborhood, neighborhood) || other.neighborhood == neighborhood)&&(identical(other.suburb, suburb) || other.suburb == suburb)&&(identical(other.city, city) || other.city == city)&&(identical(other.state, state) || other.state == state)&&(identical(other.country, country) || other.country == country)&&(identical(other.postalCode, postalCode) || other.postalCode == postalCode));
}


@override
int get hashCode => Object.hash(runtimeType,formattedAddress,latitude,longitude,neighborhood,suburb,city,state,country,postalCode);

@override
String toString() {
  return 'PlaceDetails(formattedAddress: $formattedAddress, latitude: $latitude, longitude: $longitude, neighborhood: $neighborhood, suburb: $suburb, city: $city, state: $state, country: $country, postalCode: $postalCode)';
}


}

/// @nodoc
abstract mixin class _$PlaceDetailsCopyWith<$Res> implements $PlaceDetailsCopyWith<$Res> {
  factory _$PlaceDetailsCopyWith(_PlaceDetails value, $Res Function(_PlaceDetails) _then) = __$PlaceDetailsCopyWithImpl;
@override @useResult
$Res call({
 String formattedAddress, double latitude, double longitude, String? neighborhood, String? suburb, String? city, String? state, String? country, String? postalCode
});




}
/// @nodoc
class __$PlaceDetailsCopyWithImpl<$Res>
    implements _$PlaceDetailsCopyWith<$Res> {
  __$PlaceDetailsCopyWithImpl(this._self, this._then);

  final _PlaceDetails _self;
  final $Res Function(_PlaceDetails) _then;

/// Create a copy of PlaceDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? formattedAddress = null,Object? latitude = null,Object? longitude = null,Object? neighborhood = freezed,Object? suburb = freezed,Object? city = freezed,Object? state = freezed,Object? country = freezed,Object? postalCode = freezed,}) {
  return _then(_PlaceDetails(
formattedAddress: null == formattedAddress ? _self.formattedAddress : formattedAddress // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,neighborhood: freezed == neighborhood ? _self.neighborhood : neighborhood // ignore: cast_nullable_to_non_nullable
as String?,suburb: freezed == suburb ? _self.suburb : suburb // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,country: freezed == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String?,postalCode: freezed == postalCode ? _self.postalCode : postalCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

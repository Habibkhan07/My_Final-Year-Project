// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_location_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkLocationPickerState {

 double get latitude; double get longitude; String get streetAddress; int get maxTravelRadiusKm; PlaceDetails? get details; bool get isGeocoding; AsyncValue<WorkLocationEntity?> get saveState;
/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkLocationPickerStateCopyWith<WorkLocationPickerState> get copyWith => _$WorkLocationPickerStateCopyWithImpl<WorkLocationPickerState>(this as WorkLocationPickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkLocationPickerState&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.details, details) || other.details == details)&&(identical(other.isGeocoding, isGeocoding) || other.isGeocoding == isGeocoding)&&(identical(other.saveState, saveState) || other.saveState == saveState));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,streetAddress,maxTravelRadiusKm,details,isGeocoding,saveState);

@override
String toString() {
  return 'WorkLocationPickerState(latitude: $latitude, longitude: $longitude, streetAddress: $streetAddress, maxTravelRadiusKm: $maxTravelRadiusKm, details: $details, isGeocoding: $isGeocoding, saveState: $saveState)';
}


}

/// @nodoc
abstract mixin class $WorkLocationPickerStateCopyWith<$Res>  {
  factory $WorkLocationPickerStateCopyWith(WorkLocationPickerState value, $Res Function(WorkLocationPickerState) _then) = _$WorkLocationPickerStateCopyWithImpl;
@useResult
$Res call({
 double latitude, double longitude, String streetAddress, int maxTravelRadiusKm, PlaceDetails? details, bool isGeocoding, AsyncValue<WorkLocationEntity?> saveState
});


$PlaceDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class _$WorkLocationPickerStateCopyWithImpl<$Res>
    implements $WorkLocationPickerStateCopyWith<$Res> {
  _$WorkLocationPickerStateCopyWithImpl(this._self, this._then);

  final WorkLocationPickerState _self;
  final $Res Function(WorkLocationPickerState) _then;

/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,Object? streetAddress = null,Object? maxTravelRadiusKm = null,Object? details = freezed,Object? isGeocoding = null,Object? saveState = null,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as PlaceDetails?,isGeocoding: null == isGeocoding ? _self.isGeocoding : isGeocoding // ignore: cast_nullable_to_non_nullable
as bool,saveState: null == saveState ? _self.saveState : saveState // ignore: cast_nullable_to_non_nullable
as AsyncValue<WorkLocationEntity?>,
  ));
}
/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $PlaceDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkLocationPickerState].
extension WorkLocationPickerStatePatterns on WorkLocationPickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkLocationPickerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkLocationPickerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkLocationPickerState value)  $default,){
final _that = this;
switch (_that) {
case _WorkLocationPickerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkLocationPickerState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkLocationPickerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String streetAddress,  int maxTravelRadiusKm,  PlaceDetails? details,  bool isGeocoding,  AsyncValue<WorkLocationEntity?> saveState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkLocationPickerState() when $default != null:
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.maxTravelRadiusKm,_that.details,_that.isGeocoding,_that.saveState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String streetAddress,  int maxTravelRadiusKm,  PlaceDetails? details,  bool isGeocoding,  AsyncValue<WorkLocationEntity?> saveState)  $default,) {final _that = this;
switch (_that) {
case _WorkLocationPickerState():
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.maxTravelRadiusKm,_that.details,_that.isGeocoding,_that.saveState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitude,  double longitude,  String streetAddress,  int maxTravelRadiusKm,  PlaceDetails? details,  bool isGeocoding,  AsyncValue<WorkLocationEntity?> saveState)?  $default,) {final _that = this;
switch (_that) {
case _WorkLocationPickerState() when $default != null:
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.maxTravelRadiusKm,_that.details,_that.isGeocoding,_that.saveState);case _:
  return null;

}
}

}

/// @nodoc


class _WorkLocationPickerState implements WorkLocationPickerState {
  const _WorkLocationPickerState({required this.latitude, required this.longitude, required this.streetAddress, required this.maxTravelRadiusKm, this.details, this.isGeocoding = false, this.saveState = const AsyncValue<WorkLocationEntity?>.data(null)});
  

@override final  double latitude;
@override final  double longitude;
@override final  String streetAddress;
@override final  int maxTravelRadiusKm;
@override final  PlaceDetails? details;
@override@JsonKey() final  bool isGeocoding;
@override@JsonKey() final  AsyncValue<WorkLocationEntity?> saveState;

/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkLocationPickerStateCopyWith<_WorkLocationPickerState> get copyWith => __$WorkLocationPickerStateCopyWithImpl<_WorkLocationPickerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkLocationPickerState&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.details, details) || other.details == details)&&(identical(other.isGeocoding, isGeocoding) || other.isGeocoding == isGeocoding)&&(identical(other.saveState, saveState) || other.saveState == saveState));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,streetAddress,maxTravelRadiusKm,details,isGeocoding,saveState);

@override
String toString() {
  return 'WorkLocationPickerState(latitude: $latitude, longitude: $longitude, streetAddress: $streetAddress, maxTravelRadiusKm: $maxTravelRadiusKm, details: $details, isGeocoding: $isGeocoding, saveState: $saveState)';
}


}

/// @nodoc
abstract mixin class _$WorkLocationPickerStateCopyWith<$Res> implements $WorkLocationPickerStateCopyWith<$Res> {
  factory _$WorkLocationPickerStateCopyWith(_WorkLocationPickerState value, $Res Function(_WorkLocationPickerState) _then) = __$WorkLocationPickerStateCopyWithImpl;
@override @useResult
$Res call({
 double latitude, double longitude, String streetAddress, int maxTravelRadiusKm, PlaceDetails? details, bool isGeocoding, AsyncValue<WorkLocationEntity?> saveState
});


@override $PlaceDetailsCopyWith<$Res>? get details;

}
/// @nodoc
class __$WorkLocationPickerStateCopyWithImpl<$Res>
    implements _$WorkLocationPickerStateCopyWith<$Res> {
  __$WorkLocationPickerStateCopyWithImpl(this._self, this._then);

  final _WorkLocationPickerState _self;
  final $Res Function(_WorkLocationPickerState) _then;

/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,Object? streetAddress = null,Object? maxTravelRadiusKm = null,Object? details = freezed,Object? isGeocoding = null,Object? saveState = null,}) {
  return _then(_WorkLocationPickerState(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as PlaceDetails?,isGeocoding: null == isGeocoding ? _self.isGeocoding : isGeocoding // ignore: cast_nullable_to_non_nullable
as bool,saveState: null == saveState ? _self.saveState : saveState // ignore: cast_nullable_to_non_nullable
as AsyncValue<WorkLocationEntity?>,
  ));
}

/// Create a copy of WorkLocationPickerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceDetailsCopyWith<$Res>? get details {
    if (_self.details == null) {
    return null;
  }

  return $PlaceDetailsCopyWith<$Res>(_self.details!, (value) {
    return _then(_self.copyWith(details: value));
  });
}
}

// dart format on

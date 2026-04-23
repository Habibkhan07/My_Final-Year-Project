// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'map_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MapPickerState {

 double get latitude; double get longitude; String get streetAddress; bool get isGeocoding; String get selectedLabel; AsyncValue<CustomerAddressEntity?> get saveState;
/// Create a copy of MapPickerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MapPickerStateCopyWith<MapPickerState> get copyWith => _$MapPickerStateCopyWithImpl<MapPickerState>(this as MapPickerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MapPickerState&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.isGeocoding, isGeocoding) || other.isGeocoding == isGeocoding)&&(identical(other.selectedLabel, selectedLabel) || other.selectedLabel == selectedLabel)&&(identical(other.saveState, saveState) || other.saveState == saveState));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,streetAddress,isGeocoding,selectedLabel,saveState);

@override
String toString() {
  return 'MapPickerState(latitude: $latitude, longitude: $longitude, streetAddress: $streetAddress, isGeocoding: $isGeocoding, selectedLabel: $selectedLabel, saveState: $saveState)';
}


}

/// @nodoc
abstract mixin class $MapPickerStateCopyWith<$Res>  {
  factory $MapPickerStateCopyWith(MapPickerState value, $Res Function(MapPickerState) _then) = _$MapPickerStateCopyWithImpl;
@useResult
$Res call({
 double latitude, double longitude, String streetAddress, bool isGeocoding, String selectedLabel, AsyncValue<CustomerAddressEntity?> saveState
});




}
/// @nodoc
class _$MapPickerStateCopyWithImpl<$Res>
    implements $MapPickerStateCopyWith<$Res> {
  _$MapPickerStateCopyWithImpl(this._self, this._then);

  final MapPickerState _self;
  final $Res Function(MapPickerState) _then;

/// Create a copy of MapPickerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,Object? streetAddress = null,Object? isGeocoding = null,Object? selectedLabel = null,Object? saveState = null,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,isGeocoding: null == isGeocoding ? _self.isGeocoding : isGeocoding // ignore: cast_nullable_to_non_nullable
as bool,selectedLabel: null == selectedLabel ? _self.selectedLabel : selectedLabel // ignore: cast_nullable_to_non_nullable
as String,saveState: null == saveState ? _self.saveState : saveState // ignore: cast_nullable_to_non_nullable
as AsyncValue<CustomerAddressEntity?>,
  ));
}

}


/// Adds pattern-matching-related methods to [MapPickerState].
extension MapPickerStatePatterns on MapPickerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MapPickerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MapPickerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MapPickerState value)  $default,){
final _that = this;
switch (_that) {
case _MapPickerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MapPickerState value)?  $default,){
final _that = this;
switch (_that) {
case _MapPickerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String streetAddress,  bool isGeocoding,  String selectedLabel,  AsyncValue<CustomerAddressEntity?> saveState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MapPickerState() when $default != null:
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.isGeocoding,_that.selectedLabel,_that.saveState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitude,  double longitude,  String streetAddress,  bool isGeocoding,  String selectedLabel,  AsyncValue<CustomerAddressEntity?> saveState)  $default,) {final _that = this;
switch (_that) {
case _MapPickerState():
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.isGeocoding,_that.selectedLabel,_that.saveState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitude,  double longitude,  String streetAddress,  bool isGeocoding,  String selectedLabel,  AsyncValue<CustomerAddressEntity?> saveState)?  $default,) {final _that = this;
switch (_that) {
case _MapPickerState() when $default != null:
return $default(_that.latitude,_that.longitude,_that.streetAddress,_that.isGeocoding,_that.selectedLabel,_that.saveState);case _:
  return null;

}
}

}

/// @nodoc


class _MapPickerState extends MapPickerState {
  const _MapPickerState({required this.latitude, required this.longitude, required this.streetAddress, this.isGeocoding = false, this.selectedLabel = 'Home', this.saveState = const AsyncValue<CustomerAddressEntity?>.data(null)}): super._();
  

@override final  double latitude;
@override final  double longitude;
@override final  String streetAddress;
@override@JsonKey() final  bool isGeocoding;
@override@JsonKey() final  String selectedLabel;
@override@JsonKey() final  AsyncValue<CustomerAddressEntity?> saveState;

/// Create a copy of MapPickerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MapPickerStateCopyWith<_MapPickerState> get copyWith => __$MapPickerStateCopyWithImpl<_MapPickerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MapPickerState&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.streetAddress, streetAddress) || other.streetAddress == streetAddress)&&(identical(other.isGeocoding, isGeocoding) || other.isGeocoding == isGeocoding)&&(identical(other.selectedLabel, selectedLabel) || other.selectedLabel == selectedLabel)&&(identical(other.saveState, saveState) || other.saveState == saveState));
}


@override
int get hashCode => Object.hash(runtimeType,latitude,longitude,streetAddress,isGeocoding,selectedLabel,saveState);

@override
String toString() {
  return 'MapPickerState(latitude: $latitude, longitude: $longitude, streetAddress: $streetAddress, isGeocoding: $isGeocoding, selectedLabel: $selectedLabel, saveState: $saveState)';
}


}

/// @nodoc
abstract mixin class _$MapPickerStateCopyWith<$Res> implements $MapPickerStateCopyWith<$Res> {
  factory _$MapPickerStateCopyWith(_MapPickerState value, $Res Function(_MapPickerState) _then) = __$MapPickerStateCopyWithImpl;
@override @useResult
$Res call({
 double latitude, double longitude, String streetAddress, bool isGeocoding, String selectedLabel, AsyncValue<CustomerAddressEntity?> saveState
});




}
/// @nodoc
class __$MapPickerStateCopyWithImpl<$Res>
    implements _$MapPickerStateCopyWith<$Res> {
  __$MapPickerStateCopyWithImpl(this._self, this._then);

  final _MapPickerState _self;
  final $Res Function(_MapPickerState) _then;

/// Create a copy of MapPickerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,Object? streetAddress = null,Object? isGeocoding = null,Object? selectedLabel = null,Object? saveState = null,}) {
  return _then(_MapPickerState(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,streetAddress: null == streetAddress ? _self.streetAddress : streetAddress // ignore: cast_nullable_to_non_nullable
as String,isGeocoding: null == isGeocoding ? _self.isGeocoding : isGeocoding // ignore: cast_nullable_to_non_nullable
as bool,selectedLabel: null == selectedLabel ? _self.selectedLabel : selectedLabel // ignore: cast_nullable_to_non_nullable
as String,saveState: null == saveState ? _self.saveState : saveState // ignore: cast_nullable_to_non_nullable
as AsyncValue<CustomerAddressEntity?>,
  ));
}


}

// dart format on

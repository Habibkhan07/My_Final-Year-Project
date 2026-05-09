// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tech_location_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechLocationRequestModel {

 double get lat; double get lng;@JsonKey(name: 'accuracy_meters') double? get accuracyMeters; double? get heading;
/// Create a copy of TechLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechLocationRequestModelCopyWith<TechLocationRequestModel> get copyWith => _$TechLocationRequestModelCopyWithImpl<TechLocationRequestModel>(this as TechLocationRequestModel, _$identity);

  /// Serializes this TechLocationRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechLocationRequestModel&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyMeters,heading);

@override
String toString() {
  return 'TechLocationRequestModel(lat: $lat, lng: $lng, accuracyMeters: $accuracyMeters, heading: $heading)';
}


}

/// @nodoc
abstract mixin class $TechLocationRequestModelCopyWith<$Res>  {
  factory $TechLocationRequestModelCopyWith(TechLocationRequestModel value, $Res Function(TechLocationRequestModel) _then) = _$TechLocationRequestModelCopyWithImpl;
@useResult
$Res call({
 double lat, double lng,@JsonKey(name: 'accuracy_meters') double? accuracyMeters, double? heading
});




}
/// @nodoc
class _$TechLocationRequestModelCopyWithImpl<$Res>
    implements $TechLocationRequestModelCopyWith<$Res> {
  _$TechLocationRequestModelCopyWithImpl(this._self, this._then);

  final TechLocationRequestModel _self;
  final $Res Function(TechLocationRequestModel) _then;

/// Create a copy of TechLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? accuracyMeters = freezed,Object? heading = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TechLocationRequestModel].
extension TechLocationRequestModelPatterns on TechLocationRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechLocationRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechLocationRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechLocationRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _TechLocationRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechLocationRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechLocationRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechLocationRequestModel() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)  $default,) {final _that = this;
switch (_that) {
case _TechLocationRequestModel():
return $default(_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)?  $default,) {final _that = this;
switch (_that) {
case _TechLocationRequestModel() when $default != null:
return $default(_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechLocationRequestModel implements TechLocationRequestModel {
  const _TechLocationRequestModel({required this.lat, required this.lng, @JsonKey(name: 'accuracy_meters') this.accuracyMeters, this.heading});
  factory _TechLocationRequestModel.fromJson(Map<String, dynamic> json) => _$TechLocationRequestModelFromJson(json);

@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'accuracy_meters') final  double? accuracyMeters;
@override final  double? heading;

/// Create a copy of TechLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechLocationRequestModelCopyWith<_TechLocationRequestModel> get copyWith => __$TechLocationRequestModelCopyWithImpl<_TechLocationRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechLocationRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechLocationRequestModel&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,accuracyMeters,heading);

@override
String toString() {
  return 'TechLocationRequestModel(lat: $lat, lng: $lng, accuracyMeters: $accuracyMeters, heading: $heading)';
}


}

/// @nodoc
abstract mixin class _$TechLocationRequestModelCopyWith<$Res> implements $TechLocationRequestModelCopyWith<$Res> {
  factory _$TechLocationRequestModelCopyWith(_TechLocationRequestModel value, $Res Function(_TechLocationRequestModel) _then) = __$TechLocationRequestModelCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng,@JsonKey(name: 'accuracy_meters') double? accuracyMeters, double? heading
});




}
/// @nodoc
class __$TechLocationRequestModelCopyWithImpl<$Res>
    implements _$TechLocationRequestModelCopyWith<$Res> {
  __$TechLocationRequestModelCopyWithImpl(this._self, this._then);

  final _TechLocationRequestModel _self;
  final $Res Function(_TechLocationRequestModel) _then;

/// Create a copy of TechLocationRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? accuracyMeters = freezed,Object? heading = freezed,}) {
  return _then(_TechLocationRequestModel(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

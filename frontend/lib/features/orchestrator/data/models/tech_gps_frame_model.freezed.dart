// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tech_gps_frame_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechGpsFrameModel {

@JsonKey(name: 'booking_id') int get bookingId; double get lat; double get lng;@JsonKey(name: 'accuracy_meters') double? get accuracyMeters; double? get heading;
/// Create a copy of TechGpsFrameModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechGpsFrameModelCopyWith<TechGpsFrameModel> get copyWith => _$TechGpsFrameModelCopyWithImpl<TechGpsFrameModel>(this as TechGpsFrameModel, _$identity);

  /// Serializes this TechGpsFrameModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechGpsFrameModel&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,lat,lng,accuracyMeters,heading);

@override
String toString() {
  return 'TechGpsFrameModel(bookingId: $bookingId, lat: $lat, lng: $lng, accuracyMeters: $accuracyMeters, heading: $heading)';
}


}

/// @nodoc
abstract mixin class $TechGpsFrameModelCopyWith<$Res>  {
  factory $TechGpsFrameModelCopyWith(TechGpsFrameModel value, $Res Function(TechGpsFrameModel) _then) = _$TechGpsFrameModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'booking_id') int bookingId, double lat, double lng,@JsonKey(name: 'accuracy_meters') double? accuracyMeters, double? heading
});




}
/// @nodoc
class _$TechGpsFrameModelCopyWithImpl<$Res>
    implements $TechGpsFrameModelCopyWith<$Res> {
  _$TechGpsFrameModelCopyWithImpl(this._self, this._then);

  final TechGpsFrameModel _self;
  final $Res Function(TechGpsFrameModel) _then;

/// Create a copy of TechGpsFrameModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = null,Object? lat = null,Object? lng = null,Object? accuracyMeters = freezed,Object? heading = freezed,}) {
  return _then(_self.copyWith(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [TechGpsFrameModel].
extension TechGpsFrameModelPatterns on TechGpsFrameModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechGpsFrameModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechGpsFrameModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechGpsFrameModel value)  $default,){
final _that = this;
switch (_that) {
case _TechGpsFrameModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechGpsFrameModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechGpsFrameModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int bookingId,  double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechGpsFrameModel() when $default != null:
return $default(_that.bookingId,_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int bookingId,  double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)  $default,) {final _that = this;
switch (_that) {
case _TechGpsFrameModel():
return $default(_that.bookingId,_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'booking_id')  int bookingId,  double lat,  double lng, @JsonKey(name: 'accuracy_meters')  double? accuracyMeters,  double? heading)?  $default,) {final _that = this;
switch (_that) {
case _TechGpsFrameModel() when $default != null:
return $default(_that.bookingId,_that.lat,_that.lng,_that.accuracyMeters,_that.heading);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechGpsFrameModel implements TechGpsFrameModel {
  const _TechGpsFrameModel({@JsonKey(name: 'booking_id') required this.bookingId, required this.lat, required this.lng, @JsonKey(name: 'accuracy_meters') this.accuracyMeters, this.heading});
  factory _TechGpsFrameModel.fromJson(Map<String, dynamic> json) => _$TechGpsFrameModelFromJson(json);

@override@JsonKey(name: 'booking_id') final  int bookingId;
@override final  double lat;
@override final  double lng;
@override@JsonKey(name: 'accuracy_meters') final  double? accuracyMeters;
@override final  double? heading;

/// Create a copy of TechGpsFrameModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechGpsFrameModelCopyWith<_TechGpsFrameModel> get copyWith => __$TechGpsFrameModelCopyWithImpl<_TechGpsFrameModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechGpsFrameModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechGpsFrameModel&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId,lat,lng,accuracyMeters,heading);

@override
String toString() {
  return 'TechGpsFrameModel(bookingId: $bookingId, lat: $lat, lng: $lng, accuracyMeters: $accuracyMeters, heading: $heading)';
}


}

/// @nodoc
abstract mixin class _$TechGpsFrameModelCopyWith<$Res> implements $TechGpsFrameModelCopyWith<$Res> {
  factory _$TechGpsFrameModelCopyWith(_TechGpsFrameModel value, $Res Function(_TechGpsFrameModel) _then) = __$TechGpsFrameModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'booking_id') int bookingId, double lat, double lng,@JsonKey(name: 'accuracy_meters') double? accuracyMeters, double? heading
});




}
/// @nodoc
class __$TechGpsFrameModelCopyWithImpl<$Res>
    implements _$TechGpsFrameModelCopyWith<$Res> {
  __$TechGpsFrameModelCopyWithImpl(this._self, this._then);

  final _TechGpsFrameModel _self;
  final $Res Function(_TechGpsFrameModel) _then;

/// Create a copy of TechGpsFrameModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = null,Object? lat = null,Object? lng = null,Object? accuracyMeters = freezed,Object? heading = freezed,}) {
  return _then(_TechGpsFrameModel(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

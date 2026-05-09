// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tech_gps_frame.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechGpsFrame {

 int get bookingId; double get latitude; double get longitude;/// GPS reported accuracy in metres. Many handsets emit `null` for
/// indoor or low-quality fixes — accept and ignore.
 double? get accuracyMeters;/// GPS heading in degrees clockwise from north (0..360). Many
/// handsets emit `null` when stationary (0 m/s). The marker
/// rotation defaults to north when heading is null.
 double? get heading;/// Wall-clock instant when the frame arrived at this client. Used
/// for the 60-second "tech offline" staleness banner.
 DateTime get frameArrivedAt;
/// Create a copy of TechGpsFrame
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechGpsFrameCopyWith<TechGpsFrame> get copyWith => _$TechGpsFrameCopyWithImpl<TechGpsFrame>(this as TechGpsFrame, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechGpsFrame&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.frameArrivedAt, frameArrivedAt) || other.frameArrivedAt == frameArrivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,bookingId,latitude,longitude,accuracyMeters,heading,frameArrivedAt);

@override
String toString() {
  return 'TechGpsFrame(bookingId: $bookingId, latitude: $latitude, longitude: $longitude, accuracyMeters: $accuracyMeters, heading: $heading, frameArrivedAt: $frameArrivedAt)';
}


}

/// @nodoc
abstract mixin class $TechGpsFrameCopyWith<$Res>  {
  factory $TechGpsFrameCopyWith(TechGpsFrame value, $Res Function(TechGpsFrame) _then) = _$TechGpsFrameCopyWithImpl;
@useResult
$Res call({
 int bookingId, double latitude, double longitude, double? accuracyMeters, double? heading, DateTime frameArrivedAt
});




}
/// @nodoc
class _$TechGpsFrameCopyWithImpl<$Res>
    implements $TechGpsFrameCopyWith<$Res> {
  _$TechGpsFrameCopyWithImpl(this._self, this._then);

  final TechGpsFrame _self;
  final $Res Function(TechGpsFrame) _then;

/// Create a copy of TechGpsFrame
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = null,Object? latitude = null,Object? longitude = null,Object? accuracyMeters = freezed,Object? heading = freezed,Object? frameArrivedAt = null,}) {
  return _then(_self.copyWith(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,frameArrivedAt: null == frameArrivedAt ? _self.frameArrivedAt : frameArrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TechGpsFrame].
extension TechGpsFramePatterns on TechGpsFrame {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechGpsFrame value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechGpsFrame() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechGpsFrame value)  $default,){
final _that = this;
switch (_that) {
case _TechGpsFrame():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechGpsFrame value)?  $default,){
final _that = this;
switch (_that) {
case _TechGpsFrame() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bookingId,  double latitude,  double longitude,  double? accuracyMeters,  double? heading,  DateTime frameArrivedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechGpsFrame() when $default != null:
return $default(_that.bookingId,_that.latitude,_that.longitude,_that.accuracyMeters,_that.heading,_that.frameArrivedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bookingId,  double latitude,  double longitude,  double? accuracyMeters,  double? heading,  DateTime frameArrivedAt)  $default,) {final _that = this;
switch (_that) {
case _TechGpsFrame():
return $default(_that.bookingId,_that.latitude,_that.longitude,_that.accuracyMeters,_that.heading,_that.frameArrivedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bookingId,  double latitude,  double longitude,  double? accuracyMeters,  double? heading,  DateTime frameArrivedAt)?  $default,) {final _that = this;
switch (_that) {
case _TechGpsFrame() when $default != null:
return $default(_that.bookingId,_that.latitude,_that.longitude,_that.accuracyMeters,_that.heading,_that.frameArrivedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TechGpsFrame implements TechGpsFrame {
  const _TechGpsFrame({required this.bookingId, required this.latitude, required this.longitude, this.accuracyMeters, this.heading, required this.frameArrivedAt});
  

@override final  int bookingId;
@override final  double latitude;
@override final  double longitude;
/// GPS reported accuracy in metres. Many handsets emit `null` for
/// indoor or low-quality fixes — accept and ignore.
@override final  double? accuracyMeters;
/// GPS heading in degrees clockwise from north (0..360). Many
/// handsets emit `null` when stationary (0 m/s). The marker
/// rotation defaults to north when heading is null.
@override final  double? heading;
/// Wall-clock instant when the frame arrived at this client. Used
/// for the 60-second "tech offline" staleness banner.
@override final  DateTime frameArrivedAt;

/// Create a copy of TechGpsFrame
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechGpsFrameCopyWith<_TechGpsFrame> get copyWith => __$TechGpsFrameCopyWithImpl<_TechGpsFrame>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechGpsFrame&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.accuracyMeters, accuracyMeters) || other.accuracyMeters == accuracyMeters)&&(identical(other.heading, heading) || other.heading == heading)&&(identical(other.frameArrivedAt, frameArrivedAt) || other.frameArrivedAt == frameArrivedAt));
}


@override
int get hashCode => Object.hash(runtimeType,bookingId,latitude,longitude,accuracyMeters,heading,frameArrivedAt);

@override
String toString() {
  return 'TechGpsFrame(bookingId: $bookingId, latitude: $latitude, longitude: $longitude, accuracyMeters: $accuracyMeters, heading: $heading, frameArrivedAt: $frameArrivedAt)';
}


}

/// @nodoc
abstract mixin class _$TechGpsFrameCopyWith<$Res> implements $TechGpsFrameCopyWith<$Res> {
  factory _$TechGpsFrameCopyWith(_TechGpsFrame value, $Res Function(_TechGpsFrame) _then) = __$TechGpsFrameCopyWithImpl;
@override @useResult
$Res call({
 int bookingId, double latitude, double longitude, double? accuracyMeters, double? heading, DateTime frameArrivedAt
});




}
/// @nodoc
class __$TechGpsFrameCopyWithImpl<$Res>
    implements _$TechGpsFrameCopyWith<$Res> {
  __$TechGpsFrameCopyWithImpl(this._self, this._then);

  final _TechGpsFrame _self;
  final $Res Function(_TechGpsFrame) _then;

/// Create a copy of TechGpsFrame
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = null,Object? latitude = null,Object? longitude = null,Object? accuracyMeters = freezed,Object? heading = freezed,Object? frameArrivedAt = null,}) {
  return _then(_TechGpsFrame(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,accuracyMeters: freezed == accuracyMeters ? _self.accuracyMeters : accuracyMeters // ignore: cast_nullable_to_non_nullable
as double?,heading: freezed == heading ? _self.heading : heading // ignore: cast_nullable_to_non_nullable
as double?,frameArrivedAt: null == frameArrivedAt ? _self.frameArrivedAt : frameArrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

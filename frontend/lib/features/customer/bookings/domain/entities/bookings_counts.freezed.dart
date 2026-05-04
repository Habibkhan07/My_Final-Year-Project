// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookings_counts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingsCounts {

 int get upcoming; int get past; DateTime get serverTime;
/// Create a copy of BookingsCounts
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingsCountsCopyWith<BookingsCounts> get copyWith => _$BookingsCountsCopyWithImpl<BookingsCounts>(this as BookingsCounts, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingsCounts&&(identical(other.upcoming, upcoming) || other.upcoming == upcoming)&&(identical(other.past, past) || other.past == past)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}


@override
int get hashCode => Object.hash(runtimeType,upcoming,past,serverTime);

@override
String toString() {
  return 'BookingsCounts(upcoming: $upcoming, past: $past, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class $BookingsCountsCopyWith<$Res>  {
  factory $BookingsCountsCopyWith(BookingsCounts value, $Res Function(BookingsCounts) _then) = _$BookingsCountsCopyWithImpl;
@useResult
$Res call({
 int upcoming, int past, DateTime serverTime
});




}
/// @nodoc
class _$BookingsCountsCopyWithImpl<$Res>
    implements $BookingsCountsCopyWith<$Res> {
  _$BookingsCountsCopyWithImpl(this._self, this._then);

  final BookingsCounts _self;
  final $Res Function(BookingsCounts) _then;

/// Create a copy of BookingsCounts
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? upcoming = null,Object? past = null,Object? serverTime = null,}) {
  return _then(_self.copyWith(
upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingsCounts].
extension BookingsCountsPatterns on BookingsCounts {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingsCounts value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingsCounts() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingsCounts value)  $default,){
final _that = this;
switch (_that) {
case _BookingsCounts():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingsCounts value)?  $default,){
final _that = this;
switch (_that) {
case _BookingsCounts() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int upcoming,  int past,  DateTime serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingsCounts() when $default != null:
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int upcoming,  int past,  DateTime serverTime)  $default,) {final _that = this;
switch (_that) {
case _BookingsCounts():
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int upcoming,  int past,  DateTime serverTime)?  $default,) {final _that = this;
switch (_that) {
case _BookingsCounts() when $default != null:
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc


class _BookingsCounts implements BookingsCounts {
  const _BookingsCounts({required this.upcoming, required this.past, required this.serverTime});
  

@override final  int upcoming;
@override final  int past;
@override final  DateTime serverTime;

/// Create a copy of BookingsCounts
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingsCountsCopyWith<_BookingsCounts> get copyWith => __$BookingsCountsCopyWithImpl<_BookingsCounts>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingsCounts&&(identical(other.upcoming, upcoming) || other.upcoming == upcoming)&&(identical(other.past, past) || other.past == past)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}


@override
int get hashCode => Object.hash(runtimeType,upcoming,past,serverTime);

@override
String toString() {
  return 'BookingsCounts(upcoming: $upcoming, past: $past, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$BookingsCountsCopyWith<$Res> implements $BookingsCountsCopyWith<$Res> {
  factory _$BookingsCountsCopyWith(_BookingsCounts value, $Res Function(_BookingsCounts) _then) = __$BookingsCountsCopyWithImpl;
@override @useResult
$Res call({
 int upcoming, int past, DateTime serverTime
});




}
/// @nodoc
class __$BookingsCountsCopyWithImpl<$Res>
    implements _$BookingsCountsCopyWith<$Res> {
  __$BookingsCountsCopyWithImpl(this._self, this._then);

  final _BookingsCounts _self;
  final $Res Function(_BookingsCounts) _then;

/// Create a copy of BookingsCounts
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? upcoming = null,Object? past = null,Object? serverTime = null,}) {
  return _then(_BookingsCounts(
upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

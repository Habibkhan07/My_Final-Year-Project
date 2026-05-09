// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_phase_timestamps.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingPhaseTimestamps {

 DateTime? get acceptedAt; DateTime? get enRouteStartedAt; DateTime? get arrivedAt; DateTime? get inspectionStartedAt; DateTime? get quoteFirstSubmittedAt; DateTime? get workStartedAt; DateTime? get completedAt;
/// Create a copy of BookingPhaseTimestamps
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingPhaseTimestampsCopyWith<BookingPhaseTimestamps> get copyWith => _$BookingPhaseTimestampsCopyWithImpl<BookingPhaseTimestamps>(this as BookingPhaseTimestamps, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingPhaseTimestamps&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteStartedAt, enRouteStartedAt) || other.enRouteStartedAt == enRouteStartedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.inspectionStartedAt, inspectionStartedAt) || other.inspectionStartedAt == inspectionStartedAt)&&(identical(other.quoteFirstSubmittedAt, quoteFirstSubmittedAt) || other.quoteFirstSubmittedAt == quoteFirstSubmittedAt)&&(identical(other.workStartedAt, workStartedAt) || other.workStartedAt == workStartedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,acceptedAt,enRouteStartedAt,arrivedAt,inspectionStartedAt,quoteFirstSubmittedAt,workStartedAt,completedAt);

@override
String toString() {
  return 'BookingPhaseTimestamps(acceptedAt: $acceptedAt, enRouteStartedAt: $enRouteStartedAt, arrivedAt: $arrivedAt, inspectionStartedAt: $inspectionStartedAt, quoteFirstSubmittedAt: $quoteFirstSubmittedAt, workStartedAt: $workStartedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $BookingPhaseTimestampsCopyWith<$Res>  {
  factory $BookingPhaseTimestampsCopyWith(BookingPhaseTimestamps value, $Res Function(BookingPhaseTimestamps) _then) = _$BookingPhaseTimestampsCopyWithImpl;
@useResult
$Res call({
 DateTime? acceptedAt, DateTime? enRouteStartedAt, DateTime? arrivedAt, DateTime? inspectionStartedAt, DateTime? quoteFirstSubmittedAt, DateTime? workStartedAt, DateTime? completedAt
});




}
/// @nodoc
class _$BookingPhaseTimestampsCopyWithImpl<$Res>
    implements $BookingPhaseTimestampsCopyWith<$Res> {
  _$BookingPhaseTimestampsCopyWithImpl(this._self, this._then);

  final BookingPhaseTimestamps _self;
  final $Res Function(BookingPhaseTimestamps) _then;

/// Create a copy of BookingPhaseTimestamps
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acceptedAt = freezed,Object? enRouteStartedAt = freezed,Object? arrivedAt = freezed,Object? inspectionStartedAt = freezed,Object? quoteFirstSubmittedAt = freezed,Object? workStartedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,enRouteStartedAt: freezed == enRouteStartedAt ? _self.enRouteStartedAt : enRouteStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inspectionStartedAt: freezed == inspectionStartedAt ? _self.inspectionStartedAt : inspectionStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quoteFirstSubmittedAt: freezed == quoteFirstSubmittedAt ? _self.quoteFirstSubmittedAt : quoteFirstSubmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,workStartedAt: freezed == workStartedAt ? _self.workStartedAt : workStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingPhaseTimestamps].
extension BookingPhaseTimestampsPatterns on BookingPhaseTimestamps {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingPhaseTimestamps value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingPhaseTimestamps() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingPhaseTimestamps value)  $default,){
final _that = this;
switch (_that) {
case _BookingPhaseTimestamps():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingPhaseTimestamps value)?  $default,){
final _that = this;
switch (_that) {
case _BookingPhaseTimestamps() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? acceptedAt,  DateTime? enRouteStartedAt,  DateTime? arrivedAt,  DateTime? inspectionStartedAt,  DateTime? quoteFirstSubmittedAt,  DateTime? workStartedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingPhaseTimestamps() when $default != null:
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? acceptedAt,  DateTime? enRouteStartedAt,  DateTime? arrivedAt,  DateTime? inspectionStartedAt,  DateTime? quoteFirstSubmittedAt,  DateTime? workStartedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _BookingPhaseTimestamps():
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? acceptedAt,  DateTime? enRouteStartedAt,  DateTime? arrivedAt,  DateTime? inspectionStartedAt,  DateTime? quoteFirstSubmittedAt,  DateTime? workStartedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingPhaseTimestamps() when $default != null:
return $default(_that.acceptedAt,_that.enRouteStartedAt,_that.arrivedAt,_that.inspectionStartedAt,_that.quoteFirstSubmittedAt,_that.workStartedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BookingPhaseTimestamps implements BookingPhaseTimestamps {
  const _BookingPhaseTimestamps({this.acceptedAt, this.enRouteStartedAt, this.arrivedAt, this.inspectionStartedAt, this.quoteFirstSubmittedAt, this.workStartedAt, this.completedAt});
  

@override final  DateTime? acceptedAt;
@override final  DateTime? enRouteStartedAt;
@override final  DateTime? arrivedAt;
@override final  DateTime? inspectionStartedAt;
@override final  DateTime? quoteFirstSubmittedAt;
@override final  DateTime? workStartedAt;
@override final  DateTime? completedAt;

/// Create a copy of BookingPhaseTimestamps
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingPhaseTimestampsCopyWith<_BookingPhaseTimestamps> get copyWith => __$BookingPhaseTimestampsCopyWithImpl<_BookingPhaseTimestamps>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingPhaseTimestamps&&(identical(other.acceptedAt, acceptedAt) || other.acceptedAt == acceptedAt)&&(identical(other.enRouteStartedAt, enRouteStartedAt) || other.enRouteStartedAt == enRouteStartedAt)&&(identical(other.arrivedAt, arrivedAt) || other.arrivedAt == arrivedAt)&&(identical(other.inspectionStartedAt, inspectionStartedAt) || other.inspectionStartedAt == inspectionStartedAt)&&(identical(other.quoteFirstSubmittedAt, quoteFirstSubmittedAt) || other.quoteFirstSubmittedAt == quoteFirstSubmittedAt)&&(identical(other.workStartedAt, workStartedAt) || other.workStartedAt == workStartedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,acceptedAt,enRouteStartedAt,arrivedAt,inspectionStartedAt,quoteFirstSubmittedAt,workStartedAt,completedAt);

@override
String toString() {
  return 'BookingPhaseTimestamps(acceptedAt: $acceptedAt, enRouteStartedAt: $enRouteStartedAt, arrivedAt: $arrivedAt, inspectionStartedAt: $inspectionStartedAt, quoteFirstSubmittedAt: $quoteFirstSubmittedAt, workStartedAt: $workStartedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingPhaseTimestampsCopyWith<$Res> implements $BookingPhaseTimestampsCopyWith<$Res> {
  factory _$BookingPhaseTimestampsCopyWith(_BookingPhaseTimestamps value, $Res Function(_BookingPhaseTimestamps) _then) = __$BookingPhaseTimestampsCopyWithImpl;
@override @useResult
$Res call({
 DateTime? acceptedAt, DateTime? enRouteStartedAt, DateTime? arrivedAt, DateTime? inspectionStartedAt, DateTime? quoteFirstSubmittedAt, DateTime? workStartedAt, DateTime? completedAt
});




}
/// @nodoc
class __$BookingPhaseTimestampsCopyWithImpl<$Res>
    implements _$BookingPhaseTimestampsCopyWith<$Res> {
  __$BookingPhaseTimestampsCopyWithImpl(this._self, this._then);

  final _BookingPhaseTimestamps _self;
  final $Res Function(_BookingPhaseTimestamps) _then;

/// Create a copy of BookingPhaseTimestamps
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acceptedAt = freezed,Object? enRouteStartedAt = freezed,Object? arrivedAt = freezed,Object? inspectionStartedAt = freezed,Object? quoteFirstSubmittedAt = freezed,Object? workStartedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_BookingPhaseTimestamps(
acceptedAt: freezed == acceptedAt ? _self.acceptedAt : acceptedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,enRouteStartedAt: freezed == enRouteStartedAt ? _self.enRouteStartedAt : enRouteStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,arrivedAt: freezed == arrivedAt ? _self.arrivedAt : arrivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,inspectionStartedAt: freezed == inspectionStartedAt ? _self.inspectionStartedAt : inspectionStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,quoteFirstSubmittedAt: freezed == quoteFirstSubmittedAt ? _self.quoteFirstSubmittedAt : quoteFirstSubmittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,workStartedAt: freezed == workStartedAt ? _self.workStartedAt : workStartedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

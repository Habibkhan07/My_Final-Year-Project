// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_metrics_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianMetricsEntity {

 int get jobsCompletedToday; double get cashCollectedToday; double get commissionDeductedToday; int get jobsCompletedThisWeek; double get cashCollectedThisWeek;
/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianMetricsEntityCopyWith<TechnicianMetricsEntity> get copyWith => _$TechnicianMetricsEntityCopyWithImpl<TechnicianMetricsEntity>(this as TechnicianMetricsEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianMetricsEntity&&(identical(other.jobsCompletedToday, jobsCompletedToday) || other.jobsCompletedToday == jobsCompletedToday)&&(identical(other.cashCollectedToday, cashCollectedToday) || other.cashCollectedToday == cashCollectedToday)&&(identical(other.commissionDeductedToday, commissionDeductedToday) || other.commissionDeductedToday == commissionDeductedToday)&&(identical(other.jobsCompletedThisWeek, jobsCompletedThisWeek) || other.jobsCompletedThisWeek == jobsCompletedThisWeek)&&(identical(other.cashCollectedThisWeek, cashCollectedThisWeek) || other.cashCollectedThisWeek == cashCollectedThisWeek));
}


@override
int get hashCode => Object.hash(runtimeType,jobsCompletedToday,cashCollectedToday,commissionDeductedToday,jobsCompletedThisWeek,cashCollectedThisWeek);

@override
String toString() {
  return 'TechnicianMetricsEntity(jobsCompletedToday: $jobsCompletedToday, cashCollectedToday: $cashCollectedToday, commissionDeductedToday: $commissionDeductedToday, jobsCompletedThisWeek: $jobsCompletedThisWeek, cashCollectedThisWeek: $cashCollectedThisWeek)';
}


}

/// @nodoc
abstract mixin class $TechnicianMetricsEntityCopyWith<$Res>  {
  factory $TechnicianMetricsEntityCopyWith(TechnicianMetricsEntity value, $Res Function(TechnicianMetricsEntity) _then) = _$TechnicianMetricsEntityCopyWithImpl;
@useResult
$Res call({
 int jobsCompletedToday, double cashCollectedToday, double commissionDeductedToday, int jobsCompletedThisWeek, double cashCollectedThisWeek
});




}
/// @nodoc
class _$TechnicianMetricsEntityCopyWithImpl<$Res>
    implements $TechnicianMetricsEntityCopyWith<$Res> {
  _$TechnicianMetricsEntityCopyWithImpl(this._self, this._then);

  final TechnicianMetricsEntity _self;
  final $Res Function(TechnicianMetricsEntity) _then;

/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobsCompletedToday = null,Object? cashCollectedToday = null,Object? commissionDeductedToday = null,Object? jobsCompletedThisWeek = null,Object? cashCollectedThisWeek = null,}) {
  return _then(_self.copyWith(
jobsCompletedToday: null == jobsCompletedToday ? _self.jobsCompletedToday : jobsCompletedToday // ignore: cast_nullable_to_non_nullable
as int,cashCollectedToday: null == cashCollectedToday ? _self.cashCollectedToday : cashCollectedToday // ignore: cast_nullable_to_non_nullable
as double,commissionDeductedToday: null == commissionDeductedToday ? _self.commissionDeductedToday : commissionDeductedToday // ignore: cast_nullable_to_non_nullable
as double,jobsCompletedThisWeek: null == jobsCompletedThisWeek ? _self.jobsCompletedThisWeek : jobsCompletedThisWeek // ignore: cast_nullable_to_non_nullable
as int,cashCollectedThisWeek: null == cashCollectedThisWeek ? _self.cashCollectedThisWeek : cashCollectedThisWeek // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianMetricsEntity].
extension TechnicianMetricsEntityPatterns on TechnicianMetricsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianMetricsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianMetricsEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianMetricsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jobsCompletedToday,  double cashCollectedToday,  double commissionDeductedToday,  int jobsCompletedThisWeek,  double cashCollectedThisWeek)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
return $default(_that.jobsCompletedToday,_that.cashCollectedToday,_that.commissionDeductedToday,_that.jobsCompletedThisWeek,_that.cashCollectedThisWeek);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jobsCompletedToday,  double cashCollectedToday,  double commissionDeductedToday,  int jobsCompletedThisWeek,  double cashCollectedThisWeek)  $default,) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity():
return $default(_that.jobsCompletedToday,_that.cashCollectedToday,_that.commissionDeductedToday,_that.jobsCompletedThisWeek,_that.cashCollectedThisWeek);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jobsCompletedToday,  double cashCollectedToday,  double commissionDeductedToday,  int jobsCompletedThisWeek,  double cashCollectedThisWeek)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
return $default(_that.jobsCompletedToday,_that.cashCollectedToday,_that.commissionDeductedToday,_that.jobsCompletedThisWeek,_that.cashCollectedThisWeek);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianMetricsEntity implements TechnicianMetricsEntity {
  const _TechnicianMetricsEntity({required this.jobsCompletedToday, required this.cashCollectedToday, required this.commissionDeductedToday, required this.jobsCompletedThisWeek, required this.cashCollectedThisWeek});
  

@override final  int jobsCompletedToday;
@override final  double cashCollectedToday;
@override final  double commissionDeductedToday;
@override final  int jobsCompletedThisWeek;
@override final  double cashCollectedThisWeek;

/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianMetricsEntityCopyWith<_TechnicianMetricsEntity> get copyWith => __$TechnicianMetricsEntityCopyWithImpl<_TechnicianMetricsEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianMetricsEntity&&(identical(other.jobsCompletedToday, jobsCompletedToday) || other.jobsCompletedToday == jobsCompletedToday)&&(identical(other.cashCollectedToday, cashCollectedToday) || other.cashCollectedToday == cashCollectedToday)&&(identical(other.commissionDeductedToday, commissionDeductedToday) || other.commissionDeductedToday == commissionDeductedToday)&&(identical(other.jobsCompletedThisWeek, jobsCompletedThisWeek) || other.jobsCompletedThisWeek == jobsCompletedThisWeek)&&(identical(other.cashCollectedThisWeek, cashCollectedThisWeek) || other.cashCollectedThisWeek == cashCollectedThisWeek));
}


@override
int get hashCode => Object.hash(runtimeType,jobsCompletedToday,cashCollectedToday,commissionDeductedToday,jobsCompletedThisWeek,cashCollectedThisWeek);

@override
String toString() {
  return 'TechnicianMetricsEntity(jobsCompletedToday: $jobsCompletedToday, cashCollectedToday: $cashCollectedToday, commissionDeductedToday: $commissionDeductedToday, jobsCompletedThisWeek: $jobsCompletedThisWeek, cashCollectedThisWeek: $cashCollectedThisWeek)';
}


}

/// @nodoc
abstract mixin class _$TechnicianMetricsEntityCopyWith<$Res> implements $TechnicianMetricsEntityCopyWith<$Res> {
  factory _$TechnicianMetricsEntityCopyWith(_TechnicianMetricsEntity value, $Res Function(_TechnicianMetricsEntity) _then) = __$TechnicianMetricsEntityCopyWithImpl;
@override @useResult
$Res call({
 int jobsCompletedToday, double cashCollectedToday, double commissionDeductedToday, int jobsCompletedThisWeek, double cashCollectedThisWeek
});




}
/// @nodoc
class __$TechnicianMetricsEntityCopyWithImpl<$Res>
    implements _$TechnicianMetricsEntityCopyWith<$Res> {
  __$TechnicianMetricsEntityCopyWithImpl(this._self, this._then);

  final _TechnicianMetricsEntity _self;
  final $Res Function(_TechnicianMetricsEntity) _then;

/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobsCompletedToday = null,Object? cashCollectedToday = null,Object? commissionDeductedToday = null,Object? jobsCompletedThisWeek = null,Object? cashCollectedThisWeek = null,}) {
  return _then(_TechnicianMetricsEntity(
jobsCompletedToday: null == jobsCompletedToday ? _self.jobsCompletedToday : jobsCompletedToday // ignore: cast_nullable_to_non_nullable
as int,cashCollectedToday: null == cashCollectedToday ? _self.cashCollectedToday : cashCollectedToday // ignore: cast_nullable_to_non_nullable
as double,commissionDeductedToday: null == commissionDeductedToday ? _self.commissionDeductedToday : commissionDeductedToday // ignore: cast_nullable_to_non_nullable
as double,jobsCompletedThisWeek: null == jobsCompletedThisWeek ? _self.jobsCompletedThisWeek : jobsCompletedThisWeek // ignore: cast_nullable_to_non_nullable
as int,cashCollectedThisWeek: null == cashCollectedThisWeek ? _self.cashCollectedThisWeek : cashCollectedThisWeek // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_dashboard_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianDashboardState {

 TechnicianDashboardEntity get dashboard; AsyncValue<void> get toggleStatus;
/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianDashboardStateCopyWith<TechnicianDashboardState> get copyWith => _$TechnicianDashboardStateCopyWithImpl<TechnicianDashboardState>(this as TechnicianDashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianDashboardState&&(identical(other.dashboard, dashboard) || other.dashboard == dashboard)&&(identical(other.toggleStatus, toggleStatus) || other.toggleStatus == toggleStatus));
}


@override
int get hashCode => Object.hash(runtimeType,dashboard,toggleStatus);

@override
String toString() {
  return 'TechnicianDashboardState(dashboard: $dashboard, toggleStatus: $toggleStatus)';
}


}

/// @nodoc
abstract mixin class $TechnicianDashboardStateCopyWith<$Res>  {
  factory $TechnicianDashboardStateCopyWith(TechnicianDashboardState value, $Res Function(TechnicianDashboardState) _then) = _$TechnicianDashboardStateCopyWithImpl;
@useResult
$Res call({
 TechnicianDashboardEntity dashboard, AsyncValue<void> toggleStatus
});


$TechnicianDashboardEntityCopyWith<$Res> get dashboard;

}
/// @nodoc
class _$TechnicianDashboardStateCopyWithImpl<$Res>
    implements $TechnicianDashboardStateCopyWith<$Res> {
  _$TechnicianDashboardStateCopyWithImpl(this._self, this._then);

  final TechnicianDashboardState _self;
  final $Res Function(TechnicianDashboardState) _then;

/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dashboard = null,Object? toggleStatus = null,}) {
  return _then(_self.copyWith(
dashboard: null == dashboard ? _self.dashboard : dashboard // ignore: cast_nullable_to_non_nullable
as TechnicianDashboardEntity,toggleStatus: null == toggleStatus ? _self.toggleStatus : toggleStatus // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}
/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TechnicianDashboardEntityCopyWith<$Res> get dashboard {
  
  return $TechnicianDashboardEntityCopyWith<$Res>(_self.dashboard, (value) {
    return _then(_self.copyWith(dashboard: value));
  });
}
}


/// Adds pattern-matching-related methods to [TechnicianDashboardState].
extension TechnicianDashboardStatePatterns on TechnicianDashboardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianDashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianDashboardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianDashboardState value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianDashboardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianDashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianDashboardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TechnicianDashboardEntity dashboard,  AsyncValue<void> toggleStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianDashboardState() when $default != null:
return $default(_that.dashboard,_that.toggleStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TechnicianDashboardEntity dashboard,  AsyncValue<void> toggleStatus)  $default,) {final _that = this;
switch (_that) {
case _TechnicianDashboardState():
return $default(_that.dashboard,_that.toggleStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TechnicianDashboardEntity dashboard,  AsyncValue<void> toggleStatus)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianDashboardState() when $default != null:
return $default(_that.dashboard,_that.toggleStatus);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianDashboardState implements TechnicianDashboardState {
  const _TechnicianDashboardState({required this.dashboard, this.toggleStatus = const AsyncValue.data(null)});
  

@override final  TechnicianDashboardEntity dashboard;
@override@JsonKey() final  AsyncValue<void> toggleStatus;

/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianDashboardStateCopyWith<_TechnicianDashboardState> get copyWith => __$TechnicianDashboardStateCopyWithImpl<_TechnicianDashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianDashboardState&&(identical(other.dashboard, dashboard) || other.dashboard == dashboard)&&(identical(other.toggleStatus, toggleStatus) || other.toggleStatus == toggleStatus));
}


@override
int get hashCode => Object.hash(runtimeType,dashboard,toggleStatus);

@override
String toString() {
  return 'TechnicianDashboardState(dashboard: $dashboard, toggleStatus: $toggleStatus)';
}


}

/// @nodoc
abstract mixin class _$TechnicianDashboardStateCopyWith<$Res> implements $TechnicianDashboardStateCopyWith<$Res> {
  factory _$TechnicianDashboardStateCopyWith(_TechnicianDashboardState value, $Res Function(_TechnicianDashboardState) _then) = __$TechnicianDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 TechnicianDashboardEntity dashboard, AsyncValue<void> toggleStatus
});


@override $TechnicianDashboardEntityCopyWith<$Res> get dashboard;

}
/// @nodoc
class __$TechnicianDashboardStateCopyWithImpl<$Res>
    implements _$TechnicianDashboardStateCopyWith<$Res> {
  __$TechnicianDashboardStateCopyWithImpl(this._self, this._then);

  final _TechnicianDashboardState _self;
  final $Res Function(_TechnicianDashboardState) _then;

/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dashboard = null,Object? toggleStatus = null,}) {
  return _then(_TechnicianDashboardState(
dashboard: null == dashboard ? _self.dashboard : dashboard // ignore: cast_nullable_to_non_nullable
as TechnicianDashboardEntity,toggleStatus: null == toggleStatus ? _self.toggleStatus : toggleStatus // ignore: cast_nullable_to_non_nullable
as AsyncValue<void>,
  ));
}

/// Create a copy of TechnicianDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TechnicianDashboardEntityCopyWith<$Res> get dashboard {
  
  return $TechnicianDashboardEntityCopyWith<$Res>(_self.dashboard, (value) {
    return _then(_self.copyWith(dashboard: value));
  });
}
}

// dart format on

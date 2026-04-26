// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_event_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SystemEventState {

 SystemEventEntity? get latestEvent; Map<String, DateTime> get processedEventIds; DateTime? get lastSyncTimestamp;
/// Create a copy of SystemEventState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemEventStateCopyWith<SystemEventState> get copyWith => _$SystemEventStateCopyWithImpl<SystemEventState>(this as SystemEventState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemEventState&&(identical(other.latestEvent, latestEvent) || other.latestEvent == latestEvent)&&const DeepCollectionEquality().equals(other.processedEventIds, processedEventIds)&&(identical(other.lastSyncTimestamp, lastSyncTimestamp) || other.lastSyncTimestamp == lastSyncTimestamp));
}


@override
int get hashCode => Object.hash(runtimeType,latestEvent,const DeepCollectionEquality().hash(processedEventIds),lastSyncTimestamp);

@override
String toString() {
  return 'SystemEventState(latestEvent: $latestEvent, processedEventIds: $processedEventIds, lastSyncTimestamp: $lastSyncTimestamp)';
}


}

/// @nodoc
abstract mixin class $SystemEventStateCopyWith<$Res>  {
  factory $SystemEventStateCopyWith(SystemEventState value, $Res Function(SystemEventState) _then) = _$SystemEventStateCopyWithImpl;
@useResult
$Res call({
 SystemEventEntity? latestEvent, Map<String, DateTime> processedEventIds, DateTime? lastSyncTimestamp
});




}
/// @nodoc
class _$SystemEventStateCopyWithImpl<$Res>
    implements $SystemEventStateCopyWith<$Res> {
  _$SystemEventStateCopyWithImpl(this._self, this._then);

  final SystemEventState _self;
  final $Res Function(SystemEventState) _then;

/// Create a copy of SystemEventState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latestEvent = freezed,Object? processedEventIds = null,Object? lastSyncTimestamp = freezed,}) {
  return _then(_self.copyWith(
latestEvent: freezed == latestEvent ? _self.latestEvent : latestEvent // ignore: cast_nullable_to_non_nullable
as SystemEventEntity?,processedEventIds: null == processedEventIds ? _self.processedEventIds : processedEventIds // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,lastSyncTimestamp: freezed == lastSyncTimestamp ? _self.lastSyncTimestamp : lastSyncTimestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemEventState].
extension SystemEventStatePatterns on SystemEventState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemEventState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemEventState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemEventState value)  $default,){
final _that = this;
switch (_that) {
case _SystemEventState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemEventState value)?  $default,){
final _that = this;
switch (_that) {
case _SystemEventState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SystemEventEntity? latestEvent,  Map<String, DateTime> processedEventIds,  DateTime? lastSyncTimestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemEventState() when $default != null:
return $default(_that.latestEvent,_that.processedEventIds,_that.lastSyncTimestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SystemEventEntity? latestEvent,  Map<String, DateTime> processedEventIds,  DateTime? lastSyncTimestamp)  $default,) {final _that = this;
switch (_that) {
case _SystemEventState():
return $default(_that.latestEvent,_that.processedEventIds,_that.lastSyncTimestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SystemEventEntity? latestEvent,  Map<String, DateTime> processedEventIds,  DateTime? lastSyncTimestamp)?  $default,) {final _that = this;
switch (_that) {
case _SystemEventState() when $default != null:
return $default(_that.latestEvent,_that.processedEventIds,_that.lastSyncTimestamp);case _:
  return null;

}
}

}

/// @nodoc


class _SystemEventState implements SystemEventState {
  const _SystemEventState({this.latestEvent, final  Map<String, DateTime> processedEventIds = const <String, DateTime>{}, this.lastSyncTimestamp}): _processedEventIds = processedEventIds;
  

@override final  SystemEventEntity? latestEvent;
 final  Map<String, DateTime> _processedEventIds;
@override@JsonKey() Map<String, DateTime> get processedEventIds {
  if (_processedEventIds is EqualUnmodifiableMapView) return _processedEventIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_processedEventIds);
}

@override final  DateTime? lastSyncTimestamp;

/// Create a copy of SystemEventState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemEventStateCopyWith<_SystemEventState> get copyWith => __$SystemEventStateCopyWithImpl<_SystemEventState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemEventState&&(identical(other.latestEvent, latestEvent) || other.latestEvent == latestEvent)&&const DeepCollectionEquality().equals(other._processedEventIds, _processedEventIds)&&(identical(other.lastSyncTimestamp, lastSyncTimestamp) || other.lastSyncTimestamp == lastSyncTimestamp));
}


@override
int get hashCode => Object.hash(runtimeType,latestEvent,const DeepCollectionEquality().hash(_processedEventIds),lastSyncTimestamp);

@override
String toString() {
  return 'SystemEventState(latestEvent: $latestEvent, processedEventIds: $processedEventIds, lastSyncTimestamp: $lastSyncTimestamp)';
}


}

/// @nodoc
abstract mixin class _$SystemEventStateCopyWith<$Res> implements $SystemEventStateCopyWith<$Res> {
  factory _$SystemEventStateCopyWith(_SystemEventState value, $Res Function(_SystemEventState) _then) = __$SystemEventStateCopyWithImpl;
@override @useResult
$Res call({
 SystemEventEntity? latestEvent, Map<String, DateTime> processedEventIds, DateTime? lastSyncTimestamp
});




}
/// @nodoc
class __$SystemEventStateCopyWithImpl<$Res>
    implements _$SystemEventStateCopyWith<$Res> {
  __$SystemEventStateCopyWithImpl(this._self, this._then);

  final _SystemEventState _self;
  final $Res Function(_SystemEventState) _then;

/// Create a copy of SystemEventState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latestEvent = freezed,Object? processedEventIds = null,Object? lastSyncTimestamp = freezed,}) {
  return _then(_SystemEventState(
latestEvent: freezed == latestEvent ? _self.latestEvent : latestEvent // ignore: cast_nullable_to_non_nullable
as SystemEventEntity?,processedEventIds: null == processedEventIds ? _self._processedEventIds : processedEventIds // ignore: cast_nullable_to_non_nullable
as Map<String, DateTime>,lastSyncTimestamp: freezed == lastSyncTimestamp ? _self.lastSyncTimestamp : lastSyncTimestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

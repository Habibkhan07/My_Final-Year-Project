// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incoming_job_queue_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IncomingJobQueueState {

 List<JobNewRequest> get queue;
/// Create a copy of IncomingJobQueueState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingJobQueueStateCopyWith<IncomingJobQueueState> get copyWith => _$IncomingJobQueueStateCopyWithImpl<IncomingJobQueueState>(this as IncomingJobQueueState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingJobQueueState&&const DeepCollectionEquality().equals(other.queue, queue));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(queue));

@override
String toString() {
  return 'IncomingJobQueueState(queue: $queue)';
}


}

/// @nodoc
abstract mixin class $IncomingJobQueueStateCopyWith<$Res>  {
  factory $IncomingJobQueueStateCopyWith(IncomingJobQueueState value, $Res Function(IncomingJobQueueState) _then) = _$IncomingJobQueueStateCopyWithImpl;
@useResult
$Res call({
 List<JobNewRequest> queue
});




}
/// @nodoc
class _$IncomingJobQueueStateCopyWithImpl<$Res>
    implements $IncomingJobQueueStateCopyWith<$Res> {
  _$IncomingJobQueueStateCopyWithImpl(this._self, this._then);

  final IncomingJobQueueState _self;
  final $Res Function(IncomingJobQueueState) _then;

/// Create a copy of IncomingJobQueueState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? queue = null,}) {
  return _then(_self.copyWith(
queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<JobNewRequest>,
  ));
}

}


/// Adds pattern-matching-related methods to [IncomingJobQueueState].
extension IncomingJobQueueStatePatterns on IncomingJobQueueState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomingJobQueueState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomingJobQueueState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomingJobQueueState value)  $default,){
final _that = this;
switch (_that) {
case _IncomingJobQueueState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomingJobQueueState value)?  $default,){
final _that = this;
switch (_that) {
case _IncomingJobQueueState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<JobNewRequest> queue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingJobQueueState() when $default != null:
return $default(_that.queue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<JobNewRequest> queue)  $default,) {final _that = this;
switch (_that) {
case _IncomingJobQueueState():
return $default(_that.queue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<JobNewRequest> queue)?  $default,) {final _that = this;
switch (_that) {
case _IncomingJobQueueState() when $default != null:
return $default(_that.queue);case _:
  return null;

}
}

}

/// @nodoc


class _IncomingJobQueueState implements IncomingJobQueueState {
  const _IncomingJobQueueState({final  List<JobNewRequest> queue = const <JobNewRequest>[]}): _queue = queue;
  

 final  List<JobNewRequest> _queue;
@override@JsonKey() List<JobNewRequest> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}


/// Create a copy of IncomingJobQueueState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomingJobQueueStateCopyWith<_IncomingJobQueueState> get copyWith => __$IncomingJobQueueStateCopyWithImpl<_IncomingJobQueueState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingJobQueueState&&const DeepCollectionEquality().equals(other._queue, _queue));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_queue));

@override
String toString() {
  return 'IncomingJobQueueState(queue: $queue)';
}


}

/// @nodoc
abstract mixin class _$IncomingJobQueueStateCopyWith<$Res> implements $IncomingJobQueueStateCopyWith<$Res> {
  factory _$IncomingJobQueueStateCopyWith(_IncomingJobQueueState value, $Res Function(_IncomingJobQueueState) _then) = __$IncomingJobQueueStateCopyWithImpl;
@override @useResult
$Res call({
 List<JobNewRequest> queue
});




}
/// @nodoc
class __$IncomingJobQueueStateCopyWithImpl<$Res>
    implements _$IncomingJobQueueStateCopyWith<$Res> {
  __$IncomingJobQueueStateCopyWithImpl(this._self, this._then);

  final _IncomingJobQueueState _self;
  final $Res Function(_IncomingJobQueueState) _then;

/// Create a copy of IncomingJobQueueState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? queue = null,}) {
  return _then(_IncomingJobQueueState(
queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<JobNewRequest>,
  ));
}


}

// dart format on

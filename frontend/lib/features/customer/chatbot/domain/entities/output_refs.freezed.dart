// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'output_refs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutputRefs {

 int get ticketId;
/// Create a copy of OutputRefs
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutputRefsCopyWith<OutputRefs> get copyWith => _$OutputRefsCopyWithImpl<OutputRefs>(this as OutputRefs, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutputRefs&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId));
}


@override
int get hashCode => Object.hash(runtimeType,ticketId);

@override
String toString() {
  return 'OutputRefs(ticketId: $ticketId)';
}


}

/// @nodoc
abstract mixin class $OutputRefsCopyWith<$Res>  {
  factory $OutputRefsCopyWith(OutputRefs value, $Res Function(OutputRefs) _then) = _$OutputRefsCopyWithImpl;
@useResult
$Res call({
 int ticketId
});




}
/// @nodoc
class _$OutputRefsCopyWithImpl<$Res>
    implements $OutputRefsCopyWith<$Res> {
  _$OutputRefsCopyWithImpl(this._self, this._then);

  final OutputRefs _self;
  final $Res Function(OutputRefs) _then;

/// Create a copy of OutputRefs
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticketId = null,}) {
  return _then(_self.copyWith(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OutputRefs].
extension OutputRefsPatterns on OutputRefs {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutputRefs value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutputRefs() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutputRefs value)  $default,){
final _that = this;
switch (_that) {
case _OutputRefs():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutputRefs value)?  $default,){
final _that = this;
switch (_that) {
case _OutputRefs() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int ticketId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutputRefs() when $default != null:
return $default(_that.ticketId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int ticketId)  $default,) {final _that = this;
switch (_that) {
case _OutputRefs():
return $default(_that.ticketId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int ticketId)?  $default,) {final _that = this;
switch (_that) {
case _OutputRefs() when $default != null:
return $default(_that.ticketId);case _:
  return null;

}
}

}

/// @nodoc


class _OutputRefs implements OutputRefs {
  const _OutputRefs({required this.ticketId});
  

@override final  int ticketId;

/// Create a copy of OutputRefs
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutputRefsCopyWith<_OutputRefs> get copyWith => __$OutputRefsCopyWithImpl<_OutputRefs>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutputRefs&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId));
}


@override
int get hashCode => Object.hash(runtimeType,ticketId);

@override
String toString() {
  return 'OutputRefs(ticketId: $ticketId)';
}


}

/// @nodoc
abstract mixin class _$OutputRefsCopyWith<$Res> implements $OutputRefsCopyWith<$Res> {
  factory _$OutputRefsCopyWith(_OutputRefs value, $Res Function(_OutputRefs) _then) = __$OutputRefsCopyWithImpl;
@override @useResult
$Res call({
 int ticketId
});




}
/// @nodoc
class __$OutputRefsCopyWithImpl<$Res>
    implements _$OutputRefsCopyWith<$Res> {
  __$OutputRefsCopyWithImpl(this._self, this._then);

  final _OutputRefs _self;
  final $Res Function(_OutputRefs) _then;

/// Create a copy of OutputRefs
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticketId = null,}) {
  return _then(_OutputRefs(
ticketId: null == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

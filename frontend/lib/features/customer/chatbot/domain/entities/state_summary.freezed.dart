// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StateSummary {

 ChatPhase get phase; int get attachmentsCount; Map<String, dynamic> get capturedFields;
/// Create a copy of StateSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateSummaryCopyWith<StateSummary> get copyWith => _$StateSummaryCopyWithImpl<StateSummary>(this as StateSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateSummary&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount)&&const DeepCollectionEquality().equals(other.capturedFields, capturedFields));
}


@override
int get hashCode => Object.hash(runtimeType,phase,attachmentsCount,const DeepCollectionEquality().hash(capturedFields));

@override
String toString() {
  return 'StateSummary(phase: $phase, attachmentsCount: $attachmentsCount, capturedFields: $capturedFields)';
}


}

/// @nodoc
abstract mixin class $StateSummaryCopyWith<$Res>  {
  factory $StateSummaryCopyWith(StateSummary value, $Res Function(StateSummary) _then) = _$StateSummaryCopyWithImpl;
@useResult
$Res call({
 ChatPhase phase, int attachmentsCount, Map<String, dynamic> capturedFields
});




}
/// @nodoc
class _$StateSummaryCopyWithImpl<$Res>
    implements $StateSummaryCopyWith<$Res> {
  _$StateSummaryCopyWithImpl(this._self, this._then);

  final StateSummary _self;
  final $Res Function(StateSummary) _then;

/// Create a copy of StateSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? attachmentsCount = null,Object? capturedFields = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,capturedFields: null == capturedFields ? _self.capturedFields : capturedFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [StateSummary].
extension StateSummaryPatterns on StateSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateSummary value)  $default,){
final _that = this;
switch (_that) {
case _StateSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateSummary value)?  $default,){
final _that = this;
switch (_that) {
case _StateSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatPhase phase,  int attachmentsCount,  Map<String, dynamic> capturedFields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateSummary() when $default != null:
return $default(_that.phase,_that.attachmentsCount,_that.capturedFields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatPhase phase,  int attachmentsCount,  Map<String, dynamic> capturedFields)  $default,) {final _that = this;
switch (_that) {
case _StateSummary():
return $default(_that.phase,_that.attachmentsCount,_that.capturedFields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatPhase phase,  int attachmentsCount,  Map<String, dynamic> capturedFields)?  $default,) {final _that = this;
switch (_that) {
case _StateSummary() when $default != null:
return $default(_that.phase,_that.attachmentsCount,_that.capturedFields);case _:
  return null;

}
}

}

/// @nodoc


class _StateSummary implements StateSummary {
  const _StateSummary({required this.phase, required this.attachmentsCount, final  Map<String, dynamic> capturedFields = const {}}): _capturedFields = capturedFields;
  

@override final  ChatPhase phase;
@override final  int attachmentsCount;
 final  Map<String, dynamic> _capturedFields;
@override@JsonKey() Map<String, dynamic> get capturedFields {
  if (_capturedFields is EqualUnmodifiableMapView) return _capturedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_capturedFields);
}


/// Create a copy of StateSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateSummaryCopyWith<_StateSummary> get copyWith => __$StateSummaryCopyWithImpl<_StateSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateSummary&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount)&&const DeepCollectionEquality().equals(other._capturedFields, _capturedFields));
}


@override
int get hashCode => Object.hash(runtimeType,phase,attachmentsCount,const DeepCollectionEquality().hash(_capturedFields));

@override
String toString() {
  return 'StateSummary(phase: $phase, attachmentsCount: $attachmentsCount, capturedFields: $capturedFields)';
}


}

/// @nodoc
abstract mixin class _$StateSummaryCopyWith<$Res> implements $StateSummaryCopyWith<$Res> {
  factory _$StateSummaryCopyWith(_StateSummary value, $Res Function(_StateSummary) _then) = __$StateSummaryCopyWithImpl;
@override @useResult
$Res call({
 ChatPhase phase, int attachmentsCount, Map<String, dynamic> capturedFields
});




}
/// @nodoc
class __$StateSummaryCopyWithImpl<$Res>
    implements _$StateSummaryCopyWith<$Res> {
  __$StateSummaryCopyWithImpl(this._self, this._then);

  final _StateSummary _self;
  final $Res Function(_StateSummary) _then;

/// Create a copy of StateSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? attachmentsCount = null,Object? capturedFields = null,}) {
  return _then(_StateSummary(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,capturedFields: null == capturedFields ? _self._capturedFields : capturedFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on

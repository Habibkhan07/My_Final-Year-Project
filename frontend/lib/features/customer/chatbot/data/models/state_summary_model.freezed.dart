// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_summary_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StateSummaryModel {

 String get phase;@JsonKey(name: 'captured_fields') Map<String, dynamic> get capturedFields;@JsonKey(name: 'attachments_count') int get attachmentsCount;
/// Create a copy of StateSummaryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StateSummaryModelCopyWith<StateSummaryModel> get copyWith => _$StateSummaryModelCopyWithImpl<StateSummaryModel>(this as StateSummaryModel, _$identity);

  /// Serializes this StateSummaryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StateSummaryModel&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.capturedFields, capturedFields)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(capturedFields),attachmentsCount);

@override
String toString() {
  return 'StateSummaryModel(phase: $phase, capturedFields: $capturedFields, attachmentsCount: $attachmentsCount)';
}


}

/// @nodoc
abstract mixin class $StateSummaryModelCopyWith<$Res>  {
  factory $StateSummaryModelCopyWith(StateSummaryModel value, $Res Function(StateSummaryModel) _then) = _$StateSummaryModelCopyWithImpl;
@useResult
$Res call({
 String phase,@JsonKey(name: 'captured_fields') Map<String, dynamic> capturedFields,@JsonKey(name: 'attachments_count') int attachmentsCount
});




}
/// @nodoc
class _$StateSummaryModelCopyWithImpl<$Res>
    implements $StateSummaryModelCopyWith<$Res> {
  _$StateSummaryModelCopyWithImpl(this._self, this._then);

  final StateSummaryModel _self;
  final $Res Function(StateSummaryModel) _then;

/// Create a copy of StateSummaryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? capturedFields = null,Object? attachmentsCount = null,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,capturedFields: null == capturedFields ? _self.capturedFields : capturedFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StateSummaryModel].
extension StateSummaryModelPatterns on StateSummaryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StateSummaryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StateSummaryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StateSummaryModel value)  $default,){
final _that = this;
switch (_that) {
case _StateSummaryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StateSummaryModel value)?  $default,){
final _that = this;
switch (_that) {
case _StateSummaryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phase, @JsonKey(name: 'captured_fields')  Map<String, dynamic> capturedFields, @JsonKey(name: 'attachments_count')  int attachmentsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StateSummaryModel() when $default != null:
return $default(_that.phase,_that.capturedFields,_that.attachmentsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phase, @JsonKey(name: 'captured_fields')  Map<String, dynamic> capturedFields, @JsonKey(name: 'attachments_count')  int attachmentsCount)  $default,) {final _that = this;
switch (_that) {
case _StateSummaryModel():
return $default(_that.phase,_that.capturedFields,_that.attachmentsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phase, @JsonKey(name: 'captured_fields')  Map<String, dynamic> capturedFields, @JsonKey(name: 'attachments_count')  int attachmentsCount)?  $default,) {final _that = this;
switch (_that) {
case _StateSummaryModel() when $default != null:
return $default(_that.phase,_that.capturedFields,_that.attachmentsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StateSummaryModel implements StateSummaryModel {
  const _StateSummaryModel({this.phase = '', @JsonKey(name: 'captured_fields') final  Map<String, dynamic> capturedFields = const {}, @JsonKey(name: 'attachments_count') this.attachmentsCount = 0}): _capturedFields = capturedFields;
  factory _StateSummaryModel.fromJson(Map<String, dynamic> json) => _$StateSummaryModelFromJson(json);

@override@JsonKey() final  String phase;
 final  Map<String, dynamic> _capturedFields;
@override@JsonKey(name: 'captured_fields') Map<String, dynamic> get capturedFields {
  if (_capturedFields is EqualUnmodifiableMapView) return _capturedFields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_capturedFields);
}

@override@JsonKey(name: 'attachments_count') final  int attachmentsCount;

/// Create a copy of StateSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StateSummaryModelCopyWith<_StateSummaryModel> get copyWith => __$StateSummaryModelCopyWithImpl<_StateSummaryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StateSummaryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StateSummaryModel&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._capturedFields, _capturedFields)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_capturedFields),attachmentsCount);

@override
String toString() {
  return 'StateSummaryModel(phase: $phase, capturedFields: $capturedFields, attachmentsCount: $attachmentsCount)';
}


}

/// @nodoc
abstract mixin class _$StateSummaryModelCopyWith<$Res> implements $StateSummaryModelCopyWith<$Res> {
  factory _$StateSummaryModelCopyWith(_StateSummaryModel value, $Res Function(_StateSummaryModel) _then) = __$StateSummaryModelCopyWithImpl;
@override @useResult
$Res call({
 String phase,@JsonKey(name: 'captured_fields') Map<String, dynamic> capturedFields,@JsonKey(name: 'attachments_count') int attachmentsCount
});




}
/// @nodoc
class __$StateSummaryModelCopyWithImpl<$Res>
    implements _$StateSummaryModelCopyWith<$Res> {
  __$StateSummaryModelCopyWithImpl(this._self, this._then);

  final _StateSummaryModel _self;
  final $Res Function(_StateSummaryModel) _then;

/// Create a copy of StateSummaryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? capturedFields = null,Object? attachmentsCount = null,}) {
  return _then(_StateSummaryModel(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as String,capturedFields: null == capturedFields ? _self._capturedFields : capturedFields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

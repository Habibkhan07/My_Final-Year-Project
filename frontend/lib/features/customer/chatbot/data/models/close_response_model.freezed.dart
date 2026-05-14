// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'close_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CloseResponseModel {

@JsonKey(name: 'closed_at') String? get closedAt;@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs;
/// Create a copy of CloseResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CloseResponseModelCopyWith<CloseResponseModel> get copyWith => _$CloseResponseModelCopyWithImpl<CloseResponseModel>(this as CloseResponseModel, _$identity);

  /// Serializes this CloseResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CloseResponseModel&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&const DeepCollectionEquality().equals(other.outputRefs, outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,closedAt,const DeepCollectionEquality().hash(outputRefs));

@override
String toString() {
  return 'CloseResponseModel(closedAt: $closedAt, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class $CloseResponseModelCopyWith<$Res>  {
  factory $CloseResponseModelCopyWith(CloseResponseModel value, $Res Function(CloseResponseModel) _then) = _$CloseResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});




}
/// @nodoc
class _$CloseResponseModelCopyWithImpl<$Res>
    implements $CloseResponseModelCopyWith<$Res> {
  _$CloseResponseModelCopyWithImpl(this._self, this._then);

  final CloseResponseModel _self;
  final $Res Function(CloseResponseModel) _then;

/// Create a copy of CloseResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? closedAt = freezed,Object? outputRefs = null,}) {
  return _then(_self.copyWith(
closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,outputRefs: null == outputRefs ? _self.outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [CloseResponseModel].
extension CloseResponseModelPatterns on CloseResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CloseResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CloseResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CloseResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _CloseResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CloseResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _CloseResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CloseResponseModel() when $default != null:
return $default(_that.closedAt,_that.outputRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)  $default,) {final _that = this;
switch (_that) {
case _CloseResponseModel():
return $default(_that.closedAt,_that.outputRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,) {final _that = this;
switch (_that) {
case _CloseResponseModel() when $default != null:
return $default(_that.closedAt,_that.outputRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CloseResponseModel implements CloseResponseModel {
  const _CloseResponseModel({@JsonKey(name: 'closed_at') this.closedAt, @JsonKey(name: 'output_refs') final  Map<String, dynamic> outputRefs = const {}}): _outputRefs = outputRefs;
  factory _CloseResponseModel.fromJson(Map<String, dynamic> json) => _$CloseResponseModelFromJson(json);

@override@JsonKey(name: 'closed_at') final  String? closedAt;
 final  Map<String, dynamic> _outputRefs;
@override@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs {
  if (_outputRefs is EqualUnmodifiableMapView) return _outputRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outputRefs);
}


/// Create a copy of CloseResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CloseResponseModelCopyWith<_CloseResponseModel> get copyWith => __$CloseResponseModelCopyWithImpl<_CloseResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CloseResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CloseResponseModel&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&const DeepCollectionEquality().equals(other._outputRefs, _outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,closedAt,const DeepCollectionEquality().hash(_outputRefs));

@override
String toString() {
  return 'CloseResponseModel(closedAt: $closedAt, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class _$CloseResponseModelCopyWith<$Res> implements $CloseResponseModelCopyWith<$Res> {
  factory _$CloseResponseModelCopyWith(_CloseResponseModel value, $Res Function(_CloseResponseModel) _then) = __$CloseResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});




}
/// @nodoc
class __$CloseResponseModelCopyWithImpl<$Res>
    implements _$CloseResponseModelCopyWith<$Res> {
  __$CloseResponseModelCopyWithImpl(this._self, this._then);

  final _CloseResponseModel _self;
  final $Res Function(_CloseResponseModel) _then;

/// Create a copy of CloseResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? closedAt = freezed,Object? outputRefs = null,}) {
  return _then(_CloseResponseModel(
closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,outputRefs: null == outputRefs ? _self._outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skill_selection_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SkillSelectionEntity {

 int get subServiceId; int get yearsOfExperience; String? get laborRate;
/// Create a copy of SkillSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillSelectionEntityCopyWith<SkillSelectionEntity> get copyWith => _$SkillSelectionEntityCopyWithImpl<SkillSelectionEntity>(this as SkillSelectionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillSelectionEntity&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&(identical(other.laborRate, laborRate) || other.laborRate == laborRate));
}


@override
int get hashCode => Object.hash(runtimeType,subServiceId,yearsOfExperience,laborRate);

@override
String toString() {
  return 'SkillSelectionEntity(subServiceId: $subServiceId, yearsOfExperience: $yearsOfExperience, laborRate: $laborRate)';
}


}

/// @nodoc
abstract mixin class $SkillSelectionEntityCopyWith<$Res>  {
  factory $SkillSelectionEntityCopyWith(SkillSelectionEntity value, $Res Function(SkillSelectionEntity) _then) = _$SkillSelectionEntityCopyWithImpl;
@useResult
$Res call({
 int subServiceId, int yearsOfExperience, String? laborRate
});




}
/// @nodoc
class _$SkillSelectionEntityCopyWithImpl<$Res>
    implements $SkillSelectionEntityCopyWith<$Res> {
  _$SkillSelectionEntityCopyWithImpl(this._self, this._then);

  final SkillSelectionEntity _self;
  final $Res Function(SkillSelectionEntity) _then;

/// Create a copy of SkillSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subServiceId = null,Object? yearsOfExperience = null,Object? laborRate = freezed,}) {
  return _then(_self.copyWith(
subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as int,laborRate: freezed == laborRate ? _self.laborRate : laborRate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillSelectionEntity].
extension SkillSelectionEntityPatterns on SkillSelectionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillSelectionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillSelectionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillSelectionEntity value)  $default,){
final _that = this;
switch (_that) {
case _SkillSelectionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillSelectionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SkillSelectionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int subServiceId,  int yearsOfExperience,  String? laborRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillSelectionEntity() when $default != null:
return $default(_that.subServiceId,_that.yearsOfExperience,_that.laborRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int subServiceId,  int yearsOfExperience,  String? laborRate)  $default,) {final _that = this;
switch (_that) {
case _SkillSelectionEntity():
return $default(_that.subServiceId,_that.yearsOfExperience,_that.laborRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int subServiceId,  int yearsOfExperience,  String? laborRate)?  $default,) {final _that = this;
switch (_that) {
case _SkillSelectionEntity() when $default != null:
return $default(_that.subServiceId,_that.yearsOfExperience,_that.laborRate);case _:
  return null;

}
}

}

/// @nodoc


class _SkillSelectionEntity implements SkillSelectionEntity {
  const _SkillSelectionEntity({required this.subServiceId, required this.yearsOfExperience, this.laborRate});
  

@override final  int subServiceId;
@override final  int yearsOfExperience;
@override final  String? laborRate;

/// Create a copy of SkillSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillSelectionEntityCopyWith<_SkillSelectionEntity> get copyWith => __$SkillSelectionEntityCopyWithImpl<_SkillSelectionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillSelectionEntity&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&(identical(other.laborRate, laborRate) || other.laborRate == laborRate));
}


@override
int get hashCode => Object.hash(runtimeType,subServiceId,yearsOfExperience,laborRate);

@override
String toString() {
  return 'SkillSelectionEntity(subServiceId: $subServiceId, yearsOfExperience: $yearsOfExperience, laborRate: $laborRate)';
}


}

/// @nodoc
abstract mixin class _$SkillSelectionEntityCopyWith<$Res> implements $SkillSelectionEntityCopyWith<$Res> {
  factory _$SkillSelectionEntityCopyWith(_SkillSelectionEntity value, $Res Function(_SkillSelectionEntity) _then) = __$SkillSelectionEntityCopyWithImpl;
@override @useResult
$Res call({
 int subServiceId, int yearsOfExperience, String? laborRate
});




}
/// @nodoc
class __$SkillSelectionEntityCopyWithImpl<$Res>
    implements _$SkillSelectionEntityCopyWith<$Res> {
  __$SkillSelectionEntityCopyWithImpl(this._self, this._then);

  final _SkillSelectionEntity _self;
  final $Res Function(_SkillSelectionEntity) _then;

/// Create a copy of SkillSelectionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subServiceId = null,Object? yearsOfExperience = null,Object? laborRate = freezed,}) {
  return _then(_SkillSelectionEntity(
subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as int,laborRate: freezed == laborRate ? _self.laborRate : laborRate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

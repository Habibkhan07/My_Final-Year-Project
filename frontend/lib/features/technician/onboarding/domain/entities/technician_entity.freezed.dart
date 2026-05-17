// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianEntity {

 int get profileId; String get status; String get fullName; String get joinedDate;
/// Create a copy of TechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianEntityCopyWith<TechnicianEntity> get copyWith => _$TechnicianEntityCopyWithImpl<TechnicianEntity>(this as TechnicianEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianEntity&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.status, status) || other.status == status)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.joinedDate, joinedDate) || other.joinedDate == joinedDate));
}


@override
int get hashCode => Object.hash(runtimeType,profileId,status,fullName,joinedDate);

@override
String toString() {
  return 'TechnicianEntity(profileId: $profileId, status: $status, fullName: $fullName, joinedDate: $joinedDate)';
}


}

/// @nodoc
abstract mixin class $TechnicianEntityCopyWith<$Res>  {
  factory $TechnicianEntityCopyWith(TechnicianEntity value, $Res Function(TechnicianEntity) _then) = _$TechnicianEntityCopyWithImpl;
@useResult
$Res call({
 int profileId, String status, String fullName, String joinedDate
});




}
/// @nodoc
class _$TechnicianEntityCopyWithImpl<$Res>
    implements $TechnicianEntityCopyWith<$Res> {
  _$TechnicianEntityCopyWithImpl(this._self, this._then);

  final TechnicianEntity _self;
  final $Res Function(TechnicianEntity) _then;

/// Create a copy of TechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profileId = null,Object? status = null,Object? fullName = null,Object? joinedDate = null,}) {
  return _then(_self.copyWith(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,joinedDate: null == joinedDate ? _self.joinedDate : joinedDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianEntity].
extension TechnicianEntityPatterns on TechnicianEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int profileId,  String status,  String fullName,  String joinedDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianEntity() when $default != null:
return $default(_that.profileId,_that.status,_that.fullName,_that.joinedDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int profileId,  String status,  String fullName,  String joinedDate)  $default,) {final _that = this;
switch (_that) {
case _TechnicianEntity():
return $default(_that.profileId,_that.status,_that.fullName,_that.joinedDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int profileId,  String status,  String fullName,  String joinedDate)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianEntity() when $default != null:
return $default(_that.profileId,_that.status,_that.fullName,_that.joinedDate);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianEntity implements TechnicianEntity {
  const _TechnicianEntity({required this.profileId, required this.status, required this.fullName, required this.joinedDate});
  

@override final  int profileId;
@override final  String status;
@override final  String fullName;
@override final  String joinedDate;

/// Create a copy of TechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianEntityCopyWith<_TechnicianEntity> get copyWith => __$TechnicianEntityCopyWithImpl<_TechnicianEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianEntity&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.status, status) || other.status == status)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.joinedDate, joinedDate) || other.joinedDate == joinedDate));
}


@override
int get hashCode => Object.hash(runtimeType,profileId,status,fullName,joinedDate);

@override
String toString() {
  return 'TechnicianEntity(profileId: $profileId, status: $status, fullName: $fullName, joinedDate: $joinedDate)';
}


}

/// @nodoc
abstract mixin class _$TechnicianEntityCopyWith<$Res> implements $TechnicianEntityCopyWith<$Res> {
  factory _$TechnicianEntityCopyWith(_TechnicianEntity value, $Res Function(_TechnicianEntity) _then) = __$TechnicianEntityCopyWithImpl;
@override @useResult
$Res call({
 int profileId, String status, String fullName, String joinedDate
});




}
/// @nodoc
class __$TechnicianEntityCopyWithImpl<$Res>
    implements _$TechnicianEntityCopyWith<$Res> {
  __$TechnicianEntityCopyWithImpl(this._self, this._then);

  final _TechnicianEntity _self;
  final $Res Function(_TechnicianEntity) _then;

/// Create a copy of TechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profileId = null,Object? status = null,Object? fullName = null,Object? joinedDate = null,}) {
  return _then(_TechnicianEntity(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,joinedDate: null == joinedDate ? _self.joinedDate : joinedDate // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_license_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryLicenseEntity {

 int get serviceId; String get mediaUuid;
/// Create a copy of CategoryLicenseEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryLicenseEntityCopyWith<CategoryLicenseEntity> get copyWith => _$CategoryLicenseEntityCopyWithImpl<CategoryLicenseEntity>(this as CategoryLicenseEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryLicenseEntity&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.mediaUuid, mediaUuid) || other.mediaUuid == mediaUuid));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,mediaUuid);

@override
String toString() {
  return 'CategoryLicenseEntity(serviceId: $serviceId, mediaUuid: $mediaUuid)';
}


}

/// @nodoc
abstract mixin class $CategoryLicenseEntityCopyWith<$Res>  {
  factory $CategoryLicenseEntityCopyWith(CategoryLicenseEntity value, $Res Function(CategoryLicenseEntity) _then) = _$CategoryLicenseEntityCopyWithImpl;
@useResult
$Res call({
 int serviceId, String mediaUuid
});




}
/// @nodoc
class _$CategoryLicenseEntityCopyWithImpl<$Res>
    implements $CategoryLicenseEntityCopyWith<$Res> {
  _$CategoryLicenseEntityCopyWithImpl(this._self, this._then);

  final CategoryLicenseEntity _self;
  final $Res Function(CategoryLicenseEntity) _then;

/// Create a copy of CategoryLicenseEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceId = null,Object? mediaUuid = null,}) {
  return _then(_self.copyWith(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int,mediaUuid: null == mediaUuid ? _self.mediaUuid : mediaUuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryLicenseEntity].
extension CategoryLicenseEntityPatterns on CategoryLicenseEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryLicenseEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryLicenseEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryLicenseEntity value)  $default,){
final _that = this;
switch (_that) {
case _CategoryLicenseEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryLicenseEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryLicenseEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int serviceId,  String mediaUuid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryLicenseEntity() when $default != null:
return $default(_that.serviceId,_that.mediaUuid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int serviceId,  String mediaUuid)  $default,) {final _that = this;
switch (_that) {
case _CategoryLicenseEntity():
return $default(_that.serviceId,_that.mediaUuid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int serviceId,  String mediaUuid)?  $default,) {final _that = this;
switch (_that) {
case _CategoryLicenseEntity() when $default != null:
return $default(_that.serviceId,_that.mediaUuid);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryLicenseEntity implements CategoryLicenseEntity {
  const _CategoryLicenseEntity({required this.serviceId, required this.mediaUuid});
  

@override final  int serviceId;
@override final  String mediaUuid;

/// Create a copy of CategoryLicenseEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryLicenseEntityCopyWith<_CategoryLicenseEntity> get copyWith => __$CategoryLicenseEntityCopyWithImpl<_CategoryLicenseEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryLicenseEntity&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.mediaUuid, mediaUuid) || other.mediaUuid == mediaUuid));
}


@override
int get hashCode => Object.hash(runtimeType,serviceId,mediaUuid);

@override
String toString() {
  return 'CategoryLicenseEntity(serviceId: $serviceId, mediaUuid: $mediaUuid)';
}


}

/// @nodoc
abstract mixin class _$CategoryLicenseEntityCopyWith<$Res> implements $CategoryLicenseEntityCopyWith<$Res> {
  factory _$CategoryLicenseEntityCopyWith(_CategoryLicenseEntity value, $Res Function(_CategoryLicenseEntity) _then) = __$CategoryLicenseEntityCopyWithImpl;
@override @useResult
$Res call({
 int serviceId, String mediaUuid
});




}
/// @nodoc
class __$CategoryLicenseEntityCopyWithImpl<$Res>
    implements _$CategoryLicenseEntityCopyWith<$Res> {
  __$CategoryLicenseEntityCopyWithImpl(this._self, this._then);

  final _CategoryLicenseEntity _self;
  final $Res Function(_CategoryLicenseEntity) _then;

/// Create a copy of CategoryLicenseEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceId = null,Object? mediaUuid = null,}) {
  return _then(_CategoryLicenseEntity(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int,mediaUuid: null == mediaUuid ? _self.mediaUuid : mediaUuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

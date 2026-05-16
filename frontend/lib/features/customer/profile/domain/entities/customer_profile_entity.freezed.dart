// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerProfileEntity {

 int get id; String get phone; bool get isTechnician; String? get firstName; String? get lastName;
/// Create a copy of CustomerProfileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerProfileEntityCopyWith<CustomerProfileEntity> get copyWith => _$CustomerProfileEntityCopyWithImpl<CustomerProfileEntity>(this as CustomerProfileEntity, _$identity);

  /// Serializes this CustomerProfileEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerProfileEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTechnician, isTechnician) || other.isTechnician == isTechnician)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,isTechnician,firstName,lastName);

@override
String toString() {
  return 'CustomerProfileEntity(id: $id, phone: $phone, isTechnician: $isTechnician, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class $CustomerProfileEntityCopyWith<$Res>  {
  factory $CustomerProfileEntityCopyWith(CustomerProfileEntity value, $Res Function(CustomerProfileEntity) _then) = _$CustomerProfileEntityCopyWithImpl;
@useResult
$Res call({
 int id, String phone, bool isTechnician, String? firstName, String? lastName
});




}
/// @nodoc
class _$CustomerProfileEntityCopyWithImpl<$Res>
    implements $CustomerProfileEntityCopyWith<$Res> {
  _$CustomerProfileEntityCopyWithImpl(this._self, this._then);

  final CustomerProfileEntity _self;
  final $Res Function(CustomerProfileEntity) _then;

/// Create a copy of CustomerProfileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? phone = null,Object? isTechnician = null,Object? firstName = freezed,Object? lastName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTechnician: null == isTechnician ? _self.isTechnician : isTechnician // ignore: cast_nullable_to_non_nullable
as bool,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerProfileEntity].
extension CustomerProfileEntityPatterns on CustomerProfileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerProfileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerProfileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerProfileEntity value)  $default,){
final _that = this;
switch (_that) {
case _CustomerProfileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerProfileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerProfileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String phone,  bool isTechnician,  String? firstName,  String? lastName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerProfileEntity() when $default != null:
return $default(_that.id,_that.phone,_that.isTechnician,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String phone,  bool isTechnician,  String? firstName,  String? lastName)  $default,) {final _that = this;
switch (_that) {
case _CustomerProfileEntity():
return $default(_that.id,_that.phone,_that.isTechnician,_that.firstName,_that.lastName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String phone,  bool isTechnician,  String? firstName,  String? lastName)?  $default,) {final _that = this;
switch (_that) {
case _CustomerProfileEntity() when $default != null:
return $default(_that.id,_that.phone,_that.isTechnician,_that.firstName,_that.lastName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerProfileEntity implements CustomerProfileEntity {
  const _CustomerProfileEntity({required this.id, required this.phone, this.isTechnician = false, this.firstName, this.lastName});
  factory _CustomerProfileEntity.fromJson(Map<String, dynamic> json) => _$CustomerProfileEntityFromJson(json);

@override final  int id;
@override final  String phone;
@override@JsonKey() final  bool isTechnician;
@override final  String? firstName;
@override final  String? lastName;

/// Create a copy of CustomerProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerProfileEntityCopyWith<_CustomerProfileEntity> get copyWith => __$CustomerProfileEntityCopyWithImpl<_CustomerProfileEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerProfileEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerProfileEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.isTechnician, isTechnician) || other.isTechnician == isTechnician)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,phone,isTechnician,firstName,lastName);

@override
String toString() {
  return 'CustomerProfileEntity(id: $id, phone: $phone, isTechnician: $isTechnician, firstName: $firstName, lastName: $lastName)';
}


}

/// @nodoc
abstract mixin class _$CustomerProfileEntityCopyWith<$Res> implements $CustomerProfileEntityCopyWith<$Res> {
  factory _$CustomerProfileEntityCopyWith(_CustomerProfileEntity value, $Res Function(_CustomerProfileEntity) _then) = __$CustomerProfileEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String phone, bool isTechnician, String? firstName, String? lastName
});




}
/// @nodoc
class __$CustomerProfileEntityCopyWithImpl<$Res>
    implements _$CustomerProfileEntityCopyWith<$Res> {
  __$CustomerProfileEntityCopyWithImpl(this._self, this._then);

  final _CustomerProfileEntity _self;
  final $Res Function(_CustomerProfileEntity) _then;

/// Create a copy of CustomerProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? phone = null,Object? isTechnician = null,Object? firstName = freezed,Object? lastName = freezed,}) {
  return _then(_CustomerProfileEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,isTechnician: null == isTechnician ? _self.isTechnician : isTechnician // ignore: cast_nullable_to_non_nullable
as bool,firstName: freezed == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String?,lastName: freezed == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

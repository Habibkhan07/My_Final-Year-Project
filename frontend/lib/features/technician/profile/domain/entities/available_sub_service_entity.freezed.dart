// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'available_sub_service_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvailableServiceEntity {

 int get id; String get name; String? get iconName; List<AvailableSubServiceEntity> get subServices;
/// Create a copy of AvailableServiceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableServiceEntityCopyWith<AvailableServiceEntity> get copyWith => _$AvailableServiceEntityCopyWithImpl<AvailableServiceEntity>(this as AvailableServiceEntity, _$identity);

  /// Serializes this AvailableServiceEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&const DeepCollectionEquality().equals(other.subServices, subServices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,const DeepCollectionEquality().hash(subServices));

@override
String toString() {
  return 'AvailableServiceEntity(id: $id, name: $name, iconName: $iconName, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class $AvailableServiceEntityCopyWith<$Res>  {
  factory $AvailableServiceEntityCopyWith(AvailableServiceEntity value, $Res Function(AvailableServiceEntity) _then) = _$AvailableServiceEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? iconName, List<AvailableSubServiceEntity> subServices
});




}
/// @nodoc
class _$AvailableServiceEntityCopyWithImpl<$Res>
    implements $AvailableServiceEntityCopyWith<$Res> {
  _$AvailableServiceEntityCopyWithImpl(this._self, this._then);

  final AvailableServiceEntity _self;
  final $Res Function(AvailableServiceEntity) _then;

/// Create a copy of AvailableServiceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? subServices = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,subServices: null == subServices ? _self.subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<AvailableSubServiceEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailableServiceEntity].
extension AvailableServiceEntityPatterns on AvailableServiceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailableServiceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailableServiceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailableServiceEntity value)  $default,){
final _that = this;
switch (_that) {
case _AvailableServiceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailableServiceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _AvailableServiceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  List<AvailableSubServiceEntity> subServices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailableServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.subServices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  List<AvailableSubServiceEntity> subServices)  $default,) {final _that = this;
switch (_that) {
case _AvailableServiceEntity():
return $default(_that.id,_that.name,_that.iconName,_that.subServices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? iconName,  List<AvailableSubServiceEntity> subServices)?  $default,) {final _that = this;
switch (_that) {
case _AvailableServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.subServices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailableServiceEntity implements AvailableServiceEntity {
  const _AvailableServiceEntity({required this.id, required this.name, required this.iconName, required final  List<AvailableSubServiceEntity> subServices}): _subServices = subServices;
  factory _AvailableServiceEntity.fromJson(Map<String, dynamic> json) => _$AvailableServiceEntityFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? iconName;
 final  List<AvailableSubServiceEntity> _subServices;
@override List<AvailableSubServiceEntity> get subServices {
  if (_subServices is EqualUnmodifiableListView) return _subServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subServices);
}


/// Create a copy of AvailableServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailableServiceEntityCopyWith<_AvailableServiceEntity> get copyWith => __$AvailableServiceEntityCopyWithImpl<_AvailableServiceEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailableServiceEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailableServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&const DeepCollectionEquality().equals(other._subServices, _subServices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,const DeepCollectionEquality().hash(_subServices));

@override
String toString() {
  return 'AvailableServiceEntity(id: $id, name: $name, iconName: $iconName, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class _$AvailableServiceEntityCopyWith<$Res> implements $AvailableServiceEntityCopyWith<$Res> {
  factory _$AvailableServiceEntityCopyWith(_AvailableServiceEntity value, $Res Function(_AvailableServiceEntity) _then) = __$AvailableServiceEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? iconName, List<AvailableSubServiceEntity> subServices
});




}
/// @nodoc
class __$AvailableServiceEntityCopyWithImpl<$Res>
    implements _$AvailableServiceEntityCopyWith<$Res> {
  __$AvailableServiceEntityCopyWithImpl(this._self, this._then);

  final _AvailableServiceEntity _self;
  final $Res Function(_AvailableServiceEntity) _then;

/// Create a copy of AvailableServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? subServices = null,}) {
  return _then(_AvailableServiceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,subServices: null == subServices ? _self._subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<AvailableSubServiceEntity>,
  ));
}


}


/// @nodoc
mixin _$AvailableSubServiceEntity {

 int get id; String get name; String? get iconName; bool get isFixedPrice;
/// Create a copy of AvailableSubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableSubServiceEntityCopyWith<AvailableSubServiceEntity> get copyWith => _$AvailableSubServiceEntityCopyWithImpl<AvailableSubServiceEntity>(this as AvailableSubServiceEntity, _$identity);

  /// Serializes this AvailableSubServiceEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableSubServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,isFixedPrice);

@override
String toString() {
  return 'AvailableSubServiceEntity(id: $id, name: $name, iconName: $iconName, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class $AvailableSubServiceEntityCopyWith<$Res>  {
  factory $AvailableSubServiceEntityCopyWith(AvailableSubServiceEntity value, $Res Function(AvailableSubServiceEntity) _then) = _$AvailableSubServiceEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? iconName, bool isFixedPrice
});




}
/// @nodoc
class _$AvailableSubServiceEntityCopyWithImpl<$Res>
    implements $AvailableSubServiceEntityCopyWith<$Res> {
  _$AvailableSubServiceEntityCopyWithImpl(this._self, this._then);

  final AvailableSubServiceEntity _self;
  final $Res Function(AvailableSubServiceEntity) _then;

/// Create a copy of AvailableSubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? isFixedPrice = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailableSubServiceEntity].
extension AvailableSubServiceEntityPatterns on AvailableSubServiceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailableSubServiceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailableSubServiceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailableSubServiceEntity value)  $default,){
final _that = this;
switch (_that) {
case _AvailableSubServiceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailableSubServiceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _AvailableSubServiceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  bool isFixedPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailableSubServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  bool isFixedPrice)  $default,) {final _that = this;
switch (_that) {
case _AvailableSubServiceEntity():
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? iconName,  bool isFixedPrice)?  $default,) {final _that = this;
switch (_that) {
case _AvailableSubServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailableSubServiceEntity implements AvailableSubServiceEntity {
  const _AvailableSubServiceEntity({required this.id, required this.name, required this.iconName, this.isFixedPrice = false});
  factory _AvailableSubServiceEntity.fromJson(Map<String, dynamic> json) => _$AvailableSubServiceEntityFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? iconName;
@override@JsonKey() final  bool isFixedPrice;

/// Create a copy of AvailableSubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailableSubServiceEntityCopyWith<_AvailableSubServiceEntity> get copyWith => __$AvailableSubServiceEntityCopyWithImpl<_AvailableSubServiceEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailableSubServiceEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailableSubServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,isFixedPrice);

@override
String toString() {
  return 'AvailableSubServiceEntity(id: $id, name: $name, iconName: $iconName, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class _$AvailableSubServiceEntityCopyWith<$Res> implements $AvailableSubServiceEntityCopyWith<$Res> {
  factory _$AvailableSubServiceEntityCopyWith(_AvailableSubServiceEntity value, $Res Function(_AvailableSubServiceEntity) _then) = __$AvailableSubServiceEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? iconName, bool isFixedPrice
});




}
/// @nodoc
class __$AvailableSubServiceEntityCopyWithImpl<$Res>
    implements _$AvailableSubServiceEntityCopyWith<$Res> {
  __$AvailableSubServiceEntityCopyWithImpl(this._self, this._then);

  final _AvailableSubServiceEntity _self;
  final $Res Function(_AvailableSubServiceEntity) _then;

/// Create a copy of AvailableSubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? isFixedPrice = null,}) {
  return _then(_AvailableSubServiceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

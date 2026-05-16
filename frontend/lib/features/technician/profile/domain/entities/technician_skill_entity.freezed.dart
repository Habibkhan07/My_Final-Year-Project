// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_skill_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechnicianSkillEntity {

/// Bridge row PK. Stable within the row's lifetime, but the delete
/// endpoint keys by `subService.id` (the catalog row), not this id.
 int get id; SubServiceRef get subService;
/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianSkillEntityCopyWith<TechnicianSkillEntity> get copyWith => _$TechnicianSkillEntityCopyWithImpl<TechnicianSkillEntity>(this as TechnicianSkillEntity, _$identity);

  /// Serializes this TechnicianSkillEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianSkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.subService, subService) || other.subService == subService));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subService);

@override
String toString() {
  return 'TechnicianSkillEntity(id: $id, subService: $subService)';
}


}

/// @nodoc
abstract mixin class $TechnicianSkillEntityCopyWith<$Res>  {
  factory $TechnicianSkillEntityCopyWith(TechnicianSkillEntity value, $Res Function(TechnicianSkillEntity) _then) = _$TechnicianSkillEntityCopyWithImpl;
@useResult
$Res call({
 int id, SubServiceRef subService
});


$SubServiceRefCopyWith<$Res> get subService;

}
/// @nodoc
class _$TechnicianSkillEntityCopyWithImpl<$Res>
    implements $TechnicianSkillEntityCopyWith<$Res> {
  _$TechnicianSkillEntityCopyWithImpl(this._self, this._then);

  final TechnicianSkillEntity _self;
  final $Res Function(TechnicianSkillEntity) _then;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subService = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subService: null == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as SubServiceRef,
  ));
}
/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubServiceRefCopyWith<$Res> get subService {
  
  return $SubServiceRefCopyWith<$Res>(_self.subService, (value) {
    return _then(_self.copyWith(subService: value));
  });
}
}


/// Adds pattern-matching-related methods to [TechnicianSkillEntity].
extension TechnicianSkillEntityPatterns on TechnicianSkillEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianSkillEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianSkillEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianSkillEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianSkillEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  SubServiceRef subService)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
return $default(_that.id,_that.subService);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  SubServiceRef subService)  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity():
return $default(_that.id,_that.subService);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  SubServiceRef subService)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
return $default(_that.id,_that.subService);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianSkillEntity implements TechnicianSkillEntity {
  const _TechnicianSkillEntity({required this.id, required this.subService});
  factory _TechnicianSkillEntity.fromJson(Map<String, dynamic> json) => _$TechnicianSkillEntityFromJson(json);

/// Bridge row PK. Stable within the row's lifetime, but the delete
/// endpoint keys by `subService.id` (the catalog row), not this id.
@override final  int id;
@override final  SubServiceRef subService;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianSkillEntityCopyWith<_TechnicianSkillEntity> get copyWith => __$TechnicianSkillEntityCopyWithImpl<_TechnicianSkillEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianSkillEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianSkillEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.subService, subService) || other.subService == subService));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subService);

@override
String toString() {
  return 'TechnicianSkillEntity(id: $id, subService: $subService)';
}


}

/// @nodoc
abstract mixin class _$TechnicianSkillEntityCopyWith<$Res> implements $TechnicianSkillEntityCopyWith<$Res> {
  factory _$TechnicianSkillEntityCopyWith(_TechnicianSkillEntity value, $Res Function(_TechnicianSkillEntity) _then) = __$TechnicianSkillEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, SubServiceRef subService
});


@override $SubServiceRefCopyWith<$Res> get subService;

}
/// @nodoc
class __$TechnicianSkillEntityCopyWithImpl<$Res>
    implements _$TechnicianSkillEntityCopyWith<$Res> {
  __$TechnicianSkillEntityCopyWithImpl(this._self, this._then);

  final _TechnicianSkillEntity _self;
  final $Res Function(_TechnicianSkillEntity) _then;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subService = null,}) {
  return _then(_TechnicianSkillEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subService: null == subService ? _self.subService : subService // ignore: cast_nullable_to_non_nullable
as SubServiceRef,
  ));
}

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubServiceRefCopyWith<$Res> get subService {
  
  return $SubServiceRefCopyWith<$Res>(_self.subService, (value) {
    return _then(_self.copyWith(subService: value));
  });
}
}


/// @nodoc
mixin _$SubServiceRef {

 int get id; String get name; String? get iconName; bool get isFixedPrice; ParentServiceRef get service;
/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubServiceRefCopyWith<SubServiceRef> get copyWith => _$SubServiceRefCopyWithImpl<SubServiceRef>(this as SubServiceRef, _$identity);

  /// Serializes this SubServiceRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubServiceRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.service, service) || other.service == service));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,isFixedPrice,service);

@override
String toString() {
  return 'SubServiceRef(id: $id, name: $name, iconName: $iconName, isFixedPrice: $isFixedPrice, service: $service)';
}


}

/// @nodoc
abstract mixin class $SubServiceRefCopyWith<$Res>  {
  factory $SubServiceRefCopyWith(SubServiceRef value, $Res Function(SubServiceRef) _then) = _$SubServiceRefCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? iconName, bool isFixedPrice, ParentServiceRef service
});


$ParentServiceRefCopyWith<$Res> get service;

}
/// @nodoc
class _$SubServiceRefCopyWithImpl<$Res>
    implements $SubServiceRefCopyWith<$Res> {
  _$SubServiceRefCopyWithImpl(this._self, this._then);

  final SubServiceRef _self;
  final $Res Function(SubServiceRef) _then;

/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? isFixedPrice = null,Object? service = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ParentServiceRef,
  ));
}
/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParentServiceRefCopyWith<$Res> get service {
  
  return $ParentServiceRefCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubServiceRef].
extension SubServiceRefPatterns on SubServiceRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubServiceRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubServiceRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubServiceRef value)  $default,){
final _that = this;
switch (_that) {
case _SubServiceRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubServiceRef value)?  $default,){
final _that = this;
switch (_that) {
case _SubServiceRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  bool isFixedPrice,  ParentServiceRef service)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubServiceRef() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice,_that.service);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName,  bool isFixedPrice,  ParentServiceRef service)  $default,) {final _that = this;
switch (_that) {
case _SubServiceRef():
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice,_that.service);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? iconName,  bool isFixedPrice,  ParentServiceRef service)?  $default,) {final _that = this;
switch (_that) {
case _SubServiceRef() when $default != null:
return $default(_that.id,_that.name,_that.iconName,_that.isFixedPrice,_that.service);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubServiceRef implements SubServiceRef {
  const _SubServiceRef({required this.id, required this.name, required this.iconName, this.isFixedPrice = false, required this.service});
  factory _SubServiceRef.fromJson(Map<String, dynamic> json) => _$SubServiceRefFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? iconName;
@override@JsonKey() final  bool isFixedPrice;
@override final  ParentServiceRef service;

/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubServiceRefCopyWith<_SubServiceRef> get copyWith => __$SubServiceRefCopyWithImpl<_SubServiceRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubServiceRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubServiceRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice)&&(identical(other.service, service) || other.service == service));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName,isFixedPrice,service);

@override
String toString() {
  return 'SubServiceRef(id: $id, name: $name, iconName: $iconName, isFixedPrice: $isFixedPrice, service: $service)';
}


}

/// @nodoc
abstract mixin class _$SubServiceRefCopyWith<$Res> implements $SubServiceRefCopyWith<$Res> {
  factory _$SubServiceRefCopyWith(_SubServiceRef value, $Res Function(_SubServiceRef) _then) = __$SubServiceRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? iconName, bool isFixedPrice, ParentServiceRef service
});


@override $ParentServiceRefCopyWith<$Res> get service;

}
/// @nodoc
class __$SubServiceRefCopyWithImpl<$Res>
    implements _$SubServiceRefCopyWith<$Res> {
  __$SubServiceRefCopyWithImpl(this._self, this._then);

  final _SubServiceRef _self;
  final $Res Function(_SubServiceRef) _then;

/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,Object? isFixedPrice = null,Object? service = null,}) {
  return _then(_SubServiceRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as ParentServiceRef,
  ));
}

/// Create a copy of SubServiceRef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ParentServiceRefCopyWith<$Res> get service {
  
  return $ParentServiceRefCopyWith<$Res>(_self.service, (value) {
    return _then(_self.copyWith(service: value));
  });
}
}


/// @nodoc
mixin _$ParentServiceRef {

 int get id; String get name; String? get iconName;
/// Create a copy of ParentServiceRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParentServiceRefCopyWith<ParentServiceRef> get copyWith => _$ParentServiceRefCopyWithImpl<ParentServiceRef>(this as ParentServiceRef, _$identity);

  /// Serializes this ParentServiceRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParentServiceRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'ParentServiceRef(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $ParentServiceRefCopyWith<$Res>  {
  factory $ParentServiceRefCopyWith(ParentServiceRef value, $Res Function(ParentServiceRef) _then) = _$ParentServiceRefCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? iconName
});




}
/// @nodoc
class _$ParentServiceRefCopyWithImpl<$Res>
    implements $ParentServiceRefCopyWith<$Res> {
  _$ParentServiceRefCopyWithImpl(this._self, this._then);

  final ParentServiceRef _self;
  final $Res Function(ParentServiceRef) _then;

/// Create a copy of ParentServiceRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ParentServiceRef].
extension ParentServiceRefPatterns on ParentServiceRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParentServiceRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParentServiceRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParentServiceRef value)  $default,){
final _that = this;
switch (_that) {
case _ParentServiceRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParentServiceRef value)?  $default,){
final _that = this;
switch (_that) {
case _ParentServiceRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParentServiceRef() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _ParentServiceRef():
return $default(_that.id,_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _ParentServiceRef() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ParentServiceRef implements ParentServiceRef {
  const _ParentServiceRef({required this.id, required this.name, required this.iconName});
  factory _ParentServiceRef.fromJson(Map<String, dynamic> json) => _$ParentServiceRefFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? iconName;

/// Create a copy of ParentServiceRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParentServiceRefCopyWith<_ParentServiceRef> get copyWith => __$ParentServiceRefCopyWithImpl<_ParentServiceRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ParentServiceRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParentServiceRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'ParentServiceRef(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$ParentServiceRefCopyWith<$Res> implements $ParentServiceRefCopyWith<$Res> {
  factory _$ParentServiceRefCopyWith(_ParentServiceRef value, $Res Function(_ParentServiceRef) _then) = __$ParentServiceRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? iconName
});




}
/// @nodoc
class __$ParentServiceRefCopyWithImpl<$Res>
    implements _$ParentServiceRefCopyWith<$Res> {
  __$ParentServiceRefCopyWithImpl(this._self, this._then);

  final _ParentServiceRef _self;
  final $Res Function(_ParentServiceRef) _then;

/// Create a copy of ParentServiceRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = freezed,}) {
  return _then(_ParentServiceRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

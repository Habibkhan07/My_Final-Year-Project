// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServiceEntity {

 int get id; String get name; List<SubServiceEntity> get subServices;
/// Create a copy of ServiceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceEntityCopyWith<ServiceEntity> get copyWith => _$ServiceEntityCopyWithImpl<ServiceEntity>(this as ServiceEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.subServices, subServices));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(subServices));

@override
String toString() {
  return 'ServiceEntity(id: $id, name: $name, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class $ServiceEntityCopyWith<$Res>  {
  factory $ServiceEntityCopyWith(ServiceEntity value, $Res Function(ServiceEntity) _then) = _$ServiceEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, List<SubServiceEntity> subServices
});




}
/// @nodoc
class _$ServiceEntityCopyWithImpl<$Res>
    implements $ServiceEntityCopyWith<$Res> {
  _$ServiceEntityCopyWithImpl(this._self, this._then);

  final ServiceEntity _self;
  final $Res Function(ServiceEntity) _then;

/// Create a copy of ServiceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? subServices = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subServices: null == subServices ? _self.subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<SubServiceEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceEntity].
extension ServiceEntityPatterns on ServiceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceEntity value)  $default,){
final _that = this;
switch (_that) {
case _ServiceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  List<SubServiceEntity> subServices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.subServices);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  List<SubServiceEntity> subServices)  $default,) {final _that = this;
switch (_that) {
case _ServiceEntity():
return $default(_that.id,_that.name,_that.subServices);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  List<SubServiceEntity> subServices)?  $default,) {final _that = this;
switch (_that) {
case _ServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.subServices);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceEntity implements ServiceEntity {
  const _ServiceEntity({required this.id, required this.name, required final  List<SubServiceEntity> subServices}): _subServices = subServices;
  

@override final  int id;
@override final  String name;
 final  List<SubServiceEntity> _subServices;
@override List<SubServiceEntity> get subServices {
  if (_subServices is EqualUnmodifiableListView) return _subServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subServices);
}


/// Create a copy of ServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceEntityCopyWith<_ServiceEntity> get copyWith => __$ServiceEntityCopyWithImpl<_ServiceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._subServices, _subServices));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_subServices));

@override
String toString() {
  return 'ServiceEntity(id: $id, name: $name, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class _$ServiceEntityCopyWith<$Res> implements $ServiceEntityCopyWith<$Res> {
  factory _$ServiceEntityCopyWith(_ServiceEntity value, $Res Function(_ServiceEntity) _then) = __$ServiceEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, List<SubServiceEntity> subServices
});




}
/// @nodoc
class __$ServiceEntityCopyWithImpl<$Res>
    implements _$ServiceEntityCopyWith<$Res> {
  __$ServiceEntityCopyWithImpl(this._self, this._then);

  final _ServiceEntity _self;
  final $Res Function(_ServiceEntity) _then;

/// Create a copy of ServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? subServices = null,}) {
  return _then(_ServiceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subServices: null == subServices ? _self._subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<SubServiceEntity>,
  ));
}


}

/// @nodoc
mixin _$SubServiceEntity {

 int get id; String get name; String get basePrice; String? get maxPrice; String? get iconName;
/// Create a copy of SubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubServiceEntityCopyWith<SubServiceEntity> get copyWith => _$SubServiceEntityCopyWithImpl<SubServiceEntity>(this as SubServiceEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,iconName);

@override
String toString() {
  return 'SubServiceEntity(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $SubServiceEntityCopyWith<$Res>  {
  factory $SubServiceEntityCopyWith(SubServiceEntity value, $Res Function(SubServiceEntity) _then) = _$SubServiceEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String basePrice, String? maxPrice, String? iconName
});




}
/// @nodoc
class _$SubServiceEntityCopyWithImpl<$Res>
    implements $SubServiceEntityCopyWith<$Res> {
  _$SubServiceEntityCopyWithImpl(this._self, this._then);

  final SubServiceEntity _self;
  final $Res Function(SubServiceEntity) _then;

/// Create a copy of SubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? maxPrice = freezed,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubServiceEntity].
extension SubServiceEntityPatterns on SubServiceEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubServiceEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubServiceEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubServiceEntity value)  $default,){
final _that = this;
switch (_that) {
case _SubServiceEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubServiceEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SubServiceEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String basePrice,  String? maxPrice,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String basePrice,  String? maxPrice,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _SubServiceEntity():
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String basePrice,  String? maxPrice,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _SubServiceEntity() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _SubServiceEntity implements SubServiceEntity {
  const _SubServiceEntity({required this.id, required this.name, required this.basePrice, required this.maxPrice, this.iconName});
  

@override final  int id;
@override final  String name;
@override final  String basePrice;
@override final  String? maxPrice;
@override final  String? iconName;

/// Create a copy of SubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubServiceEntityCopyWith<_SubServiceEntity> get copyWith => __$SubServiceEntityCopyWithImpl<_SubServiceEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubServiceEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,iconName);

@override
String toString() {
  return 'SubServiceEntity(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$SubServiceEntityCopyWith<$Res> implements $SubServiceEntityCopyWith<$Res> {
  factory _$SubServiceEntityCopyWith(_SubServiceEntity value, $Res Function(_SubServiceEntity) _then) = __$SubServiceEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String basePrice, String? maxPrice, String? iconName
});




}
/// @nodoc
class __$SubServiceEntityCopyWithImpl<$Res>
    implements _$SubServiceEntityCopyWith<$Res> {
  __$SubServiceEntityCopyWithImpl(this._self, this._then);

  final _SubServiceEntity _self;
  final $Res Function(_SubServiceEntity) _then;

/// Create a copy of SubServiceEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? maxPrice = freezed,Object? iconName = freezed,}) {
  return _then(_SubServiceEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

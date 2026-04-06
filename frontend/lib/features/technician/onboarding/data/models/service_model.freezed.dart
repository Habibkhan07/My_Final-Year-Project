// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceModel {

 int get id; String get name;@JsonKey(name: 'sub_services') List<SubServiceModel> get subServices;
/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceModelCopyWith<ServiceModel> get copyWith => _$ServiceModelCopyWithImpl<ServiceModel>(this as ServiceModel, _$identity);

  /// Serializes this ServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.subServices, subServices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(subServices));

@override
String toString() {
  return 'ServiceModel(id: $id, name: $name, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class $ServiceModelCopyWith<$Res>  {
  factory $ServiceModelCopyWith(ServiceModel value, $Res Function(ServiceModel) _then) = _$ServiceModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'sub_services') List<SubServiceModel> subServices
});




}
/// @nodoc
class _$ServiceModelCopyWithImpl<$Res>
    implements $ServiceModelCopyWith<$Res> {
  _$ServiceModelCopyWithImpl(this._self, this._then);

  final ServiceModel _self;
  final $Res Function(ServiceModel) _then;

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? subServices = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subServices: null == subServices ? _self.subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<SubServiceModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceModel].
extension ServiceModelPatterns on ServiceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _ServiceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'sub_services')  List<SubServiceModel> subServices)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'sub_services')  List<SubServiceModel> subServices)  $default,) {final _that = this;
switch (_that) {
case _ServiceModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'sub_services')  List<SubServiceModel> subServices)?  $default,) {final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.subServices);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceModel implements ServiceModel {
  const _ServiceModel({required this.id, required this.name, @JsonKey(name: 'sub_services') required final  List<SubServiceModel> subServices}): _subServices = subServices;
  factory _ServiceModel.fromJson(Map<String, dynamic> json) => _$ServiceModelFromJson(json);

@override final  int id;
@override final  String name;
 final  List<SubServiceModel> _subServices;
@override@JsonKey(name: 'sub_services') List<SubServiceModel> get subServices {
  if (_subServices is EqualUnmodifiableListView) return _subServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subServices);
}


/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceModelCopyWith<_ServiceModel> get copyWith => __$ServiceModelCopyWithImpl<_ServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._subServices, _subServices));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_subServices));

@override
String toString() {
  return 'ServiceModel(id: $id, name: $name, subServices: $subServices)';
}


}

/// @nodoc
abstract mixin class _$ServiceModelCopyWith<$Res> implements $ServiceModelCopyWith<$Res> {
  factory _$ServiceModelCopyWith(_ServiceModel value, $Res Function(_ServiceModel) _then) = __$ServiceModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'sub_services') List<SubServiceModel> subServices
});




}
/// @nodoc
class __$ServiceModelCopyWithImpl<$Res>
    implements _$ServiceModelCopyWith<$Res> {
  __$ServiceModelCopyWithImpl(this._self, this._then);

  final _ServiceModel _self;
  final $Res Function(_ServiceModel) _then;

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? subServices = null,}) {
  return _then(_ServiceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subServices: null == subServices ? _self._subServices : subServices // ignore: cast_nullable_to_non_nullable
as List<SubServiceModel>,
  ));
}


}


/// @nodoc
mixin _$SubServiceModel {

 int get id; String get name;@JsonKey(name: 'base_price') String get basePrice;@JsonKey(name: 'max_price') String? get maxPrice;@JsonKey(name: 'icon_name') String? get iconName;
/// Create a copy of SubServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubServiceModelCopyWith<SubServiceModel> get copyWith => _$SubServiceModelCopyWithImpl<SubServiceModel>(this as SubServiceModel, _$identity);

  /// Serializes this SubServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,iconName);

@override
String toString() {
  return 'SubServiceModel(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $SubServiceModelCopyWith<$Res>  {
  factory $SubServiceModelCopyWith(SubServiceModel value, $Res Function(SubServiceModel) _then) = _$SubServiceModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice,@JsonKey(name: 'icon_name') String? iconName
});




}
/// @nodoc
class _$SubServiceModelCopyWithImpl<$Res>
    implements $SubServiceModelCopyWith<$Res> {
  _$SubServiceModelCopyWithImpl(this._self, this._then);

  final SubServiceModel _self;
  final $Res Function(SubServiceModel) _then;

/// Create a copy of SubServiceModel
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


/// Adds pattern-matching-related methods to [SubServiceModel].
extension SubServiceModelPatterns on SubServiceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubServiceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _SubServiceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _SubServiceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'icon_name')  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubServiceModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'icon_name')  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _SubServiceModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'icon_name')  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _SubServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubServiceModel implements SubServiceModel {
  const _SubServiceModel({required this.id, required this.name, @JsonKey(name: 'base_price') required this.basePrice, @JsonKey(name: 'max_price') required this.maxPrice, @JsonKey(name: 'icon_name') this.iconName});
  factory _SubServiceModel.fromJson(Map<String, dynamic> json) => _$SubServiceModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'base_price') final  String basePrice;
@override@JsonKey(name: 'max_price') final  String? maxPrice;
@override@JsonKey(name: 'icon_name') final  String? iconName;

/// Create a copy of SubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubServiceModelCopyWith<_SubServiceModel> get copyWith => __$SubServiceModelCopyWithImpl<_SubServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,iconName);

@override
String toString() {
  return 'SubServiceModel(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$SubServiceModelCopyWith<$Res> implements $SubServiceModelCopyWith<$Res> {
  factory _$SubServiceModelCopyWith(_SubServiceModel value, $Res Function(_SubServiceModel) _then) = __$SubServiceModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice,@JsonKey(name: 'icon_name') String? iconName
});




}
/// @nodoc
class __$SubServiceModelCopyWithImpl<$Res>
    implements _$SubServiceModelCopyWith<$Res> {
  __$SubServiceModelCopyWithImpl(this._self, this._then);

  final _SubServiceModel _self;
  final $Res Function(_SubServiceModel) _then;

/// Create a copy of SubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? maxPrice = freezed,Object? iconName = freezed,}) {
  return _then(_SubServiceModel(
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

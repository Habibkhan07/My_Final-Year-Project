// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quotable_sub_service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuotableSubServiceModel {

 int get id; String get name;@JsonKey(name: 'base_price') String get basePrice;@JsonKey(name: 'max_price') String? get maxPrice;@JsonKey(name: 'is_fixed_price') bool get isFixedPrice;
/// Create a copy of QuotableSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuotableSubServiceModelCopyWith<QuotableSubServiceModel> get copyWith => _$QuotableSubServiceModelCopyWithImpl<QuotableSubServiceModel>(this as QuotableSubServiceModel, _$identity);

  /// Serializes this QuotableSubServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuotableSubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,isFixedPrice);

@override
String toString() {
  return 'QuotableSubServiceModel(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class $QuotableSubServiceModelCopyWith<$Res>  {
  factory $QuotableSubServiceModelCopyWith(QuotableSubServiceModel value, $Res Function(QuotableSubServiceModel) _then) = _$QuotableSubServiceModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice,@JsonKey(name: 'is_fixed_price') bool isFixedPrice
});




}
/// @nodoc
class _$QuotableSubServiceModelCopyWithImpl<$Res>
    implements $QuotableSubServiceModelCopyWith<$Res> {
  _$QuotableSubServiceModelCopyWithImpl(this._self, this._then);

  final QuotableSubServiceModel _self;
  final $Res Function(QuotableSubServiceModel) _then;

/// Create a copy of QuotableSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? maxPrice = freezed,Object? isFixedPrice = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [QuotableSubServiceModel].
extension QuotableSubServiceModelPatterns on QuotableSubServiceModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuotableSubServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuotableSubServiceModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuotableSubServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _QuotableSubServiceModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuotableSubServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _QuotableSubServiceModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuotableSubServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)  $default,) {final _that = this;
switch (_that) {
case _QuotableSubServiceModel():
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'max_price')  String? maxPrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)?  $default,) {final _that = this;
switch (_that) {
case _QuotableSubServiceModel() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.maxPrice,_that.isFixedPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuotableSubServiceModel implements QuotableSubServiceModel {
  const _QuotableSubServiceModel({required this.id, required this.name, @JsonKey(name: 'base_price') required this.basePrice, @JsonKey(name: 'max_price') this.maxPrice, @JsonKey(name: 'is_fixed_price') required this.isFixedPrice});
  factory _QuotableSubServiceModel.fromJson(Map<String, dynamic> json) => _$QuotableSubServiceModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'base_price') final  String basePrice;
@override@JsonKey(name: 'max_price') final  String? maxPrice;
@override@JsonKey(name: 'is_fixed_price') final  bool isFixedPrice;

/// Create a copy of QuotableSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuotableSubServiceModelCopyWith<_QuotableSubServiceModel> get copyWith => __$QuotableSubServiceModelCopyWithImpl<_QuotableSubServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuotableSubServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuotableSubServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,maxPrice,isFixedPrice);

@override
String toString() {
  return 'QuotableSubServiceModel(id: $id, name: $name, basePrice: $basePrice, maxPrice: $maxPrice, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class _$QuotableSubServiceModelCopyWith<$Res> implements $QuotableSubServiceModelCopyWith<$Res> {
  factory _$QuotableSubServiceModelCopyWith(_QuotableSubServiceModel value, $Res Function(_QuotableSubServiceModel) _then) = __$QuotableSubServiceModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'max_price') String? maxPrice,@JsonKey(name: 'is_fixed_price') bool isFixedPrice
});




}
/// @nodoc
class __$QuotableSubServiceModelCopyWithImpl<$Res>
    implements _$QuotableSubServiceModelCopyWith<$Res> {
  __$QuotableSubServiceModelCopyWithImpl(this._self, this._then);

  final _QuotableSubServiceModel _self;
  final $Res Function(_QuotableSubServiceModel) _then;

/// Create a copy of QuotableSubServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? maxPrice = freezed,Object? isFixedPrice = null,}) {
  return _then(_QuotableSubServiceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as String?,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

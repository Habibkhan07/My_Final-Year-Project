// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchResultModel {

 int get id; String get name;@JsonKey(name: 'category_name') String get categoryName;@JsonKey(name: 'category_icon_url') String? get categoryIconUrl;@JsonKey(name: 'base_price') String get basePrice;@JsonKey(name: 'is_fixed_price') bool get isFixedPrice;
/// Create a copy of SearchResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResultModelCopyWith<SearchResultModel> get copyWith => _$SearchResultModelCopyWithImpl<SearchResultModel>(this as SearchResultModel, _$identity);

  /// Serializes this SearchResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResultModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIconUrl, categoryIconUrl) || other.categoryIconUrl == categoryIconUrl)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryName,categoryIconUrl,basePrice,isFixedPrice);

@override
String toString() {
  return 'SearchResultModel(id: $id, name: $name, categoryName: $categoryName, categoryIconUrl: $categoryIconUrl, basePrice: $basePrice, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class $SearchResultModelCopyWith<$Res>  {
  factory $SearchResultModelCopyWith(SearchResultModel value, $Res Function(SearchResultModel) _then) = _$SearchResultModelCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'category_name') String categoryName,@JsonKey(name: 'category_icon_url') String? categoryIconUrl,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'is_fixed_price') bool isFixedPrice
});




}
/// @nodoc
class _$SearchResultModelCopyWithImpl<$Res>
    implements $SearchResultModelCopyWith<$Res> {
  _$SearchResultModelCopyWithImpl(this._self, this._then);

  final SearchResultModel _self;
  final $Res Function(SearchResultModel) _then;

/// Create a copy of SearchResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? categoryName = null,Object? categoryIconUrl = freezed,Object? basePrice = null,Object? isFixedPrice = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryIconUrl: freezed == categoryIconUrl ? _self.categoryIconUrl : categoryIconUrl // ignore: cast_nullable_to_non_nullable
as String?,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResultModel].
extension SearchResultModelPatterns on SearchResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResultModel value)  $default,){
final _that = this;
switch (_that) {
case _SearchResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'category_name')  String categoryName, @JsonKey(name: 'category_icon_url')  String? categoryIconUrl, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResultModel() when $default != null:
return $default(_that.id,_that.name,_that.categoryName,_that.categoryIconUrl,_that.basePrice,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'category_name')  String categoryName, @JsonKey(name: 'category_icon_url')  String? categoryIconUrl, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)  $default,) {final _that = this;
switch (_that) {
case _SearchResultModel():
return $default(_that.id,_that.name,_that.categoryName,_that.categoryIconUrl,_that.basePrice,_that.isFixedPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'category_name')  String categoryName, @JsonKey(name: 'category_icon_url')  String? categoryIconUrl, @JsonKey(name: 'base_price')  String basePrice, @JsonKey(name: 'is_fixed_price')  bool isFixedPrice)?  $default,) {final _that = this;
switch (_that) {
case _SearchResultModel() when $default != null:
return $default(_that.id,_that.name,_that.categoryName,_that.categoryIconUrl,_that.basePrice,_that.isFixedPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResultModel extends SearchResultModel {
  const _SearchResultModel({required this.id, required this.name, @JsonKey(name: 'category_name') required this.categoryName, @JsonKey(name: 'category_icon_url') this.categoryIconUrl, @JsonKey(name: 'base_price') required this.basePrice, @JsonKey(name: 'is_fixed_price') required this.isFixedPrice}): super._();
  factory _SearchResultModel.fromJson(Map<String, dynamic> json) => _$SearchResultModelFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'category_name') final  String categoryName;
@override@JsonKey(name: 'category_icon_url') final  String? categoryIconUrl;
@override@JsonKey(name: 'base_price') final  String basePrice;
@override@JsonKey(name: 'is_fixed_price') final  bool isFixedPrice;

/// Create a copy of SearchResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResultModelCopyWith<_SearchResultModel> get copyWith => __$SearchResultModelCopyWithImpl<_SearchResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResultModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIconUrl, categoryIconUrl) || other.categoryIconUrl == categoryIconUrl)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.isFixedPrice, isFixedPrice) || other.isFixedPrice == isFixedPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,categoryName,categoryIconUrl,basePrice,isFixedPrice);

@override
String toString() {
  return 'SearchResultModel(id: $id, name: $name, categoryName: $categoryName, categoryIconUrl: $categoryIconUrl, basePrice: $basePrice, isFixedPrice: $isFixedPrice)';
}


}

/// @nodoc
abstract mixin class _$SearchResultModelCopyWith<$Res> implements $SearchResultModelCopyWith<$Res> {
  factory _$SearchResultModelCopyWith(_SearchResultModel value, $Res Function(_SearchResultModel) _then) = __$SearchResultModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'category_name') String categoryName,@JsonKey(name: 'category_icon_url') String? categoryIconUrl,@JsonKey(name: 'base_price') String basePrice,@JsonKey(name: 'is_fixed_price') bool isFixedPrice
});




}
/// @nodoc
class __$SearchResultModelCopyWithImpl<$Res>
    implements _$SearchResultModelCopyWith<$Res> {
  __$SearchResultModelCopyWithImpl(this._self, this._then);

  final _SearchResultModel _self;
  final $Res Function(_SearchResultModel) _then;

/// Create a copy of SearchResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? categoryName = null,Object? categoryIconUrl = freezed,Object? basePrice = null,Object? isFixedPrice = null,}) {
  return _then(_SearchResultModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryIconUrl: freezed == categoryIconUrl ? _self.categoryIconUrl : categoryIconUrl // ignore: cast_nullable_to_non_nullable
as String?,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,isFixedPrice: null == isFixedPrice ? _self.isFixedPrice : isFixedPrice // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

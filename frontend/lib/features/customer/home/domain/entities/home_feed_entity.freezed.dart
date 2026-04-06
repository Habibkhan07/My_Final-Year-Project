// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_feed_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategoryEntity {

 int get id; String get name; String get iconName;
/// Create a copy of CategoryEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryEntityCopyWith<CategoryEntity> get copyWith => _$CategoryEntityCopyWithImpl<CategoryEntity>(this as CategoryEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'CategoryEntity(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $CategoryEntityCopyWith<$Res>  {
  factory $CategoryEntityCopyWith(CategoryEntity value, $Res Function(CategoryEntity) _then) = _$CategoryEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String iconName
});




}
/// @nodoc
class _$CategoryEntityCopyWithImpl<$Res>
    implements $CategoryEntityCopyWith<$Res> {
  _$CategoryEntityCopyWithImpl(this._self, this._then);

  final CategoryEntity _self;
  final $Res Function(CategoryEntity) _then;

/// Create a copy of CategoryEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? iconName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryEntity].
extension CategoryEntityPatterns on CategoryEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryEntity value)  $default,){
final _that = this;
switch (_that) {
case _CategoryEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryEntity() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String iconName)  $default,) {final _that = this;
switch (_that) {
case _CategoryEntity():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String iconName)?  $default,) {final _that = this;
switch (_that) {
case _CategoryEntity() when $default != null:
return $default(_that.id,_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryEntity implements CategoryEntity {
  const _CategoryEntity({required this.id, required this.name, required this.iconName});
  

@override final  int id;
@override final  String name;
@override final  String iconName;

/// Create a copy of CategoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryEntityCopyWith<_CategoryEntity> get copyWith => __$CategoryEntityCopyWithImpl<_CategoryEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,iconName);

@override
String toString() {
  return 'CategoryEntity(id: $id, name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$CategoryEntityCopyWith<$Res> implements $CategoryEntityCopyWith<$Res> {
  factory _$CategoryEntityCopyWith(_CategoryEntity value, $Res Function(_CategoryEntity) _then) = __$CategoryEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String iconName
});




}
/// @nodoc
class __$CategoryEntityCopyWithImpl<$Res>
    implements _$CategoryEntityCopyWith<$Res> {
  __$CategoryEntityCopyWithImpl(this._self, this._then);

  final _CategoryEntity _self;
  final $Res Function(_CategoryEntity) _then;

/// Create a copy of CategoryEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? iconName = null,}) {
  return _then(_CategoryEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: null == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PromotionEntity {

 int get id; String get title; String get bannerImageUrl; String get promoDescription;// Dumb UI String generated by backend
 String get buttonText;
/// Create a copy of PromotionEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PromotionEntityCopyWith<PromotionEntity> get copyWith => _$PromotionEntityCopyWithImpl<PromotionEntity>(this as PromotionEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PromotionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.bannerImageUrl, bannerImageUrl) || other.bannerImageUrl == bannerImageUrl)&&(identical(other.promoDescription, promoDescription) || other.promoDescription == promoDescription)&&(identical(other.buttonText, buttonText) || other.buttonText == buttonText));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,bannerImageUrl,promoDescription,buttonText);

@override
String toString() {
  return 'PromotionEntity(id: $id, title: $title, bannerImageUrl: $bannerImageUrl, promoDescription: $promoDescription, buttonText: $buttonText)';
}


}

/// @nodoc
abstract mixin class $PromotionEntityCopyWith<$Res>  {
  factory $PromotionEntityCopyWith(PromotionEntity value, $Res Function(PromotionEntity) _then) = _$PromotionEntityCopyWithImpl;
@useResult
$Res call({
 int id, String title, String bannerImageUrl, String promoDescription, String buttonText
});




}
/// @nodoc
class _$PromotionEntityCopyWithImpl<$Res>
    implements $PromotionEntityCopyWith<$Res> {
  _$PromotionEntityCopyWithImpl(this._self, this._then);

  final PromotionEntity _self;
  final $Res Function(PromotionEntity) _then;

/// Create a copy of PromotionEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? bannerImageUrl = null,Object? promoDescription = null,Object? buttonText = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,bannerImageUrl: null == bannerImageUrl ? _self.bannerImageUrl : bannerImageUrl // ignore: cast_nullable_to_non_nullable
as String,promoDescription: null == promoDescription ? _self.promoDescription : promoDescription // ignore: cast_nullable_to_non_nullable
as String,buttonText: null == buttonText ? _self.buttonText : buttonText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PromotionEntity].
extension PromotionEntityPatterns on PromotionEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PromotionEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PromotionEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PromotionEntity value)  $default,){
final _that = this;
switch (_that) {
case _PromotionEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PromotionEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PromotionEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String bannerImageUrl,  String promoDescription,  String buttonText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PromotionEntity() when $default != null:
return $default(_that.id,_that.title,_that.bannerImageUrl,_that.promoDescription,_that.buttonText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String bannerImageUrl,  String promoDescription,  String buttonText)  $default,) {final _that = this;
switch (_that) {
case _PromotionEntity():
return $default(_that.id,_that.title,_that.bannerImageUrl,_that.promoDescription,_that.buttonText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String bannerImageUrl,  String promoDescription,  String buttonText)?  $default,) {final _that = this;
switch (_that) {
case _PromotionEntity() when $default != null:
return $default(_that.id,_that.title,_that.bannerImageUrl,_that.promoDescription,_that.buttonText);case _:
  return null;

}
}

}

/// @nodoc


class _PromotionEntity implements PromotionEntity {
  const _PromotionEntity({required this.id, required this.title, required this.bannerImageUrl, required this.promoDescription, required this.buttonText});
  

@override final  int id;
@override final  String title;
@override final  String bannerImageUrl;
@override final  String promoDescription;
// Dumb UI String generated by backend
@override final  String buttonText;

/// Create a copy of PromotionEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PromotionEntityCopyWith<_PromotionEntity> get copyWith => __$PromotionEntityCopyWithImpl<_PromotionEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PromotionEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.bannerImageUrl, bannerImageUrl) || other.bannerImageUrl == bannerImageUrl)&&(identical(other.promoDescription, promoDescription) || other.promoDescription == promoDescription)&&(identical(other.buttonText, buttonText) || other.buttonText == buttonText));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,bannerImageUrl,promoDescription,buttonText);

@override
String toString() {
  return 'PromotionEntity(id: $id, title: $title, bannerImageUrl: $bannerImageUrl, promoDescription: $promoDescription, buttonText: $buttonText)';
}


}

/// @nodoc
abstract mixin class _$PromotionEntityCopyWith<$Res> implements $PromotionEntityCopyWith<$Res> {
  factory _$PromotionEntityCopyWith(_PromotionEntity value, $Res Function(_PromotionEntity) _then) = __$PromotionEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String bannerImageUrl, String promoDescription, String buttonText
});




}
/// @nodoc
class __$PromotionEntityCopyWithImpl<$Res>
    implements _$PromotionEntityCopyWith<$Res> {
  __$PromotionEntityCopyWithImpl(this._self, this._then);

  final _PromotionEntity _self;
  final $Res Function(_PromotionEntity) _then;

/// Create a copy of PromotionEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? bannerImageUrl = null,Object? promoDescription = null,Object? buttonText = null,}) {
  return _then(_PromotionEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,bannerImageUrl: null == bannerImageUrl ? _self.bannerImageUrl : bannerImageUrl // ignore: cast_nullable_to_non_nullable
as String,promoDescription: null == promoDescription ? _self.promoDescription : promoDescription // ignore: cast_nullable_to_non_nullable
as String,buttonText: null == buttonText ? _self.buttonText : buttonText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$FixedGigEntity {

 int get id; String get name; String get basePrice; String get parentCategory; String get imageUrl;
/// Create a copy of FixedGigEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FixedGigEntityCopyWith<FixedGigEntity> get copyWith => _$FixedGigEntityCopyWithImpl<FixedGigEntity>(this as FixedGigEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FixedGigEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.parentCategory, parentCategory) || other.parentCategory == parentCategory)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,parentCategory,imageUrl);

@override
String toString() {
  return 'FixedGigEntity(id: $id, name: $name, basePrice: $basePrice, parentCategory: $parentCategory, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $FixedGigEntityCopyWith<$Res>  {
  factory $FixedGigEntityCopyWith(FixedGigEntity value, $Res Function(FixedGigEntity) _then) = _$FixedGigEntityCopyWithImpl;
@useResult
$Res call({
 int id, String name, String basePrice, String parentCategory, String imageUrl
});




}
/// @nodoc
class _$FixedGigEntityCopyWithImpl<$Res>
    implements $FixedGigEntityCopyWith<$Res> {
  _$FixedGigEntityCopyWithImpl(this._self, this._then);

  final FixedGigEntity _self;
  final $Res Function(FixedGigEntity) _then;

/// Create a copy of FixedGigEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? parentCategory = null,Object? imageUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,parentCategory: null == parentCategory ? _self.parentCategory : parentCategory // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FixedGigEntity].
extension FixedGigEntityPatterns on FixedGigEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FixedGigEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FixedGigEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FixedGigEntity value)  $default,){
final _that = this;
switch (_that) {
case _FixedGigEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FixedGigEntity value)?  $default,){
final _that = this;
switch (_that) {
case _FixedGigEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String basePrice,  String parentCategory,  String imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FixedGigEntity() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.parentCategory,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String basePrice,  String parentCategory,  String imageUrl)  $default,) {final _that = this;
switch (_that) {
case _FixedGigEntity():
return $default(_that.id,_that.name,_that.basePrice,_that.parentCategory,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String basePrice,  String parentCategory,  String imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _FixedGigEntity() when $default != null:
return $default(_that.id,_that.name,_that.basePrice,_that.parentCategory,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _FixedGigEntity implements FixedGigEntity {
  const _FixedGigEntity({required this.id, required this.name, required this.basePrice, required this.parentCategory, required this.imageUrl});
  

@override final  int id;
@override final  String name;
@override final  String basePrice;
@override final  String parentCategory;
@override final  String imageUrl;

/// Create a copy of FixedGigEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FixedGigEntityCopyWith<_FixedGigEntity> get copyWith => __$FixedGigEntityCopyWithImpl<_FixedGigEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FixedGigEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.basePrice, basePrice) || other.basePrice == basePrice)&&(identical(other.parentCategory, parentCategory) || other.parentCategory == parentCategory)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,basePrice,parentCategory,imageUrl);

@override
String toString() {
  return 'FixedGigEntity(id: $id, name: $name, basePrice: $basePrice, parentCategory: $parentCategory, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$FixedGigEntityCopyWith<$Res> implements $FixedGigEntityCopyWith<$Res> {
  factory _$FixedGigEntityCopyWith(_FixedGigEntity value, $Res Function(_FixedGigEntity) _then) = __$FixedGigEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String basePrice, String parentCategory, String imageUrl
});




}
/// @nodoc
class __$FixedGigEntityCopyWithImpl<$Res>
    implements _$FixedGigEntityCopyWith<$Res> {
  __$FixedGigEntityCopyWithImpl(this._self, this._then);

  final _FixedGigEntity _self;
  final $Res Function(_FixedGigEntity) _then;

/// Create a copy of FixedGigEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? basePrice = null,Object? parentCategory = null,Object? imageUrl = null,}) {
  return _then(_FixedGigEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,basePrice: null == basePrice ? _self.basePrice : basePrice // ignore: cast_nullable_to_non_nullable
as String,parentCategory: null == parentCategory ? _self.parentCategory : parentCategory // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TechnicianFeedEntity {

 int get id; String get fullName; String get primaryCategory; String get city; String get profilePicture; double get ratingAverage; int get reviewCount; double? get distanceKm;// Nullable: Handled gracefully by backend if GPS fails
 double get bayesianScore; bool get isActive;
/// Create a copy of TechnicianFeedEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianFeedEntityCopyWith<TechnicianFeedEntity> get copyWith => _$TechnicianFeedEntityCopyWithImpl<TechnicianFeedEntity>(this as TechnicianFeedEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianFeedEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive);

@override
String toString() {
  return 'TechnicianFeedEntity(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $TechnicianFeedEntityCopyWith<$Res>  {
  factory $TechnicianFeedEntityCopyWith(TechnicianFeedEntity value, $Res Function(TechnicianFeedEntity) _then) = _$TechnicianFeedEntityCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, String primaryCategory, String city, String profilePicture, double ratingAverage, int reviewCount, double? distanceKm, double bayesianScore, bool isActive
});




}
/// @nodoc
class _$TechnicianFeedEntityCopyWithImpl<$Res>
    implements $TechnicianFeedEntityCopyWith<$Res> {
  _$TechnicianFeedEntityCopyWithImpl(this._self, this._then);

  final TechnicianFeedEntity _self;
  final $Res Function(TechnicianFeedEntity) _then;

/// Create a copy of TechnicianFeedEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? primaryCategory = null,Object? city = null,Object? profilePicture = null,Object? ratingAverage = null,Object? reviewCount = null,Object? distanceKm = freezed,Object? bayesianScore = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,primaryCategory: null == primaryCategory ? _self.primaryCategory : primaryCategory // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: null == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: null == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianFeedEntity].
extension TechnicianFeedEntityPatterns on TechnicianFeedEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianFeedEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianFeedEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianFeedEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianFeedEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianFeedEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianFeedEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  String primaryCategory,  String city,  String profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double bayesianScore,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianFeedEntity() when $default != null:
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  String primaryCategory,  String city,  String profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double bayesianScore,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _TechnicianFeedEntity():
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  String primaryCategory,  String city,  String profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double bayesianScore,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianFeedEntity() when $default != null:
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianFeedEntity implements TechnicianFeedEntity {
  const _TechnicianFeedEntity({required this.id, required this.fullName, required this.primaryCategory, required this.city, required this.profilePicture, required this.ratingAverage, required this.reviewCount, this.distanceKm, required this.bayesianScore, required this.isActive});
  

@override final  int id;
@override final  String fullName;
@override final  String primaryCategory;
@override final  String city;
@override final  String profilePicture;
@override final  double ratingAverage;
@override final  int reviewCount;
@override final  double? distanceKm;
// Nullable: Handled gracefully by backend if GPS fails
@override final  double bayesianScore;
@override final  bool isActive;

/// Create a copy of TechnicianFeedEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianFeedEntityCopyWith<_TechnicianFeedEntity> get copyWith => __$TechnicianFeedEntityCopyWithImpl<_TechnicianFeedEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianFeedEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive);

@override
String toString() {
  return 'TechnicianFeedEntity(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$TechnicianFeedEntityCopyWith<$Res> implements $TechnicianFeedEntityCopyWith<$Res> {
  factory _$TechnicianFeedEntityCopyWith(_TechnicianFeedEntity value, $Res Function(_TechnicianFeedEntity) _then) = __$TechnicianFeedEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, String primaryCategory, String city, String profilePicture, double ratingAverage, int reviewCount, double? distanceKm, double bayesianScore, bool isActive
});




}
/// @nodoc
class __$TechnicianFeedEntityCopyWithImpl<$Res>
    implements _$TechnicianFeedEntityCopyWith<$Res> {
  __$TechnicianFeedEntityCopyWithImpl(this._self, this._then);

  final _TechnicianFeedEntity _self;
  final $Res Function(_TechnicianFeedEntity) _then;

/// Create a copy of TechnicianFeedEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? primaryCategory = null,Object? city = null,Object? profilePicture = null,Object? ratingAverage = null,Object? reviewCount = null,Object? distanceKm = freezed,Object? bayesianScore = null,Object? isActive = null,}) {
  return _then(_TechnicianFeedEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,primaryCategory: null == primaryCategory ? _self.primaryCategory : primaryCategory // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: null == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: null == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$HomeFeedEntity {

 List<CategoryEntity> get categories; List<PromotionEntity> get promotions; List<FixedGigEntity> get fixedGigs; List<TechnicianFeedEntity> get topTechnicians;
/// Create a copy of HomeFeedEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeFeedEntityCopyWith<HomeFeedEntity> get copyWith => _$HomeFeedEntityCopyWithImpl<HomeFeedEntity>(this as HomeFeedEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeFeedEntity&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.promotions, promotions)&&const DeepCollectionEquality().equals(other.fixedGigs, fixedGigs)&&const DeepCollectionEquality().equals(other.topTechnicians, topTechnicians));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(promotions),const DeepCollectionEquality().hash(fixedGigs),const DeepCollectionEquality().hash(topTechnicians));

@override
String toString() {
  return 'HomeFeedEntity(categories: $categories, promotions: $promotions, fixedGigs: $fixedGigs, topTechnicians: $topTechnicians)';
}


}

/// @nodoc
abstract mixin class $HomeFeedEntityCopyWith<$Res>  {
  factory $HomeFeedEntityCopyWith(HomeFeedEntity value, $Res Function(HomeFeedEntity) _then) = _$HomeFeedEntityCopyWithImpl;
@useResult
$Res call({
 List<CategoryEntity> categories, List<PromotionEntity> promotions, List<FixedGigEntity> fixedGigs, List<TechnicianFeedEntity> topTechnicians
});




}
/// @nodoc
class _$HomeFeedEntityCopyWithImpl<$Res>
    implements $HomeFeedEntityCopyWith<$Res> {
  _$HomeFeedEntityCopyWithImpl(this._self, this._then);

  final HomeFeedEntity _self;
  final $Res Function(HomeFeedEntity) _then;

/// Create a copy of HomeFeedEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? promotions = null,Object? fixedGigs = null,Object? topTechnicians = null,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryEntity>,promotions: null == promotions ? _self.promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromotionEntity>,fixedGigs: null == fixedGigs ? _self.fixedGigs : fixedGigs // ignore: cast_nullable_to_non_nullable
as List<FixedGigEntity>,topTechnicians: null == topTechnicians ? _self.topTechnicians : topTechnicians // ignore: cast_nullable_to_non_nullable
as List<TechnicianFeedEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeFeedEntity].
extension HomeFeedEntityPatterns on HomeFeedEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeFeedEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeFeedEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeFeedEntity value)  $default,){
final _that = this;
switch (_that) {
case _HomeFeedEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeFeedEntity value)?  $default,){
final _that = this;
switch (_that) {
case _HomeFeedEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CategoryEntity> categories,  List<PromotionEntity> promotions,  List<FixedGigEntity> fixedGigs,  List<TechnicianFeedEntity> topTechnicians)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeFeedEntity() when $default != null:
return $default(_that.categories,_that.promotions,_that.fixedGigs,_that.topTechnicians);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CategoryEntity> categories,  List<PromotionEntity> promotions,  List<FixedGigEntity> fixedGigs,  List<TechnicianFeedEntity> topTechnicians)  $default,) {final _that = this;
switch (_that) {
case _HomeFeedEntity():
return $default(_that.categories,_that.promotions,_that.fixedGigs,_that.topTechnicians);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CategoryEntity> categories,  List<PromotionEntity> promotions,  List<FixedGigEntity> fixedGigs,  List<TechnicianFeedEntity> topTechnicians)?  $default,) {final _that = this;
switch (_that) {
case _HomeFeedEntity() when $default != null:
return $default(_that.categories,_that.promotions,_that.fixedGigs,_that.topTechnicians);case _:
  return null;

}
}

}

/// @nodoc


class _HomeFeedEntity implements HomeFeedEntity {
  const _HomeFeedEntity({required final  List<CategoryEntity> categories, required final  List<PromotionEntity> promotions, required final  List<FixedGigEntity> fixedGigs, required final  List<TechnicianFeedEntity> topTechnicians}): _categories = categories,_promotions = promotions,_fixedGigs = fixedGigs,_topTechnicians = topTechnicians;
  

 final  List<CategoryEntity> _categories;
@override List<CategoryEntity> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<PromotionEntity> _promotions;
@override List<PromotionEntity> get promotions {
  if (_promotions is EqualUnmodifiableListView) return _promotions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_promotions);
}

 final  List<FixedGigEntity> _fixedGigs;
@override List<FixedGigEntity> get fixedGigs {
  if (_fixedGigs is EqualUnmodifiableListView) return _fixedGigs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fixedGigs);
}

 final  List<TechnicianFeedEntity> _topTechnicians;
@override List<TechnicianFeedEntity> get topTechnicians {
  if (_topTechnicians is EqualUnmodifiableListView) return _topTechnicians;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTechnicians);
}


/// Create a copy of HomeFeedEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeFeedEntityCopyWith<_HomeFeedEntity> get copyWith => __$HomeFeedEntityCopyWithImpl<_HomeFeedEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeFeedEntity&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._promotions, _promotions)&&const DeepCollectionEquality().equals(other._fixedGigs, _fixedGigs)&&const DeepCollectionEquality().equals(other._topTechnicians, _topTechnicians));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_promotions),const DeepCollectionEquality().hash(_fixedGigs),const DeepCollectionEquality().hash(_topTechnicians));

@override
String toString() {
  return 'HomeFeedEntity(categories: $categories, promotions: $promotions, fixedGigs: $fixedGigs, topTechnicians: $topTechnicians)';
}


}

/// @nodoc
abstract mixin class _$HomeFeedEntityCopyWith<$Res> implements $HomeFeedEntityCopyWith<$Res> {
  factory _$HomeFeedEntityCopyWith(_HomeFeedEntity value, $Res Function(_HomeFeedEntity) _then) = __$HomeFeedEntityCopyWithImpl;
@override @useResult
$Res call({
 List<CategoryEntity> categories, List<PromotionEntity> promotions, List<FixedGigEntity> fixedGigs, List<TechnicianFeedEntity> topTechnicians
});




}
/// @nodoc
class __$HomeFeedEntityCopyWithImpl<$Res>
    implements _$HomeFeedEntityCopyWith<$Res> {
  __$HomeFeedEntityCopyWithImpl(this._self, this._then);

  final _HomeFeedEntity _self;
  final $Res Function(_HomeFeedEntity) _then;

/// Create a copy of HomeFeedEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? promotions = null,Object? fixedGigs = null,Object? topTechnicians = null,}) {
  return _then(_HomeFeedEntity(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryEntity>,promotions: null == promotions ? _self._promotions : promotions // ignore: cast_nullable_to_non_nullable
as List<PromotionEntity>,fixedGigs: null == fixedGigs ? _self._fixedGigs : fixedGigs // ignore: cast_nullable_to_non_nullable
as List<FixedGigEntity>,topTechnicians: null == topTechnicians ? _self._topTechnicians : topTechnicians // ignore: cast_nullable_to_non_nullable
as List<TechnicianFeedEntity>,
  ));
}


}

// dart format on

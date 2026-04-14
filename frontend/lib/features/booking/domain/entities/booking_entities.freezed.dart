// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TechnicianSkillEntity {

 String get name;// Nullable: SubService.icon_name is null=True in the DB; backend sends null
// when icon is not set in Django Admin. Flutter maps non-null values to
// assets/icons/{iconName}.svg via IconAssets.path().
 String? get iconName;
/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianSkillEntityCopyWith<TechnicianSkillEntity> get copyWith => _$TechnicianSkillEntityCopyWithImpl<TechnicianSkillEntity>(this as TechnicianSkillEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianSkillEntity&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'TechnicianSkillEntity(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $TechnicianSkillEntityCopyWith<$Res>  {
  factory $TechnicianSkillEntityCopyWith(TechnicianSkillEntity value, $Res Function(TechnicianSkillEntity) _then) = _$TechnicianSkillEntityCopyWithImpl;
@useResult
$Res call({
 String name, String? iconName
});




}
/// @nodoc
class _$TechnicianSkillEntityCopyWithImpl<$Res>
    implements $TechnicianSkillEntityCopyWith<$Res> {
  _$TechnicianSkillEntityCopyWithImpl(this._self, this._then);

  final TechnicianSkillEntity _self;
  final $Res Function(TechnicianSkillEntity) _then;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
return $default(_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity():
return $default(_that.name,_that.iconName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillEntity() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianSkillEntity implements TechnicianSkillEntity {
  const _TechnicianSkillEntity({required this.name, required this.iconName});
  

@override final  String name;
// Nullable: SubService.icon_name is null=True in the DB; backend sends null
// when icon is not set in Django Admin. Flutter maps non-null values to
// assets/icons/{iconName}.svg via IconAssets.path().
@override final  String? iconName;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianSkillEntityCopyWith<_TechnicianSkillEntity> get copyWith => __$TechnicianSkillEntityCopyWithImpl<_TechnicianSkillEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianSkillEntity&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}


@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'TechnicianSkillEntity(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$TechnicianSkillEntityCopyWith<$Res> implements $TechnicianSkillEntityCopyWith<$Res> {
  factory _$TechnicianSkillEntityCopyWith(_TechnicianSkillEntity value, $Res Function(_TechnicianSkillEntity) _then) = __$TechnicianSkillEntityCopyWithImpl;
@override @useResult
$Res call({
 String name, String? iconName
});




}
/// @nodoc
class __$TechnicianSkillEntityCopyWithImpl<$Res>
    implements _$TechnicianSkillEntityCopyWith<$Res> {
  __$TechnicianSkillEntityCopyWithImpl(this._self, this._then);

  final _TechnicianSkillEntity _self;
  final $Res Function(_TechnicianSkillEntity) _then;

/// Create a copy of TechnicianSkillEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = freezed,}) {
  return _then(_TechnicianSkillEntity(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$TechnicianReviewEntity {

 String get reviewerName; int get rating; String get text;
/// Create a copy of TechnicianReviewEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianReviewEntityCopyWith<TechnicianReviewEntity> get copyWith => _$TechnicianReviewEntityCopyWithImpl<TechnicianReviewEntity>(this as TechnicianReviewEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianReviewEntity&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,reviewerName,rating,text);

@override
String toString() {
  return 'TechnicianReviewEntity(reviewerName: $reviewerName, rating: $rating, text: $text)';
}


}

/// @nodoc
abstract mixin class $TechnicianReviewEntityCopyWith<$Res>  {
  factory $TechnicianReviewEntityCopyWith(TechnicianReviewEntity value, $Res Function(TechnicianReviewEntity) _then) = _$TechnicianReviewEntityCopyWithImpl;
@useResult
$Res call({
 String reviewerName, int rating, String text
});




}
/// @nodoc
class _$TechnicianReviewEntityCopyWithImpl<$Res>
    implements $TechnicianReviewEntityCopyWith<$Res> {
  _$TechnicianReviewEntityCopyWithImpl(this._self, this._then);

  final TechnicianReviewEntity _self;
  final $Res Function(TechnicianReviewEntity) _then;

/// Create a copy of TechnicianReviewEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviewerName = null,Object? rating = null,Object? text = null,}) {
  return _then(_self.copyWith(
reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianReviewEntity].
extension TechnicianReviewEntityPatterns on TechnicianReviewEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianReviewEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianReviewEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianReviewEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianReviewEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianReviewEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianReviewEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reviewerName,  int rating,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianReviewEntity() when $default != null:
return $default(_that.reviewerName,_that.rating,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reviewerName,  int rating,  String text)  $default,) {final _that = this;
switch (_that) {
case _TechnicianReviewEntity():
return $default(_that.reviewerName,_that.rating,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reviewerName,  int rating,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianReviewEntity() when $default != null:
return $default(_that.reviewerName,_that.rating,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianReviewEntity implements TechnicianReviewEntity {
  const _TechnicianReviewEntity({required this.reviewerName, required this.rating, required this.text});
  

@override final  String reviewerName;
@override final  int rating;
@override final  String text;

/// Create a copy of TechnicianReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianReviewEntityCopyWith<_TechnicianReviewEntity> get copyWith => __$TechnicianReviewEntityCopyWithImpl<_TechnicianReviewEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianReviewEntity&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,reviewerName,rating,text);

@override
String toString() {
  return 'TechnicianReviewEntity(reviewerName: $reviewerName, rating: $rating, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TechnicianReviewEntityCopyWith<$Res> implements $TechnicianReviewEntityCopyWith<$Res> {
  factory _$TechnicianReviewEntityCopyWith(_TechnicianReviewEntity value, $Res Function(_TechnicianReviewEntity) _then) = __$TechnicianReviewEntityCopyWithImpl;
@override @useResult
$Res call({
 String reviewerName, int rating, String text
});




}
/// @nodoc
class __$TechnicianReviewEntityCopyWithImpl<$Res>
    implements _$TechnicianReviewEntityCopyWith<$Res> {
  __$TechnicianReviewEntityCopyWithImpl(this._self, this._then);

  final _TechnicianReviewEntity _self;
  final $Res Function(_TechnicianReviewEntity) _then;

/// Create a copy of TechnicianReviewEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewerName = null,Object? rating = null,Object? text = null,}) {
  return _then(_TechnicianReviewEntity(
reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TechnicianProfileEntity {

 int get id; String get fullName; String get city; String? get profilePicture; double get ratingAverage; int get reviewCount; int get experienceYears; String get bio; double? get distanceKm; double? get bayesianScore; bool get isActive;// Dumb UI Pricing and Texts
 String get uiRatingText; String get primaryPrice; String get primaryPriceRaw; String get priceContext; String? get promoTag; List<TechnicianSkillEntity> get skills; List<TechnicianReviewEntity> get recentReviews;
/// Create a copy of TechnicianProfileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianProfileEntityCopyWith<TechnicianProfileEntity> get copyWith => _$TechnicianProfileEntityCopyWithImpl<TechnicianProfileEntity>(this as TechnicianProfileEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianProfileEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.primaryPriceRaw, primaryPriceRaw) || other.primaryPriceRaw == primaryPriceRaw)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&const DeepCollectionEquality().equals(other.skills, skills)&&const DeepCollectionEquality().equals(other.recentReviews, recentReviews));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,profilePicture,ratingAverage,reviewCount,experienceYears,bio,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,primaryPriceRaw,priceContext,promoTag,const DeepCollectionEquality().hash(skills),const DeepCollectionEquality().hash(recentReviews));

@override
String toString() {
  return 'TechnicianProfileEntity(id: $id, fullName: $fullName, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, experienceYears: $experienceYears, bio: $bio, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, primaryPriceRaw: $primaryPriceRaw, priceContext: $priceContext, promoTag: $promoTag, skills: $skills, recentReviews: $recentReviews)';
}


}

/// @nodoc
abstract mixin class $TechnicianProfileEntityCopyWith<$Res>  {
  factory $TechnicianProfileEntityCopyWith(TechnicianProfileEntity value, $Res Function(TechnicianProfileEntity) _then) = _$TechnicianProfileEntityCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, String city, String? profilePicture, double ratingAverage, int reviewCount, int experienceYears, String bio, double? distanceKm, double? bayesianScore, bool isActive, String uiRatingText, String primaryPrice, String primaryPriceRaw, String priceContext, String? promoTag, List<TechnicianSkillEntity> skills, List<TechnicianReviewEntity> recentReviews
});




}
/// @nodoc
class _$TechnicianProfileEntityCopyWithImpl<$Res>
    implements $TechnicianProfileEntityCopyWith<$Res> {
  _$TechnicianProfileEntityCopyWithImpl(this._self, this._then);

  final TechnicianProfileEntity _self;
  final $Res Function(TechnicianProfileEntity) _then;

/// Create a copy of TechnicianProfileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? experienceYears = null,Object? bio = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? primaryPriceRaw = null,Object? priceContext = null,Object? promoTag = freezed,Object? skills = null,Object? recentReviews = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,experienceYears: null == experienceYears ? _self.experienceYears : experienceYears // ignore: cast_nullable_to_non_nullable
as int,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: freezed == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,uiRatingText: null == uiRatingText ? _self.uiRatingText : uiRatingText // ignore: cast_nullable_to_non_nullable
as String,primaryPrice: null == primaryPrice ? _self.primaryPrice : primaryPrice // ignore: cast_nullable_to_non_nullable
as String,primaryPriceRaw: null == primaryPriceRaw ? _self.primaryPriceRaw : primaryPriceRaw // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,promoTag: freezed == promoTag ? _self.promoTag : promoTag // ignore: cast_nullable_to_non_nullable
as String?,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<TechnicianSkillEntity>,recentReviews: null == recentReviews ? _self.recentReviews : recentReviews // ignore: cast_nullable_to_non_nullable
as List<TechnicianReviewEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianProfileEntity].
extension TechnicianProfileEntityPatterns on TechnicianProfileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianProfileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianProfileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianProfileEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianProfileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianProfileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianProfileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  int experienceYears,  String bio,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String primaryPriceRaw,  String priceContext,  String? promoTag,  List<TechnicianSkillEntity> skills,  List<TechnicianReviewEntity> recentReviews)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianProfileEntity() when $default != null:
return $default(_that.id,_that.fullName,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.experienceYears,_that.bio,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.primaryPriceRaw,_that.priceContext,_that.promoTag,_that.skills,_that.recentReviews);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  int experienceYears,  String bio,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String primaryPriceRaw,  String priceContext,  String? promoTag,  List<TechnicianSkillEntity> skills,  List<TechnicianReviewEntity> recentReviews)  $default,) {final _that = this;
switch (_that) {
case _TechnicianProfileEntity():
return $default(_that.id,_that.fullName,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.experienceYears,_that.bio,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.primaryPriceRaw,_that.priceContext,_that.promoTag,_that.skills,_that.recentReviews);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  int experienceYears,  String bio,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String primaryPriceRaw,  String priceContext,  String? promoTag,  List<TechnicianSkillEntity> skills,  List<TechnicianReviewEntity> recentReviews)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianProfileEntity() when $default != null:
return $default(_that.id,_that.fullName,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.experienceYears,_that.bio,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.primaryPriceRaw,_that.priceContext,_that.promoTag,_that.skills,_that.recentReviews);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianProfileEntity implements TechnicianProfileEntity {
  const _TechnicianProfileEntity({required this.id, required this.fullName, required this.city, required this.profilePicture, required this.ratingAverage, required this.reviewCount, required this.experienceYears, required this.bio, required this.distanceKm, required this.bayesianScore, required this.isActive, required this.uiRatingText, required this.primaryPrice, required this.primaryPriceRaw, required this.priceContext, required this.promoTag, required final  List<TechnicianSkillEntity> skills, required final  List<TechnicianReviewEntity> recentReviews}): _skills = skills,_recentReviews = recentReviews;
  

@override final  int id;
@override final  String fullName;
@override final  String city;
@override final  String? profilePicture;
@override final  double ratingAverage;
@override final  int reviewCount;
@override final  int experienceYears;
@override final  String bio;
@override final  double? distanceKm;
@override final  double? bayesianScore;
@override final  bool isActive;
// Dumb UI Pricing and Texts
@override final  String uiRatingText;
@override final  String primaryPrice;
@override final  String primaryPriceRaw;
@override final  String priceContext;
@override final  String? promoTag;
 final  List<TechnicianSkillEntity> _skills;
@override List<TechnicianSkillEntity> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

 final  List<TechnicianReviewEntity> _recentReviews;
@override List<TechnicianReviewEntity> get recentReviews {
  if (_recentReviews is EqualUnmodifiableListView) return _recentReviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentReviews);
}


/// Create a copy of TechnicianProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianProfileEntityCopyWith<_TechnicianProfileEntity> get copyWith => __$TechnicianProfileEntityCopyWithImpl<_TechnicianProfileEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianProfileEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.primaryPriceRaw, primaryPriceRaw) || other.primaryPriceRaw == primaryPriceRaw)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&const DeepCollectionEquality().equals(other._skills, _skills)&&const DeepCollectionEquality().equals(other._recentReviews, _recentReviews));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,profilePicture,ratingAverage,reviewCount,experienceYears,bio,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,primaryPriceRaw,priceContext,promoTag,const DeepCollectionEquality().hash(_skills),const DeepCollectionEquality().hash(_recentReviews));

@override
String toString() {
  return 'TechnicianProfileEntity(id: $id, fullName: $fullName, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, experienceYears: $experienceYears, bio: $bio, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, primaryPriceRaw: $primaryPriceRaw, priceContext: $priceContext, promoTag: $promoTag, skills: $skills, recentReviews: $recentReviews)';
}


}

/// @nodoc
abstract mixin class _$TechnicianProfileEntityCopyWith<$Res> implements $TechnicianProfileEntityCopyWith<$Res> {
  factory _$TechnicianProfileEntityCopyWith(_TechnicianProfileEntity value, $Res Function(_TechnicianProfileEntity) _then) = __$TechnicianProfileEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, String city, String? profilePicture, double ratingAverage, int reviewCount, int experienceYears, String bio, double? distanceKm, double? bayesianScore, bool isActive, String uiRatingText, String primaryPrice, String primaryPriceRaw, String priceContext, String? promoTag, List<TechnicianSkillEntity> skills, List<TechnicianReviewEntity> recentReviews
});




}
/// @nodoc
class __$TechnicianProfileEntityCopyWithImpl<$Res>
    implements _$TechnicianProfileEntityCopyWith<$Res> {
  __$TechnicianProfileEntityCopyWithImpl(this._self, this._then);

  final _TechnicianProfileEntity _self;
  final $Res Function(_TechnicianProfileEntity) _then;

/// Create a copy of TechnicianProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? experienceYears = null,Object? bio = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? primaryPriceRaw = null,Object? priceContext = null,Object? promoTag = freezed,Object? skills = null,Object? recentReviews = null,}) {
  return _then(_TechnicianProfileEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,experienceYears: null == experienceYears ? _self.experienceYears : experienceYears // ignore: cast_nullable_to_non_nullable
as int,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: freezed == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,uiRatingText: null == uiRatingText ? _self.uiRatingText : uiRatingText // ignore: cast_nullable_to_non_nullable
as String,primaryPrice: null == primaryPrice ? _self.primaryPrice : primaryPrice // ignore: cast_nullable_to_non_nullable
as String,primaryPriceRaw: null == primaryPriceRaw ? _self.primaryPriceRaw : primaryPriceRaw // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,promoTag: freezed == promoTag ? _self.promoTag : promoTag // ignore: cast_nullable_to_non_nullable
as String?,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<TechnicianSkillEntity>,recentReviews: null == recentReviews ? _self._recentReviews : recentReviews // ignore: cast_nullable_to_non_nullable
as List<TechnicianReviewEntity>,
  ));
}


}

/// @nodoc
mixin _$AvailabilitySlotEntity {

/// Human-readable label for the slot picker UI (e.g. "9:00 AM").
 String get timeString;/// ISO 8601 PKT-aware start time. Pass directly to [scheduledStart].
 String get isoStart;/// ISO 8601 PKT-aware end time. Pass directly to [scheduledEnd].
 String get isoEnd;/// "AM" or "PM" — used to group slots into sections in the picker.
 String get period;
/// Create a copy of AvailabilitySlotEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilitySlotEntityCopyWith<AvailabilitySlotEntity> get copyWith => _$AvailabilitySlotEntityCopyWithImpl<AvailabilitySlotEntity>(this as AvailabilitySlotEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilitySlotEntity&&(identical(other.timeString, timeString) || other.timeString == timeString)&&(identical(other.isoStart, isoStart) || other.isoStart == isoStart)&&(identical(other.isoEnd, isoEnd) || other.isoEnd == isoEnd)&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,timeString,isoStart,isoEnd,period);

@override
String toString() {
  return 'AvailabilitySlotEntity(timeString: $timeString, isoStart: $isoStart, isoEnd: $isoEnd, period: $period)';
}


}

/// @nodoc
abstract mixin class $AvailabilitySlotEntityCopyWith<$Res>  {
  factory $AvailabilitySlotEntityCopyWith(AvailabilitySlotEntity value, $Res Function(AvailabilitySlotEntity) _then) = _$AvailabilitySlotEntityCopyWithImpl;
@useResult
$Res call({
 String timeString, String isoStart, String isoEnd, String period
});




}
/// @nodoc
class _$AvailabilitySlotEntityCopyWithImpl<$Res>
    implements $AvailabilitySlotEntityCopyWith<$Res> {
  _$AvailabilitySlotEntityCopyWithImpl(this._self, this._then);

  final AvailabilitySlotEntity _self;
  final $Res Function(AvailabilitySlotEntity) _then;

/// Create a copy of AvailabilitySlotEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timeString = null,Object? isoStart = null,Object? isoEnd = null,Object? period = null,}) {
  return _then(_self.copyWith(
timeString: null == timeString ? _self.timeString : timeString // ignore: cast_nullable_to_non_nullable
as String,isoStart: null == isoStart ? _self.isoStart : isoStart // ignore: cast_nullable_to_non_nullable
as String,isoEnd: null == isoEnd ? _self.isoEnd : isoEnd // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailabilitySlotEntity].
extension AvailabilitySlotEntityPatterns on AvailabilitySlotEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailabilitySlotEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailabilitySlotEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailabilitySlotEntity value)  $default,){
final _that = this;
switch (_that) {
case _AvailabilitySlotEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailabilitySlotEntity value)?  $default,){
final _that = this;
switch (_that) {
case _AvailabilitySlotEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String timeString,  String isoStart,  String isoEnd,  String period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailabilitySlotEntity() when $default != null:
return $default(_that.timeString,_that.isoStart,_that.isoEnd,_that.period);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String timeString,  String isoStart,  String isoEnd,  String period)  $default,) {final _that = this;
switch (_that) {
case _AvailabilitySlotEntity():
return $default(_that.timeString,_that.isoStart,_that.isoEnd,_that.period);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String timeString,  String isoStart,  String isoEnd,  String period)?  $default,) {final _that = this;
switch (_that) {
case _AvailabilitySlotEntity() when $default != null:
return $default(_that.timeString,_that.isoStart,_that.isoEnd,_that.period);case _:
  return null;

}
}

}

/// @nodoc


class _AvailabilitySlotEntity implements AvailabilitySlotEntity {
  const _AvailabilitySlotEntity({required this.timeString, required this.isoStart, required this.isoEnd, required this.period});
  

/// Human-readable label for the slot picker UI (e.g. "9:00 AM").
@override final  String timeString;
/// ISO 8601 PKT-aware start time. Pass directly to [scheduledStart].
@override final  String isoStart;
/// ISO 8601 PKT-aware end time. Pass directly to [scheduledEnd].
@override final  String isoEnd;
/// "AM" or "PM" — used to group slots into sections in the picker.
@override final  String period;

/// Create a copy of AvailabilitySlotEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailabilitySlotEntityCopyWith<_AvailabilitySlotEntity> get copyWith => __$AvailabilitySlotEntityCopyWithImpl<_AvailabilitySlotEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailabilitySlotEntity&&(identical(other.timeString, timeString) || other.timeString == timeString)&&(identical(other.isoStart, isoStart) || other.isoStart == isoStart)&&(identical(other.isoEnd, isoEnd) || other.isoEnd == isoEnd)&&(identical(other.period, period) || other.period == period));
}


@override
int get hashCode => Object.hash(runtimeType,timeString,isoStart,isoEnd,period);

@override
String toString() {
  return 'AvailabilitySlotEntity(timeString: $timeString, isoStart: $isoStart, isoEnd: $isoEnd, period: $period)';
}


}

/// @nodoc
abstract mixin class _$AvailabilitySlotEntityCopyWith<$Res> implements $AvailabilitySlotEntityCopyWith<$Res> {
  factory _$AvailabilitySlotEntityCopyWith(_AvailabilitySlotEntity value, $Res Function(_AvailabilitySlotEntity) _then) = __$AvailabilitySlotEntityCopyWithImpl;
@override @useResult
$Res call({
 String timeString, String isoStart, String isoEnd, String period
});




}
/// @nodoc
class __$AvailabilitySlotEntityCopyWithImpl<$Res>
    implements _$AvailabilitySlotEntityCopyWith<$Res> {
  __$AvailabilitySlotEntityCopyWithImpl(this._self, this._then);

  final _AvailabilitySlotEntity _self;
  final $Res Function(_AvailabilitySlotEntity) _then;

/// Create a copy of AvailabilitySlotEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timeString = null,Object? isoStart = null,Object? isoEnd = null,Object? period = null,}) {
  return _then(_AvailabilitySlotEntity(
timeString: null == timeString ? _self.timeString : timeString // ignore: cast_nullable_to_non_nullable
as String,isoStart: null == isoStart ? _self.isoStart : isoStart // ignore: cast_nullable_to_non_nullable
as String,isoEnd: null == isoEnd ? _self.isoEnd : isoEnd // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CreatedBookingEntity {

 int get bookingId;
/// Create a copy of CreatedBookingEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatedBookingEntityCopyWith<CreatedBookingEntity> get copyWith => _$CreatedBookingEntityCopyWithImpl<CreatedBookingEntity>(this as CreatedBookingEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatedBookingEntity&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}


@override
int get hashCode => Object.hash(runtimeType,bookingId);

@override
String toString() {
  return 'CreatedBookingEntity(bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class $CreatedBookingEntityCopyWith<$Res>  {
  factory $CreatedBookingEntityCopyWith(CreatedBookingEntity value, $Res Function(CreatedBookingEntity) _then) = _$CreatedBookingEntityCopyWithImpl;
@useResult
$Res call({
 int bookingId
});




}
/// @nodoc
class _$CreatedBookingEntityCopyWithImpl<$Res>
    implements $CreatedBookingEntityCopyWith<$Res> {
  _$CreatedBookingEntityCopyWithImpl(this._self, this._then);

  final CreatedBookingEntity _self;
  final $Res Function(CreatedBookingEntity) _then;

/// Create a copy of CreatedBookingEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = null,}) {
  return _then(_self.copyWith(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CreatedBookingEntity].
extension CreatedBookingEntityPatterns on CreatedBookingEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatedBookingEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatedBookingEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatedBookingEntity value)  $default,){
final _that = this;
switch (_that) {
case _CreatedBookingEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatedBookingEntity value)?  $default,){
final _that = this;
switch (_that) {
case _CreatedBookingEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int bookingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreatedBookingEntity() when $default != null:
return $default(_that.bookingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int bookingId)  $default,) {final _that = this;
switch (_that) {
case _CreatedBookingEntity():
return $default(_that.bookingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int bookingId)?  $default,) {final _that = this;
switch (_that) {
case _CreatedBookingEntity() when $default != null:
return $default(_that.bookingId);case _:
  return null;

}
}

}

/// @nodoc


class _CreatedBookingEntity implements CreatedBookingEntity {
  const _CreatedBookingEntity({required this.bookingId});
  

@override final  int bookingId;

/// Create a copy of CreatedBookingEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatedBookingEntityCopyWith<_CreatedBookingEntity> get copyWith => __$CreatedBookingEntityCopyWithImpl<_CreatedBookingEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatedBookingEntity&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}


@override
int get hashCode => Object.hash(runtimeType,bookingId);

@override
String toString() {
  return 'CreatedBookingEntity(bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class _$CreatedBookingEntityCopyWith<$Res> implements $CreatedBookingEntityCopyWith<$Res> {
  factory _$CreatedBookingEntityCopyWith(_CreatedBookingEntity value, $Res Function(_CreatedBookingEntity) _then) = __$CreatedBookingEntityCopyWithImpl;
@override @useResult
$Res call({
 int bookingId
});




}
/// @nodoc
class __$CreatedBookingEntityCopyWithImpl<$Res>
    implements _$CreatedBookingEntityCopyWith<$Res> {
  __$CreatedBookingEntityCopyWithImpl(this._self, this._then);

  final _CreatedBookingEntity _self;
  final $Res Function(_CreatedBookingEntity) _then;

/// Create a copy of CreatedBookingEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = null,}) {
  return _then(_CreatedBookingEntity(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$SavedAddressEntity {

 int get id; String get label; String get addressText; double get latitude; double get longitude;
/// Create a copy of SavedAddressEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedAddressEntityCopyWith<SavedAddressEntity> get copyWith => _$SavedAddressEntityCopyWithImpl<SavedAddressEntity>(this as SavedAddressEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedAddressEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,addressText,latitude,longitude);

@override
String toString() {
  return 'SavedAddressEntity(id: $id, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $SavedAddressEntityCopyWith<$Res>  {
  factory $SavedAddressEntityCopyWith(SavedAddressEntity value, $Res Function(SavedAddressEntity) _then) = _$SavedAddressEntityCopyWithImpl;
@useResult
$Res call({
 int id, String label, String addressText, double latitude, double longitude
});




}
/// @nodoc
class _$SavedAddressEntityCopyWithImpl<$Res>
    implements $SavedAddressEntityCopyWith<$Res> {
  _$SavedAddressEntityCopyWithImpl(this._self, this._then);

  final SavedAddressEntity _self;
  final $Res Function(SavedAddressEntity) _then;

/// Create a copy of SavedAddressEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? addressText = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedAddressEntity].
extension SavedAddressEntityPatterns on SavedAddressEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedAddressEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedAddressEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedAddressEntity value)  $default,){
final _that = this;
switch (_that) {
case _SavedAddressEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedAddressEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SavedAddressEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label,  String addressText,  double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedAddressEntity() when $default != null:
return $default(_that.id,_that.label,_that.addressText,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label,  String addressText,  double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _SavedAddressEntity():
return $default(_that.id,_that.label,_that.addressText,_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label,  String addressText,  double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _SavedAddressEntity() when $default != null:
return $default(_that.id,_that.label,_that.addressText,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc


class _SavedAddressEntity implements SavedAddressEntity {
  const _SavedAddressEntity({required this.id, required this.label, required this.addressText, required this.latitude, required this.longitude});
  

@override final  int id;
@override final  String label;
@override final  String addressText;
@override final  double latitude;
@override final  double longitude;

/// Create a copy of SavedAddressEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedAddressEntityCopyWith<_SavedAddressEntity> get copyWith => __$SavedAddressEntityCopyWithImpl<_SavedAddressEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedAddressEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}


@override
int get hashCode => Object.hash(runtimeType,id,label,addressText,latitude,longitude);

@override
String toString() {
  return 'SavedAddressEntity(id: $id, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$SavedAddressEntityCopyWith<$Res> implements $SavedAddressEntityCopyWith<$Res> {
  factory _$SavedAddressEntityCopyWith(_SavedAddressEntity value, $Res Function(_SavedAddressEntity) _then) = __$SavedAddressEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String label, String addressText, double latitude, double longitude
});




}
/// @nodoc
class __$SavedAddressEntityCopyWithImpl<$Res>
    implements _$SavedAddressEntityCopyWith<$Res> {
  __$SavedAddressEntityCopyWithImpl(this._self, this._then);

  final _SavedAddressEntity _self;
  final $Res Function(_SavedAddressEntity) _then;

/// Create a copy of SavedAddressEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? addressText = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_SavedAddressEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on

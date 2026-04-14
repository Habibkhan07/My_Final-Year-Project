// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechnicianSkillModel {

 String get name;// Nullable: backend sends null when SubService.icon_name is unset in Admin.
@JsonKey(name: 'icon_name') String? get iconName;
/// Create a copy of TechnicianSkillModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianSkillModelCopyWith<TechnicianSkillModel> get copyWith => _$TechnicianSkillModelCopyWithImpl<TechnicianSkillModel>(this as TechnicianSkillModel, _$identity);

  /// Serializes this TechnicianSkillModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianSkillModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'TechnicianSkillModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class $TechnicianSkillModelCopyWith<$Res>  {
  factory $TechnicianSkillModelCopyWith(TechnicianSkillModel value, $Res Function(TechnicianSkillModel) _then) = _$TechnicianSkillModelCopyWithImpl;
@useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String? iconName
});




}
/// @nodoc
class _$TechnicianSkillModelCopyWithImpl<$Res>
    implements $TechnicianSkillModelCopyWith<$Res> {
  _$TechnicianSkillModelCopyWithImpl(this._self, this._then);

  final TechnicianSkillModel _self;
  final $Res Function(TechnicianSkillModel) _then;

/// Create a copy of TechnicianSkillModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? iconName = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianSkillModel].
extension TechnicianSkillModelPatterns on TechnicianSkillModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianSkillModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianSkillModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianSkillModel value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianSkillModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianSkillModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianSkillModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'icon_name')  String? iconName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianSkillModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name, @JsonKey(name: 'icon_name')  String? iconName)  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name, @JsonKey(name: 'icon_name')  String? iconName)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianSkillModel() when $default != null:
return $default(_that.name,_that.iconName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianSkillModel extends TechnicianSkillModel {
  const _TechnicianSkillModel({required this.name, @JsonKey(name: 'icon_name') required this.iconName}): super._();
  factory _TechnicianSkillModel.fromJson(Map<String, dynamic> json) => _$TechnicianSkillModelFromJson(json);

@override final  String name;
// Nullable: backend sends null when SubService.icon_name is unset in Admin.
@override@JsonKey(name: 'icon_name') final  String? iconName;

/// Create a copy of TechnicianSkillModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianSkillModelCopyWith<_TechnicianSkillModel> get copyWith => __$TechnicianSkillModelCopyWithImpl<_TechnicianSkillModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianSkillModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianSkillModel&&(identical(other.name, name) || other.name == name)&&(identical(other.iconName, iconName) || other.iconName == iconName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,iconName);

@override
String toString() {
  return 'TechnicianSkillModel(name: $name, iconName: $iconName)';
}


}

/// @nodoc
abstract mixin class _$TechnicianSkillModelCopyWith<$Res> implements $TechnicianSkillModelCopyWith<$Res> {
  factory _$TechnicianSkillModelCopyWith(_TechnicianSkillModel value, $Res Function(_TechnicianSkillModel) _then) = __$TechnicianSkillModelCopyWithImpl;
@override @useResult
$Res call({
 String name,@JsonKey(name: 'icon_name') String? iconName
});




}
/// @nodoc
class __$TechnicianSkillModelCopyWithImpl<$Res>
    implements _$TechnicianSkillModelCopyWith<$Res> {
  __$TechnicianSkillModelCopyWithImpl(this._self, this._then);

  final _TechnicianSkillModel _self;
  final $Res Function(_TechnicianSkillModel) _then;

/// Create a copy of TechnicianSkillModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? iconName = freezed,}) {
  return _then(_TechnicianSkillModel(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TechnicianReviewModel {

@JsonKey(name: 'reviewer_name') String get reviewerName; int get rating; String get text;
/// Create a copy of TechnicianReviewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianReviewModelCopyWith<TechnicianReviewModel> get copyWith => _$TechnicianReviewModelCopyWithImpl<TechnicianReviewModel>(this as TechnicianReviewModel, _$identity);

  /// Serializes this TechnicianReviewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianReviewModel&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerName,rating,text);

@override
String toString() {
  return 'TechnicianReviewModel(reviewerName: $reviewerName, rating: $rating, text: $text)';
}


}

/// @nodoc
abstract mixin class $TechnicianReviewModelCopyWith<$Res>  {
  factory $TechnicianReviewModelCopyWith(TechnicianReviewModel value, $Res Function(TechnicianReviewModel) _then) = _$TechnicianReviewModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reviewer_name') String reviewerName, int rating, String text
});




}
/// @nodoc
class _$TechnicianReviewModelCopyWithImpl<$Res>
    implements $TechnicianReviewModelCopyWith<$Res> {
  _$TechnicianReviewModelCopyWithImpl(this._self, this._then);

  final TechnicianReviewModel _self;
  final $Res Function(TechnicianReviewModel) _then;

/// Create a copy of TechnicianReviewModel
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


/// Adds pattern-matching-related methods to [TechnicianReviewModel].
extension TechnicianReviewModelPatterns on TechnicianReviewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianReviewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianReviewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianReviewModel value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianReviewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianReviewModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianReviewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reviewer_name')  String reviewerName,  int rating,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianReviewModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reviewer_name')  String reviewerName,  int rating,  String text)  $default,) {final _that = this;
switch (_that) {
case _TechnicianReviewModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reviewer_name')  String reviewerName,  int rating,  String text)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianReviewModel() when $default != null:
return $default(_that.reviewerName,_that.rating,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianReviewModel extends TechnicianReviewModel {
  const _TechnicianReviewModel({@JsonKey(name: 'reviewer_name') required this.reviewerName, required this.rating, required this.text}): super._();
  factory _TechnicianReviewModel.fromJson(Map<String, dynamic> json) => _$TechnicianReviewModelFromJson(json);

@override@JsonKey(name: 'reviewer_name') final  String reviewerName;
@override final  int rating;
@override final  String text;

/// Create a copy of TechnicianReviewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianReviewModelCopyWith<_TechnicianReviewModel> get copyWith => __$TechnicianReviewModelCopyWithImpl<_TechnicianReviewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianReviewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianReviewModel&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reviewerName,rating,text);

@override
String toString() {
  return 'TechnicianReviewModel(reviewerName: $reviewerName, rating: $rating, text: $text)';
}


}

/// @nodoc
abstract mixin class _$TechnicianReviewModelCopyWith<$Res> implements $TechnicianReviewModelCopyWith<$Res> {
  factory _$TechnicianReviewModelCopyWith(_TechnicianReviewModel value, $Res Function(_TechnicianReviewModel) _then) = __$TechnicianReviewModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reviewer_name') String reviewerName, int rating, String text
});




}
/// @nodoc
class __$TechnicianReviewModelCopyWithImpl<$Res>
    implements _$TechnicianReviewModelCopyWith<$Res> {
  __$TechnicianReviewModelCopyWithImpl(this._self, this._then);

  final _TechnicianReviewModel _self;
  final $Res Function(_TechnicianReviewModel) _then;

/// Create a copy of TechnicianReviewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviewerName = null,Object? rating = null,Object? text = null,}) {
  return _then(_TechnicianReviewModel(
reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TechnicianProfileModel {

 int get id;@JsonKey(name: 'full_name') String get fullName; String get city;@JsonKey(name: 'profile_picture') String? get profilePicture;@JsonKey(name: 'rating_average') double get ratingAverage;@JsonKey(name: 'review_count') int get reviewCount;@JsonKey(name: 'experience_years') int get experienceYears; String get bio;@JsonKey(name: 'distance_km') double? get distanceKm;@JsonKey(name: 'bayesian_score') double? get bayesianScore;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'ui_rating_text') String get uiRatingText;@JsonKey(name: 'primary_price') String get primaryPrice;@JsonKey(name: 'primary_price_raw') String get primaryPriceRaw;@JsonKey(name: 'price_context') String get priceContext;@JsonKey(name: 'promo_tag') String? get promoTag; List<TechnicianSkillModel> get skills;@JsonKey(name: 'recent_reviews') List<TechnicianReviewModel> get recentReviews;
/// Create a copy of TechnicianProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianProfileModelCopyWith<TechnicianProfileModel> get copyWith => _$TechnicianProfileModelCopyWithImpl<TechnicianProfileModel>(this as TechnicianProfileModel, _$identity);

  /// Serializes this TechnicianProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.primaryPriceRaw, primaryPriceRaw) || other.primaryPriceRaw == primaryPriceRaw)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&const DeepCollectionEquality().equals(other.skills, skills)&&const DeepCollectionEquality().equals(other.recentReviews, recentReviews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,profilePicture,ratingAverage,reviewCount,experienceYears,bio,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,primaryPriceRaw,priceContext,promoTag,const DeepCollectionEquality().hash(skills),const DeepCollectionEquality().hash(recentReviews));

@override
String toString() {
  return 'TechnicianProfileModel(id: $id, fullName: $fullName, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, experienceYears: $experienceYears, bio: $bio, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, primaryPriceRaw: $primaryPriceRaw, priceContext: $priceContext, promoTag: $promoTag, skills: $skills, recentReviews: $recentReviews)';
}


}

/// @nodoc
abstract mixin class $TechnicianProfileModelCopyWith<$Res>  {
  factory $TechnicianProfileModelCopyWith(TechnicianProfileModel value, $Res Function(TechnicianProfileModel) _then) = _$TechnicianProfileModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName, String city,@JsonKey(name: 'profile_picture') String? profilePicture,@JsonKey(name: 'rating_average') double ratingAverage,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'experience_years') int experienceYears, String bio,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'bayesian_score') double? bayesianScore,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'ui_rating_text') String uiRatingText,@JsonKey(name: 'primary_price') String primaryPrice,@JsonKey(name: 'primary_price_raw') String primaryPriceRaw,@JsonKey(name: 'price_context') String priceContext,@JsonKey(name: 'promo_tag') String? promoTag, List<TechnicianSkillModel> skills,@JsonKey(name: 'recent_reviews') List<TechnicianReviewModel> recentReviews
});




}
/// @nodoc
class _$TechnicianProfileModelCopyWithImpl<$Res>
    implements $TechnicianProfileModelCopyWith<$Res> {
  _$TechnicianProfileModelCopyWithImpl(this._self, this._then);

  final TechnicianProfileModel _self;
  final $Res Function(TechnicianProfileModel) _then;

/// Create a copy of TechnicianProfileModel
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
as List<TechnicianSkillModel>,recentReviews: null == recentReviews ? _self.recentReviews : recentReviews // ignore: cast_nullable_to_non_nullable
as List<TechnicianReviewModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianProfileModel].
extension TechnicianProfileModelPatterns on TechnicianProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'primary_price_raw')  String primaryPriceRaw, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag,  List<TechnicianSkillModel> skills, @JsonKey(name: 'recent_reviews')  List<TechnicianReviewModel> recentReviews)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianProfileModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'primary_price_raw')  String primaryPriceRaw, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag,  List<TechnicianSkillModel> skills, @JsonKey(name: 'recent_reviews')  List<TechnicianReviewModel> recentReviews)  $default,) {final _that = this;
switch (_that) {
case _TechnicianProfileModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'full_name')  String fullName,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'primary_price_raw')  String primaryPriceRaw, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag,  List<TechnicianSkillModel> skills, @JsonKey(name: 'recent_reviews')  List<TechnicianReviewModel> recentReviews)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianProfileModel() when $default != null:
return $default(_that.id,_that.fullName,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.experienceYears,_that.bio,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.primaryPriceRaw,_that.priceContext,_that.promoTag,_that.skills,_that.recentReviews);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianProfileModel extends TechnicianProfileModel {
  const _TechnicianProfileModel({required this.id, @JsonKey(name: 'full_name') required this.fullName, required this.city, @JsonKey(name: 'profile_picture') required this.profilePicture, @JsonKey(name: 'rating_average') required this.ratingAverage, @JsonKey(name: 'review_count') required this.reviewCount, @JsonKey(name: 'experience_years') required this.experienceYears, required this.bio, @JsonKey(name: 'distance_km') this.distanceKm, @JsonKey(name: 'bayesian_score') this.bayesianScore, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'ui_rating_text') required this.uiRatingText, @JsonKey(name: 'primary_price') required this.primaryPrice, @JsonKey(name: 'primary_price_raw') required this.primaryPriceRaw, @JsonKey(name: 'price_context') required this.priceContext, @JsonKey(name: 'promo_tag') this.promoTag, required final  List<TechnicianSkillModel> skills, @JsonKey(name: 'recent_reviews') required final  List<TechnicianReviewModel> recentReviews}): _skills = skills,_recentReviews = recentReviews,super._();
  factory _TechnicianProfileModel.fromJson(Map<String, dynamic> json) => _$TechnicianProfileModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String city;
@override@JsonKey(name: 'profile_picture') final  String? profilePicture;
@override@JsonKey(name: 'rating_average') final  double ratingAverage;
@override@JsonKey(name: 'review_count') final  int reviewCount;
@override@JsonKey(name: 'experience_years') final  int experienceYears;
@override final  String bio;
@override@JsonKey(name: 'distance_km') final  double? distanceKm;
@override@JsonKey(name: 'bayesian_score') final  double? bayesianScore;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'ui_rating_text') final  String uiRatingText;
@override@JsonKey(name: 'primary_price') final  String primaryPrice;
@override@JsonKey(name: 'primary_price_raw') final  String primaryPriceRaw;
@override@JsonKey(name: 'price_context') final  String priceContext;
@override@JsonKey(name: 'promo_tag') final  String? promoTag;
 final  List<TechnicianSkillModel> _skills;
@override List<TechnicianSkillModel> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}

 final  List<TechnicianReviewModel> _recentReviews;
@override@JsonKey(name: 'recent_reviews') List<TechnicianReviewModel> get recentReviews {
  if (_recentReviews is EqualUnmodifiableListView) return _recentReviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentReviews);
}


/// Create a copy of TechnicianProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianProfileModelCopyWith<_TechnicianProfileModel> get copyWith => __$TechnicianProfileModelCopyWithImpl<_TechnicianProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianProfileModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.primaryPriceRaw, primaryPriceRaw) || other.primaryPriceRaw == primaryPriceRaw)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&const DeepCollectionEquality().equals(other._skills, _skills)&&const DeepCollectionEquality().equals(other._recentReviews, _recentReviews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,profilePicture,ratingAverage,reviewCount,experienceYears,bio,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,primaryPriceRaw,priceContext,promoTag,const DeepCollectionEquality().hash(_skills),const DeepCollectionEquality().hash(_recentReviews));

@override
String toString() {
  return 'TechnicianProfileModel(id: $id, fullName: $fullName, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, experienceYears: $experienceYears, bio: $bio, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, primaryPriceRaw: $primaryPriceRaw, priceContext: $priceContext, promoTag: $promoTag, skills: $skills, recentReviews: $recentReviews)';
}


}

/// @nodoc
abstract mixin class _$TechnicianProfileModelCopyWith<$Res> implements $TechnicianProfileModelCopyWith<$Res> {
  factory _$TechnicianProfileModelCopyWith(_TechnicianProfileModel value, $Res Function(_TechnicianProfileModel) _then) = __$TechnicianProfileModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName, String city,@JsonKey(name: 'profile_picture') String? profilePicture,@JsonKey(name: 'rating_average') double ratingAverage,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'experience_years') int experienceYears, String bio,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'bayesian_score') double? bayesianScore,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'ui_rating_text') String uiRatingText,@JsonKey(name: 'primary_price') String primaryPrice,@JsonKey(name: 'primary_price_raw') String primaryPriceRaw,@JsonKey(name: 'price_context') String priceContext,@JsonKey(name: 'promo_tag') String? promoTag, List<TechnicianSkillModel> skills,@JsonKey(name: 'recent_reviews') List<TechnicianReviewModel> recentReviews
});




}
/// @nodoc
class __$TechnicianProfileModelCopyWithImpl<$Res>
    implements _$TechnicianProfileModelCopyWith<$Res> {
  __$TechnicianProfileModelCopyWithImpl(this._self, this._then);

  final _TechnicianProfileModel _self;
  final $Res Function(_TechnicianProfileModel) _then;

/// Create a copy of TechnicianProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? experienceYears = null,Object? bio = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? primaryPriceRaw = null,Object? priceContext = null,Object? promoTag = freezed,Object? skills = null,Object? recentReviews = null,}) {
  return _then(_TechnicianProfileModel(
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
as List<TechnicianSkillModel>,recentReviews: null == recentReviews ? _self._recentReviews : recentReviews // ignore: cast_nullable_to_non_nullable
as List<TechnicianReviewModel>,
  ));
}


}


/// @nodoc
mixin _$AvailabilitySlotModel {

@JsonKey(name: 'time_string') String get timeString;/// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
@JsonKey(name: 'iso_start') String get isoStart;/// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
@JsonKey(name: 'iso_end') String get isoEnd; String get period;
/// Create a copy of AvailabilitySlotModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilitySlotModelCopyWith<AvailabilitySlotModel> get copyWith => _$AvailabilitySlotModelCopyWithImpl<AvailabilitySlotModel>(this as AvailabilitySlotModel, _$identity);

  /// Serializes this AvailabilitySlotModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilitySlotModel&&(identical(other.timeString, timeString) || other.timeString == timeString)&&(identical(other.isoStart, isoStart) || other.isoStart == isoStart)&&(identical(other.isoEnd, isoEnd) || other.isoEnd == isoEnd)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeString,isoStart,isoEnd,period);

@override
String toString() {
  return 'AvailabilitySlotModel(timeString: $timeString, isoStart: $isoStart, isoEnd: $isoEnd, period: $period)';
}


}

/// @nodoc
abstract mixin class $AvailabilitySlotModelCopyWith<$Res>  {
  factory $AvailabilitySlotModelCopyWith(AvailabilitySlotModel value, $Res Function(AvailabilitySlotModel) _then) = _$AvailabilitySlotModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'time_string') String timeString,@JsonKey(name: 'iso_start') String isoStart,@JsonKey(name: 'iso_end') String isoEnd, String period
});




}
/// @nodoc
class _$AvailabilitySlotModelCopyWithImpl<$Res>
    implements $AvailabilitySlotModelCopyWith<$Res> {
  _$AvailabilitySlotModelCopyWithImpl(this._self, this._then);

  final AvailabilitySlotModel _self;
  final $Res Function(AvailabilitySlotModel) _then;

/// Create a copy of AvailabilitySlotModel
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


/// Adds pattern-matching-related methods to [AvailabilitySlotModel].
extension AvailabilitySlotModelPatterns on AvailabilitySlotModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailabilitySlotModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailabilitySlotModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailabilitySlotModel value)  $default,){
final _that = this;
switch (_that) {
case _AvailabilitySlotModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailabilitySlotModel value)?  $default,){
final _that = this;
switch (_that) {
case _AvailabilitySlotModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'time_string')  String timeString, @JsonKey(name: 'iso_start')  String isoStart, @JsonKey(name: 'iso_end')  String isoEnd,  String period)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailabilitySlotModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'time_string')  String timeString, @JsonKey(name: 'iso_start')  String isoStart, @JsonKey(name: 'iso_end')  String isoEnd,  String period)  $default,) {final _that = this;
switch (_that) {
case _AvailabilitySlotModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'time_string')  String timeString, @JsonKey(name: 'iso_start')  String isoStart, @JsonKey(name: 'iso_end')  String isoEnd,  String period)?  $default,) {final _that = this;
switch (_that) {
case _AvailabilitySlotModel() when $default != null:
return $default(_that.timeString,_that.isoStart,_that.isoEnd,_that.period);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailabilitySlotModel extends AvailabilitySlotModel {
  const _AvailabilitySlotModel({@JsonKey(name: 'time_string') required this.timeString, @JsonKey(name: 'iso_start') required this.isoStart, @JsonKey(name: 'iso_end') required this.isoEnd, required this.period}): super._();
  factory _AvailabilitySlotModel.fromJson(Map<String, dynamic> json) => _$AvailabilitySlotModelFromJson(json);

@override@JsonKey(name: 'time_string') final  String timeString;
/// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
@override@JsonKey(name: 'iso_start') final  String isoStart;
/// ISO 8601 PKT-aware — stored as String, passed verbatim to instant-book.
@override@JsonKey(name: 'iso_end') final  String isoEnd;
@override final  String period;

/// Create a copy of AvailabilitySlotModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailabilitySlotModelCopyWith<_AvailabilitySlotModel> get copyWith => __$AvailabilitySlotModelCopyWithImpl<_AvailabilitySlotModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailabilitySlotModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailabilitySlotModel&&(identical(other.timeString, timeString) || other.timeString == timeString)&&(identical(other.isoStart, isoStart) || other.isoStart == isoStart)&&(identical(other.isoEnd, isoEnd) || other.isoEnd == isoEnd)&&(identical(other.period, period) || other.period == period));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timeString,isoStart,isoEnd,period);

@override
String toString() {
  return 'AvailabilitySlotModel(timeString: $timeString, isoStart: $isoStart, isoEnd: $isoEnd, period: $period)';
}


}

/// @nodoc
abstract mixin class _$AvailabilitySlotModelCopyWith<$Res> implements $AvailabilitySlotModelCopyWith<$Res> {
  factory _$AvailabilitySlotModelCopyWith(_AvailabilitySlotModel value, $Res Function(_AvailabilitySlotModel) _then) = __$AvailabilitySlotModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'time_string') String timeString,@JsonKey(name: 'iso_start') String isoStart,@JsonKey(name: 'iso_end') String isoEnd, String period
});




}
/// @nodoc
class __$AvailabilitySlotModelCopyWithImpl<$Res>
    implements _$AvailabilitySlotModelCopyWith<$Res> {
  __$AvailabilitySlotModelCopyWithImpl(this._self, this._then);

  final _AvailabilitySlotModel _self;
  final $Res Function(_AvailabilitySlotModel) _then;

/// Create a copy of AvailabilitySlotModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timeString = null,Object? isoStart = null,Object? isoEnd = null,Object? period = null,}) {
  return _then(_AvailabilitySlotModel(
timeString: null == timeString ? _self.timeString : timeString // ignore: cast_nullable_to_non_nullable
as String,isoStart: null == isoStart ? _self.isoStart : isoStart // ignore: cast_nullable_to_non_nullable
as String,isoEnd: null == isoEnd ? _self.isoEnd : isoEnd // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InstantBookingRequestModel {

@JsonKey(name: 'technician_id') int get technicianId;@JsonKey(name: 'address_id') int get addressId;/// Pass [AvailabilitySlotEntity.isoStart] directly — no conversion.
@JsonKey(name: 'scheduled_start') String get scheduledStart;/// Pass [AvailabilitySlotEntity.isoEnd] directly — no conversion.
@JsonKey(name: 'scheduled_end') String get scheduledEnd;/// Decimal string e.g. "1500.00" — backend validates as DecimalField.
@JsonKey(name: 'price_amount') String get priceAmount;/// Optional display label for the UI receipt (max 50 chars).
@JsonKey(name: 'price_context') String get priceContext;
/// Create a copy of InstantBookingRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstantBookingRequestModelCopyWith<InstantBookingRequestModel> get copyWith => _$InstantBookingRequestModelCopyWithImpl<InstantBookingRequestModel>(this as InstantBookingRequestModel, _$identity);

  /// Serializes this InstantBookingRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstantBookingRequestModel&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,technicianId,addressId,scheduledStart,scheduledEnd,priceAmount,priceContext);

@override
String toString() {
  return 'InstantBookingRequestModel(technicianId: $technicianId, addressId: $addressId, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, priceAmount: $priceAmount, priceContext: $priceContext)';
}


}

/// @nodoc
abstract mixin class $InstantBookingRequestModelCopyWith<$Res>  {
  factory $InstantBookingRequestModelCopyWith(InstantBookingRequestModel value, $Res Function(InstantBookingRequestModel) _then) = _$InstantBookingRequestModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'technician_id') int technicianId,@JsonKey(name: 'address_id') int addressId,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'price_amount') String priceAmount,@JsonKey(name: 'price_context') String priceContext
});




}
/// @nodoc
class _$InstantBookingRequestModelCopyWithImpl<$Res>
    implements $InstantBookingRequestModelCopyWith<$Res> {
  _$InstantBookingRequestModelCopyWithImpl(this._self, this._then);

  final InstantBookingRequestModel _self;
  final $Res Function(InstantBookingRequestModel) _then;

/// Create a copy of InstantBookingRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? technicianId = null,Object? addressId = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? priceAmount = null,Object? priceContext = null,}) {
  return _then(_self.copyWith(
technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as int,addressId: null == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as int,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InstantBookingRequestModel].
extension InstantBookingRequestModelPatterns on InstantBookingRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstantBookingRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstantBookingRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstantBookingRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _InstantBookingRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstantBookingRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _InstantBookingRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'technician_id')  int technicianId, @JsonKey(name: 'address_id')  int addressId, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'price_amount')  String priceAmount, @JsonKey(name: 'price_context')  String priceContext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstantBookingRequestModel() when $default != null:
return $default(_that.technicianId,_that.addressId,_that.scheduledStart,_that.scheduledEnd,_that.priceAmount,_that.priceContext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'technician_id')  int technicianId, @JsonKey(name: 'address_id')  int addressId, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'price_amount')  String priceAmount, @JsonKey(name: 'price_context')  String priceContext)  $default,) {final _that = this;
switch (_that) {
case _InstantBookingRequestModel():
return $default(_that.technicianId,_that.addressId,_that.scheduledStart,_that.scheduledEnd,_that.priceAmount,_that.priceContext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'technician_id')  int technicianId, @JsonKey(name: 'address_id')  int addressId, @JsonKey(name: 'scheduled_start')  String scheduledStart, @JsonKey(name: 'scheduled_end')  String scheduledEnd, @JsonKey(name: 'price_amount')  String priceAmount, @JsonKey(name: 'price_context')  String priceContext)?  $default,) {final _that = this;
switch (_that) {
case _InstantBookingRequestModel() when $default != null:
return $default(_that.technicianId,_that.addressId,_that.scheduledStart,_that.scheduledEnd,_that.priceAmount,_that.priceContext);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstantBookingRequestModel implements InstantBookingRequestModel {
  const _InstantBookingRequestModel({@JsonKey(name: 'technician_id') required this.technicianId, @JsonKey(name: 'address_id') required this.addressId, @JsonKey(name: 'scheduled_start') required this.scheduledStart, @JsonKey(name: 'scheduled_end') required this.scheduledEnd, @JsonKey(name: 'price_amount') required this.priceAmount, @JsonKey(name: 'price_context') this.priceContext = ''});
  factory _InstantBookingRequestModel.fromJson(Map<String, dynamic> json) => _$InstantBookingRequestModelFromJson(json);

@override@JsonKey(name: 'technician_id') final  int technicianId;
@override@JsonKey(name: 'address_id') final  int addressId;
/// Pass [AvailabilitySlotEntity.isoStart] directly — no conversion.
@override@JsonKey(name: 'scheduled_start') final  String scheduledStart;
/// Pass [AvailabilitySlotEntity.isoEnd] directly — no conversion.
@override@JsonKey(name: 'scheduled_end') final  String scheduledEnd;
/// Decimal string e.g. "1500.00" — backend validates as DecimalField.
@override@JsonKey(name: 'price_amount') final  String priceAmount;
/// Optional display label for the UI receipt (max 50 chars).
@override@JsonKey(name: 'price_context') final  String priceContext;

/// Create a copy of InstantBookingRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstantBookingRequestModelCopyWith<_InstantBookingRequestModel> get copyWith => __$InstantBookingRequestModelCopyWithImpl<_InstantBookingRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstantBookingRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstantBookingRequestModel&&(identical(other.technicianId, technicianId) || other.technicianId == technicianId)&&(identical(other.addressId, addressId) || other.addressId == addressId)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.scheduledEnd, scheduledEnd) || other.scheduledEnd == scheduledEnd)&&(identical(other.priceAmount, priceAmount) || other.priceAmount == priceAmount)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,technicianId,addressId,scheduledStart,scheduledEnd,priceAmount,priceContext);

@override
String toString() {
  return 'InstantBookingRequestModel(technicianId: $technicianId, addressId: $addressId, scheduledStart: $scheduledStart, scheduledEnd: $scheduledEnd, priceAmount: $priceAmount, priceContext: $priceContext)';
}


}

/// @nodoc
abstract mixin class _$InstantBookingRequestModelCopyWith<$Res> implements $InstantBookingRequestModelCopyWith<$Res> {
  factory _$InstantBookingRequestModelCopyWith(_InstantBookingRequestModel value, $Res Function(_InstantBookingRequestModel) _then) = __$InstantBookingRequestModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'technician_id') int technicianId,@JsonKey(name: 'address_id') int addressId,@JsonKey(name: 'scheduled_start') String scheduledStart,@JsonKey(name: 'scheduled_end') String scheduledEnd,@JsonKey(name: 'price_amount') String priceAmount,@JsonKey(name: 'price_context') String priceContext
});




}
/// @nodoc
class __$InstantBookingRequestModelCopyWithImpl<$Res>
    implements _$InstantBookingRequestModelCopyWith<$Res> {
  __$InstantBookingRequestModelCopyWithImpl(this._self, this._then);

  final _InstantBookingRequestModel _self;
  final $Res Function(_InstantBookingRequestModel) _then;

/// Create a copy of InstantBookingRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? technicianId = null,Object? addressId = null,Object? scheduledStart = null,Object? scheduledEnd = null,Object? priceAmount = null,Object? priceContext = null,}) {
  return _then(_InstantBookingRequestModel(
technicianId: null == technicianId ? _self.technicianId : technicianId // ignore: cast_nullable_to_non_nullable
as int,addressId: null == addressId ? _self.addressId : addressId // ignore: cast_nullable_to_non_nullable
as int,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as String,scheduledEnd: null == scheduledEnd ? _self.scheduledEnd : scheduledEnd // ignore: cast_nullable_to_non_nullable
as String,priceAmount: null == priceAmount ? _self.priceAmount : priceAmount // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InstantBookingResponseModel {

@JsonKey(name: 'booking_id') int get bookingId;
/// Create a copy of InstantBookingResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstantBookingResponseModelCopyWith<InstantBookingResponseModel> get copyWith => _$InstantBookingResponseModelCopyWithImpl<InstantBookingResponseModel>(this as InstantBookingResponseModel, _$identity);

  /// Serializes this InstantBookingResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstantBookingResponseModel&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId);

@override
String toString() {
  return 'InstantBookingResponseModel(bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class $InstantBookingResponseModelCopyWith<$Res>  {
  factory $InstantBookingResponseModelCopyWith(InstantBookingResponseModel value, $Res Function(InstantBookingResponseModel) _then) = _$InstantBookingResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'booking_id') int bookingId
});




}
/// @nodoc
class _$InstantBookingResponseModelCopyWithImpl<$Res>
    implements $InstantBookingResponseModelCopyWith<$Res> {
  _$InstantBookingResponseModelCopyWithImpl(this._self, this._then);

  final InstantBookingResponseModel _self;
  final $Res Function(InstantBookingResponseModel) _then;

/// Create a copy of InstantBookingResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bookingId = null,}) {
  return _then(_self.copyWith(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InstantBookingResponseModel].
extension InstantBookingResponseModelPatterns on InstantBookingResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstantBookingResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstantBookingResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstantBookingResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _InstantBookingResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstantBookingResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _InstantBookingResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int bookingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstantBookingResponseModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'booking_id')  int bookingId)  $default,) {final _that = this;
switch (_that) {
case _InstantBookingResponseModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'booking_id')  int bookingId)?  $default,) {final _that = this;
switch (_that) {
case _InstantBookingResponseModel() when $default != null:
return $default(_that.bookingId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstantBookingResponseModel extends InstantBookingResponseModel {
  const _InstantBookingResponseModel({@JsonKey(name: 'booking_id') required this.bookingId}): super._();
  factory _InstantBookingResponseModel.fromJson(Map<String, dynamic> json) => _$InstantBookingResponseModelFromJson(json);

@override@JsonKey(name: 'booking_id') final  int bookingId;

/// Create a copy of InstantBookingResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstantBookingResponseModelCopyWith<_InstantBookingResponseModel> get copyWith => __$InstantBookingResponseModelCopyWithImpl<_InstantBookingResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstantBookingResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstantBookingResponseModel&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bookingId);

@override
String toString() {
  return 'InstantBookingResponseModel(bookingId: $bookingId)';
}


}

/// @nodoc
abstract mixin class _$InstantBookingResponseModelCopyWith<$Res> implements $InstantBookingResponseModelCopyWith<$Res> {
  factory _$InstantBookingResponseModelCopyWith(_InstantBookingResponseModel value, $Res Function(_InstantBookingResponseModel) _then) = __$InstantBookingResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'booking_id') int bookingId
});




}
/// @nodoc
class __$InstantBookingResponseModelCopyWithImpl<$Res>
    implements _$InstantBookingResponseModelCopyWith<$Res> {
  __$InstantBookingResponseModelCopyWithImpl(this._self, this._then);

  final _InstantBookingResponseModel _self;
  final $Res Function(_InstantBookingResponseModel) _then;

/// Create a copy of InstantBookingResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bookingId = null,}) {
  return _then(_InstantBookingResponseModel(
bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SavedAddressModel {

 int get id; String get label;@JsonKey(name: 'address_text') String get addressText; String get latitude;// String because it's Decimal in DB
 String get longitude;
/// Create a copy of SavedAddressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedAddressModelCopyWith<SavedAddressModel> get copyWith => _$SavedAddressModelCopyWithImpl<SavedAddressModel>(this as SavedAddressModel, _$identity);

  /// Serializes this SavedAddressModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedAddressModel&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,addressText,latitude,longitude);

@override
String toString() {
  return 'SavedAddressModel(id: $id, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $SavedAddressModelCopyWith<$Res>  {
  factory $SavedAddressModelCopyWith(SavedAddressModel value, $Res Function(SavedAddressModel) _then) = _$SavedAddressModelCopyWithImpl;
@useResult
$Res call({
 int id, String label,@JsonKey(name: 'address_text') String addressText, String latitude, String longitude
});




}
/// @nodoc
class _$SavedAddressModelCopyWithImpl<$Res>
    implements $SavedAddressModelCopyWith<$Res> {
  _$SavedAddressModelCopyWithImpl(this._self, this._then);

  final SavedAddressModel _self;
  final $Res Function(SavedAddressModel) _then;

/// Create a copy of SavedAddressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? addressText = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SavedAddressModel].
extension SavedAddressModelPatterns on SavedAddressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedAddressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedAddressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedAddressModel value)  $default,){
final _that = this;
switch (_that) {
case _SavedAddressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedAddressModel value)?  $default,){
final _that = this;
switch (_that) {
case _SavedAddressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'address_text')  String addressText,  String latitude,  String longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedAddressModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'address_text')  String addressText,  String latitude,  String longitude)  $default,) {final _that = this;
switch (_that) {
case _SavedAddressModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label, @JsonKey(name: 'address_text')  String addressText,  String latitude,  String longitude)?  $default,) {final _that = this;
switch (_that) {
case _SavedAddressModel() when $default != null:
return $default(_that.id,_that.label,_that.addressText,_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedAddressModel extends SavedAddressModel {
  const _SavedAddressModel({required this.id, required this.label, @JsonKey(name: 'address_text') required this.addressText, required this.latitude, required this.longitude}): super._();
  factory _SavedAddressModel.fromJson(Map<String, dynamic> json) => _$SavedAddressModelFromJson(json);

@override final  int id;
@override final  String label;
@override@JsonKey(name: 'address_text') final  String addressText;
@override final  String latitude;
// String because it's Decimal in DB
@override final  String longitude;

/// Create a copy of SavedAddressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedAddressModelCopyWith<_SavedAddressModel> get copyWith => __$SavedAddressModelCopyWithImpl<_SavedAddressModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedAddressModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedAddressModel&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,addressText,latitude,longitude);

@override
String toString() {
  return 'SavedAddressModel(id: $id, label: $label, addressText: $addressText, latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$SavedAddressModelCopyWith<$Res> implements $SavedAddressModelCopyWith<$Res> {
  factory _$SavedAddressModelCopyWith(_SavedAddressModel value, $Res Function(_SavedAddressModel) _then) = __$SavedAddressModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String label,@JsonKey(name: 'address_text') String addressText, String latitude, String longitude
});




}
/// @nodoc
class __$SavedAddressModelCopyWithImpl<$Res>
    implements _$SavedAddressModelCopyWith<$Res> {
  __$SavedAddressModelCopyWithImpl(this._self, this._then);

  final _SavedAddressModel _self;
  final $Res Function(_SavedAddressModel) _then;

/// Create a copy of SavedAddressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? addressText = null,Object? latitude = null,Object? longitude = null,}) {
  return _then(_SavedAddressModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as String,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

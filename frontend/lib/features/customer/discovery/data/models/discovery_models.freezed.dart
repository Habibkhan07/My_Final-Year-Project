// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechnicianModel {

 int get id;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'primary_category') String get primaryCategory; String get city;@JsonKey(name: 'profile_picture') String? get profilePicture;@JsonKey(name: 'rating_average') double get ratingAverage;@JsonKey(name: 'review_count') int get reviewCount;@JsonKey(name: 'distance_km') double? get distanceKm;@JsonKey(name: 'bayesian_score') double? get bayesianScore;@JsonKey(name: 'is_active') bool get isActive;// Dumb UI Fields
@JsonKey(name: 'ui_rating_text') String get uiRatingText;@JsonKey(name: 'primary_price') String get primaryPrice;@JsonKey(name: 'price_context') String get priceContext;@JsonKey(name: 'promo_tag') String? get promoTag;@JsonKey(name: 'ui_subtitle_text') String? get uiSubtitleText;
/// Create a copy of TechnicianModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianModelCopyWith<TechnicianModel> get copyWith => _$TechnicianModelCopyWithImpl<TechnicianModel>(this as TechnicianModel, _$identity);

  /// Serializes this TechnicianModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&(identical(other.uiSubtitleText, uiSubtitleText) || other.uiSubtitleText == uiSubtitleText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,priceContext,promoTag,uiSubtitleText);

@override
String toString() {
  return 'TechnicianModel(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, priceContext: $priceContext, promoTag: $promoTag, uiSubtitleText: $uiSubtitleText)';
}


}

/// @nodoc
abstract mixin class $TechnicianModelCopyWith<$Res>  {
  factory $TechnicianModelCopyWith(TechnicianModel value, $Res Function(TechnicianModel) _then) = _$TechnicianModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'primary_category') String primaryCategory, String city,@JsonKey(name: 'profile_picture') String? profilePicture,@JsonKey(name: 'rating_average') double ratingAverage,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'bayesian_score') double? bayesianScore,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'ui_rating_text') String uiRatingText,@JsonKey(name: 'primary_price') String primaryPrice,@JsonKey(name: 'price_context') String priceContext,@JsonKey(name: 'promo_tag') String? promoTag,@JsonKey(name: 'ui_subtitle_text') String? uiSubtitleText
});




}
/// @nodoc
class _$TechnicianModelCopyWithImpl<$Res>
    implements $TechnicianModelCopyWith<$Res> {
  _$TechnicianModelCopyWithImpl(this._self, this._then);

  final TechnicianModel _self;
  final $Res Function(TechnicianModel) _then;

/// Create a copy of TechnicianModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? primaryCategory = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? priceContext = null,Object? promoTag = freezed,Object? uiSubtitleText = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,primaryCategory: null == primaryCategory ? _self.primaryCategory : primaryCategory // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: freezed == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,uiRatingText: null == uiRatingText ? _self.uiRatingText : uiRatingText // ignore: cast_nullable_to_non_nullable
as String,primaryPrice: null == primaryPrice ? _self.primaryPrice : primaryPrice // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,promoTag: freezed == promoTag ? _self.promoTag : promoTag // ignore: cast_nullable_to_non_nullable
as String?,uiSubtitleText: freezed == uiSubtitleText ? _self.uiSubtitleText : uiSubtitleText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianModel].
extension TechnicianModelPatterns on TechnicianModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianModel value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'primary_category')  String primaryCategory,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag, @JsonKey(name: 'ui_subtitle_text')  String? uiSubtitleText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianModel() when $default != null:
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.priceContext,_that.promoTag,_that.uiSubtitleText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'primary_category')  String primaryCategory,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag, @JsonKey(name: 'ui_subtitle_text')  String? uiSubtitleText)  $default,) {final _that = this;
switch (_that) {
case _TechnicianModel():
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.priceContext,_that.promoTag,_that.uiSubtitleText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'primary_category')  String primaryCategory,  String city, @JsonKey(name: 'profile_picture')  String? profilePicture, @JsonKey(name: 'rating_average')  double ratingAverage, @JsonKey(name: 'review_count')  int reviewCount, @JsonKey(name: 'distance_km')  double? distanceKm, @JsonKey(name: 'bayesian_score')  double? bayesianScore, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'ui_rating_text')  String uiRatingText, @JsonKey(name: 'primary_price')  String primaryPrice, @JsonKey(name: 'price_context')  String priceContext, @JsonKey(name: 'promo_tag')  String? promoTag, @JsonKey(name: 'ui_subtitle_text')  String? uiSubtitleText)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianModel() when $default != null:
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.priceContext,_that.promoTag,_that.uiSubtitleText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianModel extends TechnicianModel {
  const _TechnicianModel({required this.id, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'primary_category') required this.primaryCategory, required this.city, @JsonKey(name: 'profile_picture') required this.profilePicture, @JsonKey(name: 'rating_average') required this.ratingAverage, @JsonKey(name: 'review_count') required this.reviewCount, @JsonKey(name: 'distance_km') this.distanceKm, @JsonKey(name: 'bayesian_score') this.bayesianScore, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'ui_rating_text') required this.uiRatingText, @JsonKey(name: 'primary_price') required this.primaryPrice, @JsonKey(name: 'price_context') required this.priceContext, @JsonKey(name: 'promo_tag') this.promoTag, @JsonKey(name: 'ui_subtitle_text') this.uiSubtitleText}): super._();
  factory _TechnicianModel.fromJson(Map<String, dynamic> json) => _$TechnicianModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'primary_category') final  String primaryCategory;
@override final  String city;
@override@JsonKey(name: 'profile_picture') final  String? profilePicture;
@override@JsonKey(name: 'rating_average') final  double ratingAverage;
@override@JsonKey(name: 'review_count') final  int reviewCount;
@override@JsonKey(name: 'distance_km') final  double? distanceKm;
@override@JsonKey(name: 'bayesian_score') final  double? bayesianScore;
@override@JsonKey(name: 'is_active') final  bool isActive;
// Dumb UI Fields
@override@JsonKey(name: 'ui_rating_text') final  String uiRatingText;
@override@JsonKey(name: 'primary_price') final  String primaryPrice;
@override@JsonKey(name: 'price_context') final  String priceContext;
@override@JsonKey(name: 'promo_tag') final  String? promoTag;
@override@JsonKey(name: 'ui_subtitle_text') final  String? uiSubtitleText;

/// Create a copy of TechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianModelCopyWith<_TechnicianModel> get copyWith => __$TechnicianModelCopyWithImpl<_TechnicianModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianModel&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&(identical(other.uiSubtitleText, uiSubtitleText) || other.uiSubtitleText == uiSubtitleText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,priceContext,promoTag,uiSubtitleText);

@override
String toString() {
  return 'TechnicianModel(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, priceContext: $priceContext, promoTag: $promoTag, uiSubtitleText: $uiSubtitleText)';
}


}

/// @nodoc
abstract mixin class _$TechnicianModelCopyWith<$Res> implements $TechnicianModelCopyWith<$Res> {
  factory _$TechnicianModelCopyWith(_TechnicianModel value, $Res Function(_TechnicianModel) _then) = __$TechnicianModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'primary_category') String primaryCategory, String city,@JsonKey(name: 'profile_picture') String? profilePicture,@JsonKey(name: 'rating_average') double ratingAverage,@JsonKey(name: 'review_count') int reviewCount,@JsonKey(name: 'distance_km') double? distanceKm,@JsonKey(name: 'bayesian_score') double? bayesianScore,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'ui_rating_text') String uiRatingText,@JsonKey(name: 'primary_price') String primaryPrice,@JsonKey(name: 'price_context') String priceContext,@JsonKey(name: 'promo_tag') String? promoTag,@JsonKey(name: 'ui_subtitle_text') String? uiSubtitleText
});




}
/// @nodoc
class __$TechnicianModelCopyWithImpl<$Res>
    implements _$TechnicianModelCopyWith<$Res> {
  __$TechnicianModelCopyWithImpl(this._self, this._then);

  final _TechnicianModel _self;
  final $Res Function(_TechnicianModel) _then;

/// Create a copy of TechnicianModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? primaryCategory = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? priceContext = null,Object? promoTag = freezed,Object? uiSubtitleText = freezed,}) {
  return _then(_TechnicianModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,primaryCategory: null == primaryCategory ? _self.primaryCategory : primaryCategory // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,ratingAverage: null == ratingAverage ? _self.ratingAverage : ratingAverage // ignore: cast_nullable_to_non_nullable
as double,reviewCount: null == reviewCount ? _self.reviewCount : reviewCount // ignore: cast_nullable_to_non_nullable
as int,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,bayesianScore: freezed == bayesianScore ? _self.bayesianScore : bayesianScore // ignore: cast_nullable_to_non_nullable
as double?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,uiRatingText: null == uiRatingText ? _self.uiRatingText : uiRatingText // ignore: cast_nullable_to_non_nullable
as String,primaryPrice: null == primaryPrice ? _self.primaryPrice : primaryPrice // ignore: cast_nullable_to_non_nullable
as String,priceContext: null == priceContext ? _self.priceContext : priceContext // ignore: cast_nullable_to_non_nullable
as String,promoTag: freezed == promoTag ? _self.promoTag : promoTag // ignore: cast_nullable_to_non_nullable
as String?,uiSubtitleText: freezed == uiSubtitleText ? _self.uiSubtitleText : uiSubtitleText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DiscoveryResultModel {

 int get count; String? get next; String? get previous;@JsonKey(name: 'ui_promo_banner_text') String? get uiPromoBannerText;@JsonKey(name: 'resolved_service_id') int? get resolvedServiceId;@JsonKey(name: 'resolved_sub_service_id') int? get resolvedSubServiceId; List<TechnicianModel> get results;
/// Create a copy of DiscoveryResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryResultModelCopyWith<DiscoveryResultModel> get copyWith => _$DiscoveryResultModelCopyWithImpl<DiscoveryResultModel>(this as DiscoveryResultModel, _$identity);

  /// Serializes this DiscoveryResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryResultModel&&(identical(other.count, count) || other.count == count)&&(identical(other.next, next) || other.next == next)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.uiPromoBannerText, uiPromoBannerText) || other.uiPromoBannerText == uiPromoBannerText)&&(identical(other.resolvedServiceId, resolvedServiceId) || other.resolvedServiceId == resolvedServiceId)&&(identical(other.resolvedSubServiceId, resolvedSubServiceId) || other.resolvedSubServiceId == resolvedSubServiceId)&&const DeepCollectionEquality().equals(other.results, results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,next,previous,uiPromoBannerText,resolvedServiceId,resolvedSubServiceId,const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'DiscoveryResultModel(count: $count, next: $next, previous: $previous, uiPromoBannerText: $uiPromoBannerText, resolvedServiceId: $resolvedServiceId, resolvedSubServiceId: $resolvedSubServiceId, results: $results)';
}


}

/// @nodoc
abstract mixin class $DiscoveryResultModelCopyWith<$Res>  {
  factory $DiscoveryResultModelCopyWith(DiscoveryResultModel value, $Res Function(DiscoveryResultModel) _then) = _$DiscoveryResultModelCopyWithImpl;
@useResult
$Res call({
 int count, String? next, String? previous,@JsonKey(name: 'ui_promo_banner_text') String? uiPromoBannerText,@JsonKey(name: 'resolved_service_id') int? resolvedServiceId,@JsonKey(name: 'resolved_sub_service_id') int? resolvedSubServiceId, List<TechnicianModel> results
});




}
/// @nodoc
class _$DiscoveryResultModelCopyWithImpl<$Res>
    implements $DiscoveryResultModelCopyWith<$Res> {
  _$DiscoveryResultModelCopyWithImpl(this._self, this._then);

  final DiscoveryResultModel _self;
  final $Res Function(DiscoveryResultModel) _then;

/// Create a copy of DiscoveryResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? next = freezed,Object? previous = freezed,Object? uiPromoBannerText = freezed,Object? resolvedServiceId = freezed,Object? resolvedSubServiceId = freezed,Object? results = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,uiPromoBannerText: freezed == uiPromoBannerText ? _self.uiPromoBannerText : uiPromoBannerText // ignore: cast_nullable_to_non_nullable
as String?,resolvedServiceId: freezed == resolvedServiceId ? _self.resolvedServiceId : resolvedServiceId // ignore: cast_nullable_to_non_nullable
as int?,resolvedSubServiceId: freezed == resolvedSubServiceId ? _self.resolvedSubServiceId : resolvedSubServiceId // ignore: cast_nullable_to_non_nullable
as int?,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<TechnicianModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveryResultModel].
extension DiscoveryResultModelPatterns on DiscoveryResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryResultModel value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  String? next,  String? previous, @JsonKey(name: 'ui_promo_banner_text')  String? uiPromoBannerText, @JsonKey(name: 'resolved_service_id')  int? resolvedServiceId, @JsonKey(name: 'resolved_sub_service_id')  int? resolvedSubServiceId,  List<TechnicianModel> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryResultModel() when $default != null:
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.resolvedServiceId,_that.resolvedSubServiceId,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  String? next,  String? previous, @JsonKey(name: 'ui_promo_banner_text')  String? uiPromoBannerText, @JsonKey(name: 'resolved_service_id')  int? resolvedServiceId, @JsonKey(name: 'resolved_sub_service_id')  int? resolvedSubServiceId,  List<TechnicianModel> results)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryResultModel():
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.resolvedServiceId,_that.resolvedSubServiceId,_that.results);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  String? next,  String? previous, @JsonKey(name: 'ui_promo_banner_text')  String? uiPromoBannerText, @JsonKey(name: 'resolved_service_id')  int? resolvedServiceId, @JsonKey(name: 'resolved_sub_service_id')  int? resolvedSubServiceId,  List<TechnicianModel> results)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryResultModel() when $default != null:
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.resolvedServiceId,_that.resolvedSubServiceId,_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscoveryResultModel extends DiscoveryResultModel {
  const _DiscoveryResultModel({required this.count, required this.next, required this.previous, @JsonKey(name: 'ui_promo_banner_text') required this.uiPromoBannerText, @JsonKey(name: 'resolved_service_id') this.resolvedServiceId, @JsonKey(name: 'resolved_sub_service_id') this.resolvedSubServiceId, required final  List<TechnicianModel> results}): _results = results,super._();
  factory _DiscoveryResultModel.fromJson(Map<String, dynamic> json) => _$DiscoveryResultModelFromJson(json);

@override final  int count;
@override final  String? next;
@override final  String? previous;
@override@JsonKey(name: 'ui_promo_banner_text') final  String? uiPromoBannerText;
@override@JsonKey(name: 'resolved_service_id') final  int? resolvedServiceId;
@override@JsonKey(name: 'resolved_sub_service_id') final  int? resolvedSubServiceId;
 final  List<TechnicianModel> _results;
@override List<TechnicianModel> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of DiscoveryResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryResultModelCopyWith<_DiscoveryResultModel> get copyWith => __$DiscoveryResultModelCopyWithImpl<_DiscoveryResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscoveryResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryResultModel&&(identical(other.count, count) || other.count == count)&&(identical(other.next, next) || other.next == next)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.uiPromoBannerText, uiPromoBannerText) || other.uiPromoBannerText == uiPromoBannerText)&&(identical(other.resolvedServiceId, resolvedServiceId) || other.resolvedServiceId == resolvedServiceId)&&(identical(other.resolvedSubServiceId, resolvedSubServiceId) || other.resolvedSubServiceId == resolvedSubServiceId)&&const DeepCollectionEquality().equals(other._results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,next,previous,uiPromoBannerText,resolvedServiceId,resolvedSubServiceId,const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'DiscoveryResultModel(count: $count, next: $next, previous: $previous, uiPromoBannerText: $uiPromoBannerText, resolvedServiceId: $resolvedServiceId, resolvedSubServiceId: $resolvedSubServiceId, results: $results)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryResultModelCopyWith<$Res> implements $DiscoveryResultModelCopyWith<$Res> {
  factory _$DiscoveryResultModelCopyWith(_DiscoveryResultModel value, $Res Function(_DiscoveryResultModel) _then) = __$DiscoveryResultModelCopyWithImpl;
@override @useResult
$Res call({
 int count, String? next, String? previous,@JsonKey(name: 'ui_promo_banner_text') String? uiPromoBannerText,@JsonKey(name: 'resolved_service_id') int? resolvedServiceId,@JsonKey(name: 'resolved_sub_service_id') int? resolvedSubServiceId, List<TechnicianModel> results
});




}
/// @nodoc
class __$DiscoveryResultModelCopyWithImpl<$Res>
    implements _$DiscoveryResultModelCopyWith<$Res> {
  __$DiscoveryResultModelCopyWithImpl(this._self, this._then);

  final _DiscoveryResultModel _self;
  final $Res Function(_DiscoveryResultModel) _then;

/// Create a copy of DiscoveryResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? next = freezed,Object? previous = freezed,Object? uiPromoBannerText = freezed,Object? resolvedServiceId = freezed,Object? resolvedSubServiceId = freezed,Object? results = null,}) {
  return _then(_DiscoveryResultModel(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,uiPromoBannerText: freezed == uiPromoBannerText ? _self.uiPromoBannerText : uiPromoBannerText // ignore: cast_nullable_to_non_nullable
as String?,resolvedServiceId: freezed == resolvedServiceId ? _self.resolvedServiceId : resolvedServiceId // ignore: cast_nullable_to_non_nullable
as int?,resolvedSubServiceId: freezed == resolvedSubServiceId ? _self.resolvedSubServiceId : resolvedSubServiceId // ignore: cast_nullable_to_non_nullable
as int?,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<TechnicianModel>,
  ));
}


}

// dart format on

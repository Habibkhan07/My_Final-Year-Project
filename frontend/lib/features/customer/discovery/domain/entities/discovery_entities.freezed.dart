// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoveryTechnicianEntity {

 int get id; String get fullName; String get primaryCategory; String get city; String? get profilePicture; double get ratingAverage; int get reviewCount; double? get distanceKm; double? get bayesianScore; bool get isActive;// Unified Money Corner (Dumb UI)
 String get uiRatingText; String get primaryPrice; String get priceContext; String? get promoTag; String? get uiSubtitleText;
/// Create a copy of DiscoveryTechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryTechnicianEntityCopyWith<DiscoveryTechnicianEntity> get copyWith => _$DiscoveryTechnicianEntityCopyWithImpl<DiscoveryTechnicianEntity>(this as DiscoveryTechnicianEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryTechnicianEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&(identical(other.uiSubtitleText, uiSubtitleText) || other.uiSubtitleText == uiSubtitleText));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,priceContext,promoTag,uiSubtitleText);

@override
String toString() {
  return 'DiscoveryTechnicianEntity(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, priceContext: $priceContext, promoTag: $promoTag, uiSubtitleText: $uiSubtitleText)';
}


}

/// @nodoc
abstract mixin class $DiscoveryTechnicianEntityCopyWith<$Res>  {
  factory $DiscoveryTechnicianEntityCopyWith(DiscoveryTechnicianEntity value, $Res Function(DiscoveryTechnicianEntity) _then) = _$DiscoveryTechnicianEntityCopyWithImpl;
@useResult
$Res call({
 int id, String fullName, String primaryCategory, String city, String? profilePicture, double ratingAverage, int reviewCount, double? distanceKm, double? bayesianScore, bool isActive, String uiRatingText, String primaryPrice, String priceContext, String? promoTag, String? uiSubtitleText
});




}
/// @nodoc
class _$DiscoveryTechnicianEntityCopyWithImpl<$Res>
    implements $DiscoveryTechnicianEntityCopyWith<$Res> {
  _$DiscoveryTechnicianEntityCopyWithImpl(this._self, this._then);

  final DiscoveryTechnicianEntity _self;
  final $Res Function(DiscoveryTechnicianEntity) _then;

/// Create a copy of DiscoveryTechnicianEntity
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


/// Adds pattern-matching-related methods to [DiscoveryTechnicianEntity].
extension DiscoveryTechnicianEntityPatterns on DiscoveryTechnicianEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryTechnicianEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryTechnicianEntity value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryTechnicianEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fullName,  String primaryCategory,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String priceContext,  String? promoTag,  String? uiSubtitleText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fullName,  String primaryCategory,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String priceContext,  String? promoTag,  String? uiSubtitleText)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fullName,  String primaryCategory,  String city,  String? profilePicture,  double ratingAverage,  int reviewCount,  double? distanceKm,  double? bayesianScore,  bool isActive,  String uiRatingText,  String primaryPrice,  String priceContext,  String? promoTag,  String? uiSubtitleText)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryTechnicianEntity() when $default != null:
return $default(_that.id,_that.fullName,_that.primaryCategory,_that.city,_that.profilePicture,_that.ratingAverage,_that.reviewCount,_that.distanceKm,_that.bayesianScore,_that.isActive,_that.uiRatingText,_that.primaryPrice,_that.priceContext,_that.promoTag,_that.uiSubtitleText);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoveryTechnicianEntity implements DiscoveryTechnicianEntity {
  const _DiscoveryTechnicianEntity({required this.id, required this.fullName, required this.primaryCategory, required this.city, required this.profilePicture, required this.ratingAverage, required this.reviewCount, required this.distanceKm, required this.bayesianScore, required this.isActive, required this.uiRatingText, required this.primaryPrice, required this.priceContext, required this.promoTag, required this.uiSubtitleText});
  

@override final  int id;
@override final  String fullName;
@override final  String primaryCategory;
@override final  String city;
@override final  String? profilePicture;
@override final  double ratingAverage;
@override final  int reviewCount;
@override final  double? distanceKm;
@override final  double? bayesianScore;
@override final  bool isActive;
// Unified Money Corner (Dumb UI)
@override final  String uiRatingText;
@override final  String primaryPrice;
@override final  String priceContext;
@override final  String? promoTag;
@override final  String? uiSubtitleText;

/// Create a copy of DiscoveryTechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryTechnicianEntityCopyWith<_DiscoveryTechnicianEntity> get copyWith => __$DiscoveryTechnicianEntityCopyWithImpl<_DiscoveryTechnicianEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryTechnicianEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.primaryCategory, primaryCategory) || other.primaryCategory == primaryCategory)&&(identical(other.city, city) || other.city == city)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.ratingAverage, ratingAverage) || other.ratingAverage == ratingAverage)&&(identical(other.reviewCount, reviewCount) || other.reviewCount == reviewCount)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.bayesianScore, bayesianScore) || other.bayesianScore == bayesianScore)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.uiRatingText, uiRatingText) || other.uiRatingText == uiRatingText)&&(identical(other.primaryPrice, primaryPrice) || other.primaryPrice == primaryPrice)&&(identical(other.priceContext, priceContext) || other.priceContext == priceContext)&&(identical(other.promoTag, promoTag) || other.promoTag == promoTag)&&(identical(other.uiSubtitleText, uiSubtitleText) || other.uiSubtitleText == uiSubtitleText));
}


@override
int get hashCode => Object.hash(runtimeType,id,fullName,primaryCategory,city,profilePicture,ratingAverage,reviewCount,distanceKm,bayesianScore,isActive,uiRatingText,primaryPrice,priceContext,promoTag,uiSubtitleText);

@override
String toString() {
  return 'DiscoveryTechnicianEntity(id: $id, fullName: $fullName, primaryCategory: $primaryCategory, city: $city, profilePicture: $profilePicture, ratingAverage: $ratingAverage, reviewCount: $reviewCount, distanceKm: $distanceKm, bayesianScore: $bayesianScore, isActive: $isActive, uiRatingText: $uiRatingText, primaryPrice: $primaryPrice, priceContext: $priceContext, promoTag: $promoTag, uiSubtitleText: $uiSubtitleText)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryTechnicianEntityCopyWith<$Res> implements $DiscoveryTechnicianEntityCopyWith<$Res> {
  factory _$DiscoveryTechnicianEntityCopyWith(_DiscoveryTechnicianEntity value, $Res Function(_DiscoveryTechnicianEntity) _then) = __$DiscoveryTechnicianEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String fullName, String primaryCategory, String city, String? profilePicture, double ratingAverage, int reviewCount, double? distanceKm, double? bayesianScore, bool isActive, String uiRatingText, String primaryPrice, String priceContext, String? promoTag, String? uiSubtitleText
});




}
/// @nodoc
class __$DiscoveryTechnicianEntityCopyWithImpl<$Res>
    implements _$DiscoveryTechnicianEntityCopyWith<$Res> {
  __$DiscoveryTechnicianEntityCopyWithImpl(this._self, this._then);

  final _DiscoveryTechnicianEntity _self;
  final $Res Function(_DiscoveryTechnicianEntity) _then;

/// Create a copy of DiscoveryTechnicianEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? primaryCategory = null,Object? city = null,Object? profilePicture = freezed,Object? ratingAverage = null,Object? reviewCount = null,Object? distanceKm = freezed,Object? bayesianScore = freezed,Object? isActive = null,Object? uiRatingText = null,Object? primaryPrice = null,Object? priceContext = null,Object? promoTag = freezed,Object? uiSubtitleText = freezed,}) {
  return _then(_DiscoveryTechnicianEntity(
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
mixin _$DiscoveryResultEntity {

 int get count; String? get next; String? get previous; String? get uiPromoBannerText; List<DiscoveryTechnicianEntity> get results;
/// Create a copy of DiscoveryResultEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryResultEntityCopyWith<DiscoveryResultEntity> get copyWith => _$DiscoveryResultEntityCopyWithImpl<DiscoveryResultEntity>(this as DiscoveryResultEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryResultEntity&&(identical(other.count, count) || other.count == count)&&(identical(other.next, next) || other.next == next)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.uiPromoBannerText, uiPromoBannerText) || other.uiPromoBannerText == uiPromoBannerText)&&const DeepCollectionEquality().equals(other.results, results));
}


@override
int get hashCode => Object.hash(runtimeType,count,next,previous,uiPromoBannerText,const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'DiscoveryResultEntity(count: $count, next: $next, previous: $previous, uiPromoBannerText: $uiPromoBannerText, results: $results)';
}


}

/// @nodoc
abstract mixin class $DiscoveryResultEntityCopyWith<$Res>  {
  factory $DiscoveryResultEntityCopyWith(DiscoveryResultEntity value, $Res Function(DiscoveryResultEntity) _then) = _$DiscoveryResultEntityCopyWithImpl;
@useResult
$Res call({
 int count, String? next, String? previous, String? uiPromoBannerText, List<DiscoveryTechnicianEntity> results
});




}
/// @nodoc
class _$DiscoveryResultEntityCopyWithImpl<$Res>
    implements $DiscoveryResultEntityCopyWith<$Res> {
  _$DiscoveryResultEntityCopyWithImpl(this._self, this._then);

  final DiscoveryResultEntity _self;
  final $Res Function(DiscoveryResultEntity) _then;

/// Create a copy of DiscoveryResultEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? next = freezed,Object? previous = freezed,Object? uiPromoBannerText = freezed,Object? results = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,uiPromoBannerText: freezed == uiPromoBannerText ? _self.uiPromoBannerText : uiPromoBannerText // ignore: cast_nullable_to_non_nullable
as String?,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<DiscoveryTechnicianEntity>,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveryResultEntity].
extension DiscoveryResultEntityPatterns on DiscoveryResultEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryResultEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryResultEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryResultEntity value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryResultEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryResultEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryResultEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  String? next,  String? previous,  String? uiPromoBannerText,  List<DiscoveryTechnicianEntity> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryResultEntity() when $default != null:
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  String? next,  String? previous,  String? uiPromoBannerText,  List<DiscoveryTechnicianEntity> results)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryResultEntity():
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.results);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  String? next,  String? previous,  String? uiPromoBannerText,  List<DiscoveryTechnicianEntity> results)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryResultEntity() when $default != null:
return $default(_that.count,_that.next,_that.previous,_that.uiPromoBannerText,_that.results);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoveryResultEntity implements DiscoveryResultEntity {
  const _DiscoveryResultEntity({required this.count, required this.next, required this.previous, required this.uiPromoBannerText, required final  List<DiscoveryTechnicianEntity> results}): _results = results;
  

@override final  int count;
@override final  String? next;
@override final  String? previous;
@override final  String? uiPromoBannerText;
 final  List<DiscoveryTechnicianEntity> _results;
@override List<DiscoveryTechnicianEntity> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of DiscoveryResultEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryResultEntityCopyWith<_DiscoveryResultEntity> get copyWith => __$DiscoveryResultEntityCopyWithImpl<_DiscoveryResultEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryResultEntity&&(identical(other.count, count) || other.count == count)&&(identical(other.next, next) || other.next == next)&&(identical(other.previous, previous) || other.previous == previous)&&(identical(other.uiPromoBannerText, uiPromoBannerText) || other.uiPromoBannerText == uiPromoBannerText)&&const DeepCollectionEquality().equals(other._results, _results));
}


@override
int get hashCode => Object.hash(runtimeType,count,next,previous,uiPromoBannerText,const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'DiscoveryResultEntity(count: $count, next: $next, previous: $previous, uiPromoBannerText: $uiPromoBannerText, results: $results)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryResultEntityCopyWith<$Res> implements $DiscoveryResultEntityCopyWith<$Res> {
  factory _$DiscoveryResultEntityCopyWith(_DiscoveryResultEntity value, $Res Function(_DiscoveryResultEntity) _then) = __$DiscoveryResultEntityCopyWithImpl;
@override @useResult
$Res call({
 int count, String? next, String? previous, String? uiPromoBannerText, List<DiscoveryTechnicianEntity> results
});




}
/// @nodoc
class __$DiscoveryResultEntityCopyWithImpl<$Res>
    implements _$DiscoveryResultEntityCopyWith<$Res> {
  __$DiscoveryResultEntityCopyWithImpl(this._self, this._then);

  final _DiscoveryResultEntity _self;
  final $Res Function(_DiscoveryResultEntity) _then;

/// Create a copy of DiscoveryResultEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? next = freezed,Object? previous = freezed,Object? uiPromoBannerText = freezed,Object? results = null,}) {
  return _then(_DiscoveryResultEntity(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,next: freezed == next ? _self.next : next // ignore: cast_nullable_to_non_nullable
as String?,previous: freezed == previous ? _self.previous : previous // ignore: cast_nullable_to_non_nullable
as String?,uiPromoBannerText: freezed == uiPromoBannerText ? _self.uiPromoBannerText : uiPromoBannerText // ignore: cast_nullable_to_non_nullable
as String?,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<DiscoveryTechnicianEntity>,
  ));
}


}

// dart format on

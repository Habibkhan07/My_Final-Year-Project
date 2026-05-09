// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_pricing.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingPricing {

 int? get inspectionFee; int? get baseServicesTotal; int? get discountApplied; int? get finalCashToCollect; String? get promoCodeSnapshot; int? get promoDiscountSnapshot;
/// Create a copy of BookingPricing
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingPricingCopyWith<BookingPricing> get copyWith => _$BookingPricingCopyWithImpl<BookingPricing>(this as BookingPricing, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingPricing&&(identical(other.inspectionFee, inspectionFee) || other.inspectionFee == inspectionFee)&&(identical(other.baseServicesTotal, baseServicesTotal) || other.baseServicesTotal == baseServicesTotal)&&(identical(other.discountApplied, discountApplied) || other.discountApplied == discountApplied)&&(identical(other.finalCashToCollect, finalCashToCollect) || other.finalCashToCollect == finalCashToCollect)&&(identical(other.promoCodeSnapshot, promoCodeSnapshot) || other.promoCodeSnapshot == promoCodeSnapshot)&&(identical(other.promoDiscountSnapshot, promoDiscountSnapshot) || other.promoDiscountSnapshot == promoDiscountSnapshot));
}


@override
int get hashCode => Object.hash(runtimeType,inspectionFee,baseServicesTotal,discountApplied,finalCashToCollect,promoCodeSnapshot,promoDiscountSnapshot);

@override
String toString() {
  return 'BookingPricing(inspectionFee: $inspectionFee, baseServicesTotal: $baseServicesTotal, discountApplied: $discountApplied, finalCashToCollect: $finalCashToCollect, promoCodeSnapshot: $promoCodeSnapshot, promoDiscountSnapshot: $promoDiscountSnapshot)';
}


}

/// @nodoc
abstract mixin class $BookingPricingCopyWith<$Res>  {
  factory $BookingPricingCopyWith(BookingPricing value, $Res Function(BookingPricing) _then) = _$BookingPricingCopyWithImpl;
@useResult
$Res call({
 int? inspectionFee, int? baseServicesTotal, int? discountApplied, int? finalCashToCollect, String? promoCodeSnapshot, int? promoDiscountSnapshot
});




}
/// @nodoc
class _$BookingPricingCopyWithImpl<$Res>
    implements $BookingPricingCopyWith<$Res> {
  _$BookingPricingCopyWithImpl(this._self, this._then);

  final BookingPricing _self;
  final $Res Function(BookingPricing) _then;

/// Create a copy of BookingPricing
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inspectionFee = freezed,Object? baseServicesTotal = freezed,Object? discountApplied = freezed,Object? finalCashToCollect = freezed,Object? promoCodeSnapshot = freezed,Object? promoDiscountSnapshot = freezed,}) {
  return _then(_self.copyWith(
inspectionFee: freezed == inspectionFee ? _self.inspectionFee : inspectionFee // ignore: cast_nullable_to_non_nullable
as int?,baseServicesTotal: freezed == baseServicesTotal ? _self.baseServicesTotal : baseServicesTotal // ignore: cast_nullable_to_non_nullable
as int?,discountApplied: freezed == discountApplied ? _self.discountApplied : discountApplied // ignore: cast_nullable_to_non_nullable
as int?,finalCashToCollect: freezed == finalCashToCollect ? _self.finalCashToCollect : finalCashToCollect // ignore: cast_nullable_to_non_nullable
as int?,promoCodeSnapshot: freezed == promoCodeSnapshot ? _self.promoCodeSnapshot : promoCodeSnapshot // ignore: cast_nullable_to_non_nullable
as String?,promoDiscountSnapshot: freezed == promoDiscountSnapshot ? _self.promoDiscountSnapshot : promoDiscountSnapshot // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingPricing].
extension BookingPricingPatterns on BookingPricing {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingPricing value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingPricing() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingPricing value)  $default,){
final _that = this;
switch (_that) {
case _BookingPricing():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingPricing value)?  $default,){
final _that = this;
switch (_that) {
case _BookingPricing() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? inspectionFee,  int? baseServicesTotal,  int? discountApplied,  int? finalCashToCollect,  String? promoCodeSnapshot,  int? promoDiscountSnapshot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingPricing() when $default != null:
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? inspectionFee,  int? baseServicesTotal,  int? discountApplied,  int? finalCashToCollect,  String? promoCodeSnapshot,  int? promoDiscountSnapshot)  $default,) {final _that = this;
switch (_that) {
case _BookingPricing():
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? inspectionFee,  int? baseServicesTotal,  int? discountApplied,  int? finalCashToCollect,  String? promoCodeSnapshot,  int? promoDiscountSnapshot)?  $default,) {final _that = this;
switch (_that) {
case _BookingPricing() when $default != null:
return $default(_that.inspectionFee,_that.baseServicesTotal,_that.discountApplied,_that.finalCashToCollect,_that.promoCodeSnapshot,_that.promoDiscountSnapshot);case _:
  return null;

}
}

}

/// @nodoc


class _BookingPricing implements BookingPricing {
  const _BookingPricing({this.inspectionFee, this.baseServicesTotal, this.discountApplied, this.finalCashToCollect, this.promoCodeSnapshot, this.promoDiscountSnapshot});
  

@override final  int? inspectionFee;
@override final  int? baseServicesTotal;
@override final  int? discountApplied;
@override final  int? finalCashToCollect;
@override final  String? promoCodeSnapshot;
@override final  int? promoDiscountSnapshot;

/// Create a copy of BookingPricing
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingPricingCopyWith<_BookingPricing> get copyWith => __$BookingPricingCopyWithImpl<_BookingPricing>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingPricing&&(identical(other.inspectionFee, inspectionFee) || other.inspectionFee == inspectionFee)&&(identical(other.baseServicesTotal, baseServicesTotal) || other.baseServicesTotal == baseServicesTotal)&&(identical(other.discountApplied, discountApplied) || other.discountApplied == discountApplied)&&(identical(other.finalCashToCollect, finalCashToCollect) || other.finalCashToCollect == finalCashToCollect)&&(identical(other.promoCodeSnapshot, promoCodeSnapshot) || other.promoCodeSnapshot == promoCodeSnapshot)&&(identical(other.promoDiscountSnapshot, promoDiscountSnapshot) || other.promoDiscountSnapshot == promoDiscountSnapshot));
}


@override
int get hashCode => Object.hash(runtimeType,inspectionFee,baseServicesTotal,discountApplied,finalCashToCollect,promoCodeSnapshot,promoDiscountSnapshot);

@override
String toString() {
  return 'BookingPricing(inspectionFee: $inspectionFee, baseServicesTotal: $baseServicesTotal, discountApplied: $discountApplied, finalCashToCollect: $finalCashToCollect, promoCodeSnapshot: $promoCodeSnapshot, promoDiscountSnapshot: $promoDiscountSnapshot)';
}


}

/// @nodoc
abstract mixin class _$BookingPricingCopyWith<$Res> implements $BookingPricingCopyWith<$Res> {
  factory _$BookingPricingCopyWith(_BookingPricing value, $Res Function(_BookingPricing) _then) = __$BookingPricingCopyWithImpl;
@override @useResult
$Res call({
 int? inspectionFee, int? baseServicesTotal, int? discountApplied, int? finalCashToCollect, String? promoCodeSnapshot, int? promoDiscountSnapshot
});




}
/// @nodoc
class __$BookingPricingCopyWithImpl<$Res>
    implements _$BookingPricingCopyWith<$Res> {
  __$BookingPricingCopyWithImpl(this._self, this._then);

  final _BookingPricing _self;
  final $Res Function(_BookingPricing) _then;

/// Create a copy of BookingPricing
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inspectionFee = freezed,Object? baseServicesTotal = freezed,Object? discountApplied = freezed,Object? finalCashToCollect = freezed,Object? promoCodeSnapshot = freezed,Object? promoDiscountSnapshot = freezed,}) {
  return _then(_BookingPricing(
inspectionFee: freezed == inspectionFee ? _self.inspectionFee : inspectionFee // ignore: cast_nullable_to_non_nullable
as int?,baseServicesTotal: freezed == baseServicesTotal ? _self.baseServicesTotal : baseServicesTotal // ignore: cast_nullable_to_non_nullable
as int?,discountApplied: freezed == discountApplied ? _self.discountApplied : discountApplied // ignore: cast_nullable_to_non_nullable
as int?,finalCashToCollect: freezed == finalCashToCollect ? _self.finalCashToCollect : finalCashToCollect // ignore: cast_nullable_to_non_nullable
as int?,promoCodeSnapshot: freezed == promoCodeSnapshot ? _self.promoCodeSnapshot : promoCodeSnapshot // ignore: cast_nullable_to_non_nullable
as String?,promoDiscountSnapshot: freezed == promoDiscountSnapshot ? _self.promoDiscountSnapshot : promoDiscountSnapshot // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

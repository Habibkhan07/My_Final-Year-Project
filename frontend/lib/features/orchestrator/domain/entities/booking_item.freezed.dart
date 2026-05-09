// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingItem {

 int get id; int get subServiceId; String get subServiceName; int get quantity; int get priceCharged; int get lineTotal; int? get sourcedQuoteId;
/// Create a copy of BookingItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingItemCopyWith<BookingItem> get copyWith => _$BookingItemCopyWithImpl<BookingItem>(this as BookingItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceCharged, priceCharged) || other.priceCharged == priceCharged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.sourcedQuoteId, sourcedQuoteId) || other.sourcedQuoteId == sourcedQuoteId));
}


@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,priceCharged,lineTotal,sourcedQuoteId);

@override
String toString() {
  return 'BookingItem(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, priceCharged: $priceCharged, lineTotal: $lineTotal, sourcedQuoteId: $sourcedQuoteId)';
}


}

/// @nodoc
abstract mixin class $BookingItemCopyWith<$Res>  {
  factory $BookingItemCopyWith(BookingItem value, $Res Function(BookingItem) _then) = _$BookingItemCopyWithImpl;
@useResult
$Res call({
 int id, int subServiceId, String subServiceName, int quantity, int priceCharged, int lineTotal, int? sourcedQuoteId
});




}
/// @nodoc
class _$BookingItemCopyWithImpl<$Res>
    implements $BookingItemCopyWith<$Res> {
  _$BookingItemCopyWithImpl(this._self, this._then);

  final BookingItem _self;
  final $Res Function(BookingItem) _then;

/// Create a copy of BookingItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? priceCharged = null,Object? lineTotal = null,Object? sourcedQuoteId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,priceCharged: null == priceCharged ? _self.priceCharged : priceCharged // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,sourcedQuoteId: freezed == sourcedQuoteId ? _self.sourcedQuoteId : sourcedQuoteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingItem].
extension BookingItemPatterns on BookingItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingItem value)  $default,){
final _that = this;
switch (_that) {
case _BookingItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingItem value)?  $default,){
final _that = this;
switch (_that) {
case _BookingItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int priceCharged,  int lineTotal,  int? sourcedQuoteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingItem() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.priceCharged,_that.lineTotal,_that.sourcedQuoteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int priceCharged,  int lineTotal,  int? sourcedQuoteId)  $default,) {final _that = this;
switch (_that) {
case _BookingItem():
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.priceCharged,_that.lineTotal,_that.sourcedQuoteId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int priceCharged,  int lineTotal,  int? sourcedQuoteId)?  $default,) {final _that = this;
switch (_that) {
case _BookingItem() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.priceCharged,_that.lineTotal,_that.sourcedQuoteId);case _:
  return null;

}
}

}

/// @nodoc


class _BookingItem implements BookingItem {
  const _BookingItem({required this.id, required this.subServiceId, required this.subServiceName, required this.quantity, required this.priceCharged, required this.lineTotal, this.sourcedQuoteId});
  

@override final  int id;
@override final  int subServiceId;
@override final  String subServiceName;
@override final  int quantity;
@override final  int priceCharged;
@override final  int lineTotal;
@override final  int? sourcedQuoteId;

/// Create a copy of BookingItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingItemCopyWith<_BookingItem> get copyWith => __$BookingItemCopyWithImpl<_BookingItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingItem&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceCharged, priceCharged) || other.priceCharged == priceCharged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.sourcedQuoteId, sourcedQuoteId) || other.sourcedQuoteId == sourcedQuoteId));
}


@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,priceCharged,lineTotal,sourcedQuoteId);

@override
String toString() {
  return 'BookingItem(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, priceCharged: $priceCharged, lineTotal: $lineTotal, sourcedQuoteId: $sourcedQuoteId)';
}


}

/// @nodoc
abstract mixin class _$BookingItemCopyWith<$Res> implements $BookingItemCopyWith<$Res> {
  factory _$BookingItemCopyWith(_BookingItem value, $Res Function(_BookingItem) _then) = __$BookingItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int subServiceId, String subServiceName, int quantity, int priceCharged, int lineTotal, int? sourcedQuoteId
});




}
/// @nodoc
class __$BookingItemCopyWithImpl<$Res>
    implements _$BookingItemCopyWith<$Res> {
  __$BookingItemCopyWithImpl(this._self, this._then);

  final _BookingItem _self;
  final $Res Function(_BookingItem) _then;

/// Create a copy of BookingItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? priceCharged = null,Object? lineTotal = null,Object? sourcedQuoteId = freezed,}) {
  return _then(_BookingItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,priceCharged: null == priceCharged ? _self.priceCharged : priceCharged // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,sourcedQuoteId: freezed == sourcedQuoteId ? _self.sourcedQuoteId : sourcedQuoteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

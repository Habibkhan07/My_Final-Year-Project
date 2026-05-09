// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingQuote {

 int get id; int get bookingId; int get revisionNumber; BookingQuoteStatus get status; int get totalAmount; bool get isUpsell; List<BookingQuoteLineItem> get lineItems; DateTime? get submittedAt;
/// Create a copy of BookingQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingQuoteCopyWith<BookingQuote> get copyWith => _$BookingQuoteCopyWithImpl<BookingQuote>(this as BookingQuote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.isUpsell, isUpsell) || other.isUpsell == isUpsell)&&const DeepCollectionEquality().equals(other.lineItems, lineItems)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,bookingId,revisionNumber,status,totalAmount,isUpsell,const DeepCollectionEquality().hash(lineItems),submittedAt);

@override
String toString() {
  return 'BookingQuote(id: $id, bookingId: $bookingId, revisionNumber: $revisionNumber, status: $status, totalAmount: $totalAmount, isUpsell: $isUpsell, lineItems: $lineItems, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class $BookingQuoteCopyWith<$Res>  {
  factory $BookingQuoteCopyWith(BookingQuote value, $Res Function(BookingQuote) _then) = _$BookingQuoteCopyWithImpl;
@useResult
$Res call({
 int id, int bookingId, int revisionNumber, BookingQuoteStatus status, int totalAmount, bool isUpsell, List<BookingQuoteLineItem> lineItems, DateTime? submittedAt
});




}
/// @nodoc
class _$BookingQuoteCopyWithImpl<$Res>
    implements $BookingQuoteCopyWith<$Res> {
  _$BookingQuoteCopyWithImpl(this._self, this._then);

  final BookingQuote _self;
  final $Res Function(BookingQuote) _then;

/// Create a copy of BookingQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? revisionNumber = null,Object? status = null,Object? totalAmount = null,Object? isUpsell = null,Object? lineItems = null,Object? submittedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingQuoteStatus,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,isUpsell: null == isUpsell ? _self.isUpsell : isUpsell // ignore: cast_nullable_to_non_nullable
as bool,lineItems: null == lineItems ? _self.lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<BookingQuoteLineItem>,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingQuote].
extension BookingQuotePatterns on BookingQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingQuote value)  $default,){
final _that = this;
switch (_that) {
case _BookingQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingQuote value)?  $default,){
final _that = this;
switch (_that) {
case _BookingQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int bookingId,  int revisionNumber,  BookingQuoteStatus status,  int totalAmount,  bool isUpsell,  List<BookingQuoteLineItem> lineItems,  DateTime? submittedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingQuote() when $default != null:
return $default(_that.id,_that.bookingId,_that.revisionNumber,_that.status,_that.totalAmount,_that.isUpsell,_that.lineItems,_that.submittedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int bookingId,  int revisionNumber,  BookingQuoteStatus status,  int totalAmount,  bool isUpsell,  List<BookingQuoteLineItem> lineItems,  DateTime? submittedAt)  $default,) {final _that = this;
switch (_that) {
case _BookingQuote():
return $default(_that.id,_that.bookingId,_that.revisionNumber,_that.status,_that.totalAmount,_that.isUpsell,_that.lineItems,_that.submittedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int bookingId,  int revisionNumber,  BookingQuoteStatus status,  int totalAmount,  bool isUpsell,  List<BookingQuoteLineItem> lineItems,  DateTime? submittedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingQuote() when $default != null:
return $default(_that.id,_that.bookingId,_that.revisionNumber,_that.status,_that.totalAmount,_that.isUpsell,_that.lineItems,_that.submittedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BookingQuote implements BookingQuote {
  const _BookingQuote({required this.id, required this.bookingId, required this.revisionNumber, required this.status, required this.totalAmount, required this.isUpsell, required final  List<BookingQuoteLineItem> lineItems, this.submittedAt}): _lineItems = lineItems;
  

@override final  int id;
@override final  int bookingId;
@override final  int revisionNumber;
@override final  BookingQuoteStatus status;
@override final  int totalAmount;
@override final  bool isUpsell;
 final  List<BookingQuoteLineItem> _lineItems;
@override List<BookingQuoteLineItem> get lineItems {
  if (_lineItems is EqualUnmodifiableListView) return _lineItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineItems);
}

@override final  DateTime? submittedAt;

/// Create a copy of BookingQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingQuoteCopyWith<_BookingQuote> get copyWith => __$BookingQuoteCopyWithImpl<_BookingQuote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.isUpsell, isUpsell) || other.isUpsell == isUpsell)&&const DeepCollectionEquality().equals(other._lineItems, _lineItems)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,bookingId,revisionNumber,status,totalAmount,isUpsell,const DeepCollectionEquality().hash(_lineItems),submittedAt);

@override
String toString() {
  return 'BookingQuote(id: $id, bookingId: $bookingId, revisionNumber: $revisionNumber, status: $status, totalAmount: $totalAmount, isUpsell: $isUpsell, lineItems: $lineItems, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingQuoteCopyWith<$Res> implements $BookingQuoteCopyWith<$Res> {
  factory _$BookingQuoteCopyWith(_BookingQuote value, $Res Function(_BookingQuote) _then) = __$BookingQuoteCopyWithImpl;
@override @useResult
$Res call({
 int id, int bookingId, int revisionNumber, BookingQuoteStatus status, int totalAmount, bool isUpsell, List<BookingQuoteLineItem> lineItems, DateTime? submittedAt
});




}
/// @nodoc
class __$BookingQuoteCopyWithImpl<$Res>
    implements _$BookingQuoteCopyWith<$Res> {
  __$BookingQuoteCopyWithImpl(this._self, this._then);

  final _BookingQuote _self;
  final $Res Function(_BookingQuote) _then;

/// Create a copy of BookingQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? revisionNumber = null,Object? status = null,Object? totalAmount = null,Object? isUpsell = null,Object? lineItems = null,Object? submittedAt = freezed,}) {
  return _then(_BookingQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BookingQuoteStatus,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as int,isUpsell: null == isUpsell ? _self.isUpsell : isUpsell // ignore: cast_nullable_to_non_nullable
as bool,lineItems: null == lineItems ? _self._lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<BookingQuoteLineItem>,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$BookingQuoteLineItem {

 int get id; int get subServiceId; String get subServiceName; int get quantity; int get pricedAt; int get lineTotal;
/// Create a copy of BookingQuoteLineItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingQuoteLineItemCopyWith<BookingQuoteLineItem> get copyWith => _$BookingQuoteLineItemCopyWithImpl<BookingQuoteLineItem>(this as BookingQuoteLineItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingQuoteLineItem&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,pricedAt,lineTotal);

@override
String toString() {
  return 'BookingQuoteLineItem(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, pricedAt: $pricedAt, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $BookingQuoteLineItemCopyWith<$Res>  {
  factory $BookingQuoteLineItemCopyWith(BookingQuoteLineItem value, $Res Function(BookingQuoteLineItem) _then) = _$BookingQuoteLineItemCopyWithImpl;
@useResult
$Res call({
 int id, int subServiceId, String subServiceName, int quantity, int pricedAt, int lineTotal
});




}
/// @nodoc
class _$BookingQuoteLineItemCopyWithImpl<$Res>
    implements $BookingQuoteLineItemCopyWith<$Res> {
  _$BookingQuoteLineItemCopyWithImpl(this._self, this._then);

  final BookingQuoteLineItem _self;
  final $Res Function(BookingQuoteLineItem) _then;

/// Create a copy of BookingQuoteLineItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? pricedAt = null,Object? lineTotal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pricedAt: null == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingQuoteLineItem].
extension BookingQuoteLineItemPatterns on BookingQuoteLineItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingQuoteLineItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingQuoteLineItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingQuoteLineItem value)  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteLineItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingQuoteLineItem value)?  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteLineItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int pricedAt,  int lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingQuoteLineItem() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.pricedAt,_that.lineTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int pricedAt,  int lineTotal)  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteLineItem():
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.pricedAt,_that.lineTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int subServiceId,  String subServiceName,  int quantity,  int pricedAt,  int lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteLineItem() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.pricedAt,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc


class _BookingQuoteLineItem implements BookingQuoteLineItem {
  const _BookingQuoteLineItem({required this.id, required this.subServiceId, required this.subServiceName, required this.quantity, required this.pricedAt, required this.lineTotal});
  

@override final  int id;
@override final  int subServiceId;
@override final  String subServiceName;
@override final  int quantity;
@override final  int pricedAt;
@override final  int lineTotal;

/// Create a copy of BookingQuoteLineItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingQuoteLineItemCopyWith<_BookingQuoteLineItem> get copyWith => __$BookingQuoteLineItemCopyWithImpl<_BookingQuoteLineItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingQuoteLineItem&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}


@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,pricedAt,lineTotal);

@override
String toString() {
  return 'BookingQuoteLineItem(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, pricedAt: $pricedAt, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$BookingQuoteLineItemCopyWith<$Res> implements $BookingQuoteLineItemCopyWith<$Res> {
  factory _$BookingQuoteLineItemCopyWith(_BookingQuoteLineItem value, $Res Function(_BookingQuoteLineItem) _then) = __$BookingQuoteLineItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int subServiceId, String subServiceName, int quantity, int pricedAt, int lineTotal
});




}
/// @nodoc
class __$BookingQuoteLineItemCopyWithImpl<$Res>
    implements _$BookingQuoteLineItemCopyWith<$Res> {
  __$BookingQuoteLineItemCopyWithImpl(this._self, this._then);

  final _BookingQuoteLineItem _self;
  final $Res Function(_BookingQuoteLineItem) _then;

/// Create a copy of BookingQuoteLineItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? pricedAt = null,Object? lineTotal = null,}) {
  return _then(_BookingQuoteLineItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pricedAt: null == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as int,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

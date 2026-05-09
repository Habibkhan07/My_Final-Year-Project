// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_quote_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingQuoteModel {

 int get id;@JsonKey(name: 'booking_id') int get bookingId;@JsonKey(name: 'revision_number') int get revisionNumber; String get status;@JsonKey(name: 'total_amount') String get totalAmount;@JsonKey(name: 'is_upsell') bool get isUpsell;@JsonKey(name: 'line_items') List<BookingQuoteLineItemModel> get lineItems;@JsonKey(name: 'submitted_at') String? get submittedAt;
/// Create a copy of BookingQuoteModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingQuoteModelCopyWith<BookingQuoteModel> get copyWith => _$BookingQuoteModelCopyWithImpl<BookingQuoteModel>(this as BookingQuoteModel, _$identity);

  /// Serializes this BookingQuoteModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingQuoteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.isUpsell, isUpsell) || other.isUpsell == isUpsell)&&const DeepCollectionEquality().equals(other.lineItems, lineItems)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,revisionNumber,status,totalAmount,isUpsell,const DeepCollectionEquality().hash(lineItems),submittedAt);

@override
String toString() {
  return 'BookingQuoteModel(id: $id, bookingId: $bookingId, revisionNumber: $revisionNumber, status: $status, totalAmount: $totalAmount, isUpsell: $isUpsell, lineItems: $lineItems, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class $BookingQuoteModelCopyWith<$Res>  {
  factory $BookingQuoteModelCopyWith(BookingQuoteModel value, $Res Function(BookingQuoteModel) _then) = _$BookingQuoteModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'booking_id') int bookingId,@JsonKey(name: 'revision_number') int revisionNumber, String status,@JsonKey(name: 'total_amount') String totalAmount,@JsonKey(name: 'is_upsell') bool isUpsell,@JsonKey(name: 'line_items') List<BookingQuoteLineItemModel> lineItems,@JsonKey(name: 'submitted_at') String? submittedAt
});




}
/// @nodoc
class _$BookingQuoteModelCopyWithImpl<$Res>
    implements $BookingQuoteModelCopyWith<$Res> {
  _$BookingQuoteModelCopyWithImpl(this._self, this._then);

  final BookingQuoteModel _self;
  final $Res Function(BookingQuoteModel) _then;

/// Create a copy of BookingQuoteModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bookingId = null,Object? revisionNumber = null,Object? status = null,Object? totalAmount = null,Object? isUpsell = null,Object? lineItems = null,Object? submittedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,isUpsell: null == isUpsell ? _self.isUpsell : isUpsell // ignore: cast_nullable_to_non_nullable
as bool,lineItems: null == lineItems ? _self.lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<BookingQuoteLineItemModel>,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingQuoteModel].
extension BookingQuoteModelPatterns on BookingQuoteModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingQuoteModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingQuoteModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingQuoteModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingQuoteModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'booking_id')  int bookingId, @JsonKey(name: 'revision_number')  int revisionNumber,  String status, @JsonKey(name: 'total_amount')  String totalAmount, @JsonKey(name: 'is_upsell')  bool isUpsell, @JsonKey(name: 'line_items')  List<BookingQuoteLineItemModel> lineItems, @JsonKey(name: 'submitted_at')  String? submittedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingQuoteModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'booking_id')  int bookingId, @JsonKey(name: 'revision_number')  int revisionNumber,  String status, @JsonKey(name: 'total_amount')  String totalAmount, @JsonKey(name: 'is_upsell')  bool isUpsell, @JsonKey(name: 'line_items')  List<BookingQuoteLineItemModel> lineItems, @JsonKey(name: 'submitted_at')  String? submittedAt)  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'booking_id')  int bookingId, @JsonKey(name: 'revision_number')  int revisionNumber,  String status, @JsonKey(name: 'total_amount')  String totalAmount, @JsonKey(name: 'is_upsell')  bool isUpsell, @JsonKey(name: 'line_items')  List<BookingQuoteLineItemModel> lineItems, @JsonKey(name: 'submitted_at')  String? submittedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteModel() when $default != null:
return $default(_that.id,_that.bookingId,_that.revisionNumber,_that.status,_that.totalAmount,_that.isUpsell,_that.lineItems,_that.submittedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingQuoteModel implements BookingQuoteModel {
  const _BookingQuoteModel({required this.id, @JsonKey(name: 'booking_id') required this.bookingId, @JsonKey(name: 'revision_number') required this.revisionNumber, required this.status, @JsonKey(name: 'total_amount') required this.totalAmount, @JsonKey(name: 'is_upsell') required this.isUpsell, @JsonKey(name: 'line_items') required final  List<BookingQuoteLineItemModel> lineItems, @JsonKey(name: 'submitted_at') this.submittedAt}): _lineItems = lineItems;
  factory _BookingQuoteModel.fromJson(Map<String, dynamic> json) => _$BookingQuoteModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'booking_id') final  int bookingId;
@override@JsonKey(name: 'revision_number') final  int revisionNumber;
@override final  String status;
@override@JsonKey(name: 'total_amount') final  String totalAmount;
@override@JsonKey(name: 'is_upsell') final  bool isUpsell;
 final  List<BookingQuoteLineItemModel> _lineItems;
@override@JsonKey(name: 'line_items') List<BookingQuoteLineItemModel> get lineItems {
  if (_lineItems is EqualUnmodifiableListView) return _lineItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lineItems);
}

@override@JsonKey(name: 'submitted_at') final  String? submittedAt;

/// Create a copy of BookingQuoteModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingQuoteModelCopyWith<_BookingQuoteModel> get copyWith => __$BookingQuoteModelCopyWithImpl<_BookingQuoteModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingQuoteModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingQuoteModel&&(identical(other.id, id) || other.id == id)&&(identical(other.bookingId, bookingId) || other.bookingId == bookingId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount)&&(identical(other.isUpsell, isUpsell) || other.isUpsell == isUpsell)&&const DeepCollectionEquality().equals(other._lineItems, _lineItems)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,bookingId,revisionNumber,status,totalAmount,isUpsell,const DeepCollectionEquality().hash(_lineItems),submittedAt);

@override
String toString() {
  return 'BookingQuoteModel(id: $id, bookingId: $bookingId, revisionNumber: $revisionNumber, status: $status, totalAmount: $totalAmount, isUpsell: $isUpsell, lineItems: $lineItems, submittedAt: $submittedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingQuoteModelCopyWith<$Res> implements $BookingQuoteModelCopyWith<$Res> {
  factory _$BookingQuoteModelCopyWith(_BookingQuoteModel value, $Res Function(_BookingQuoteModel) _then) = __$BookingQuoteModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'booking_id') int bookingId,@JsonKey(name: 'revision_number') int revisionNumber, String status,@JsonKey(name: 'total_amount') String totalAmount,@JsonKey(name: 'is_upsell') bool isUpsell,@JsonKey(name: 'line_items') List<BookingQuoteLineItemModel> lineItems,@JsonKey(name: 'submitted_at') String? submittedAt
});




}
/// @nodoc
class __$BookingQuoteModelCopyWithImpl<$Res>
    implements _$BookingQuoteModelCopyWith<$Res> {
  __$BookingQuoteModelCopyWithImpl(this._self, this._then);

  final _BookingQuoteModel _self;
  final $Res Function(_BookingQuoteModel) _then;

/// Create a copy of BookingQuoteModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bookingId = null,Object? revisionNumber = null,Object? status = null,Object? totalAmount = null,Object? isUpsell = null,Object? lineItems = null,Object? submittedAt = freezed,}) {
  return _then(_BookingQuoteModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,bookingId: null == bookingId ? _self.bookingId : bookingId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,isUpsell: null == isUpsell ? _self.isUpsell : isUpsell // ignore: cast_nullable_to_non_nullable
as bool,lineItems: null == lineItems ? _self._lineItems : lineItems // ignore: cast_nullable_to_non_nullable
as List<BookingQuoteLineItemModel>,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BookingQuoteLineItemModel {

 int get id;@JsonKey(name: 'sub_service_id') int get subServiceId;@JsonKey(name: 'sub_service_name') String get subServiceName; int get quantity;@JsonKey(name: 'priced_at') String get pricedAt;@JsonKey(name: 'line_total') String get lineTotal;
/// Create a copy of BookingQuoteLineItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingQuoteLineItemModelCopyWith<BookingQuoteLineItemModel> get copyWith => _$BookingQuoteLineItemModelCopyWithImpl<BookingQuoteLineItemModel>(this as BookingQuoteLineItemModel, _$identity);

  /// Serializes this BookingQuoteLineItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingQuoteLineItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,pricedAt,lineTotal);

@override
String toString() {
  return 'BookingQuoteLineItemModel(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, pricedAt: $pricedAt, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $BookingQuoteLineItemModelCopyWith<$Res>  {
  factory $BookingQuoteLineItemModelCopyWith(BookingQuoteLineItemModel value, $Res Function(BookingQuoteLineItemModel) _then) = _$BookingQuoteLineItemModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'sub_service_name') String subServiceName, int quantity,@JsonKey(name: 'priced_at') String pricedAt,@JsonKey(name: 'line_total') String lineTotal
});




}
/// @nodoc
class _$BookingQuoteLineItemModelCopyWithImpl<$Res>
    implements $BookingQuoteLineItemModelCopyWith<$Res> {
  _$BookingQuoteLineItemModelCopyWithImpl(this._self, this._then);

  final BookingQuoteLineItemModel _self;
  final $Res Function(BookingQuoteLineItemModel) _then;

/// Create a copy of BookingQuoteLineItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? pricedAt = null,Object? lineTotal = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pricedAt: null == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingQuoteLineItemModel].
extension BookingQuoteLineItemModelPatterns on BookingQuoteLineItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingQuoteLineItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingQuoteLineItemModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingQuoteLineItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'priced_at')  String pricedAt, @JsonKey(name: 'line_total')  String lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'priced_at')  String pricedAt, @JsonKey(name: 'line_total')  String lineTotal)  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'priced_at')  String pricedAt, @JsonKey(name: 'line_total')  String lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _BookingQuoteLineItemModel() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.pricedAt,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingQuoteLineItemModel implements BookingQuoteLineItemModel {
  const _BookingQuoteLineItemModel({required this.id, @JsonKey(name: 'sub_service_id') required this.subServiceId, @JsonKey(name: 'sub_service_name') required this.subServiceName, required this.quantity, @JsonKey(name: 'priced_at') required this.pricedAt, @JsonKey(name: 'line_total') required this.lineTotal});
  factory _BookingQuoteLineItemModel.fromJson(Map<String, dynamic> json) => _$BookingQuoteLineItemModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'sub_service_id') final  int subServiceId;
@override@JsonKey(name: 'sub_service_name') final  String subServiceName;
@override final  int quantity;
@override@JsonKey(name: 'priced_at') final  String pricedAt;
@override@JsonKey(name: 'line_total') final  String lineTotal;

/// Create a copy of BookingQuoteLineItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingQuoteLineItemModelCopyWith<_BookingQuoteLineItemModel> get copyWith => __$BookingQuoteLineItemModelCopyWithImpl<_BookingQuoteLineItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingQuoteLineItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingQuoteLineItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.pricedAt, pricedAt) || other.pricedAt == pricedAt)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,pricedAt,lineTotal);

@override
String toString() {
  return 'BookingQuoteLineItemModel(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, pricedAt: $pricedAt, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$BookingQuoteLineItemModelCopyWith<$Res> implements $BookingQuoteLineItemModelCopyWith<$Res> {
  factory _$BookingQuoteLineItemModelCopyWith(_BookingQuoteLineItemModel value, $Res Function(_BookingQuoteLineItemModel) _then) = __$BookingQuoteLineItemModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'sub_service_name') String subServiceName, int quantity,@JsonKey(name: 'priced_at') String pricedAt,@JsonKey(name: 'line_total') String lineTotal
});




}
/// @nodoc
class __$BookingQuoteLineItemModelCopyWithImpl<$Res>
    implements _$BookingQuoteLineItemModelCopyWith<$Res> {
  __$BookingQuoteLineItemModelCopyWithImpl(this._self, this._then);

  final _BookingQuoteLineItemModel _self;
  final $Res Function(_BookingQuoteLineItemModel) _then;

/// Create a copy of BookingQuoteLineItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? pricedAt = null,Object? lineTotal = null,}) {
  return _then(_BookingQuoteLineItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,pricedAt: null == pricedAt ? _self.pricedAt : pricedAt // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

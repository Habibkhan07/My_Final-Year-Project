// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_item_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingItemModel {

 int get id;@JsonKey(name: 'sub_service_id') int get subServiceId;@JsonKey(name: 'sub_service_name') String get subServiceName; int get quantity;@JsonKey(name: 'price_charged') String get priceCharged;@JsonKey(name: 'line_total') String get lineTotal;@JsonKey(name: 'sourced_quote_id') int? get sourcedQuoteId;
/// Create a copy of BookingItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingItemModelCopyWith<BookingItemModel> get copyWith => _$BookingItemModelCopyWithImpl<BookingItemModel>(this as BookingItemModel, _$identity);

  /// Serializes this BookingItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceCharged, priceCharged) || other.priceCharged == priceCharged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.sourcedQuoteId, sourcedQuoteId) || other.sourcedQuoteId == sourcedQuoteId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,priceCharged,lineTotal,sourcedQuoteId);

@override
String toString() {
  return 'BookingItemModel(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, priceCharged: $priceCharged, lineTotal: $lineTotal, sourcedQuoteId: $sourcedQuoteId)';
}


}

/// @nodoc
abstract mixin class $BookingItemModelCopyWith<$Res>  {
  factory $BookingItemModelCopyWith(BookingItemModel value, $Res Function(BookingItemModel) _then) = _$BookingItemModelCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'sub_service_name') String subServiceName, int quantity,@JsonKey(name: 'price_charged') String priceCharged,@JsonKey(name: 'line_total') String lineTotal,@JsonKey(name: 'sourced_quote_id') int? sourcedQuoteId
});




}
/// @nodoc
class _$BookingItemModelCopyWithImpl<$Res>
    implements $BookingItemModelCopyWith<$Res> {
  _$BookingItemModelCopyWithImpl(this._self, this._then);

  final BookingItemModel _self;
  final $Res Function(BookingItemModel) _then;

/// Create a copy of BookingItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? priceCharged = null,Object? lineTotal = null,Object? sourcedQuoteId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,priceCharged: null == priceCharged ? _self.priceCharged : priceCharged // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,sourcedQuoteId: freezed == sourcedQuoteId ? _self.sourcedQuoteId : sourcedQuoteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingItemModel].
extension BookingItemModelPatterns on BookingItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingItemModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'price_charged')  String priceCharged, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'sourced_quote_id')  int? sourcedQuoteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingItemModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'price_charged')  String priceCharged, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'sourced_quote_id')  int? sourcedQuoteId)  $default,) {final _that = this;
switch (_that) {
case _BookingItemModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'sub_service_name')  String subServiceName,  int quantity, @JsonKey(name: 'price_charged')  String priceCharged, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'sourced_quote_id')  int? sourcedQuoteId)?  $default,) {final _that = this;
switch (_that) {
case _BookingItemModel() when $default != null:
return $default(_that.id,_that.subServiceId,_that.subServiceName,_that.quantity,_that.priceCharged,_that.lineTotal,_that.sourcedQuoteId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingItemModel implements BookingItemModel {
  const _BookingItemModel({required this.id, @JsonKey(name: 'sub_service_id') required this.subServiceId, @JsonKey(name: 'sub_service_name') required this.subServiceName, required this.quantity, @JsonKey(name: 'price_charged') required this.priceCharged, @JsonKey(name: 'line_total') required this.lineTotal, @JsonKey(name: 'sourced_quote_id') this.sourcedQuoteId});
  factory _BookingItemModel.fromJson(Map<String, dynamic> json) => _$BookingItemModelFromJson(json);

@override final  int id;
@override@JsonKey(name: 'sub_service_id') final  int subServiceId;
@override@JsonKey(name: 'sub_service_name') final  String subServiceName;
@override final  int quantity;
@override@JsonKey(name: 'price_charged') final  String priceCharged;
@override@JsonKey(name: 'line_total') final  String lineTotal;
@override@JsonKey(name: 'sourced_quote_id') final  int? sourcedQuoteId;

/// Create a copy of BookingItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingItemModelCopyWith<_BookingItemModel> get copyWith => __$BookingItemModelCopyWithImpl<_BookingItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.subServiceName, subServiceName) || other.subServiceName == subServiceName)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.priceCharged, priceCharged) || other.priceCharged == priceCharged)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.sourcedQuoteId, sourcedQuoteId) || other.sourcedQuoteId == sourcedQuoteId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subServiceId,subServiceName,quantity,priceCharged,lineTotal,sourcedQuoteId);

@override
String toString() {
  return 'BookingItemModel(id: $id, subServiceId: $subServiceId, subServiceName: $subServiceName, quantity: $quantity, priceCharged: $priceCharged, lineTotal: $lineTotal, sourcedQuoteId: $sourcedQuoteId)';
}


}

/// @nodoc
abstract mixin class _$BookingItemModelCopyWith<$Res> implements $BookingItemModelCopyWith<$Res> {
  factory _$BookingItemModelCopyWith(_BookingItemModel value, $Res Function(_BookingItemModel) _then) = __$BookingItemModelCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'sub_service_name') String subServiceName, int quantity,@JsonKey(name: 'price_charged') String priceCharged,@JsonKey(name: 'line_total') String lineTotal,@JsonKey(name: 'sourced_quote_id') int? sourcedQuoteId
});




}
/// @nodoc
class __$BookingItemModelCopyWithImpl<$Res>
    implements _$BookingItemModelCopyWith<$Res> {
  __$BookingItemModelCopyWithImpl(this._self, this._then);

  final _BookingItemModel _self;
  final $Res Function(_BookingItemModel) _then;

/// Create a copy of BookingItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subServiceId = null,Object? subServiceName = null,Object? quantity = null,Object? priceCharged = null,Object? lineTotal = null,Object? sourcedQuoteId = freezed,}) {
  return _then(_BookingItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,subServiceName: null == subServiceName ? _self.subServiceName : subServiceName // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,priceCharged: null == priceCharged ? _self.priceCharged : priceCharged // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,sourcedQuoteId: freezed == sourcedQuoteId ? _self.sourcedQuoteId : sourcedQuoteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

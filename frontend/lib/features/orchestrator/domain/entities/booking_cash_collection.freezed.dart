// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_cash_collection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingCashCollection {

 int? get amount; DateTime? get at; String get method;
/// Create a copy of BookingCashCollection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingCashCollectionCopyWith<BookingCashCollection> get copyWith => _$BookingCashCollectionCopyWithImpl<BookingCashCollection>(this as BookingCashCollection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingCashCollection&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at)&&(identical(other.method, method) || other.method == method));
}


@override
int get hashCode => Object.hash(runtimeType,amount,at,method);

@override
String toString() {
  return 'BookingCashCollection(amount: $amount, at: $at, method: $method)';
}


}

/// @nodoc
abstract mixin class $BookingCashCollectionCopyWith<$Res>  {
  factory $BookingCashCollectionCopyWith(BookingCashCollection value, $Res Function(BookingCashCollection) _then) = _$BookingCashCollectionCopyWithImpl;
@useResult
$Res call({
 int? amount, DateTime? at, String method
});




}
/// @nodoc
class _$BookingCashCollectionCopyWithImpl<$Res>
    implements $BookingCashCollectionCopyWith<$Res> {
  _$BookingCashCollectionCopyWithImpl(this._self, this._then);

  final BookingCashCollection _self;
  final $Res Function(BookingCashCollection) _then;

/// Create a copy of BookingCashCollection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? amount = freezed,Object? at = freezed,Object? method = null,}) {
  return _then(_self.copyWith(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingCashCollection].
extension BookingCashCollectionPatterns on BookingCashCollection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingCashCollection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingCashCollection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingCashCollection value)  $default,){
final _that = this;
switch (_that) {
case _BookingCashCollection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingCashCollection value)?  $default,){
final _that = this;
switch (_that) {
case _BookingCashCollection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? amount,  DateTime? at,  String method)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingCashCollection() when $default != null:
return $default(_that.amount,_that.at,_that.method);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? amount,  DateTime? at,  String method)  $default,) {final _that = this;
switch (_that) {
case _BookingCashCollection():
return $default(_that.amount,_that.at,_that.method);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? amount,  DateTime? at,  String method)?  $default,) {final _that = this;
switch (_that) {
case _BookingCashCollection() when $default != null:
return $default(_that.amount,_that.at,_that.method);case _:
  return null;

}
}

}

/// @nodoc


class _BookingCashCollection implements BookingCashCollection {
  const _BookingCashCollection({this.amount, this.at, this.method = 'cash'});
  

@override final  int? amount;
@override final  DateTime? at;
@override@JsonKey() final  String method;

/// Create a copy of BookingCashCollection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingCashCollectionCopyWith<_BookingCashCollection> get copyWith => __$BookingCashCollectionCopyWithImpl<_BookingCashCollection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingCashCollection&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.at, at) || other.at == at)&&(identical(other.method, method) || other.method == method));
}


@override
int get hashCode => Object.hash(runtimeType,amount,at,method);

@override
String toString() {
  return 'BookingCashCollection(amount: $amount, at: $at, method: $method)';
}


}

/// @nodoc
abstract mixin class _$BookingCashCollectionCopyWith<$Res> implements $BookingCashCollectionCopyWith<$Res> {
  factory _$BookingCashCollectionCopyWith(_BookingCashCollection value, $Res Function(_BookingCashCollection) _then) = __$BookingCashCollectionCopyWithImpl;
@override @useResult
$Res call({
 int? amount, DateTime? at, String method
});




}
/// @nodoc
class __$BookingCashCollectionCopyWithImpl<$Res>
    implements _$BookingCashCollectionCopyWith<$Res> {
  __$BookingCashCollectionCopyWithImpl(this._self, this._then);

  final _BookingCashCollection _self;
  final $Res Function(_BookingCashCollection) _then;

/// Create a copy of BookingCashCollection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? amount = freezed,Object? at = freezed,Object? method = null,}) {
  return _then(_BookingCashCollection(
amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,at: freezed == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime?,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

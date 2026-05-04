// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookings_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingsPage {

 List<CustomerBooking> get items; String? get nextCursor; bool get hasMore; DateTime get serverTime; bool get isStaleCache; DateTime? get cachedAt;
/// Create a copy of BookingsPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingsPageCopyWith<BookingsPage> get copyWith => _$BookingsPageCopyWithImpl<BookingsPage>(this as BookingsPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingsPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor,hasMore,serverTime,isStaleCache,cachedAt);

@override
String toString() {
  return 'BookingsPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime, isStaleCache: $isStaleCache, cachedAt: $cachedAt)';
}


}

/// @nodoc
abstract mixin class $BookingsPageCopyWith<$Res>  {
  factory $BookingsPageCopyWith(BookingsPage value, $Res Function(BookingsPage) _then) = _$BookingsPageCopyWithImpl;
@useResult
$Res call({
 List<CustomerBooking> items, String? nextCursor, bool hasMore, DateTime serverTime, bool isStaleCache, DateTime? cachedAt
});




}
/// @nodoc
class _$BookingsPageCopyWithImpl<$Res>
    implements $BookingsPageCopyWith<$Res> {
  _$BookingsPageCopyWithImpl(this._self, this._then);

  final BookingsPage _self;
  final $Res Function(BookingsPage) _then;

/// Create a copy of BookingsPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? isStaleCache = null,Object? cachedAt = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CustomerBooking>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingsPage].
extension BookingsPagePatterns on BookingsPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingsPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingsPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingsPage value)  $default,){
final _that = this;
switch (_that) {
case _BookingsPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingsPage value)?  $default,){
final _that = this;
switch (_that) {
case _BookingsPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CustomerBooking> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingsPage() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime,_that.isStaleCache,_that.cachedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CustomerBooking> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)  $default,) {final _that = this;
switch (_that) {
case _BookingsPage():
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime,_that.isStaleCache,_that.cachedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CustomerBooking> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)?  $default,) {final _that = this;
switch (_that) {
case _BookingsPage() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime,_that.isStaleCache,_that.cachedAt);case _:
  return null;

}
}

}

/// @nodoc


class _BookingsPage implements BookingsPage {
  const _BookingsPage({required final  List<CustomerBooking> items, required this.nextCursor, required this.hasMore, required this.serverTime, this.isStaleCache = false, this.cachedAt}): _items = items;
  

 final  List<CustomerBooking> _items;
@override List<CustomerBooking> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override final  bool hasMore;
@override final  DateTime serverTime;
@override@JsonKey() final  bool isStaleCache;
@override final  DateTime? cachedAt;

/// Create a copy of BookingsPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingsPageCopyWith<_BookingsPage> get copyWith => __$BookingsPageCopyWithImpl<_BookingsPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingsPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,hasMore,serverTime,isStaleCache,cachedAt);

@override
String toString() {
  return 'BookingsPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime, isStaleCache: $isStaleCache, cachedAt: $cachedAt)';
}


}

/// @nodoc
abstract mixin class _$BookingsPageCopyWith<$Res> implements $BookingsPageCopyWith<$Res> {
  factory _$BookingsPageCopyWith(_BookingsPage value, $Res Function(_BookingsPage) _then) = __$BookingsPageCopyWithImpl;
@override @useResult
$Res call({
 List<CustomerBooking> items, String? nextCursor, bool hasMore, DateTime serverTime, bool isStaleCache, DateTime? cachedAt
});




}
/// @nodoc
class __$BookingsPageCopyWithImpl<$Res>
    implements _$BookingsPageCopyWith<$Res> {
  __$BookingsPageCopyWithImpl(this._self, this._then);

  final _BookingsPage _self;
  final $Res Function(_BookingsPage) _then;

/// Create a copy of BookingsPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? isStaleCache = null,Object? cachedAt = freezed,}) {
  return _then(_BookingsPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CustomerBooking>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

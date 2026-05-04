// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookings_list_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingsListResponseModel {

 List<CustomerBookingModel> get items;@JsonKey(name: 'next_cursor') String? get nextCursor;@JsonKey(name: 'has_more') bool get hasMore;@JsonKey(name: 'server_time') String get serverTime;
/// Create a copy of BookingsListResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingsListResponseModelCopyWith<BookingsListResponseModel> get copyWith => _$BookingsListResponseModelCopyWithImpl<BookingsListResponseModel>(this as BookingsListResponseModel, _$identity);

  /// Serializes this BookingsListResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingsListResponseModel&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor,hasMore,serverTime);

@override
String toString() {
  return 'BookingsListResponseModel(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class $BookingsListResponseModelCopyWith<$Res>  {
  factory $BookingsListResponseModelCopyWith(BookingsListResponseModel value, $Res Function(BookingsListResponseModel) _then) = _$BookingsListResponseModelCopyWithImpl;
@useResult
$Res call({
 List<CustomerBookingModel> items,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'server_time') String serverTime
});




}
/// @nodoc
class _$BookingsListResponseModelCopyWithImpl<$Res>
    implements $BookingsListResponseModelCopyWith<$Res> {
  _$BookingsListResponseModelCopyWithImpl(this._self, this._then);

  final BookingsListResponseModel _self;
  final $Res Function(BookingsListResponseModel) _then;

/// Create a copy of BookingsListResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CustomerBookingModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingsListResponseModel].
extension BookingsListResponseModelPatterns on BookingsListResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingsListResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingsListResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingsListResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingsListResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingsListResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingsListResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CustomerBookingModel> items, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'server_time')  String serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingsListResponseModel() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CustomerBookingModel> items, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'server_time')  String serverTime)  $default,) {final _that = this;
switch (_that) {
case _BookingsListResponseModel():
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CustomerBookingModel> items, @JsonKey(name: 'next_cursor')  String? nextCursor, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'server_time')  String serverTime)?  $default,) {final _that = this;
switch (_that) {
case _BookingsListResponseModel() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingsListResponseModel implements BookingsListResponseModel {
  const _BookingsListResponseModel({required final  List<CustomerBookingModel> items, @JsonKey(name: 'next_cursor') required this.nextCursor, @JsonKey(name: 'has_more') required this.hasMore, @JsonKey(name: 'server_time') required this.serverTime}): _items = items;
  factory _BookingsListResponseModel.fromJson(Map<String, dynamic> json) => _$BookingsListResponseModelFromJson(json);

 final  List<CustomerBookingModel> _items;
@override List<CustomerBookingModel> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'next_cursor') final  String? nextCursor;
@override@JsonKey(name: 'has_more') final  bool hasMore;
@override@JsonKey(name: 'server_time') final  String serverTime;

/// Create a copy of BookingsListResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingsListResponseModelCopyWith<_BookingsListResponseModel> get copyWith => __$BookingsListResponseModelCopyWithImpl<_BookingsListResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingsListResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingsListResponseModel&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,hasMore,serverTime);

@override
String toString() {
  return 'BookingsListResponseModel(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$BookingsListResponseModelCopyWith<$Res> implements $BookingsListResponseModelCopyWith<$Res> {
  factory _$BookingsListResponseModelCopyWith(_BookingsListResponseModel value, $Res Function(_BookingsListResponseModel) _then) = __$BookingsListResponseModelCopyWithImpl;
@override @useResult
$Res call({
 List<CustomerBookingModel> items,@JsonKey(name: 'next_cursor') String? nextCursor,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'server_time') String serverTime
});




}
/// @nodoc
class __$BookingsListResponseModelCopyWithImpl<$Res>
    implements _$BookingsListResponseModelCopyWith<$Res> {
  __$BookingsListResponseModelCopyWithImpl(this._self, this._then);

  final _BookingsListResponseModel _self;
  final $Res Function(_BookingsListResponseModel) _then;

/// Create a copy of BookingsListResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,}) {
  return _then(_BookingsListResponseModel(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CustomerBookingModel>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

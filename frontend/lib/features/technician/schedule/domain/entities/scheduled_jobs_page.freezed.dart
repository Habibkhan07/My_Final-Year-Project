// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_jobs_page.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduledJobsPage {

 List<ScheduledJob> get items; String? get nextCursor; bool get hasMore; DateTime get serverTime; bool get isStaleCache; DateTime? get cachedAt;
/// Create a copy of ScheduledJobsPage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobsPageCopyWith<ScheduledJobsPage> get copyWith => _$ScheduledJobsPageCopyWithImpl<ScheduledJobsPage>(this as ScheduledJobsPage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobsPage&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),nextCursor,hasMore,serverTime,isStaleCache,cachedAt);

@override
String toString() {
  return 'ScheduledJobsPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime, isStaleCache: $isStaleCache, cachedAt: $cachedAt)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobsPageCopyWith<$Res>  {
  factory $ScheduledJobsPageCopyWith(ScheduledJobsPage value, $Res Function(ScheduledJobsPage) _then) = _$ScheduledJobsPageCopyWithImpl;
@useResult
$Res call({
 List<ScheduledJob> items, String? nextCursor, bool hasMore, DateTime serverTime, bool isStaleCache, DateTime? cachedAt
});




}
/// @nodoc
class _$ScheduledJobsPageCopyWithImpl<$Res>
    implements $ScheduledJobsPageCopyWith<$Res> {
  _$ScheduledJobsPageCopyWithImpl(this._self, this._then);

  final ScheduledJobsPage _self;
  final $Res Function(ScheduledJobsPage) _then;

/// Create a copy of ScheduledJobsPage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? isStaleCache = null,Object? cachedAt = freezed,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ScheduledJob>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledJobsPage].
extension ScheduledJobsPagePatterns on ScheduledJobsPage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobsPage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobsPage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobsPage value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobsPage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobsPage value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobsPage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJobsPage() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobsPage():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  DateTime serverTime,  bool isStaleCache,  DateTime? cachedAt)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobsPage() when $default != null:
return $default(_that.items,_that.nextCursor,_that.hasMore,_that.serverTime,_that.isStaleCache,_that.cachedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJobsPage implements ScheduledJobsPage {
  const _ScheduledJobsPage({required final  List<ScheduledJob> items, required this.nextCursor, required this.hasMore, required this.serverTime, this.isStaleCache = false, this.cachedAt}): _items = items;
  

 final  List<ScheduledJob> _items;
@override List<ScheduledJob> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  String? nextCursor;
@override final  bool hasMore;
@override final  DateTime serverTime;
@override@JsonKey() final  bool isStaleCache;
@override final  DateTime? cachedAt;

/// Create a copy of ScheduledJobsPage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobsPageCopyWith<_ScheduledJobsPage> get copyWith => __$ScheduledJobsPageCopyWithImpl<_ScheduledJobsPage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobsPage&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),nextCursor,hasMore,serverTime,isStaleCache,cachedAt);

@override
String toString() {
  return 'ScheduledJobsPage(items: $items, nextCursor: $nextCursor, hasMore: $hasMore, serverTime: $serverTime, isStaleCache: $isStaleCache, cachedAt: $cachedAt)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobsPageCopyWith<$Res> implements $ScheduledJobsPageCopyWith<$Res> {
  factory _$ScheduledJobsPageCopyWith(_ScheduledJobsPage value, $Res Function(_ScheduledJobsPage) _then) = __$ScheduledJobsPageCopyWithImpl;
@override @useResult
$Res call({
 List<ScheduledJob> items, String? nextCursor, bool hasMore, DateTime serverTime, bool isStaleCache, DateTime? cachedAt
});




}
/// @nodoc
class __$ScheduledJobsPageCopyWithImpl<$Res>
    implements _$ScheduledJobsPageCopyWith<$Res> {
  __$ScheduledJobsPageCopyWithImpl(this._self, this._then);

  final _ScheduledJobsPage _self;
  final $Res Function(_ScheduledJobsPage) _then;

/// Create a copy of ScheduledJobsPage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? serverTime = null,Object? isStaleCache = null,Object? cachedAt = freezed,}) {
  return _then(_ScheduledJobsPage(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ScheduledJob>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on

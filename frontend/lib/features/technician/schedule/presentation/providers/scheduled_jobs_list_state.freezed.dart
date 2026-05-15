// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheduled_jobs_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduledJobsListState {

/// Which segment this state belongs to. The notifier sets it on
/// build; the screen reads it when deciding whether to re-issue a
/// load (rare belt-and-suspenders — the watched
/// `selectedScheduleSegmentProvider` already triggers a re-build).
 ScheduledJobSegment get segment;/// All jobs loaded so far for [segment]. Pagination appends to this
/// list; pull-to-refresh replaces it.
 List<ScheduledJob> get items;/// Cursor to fetch the next page. Null when no more pages.
 String? get nextCursor;/// Whether the underlying queryset has rows beyond what's loaded.
/// Drives both the list-footer loading spinner and the `loadMore()`
/// guard.
 bool get hasMore;/// True while a `loadMore()` request is in flight. The screen
/// renders a footer spinner while true and gates further
/// `loadMore()` calls.
 bool get isLoadingMore;/// True when the items currently shown were served from local cache
/// after a `SocketException`. The screen surfaces an offline banner
/// with the [cachedAt] timestamp when true.
 bool get isStaleCache;/// When the cached page was originally fetched. Null when [items]
/// is fresh-from-network.
 DateTime? get cachedAt;/// Server clock at the time the page was assembled. Used by the
/// card's date formatter to anchor "Today / Tomorrow / In 30 min"
/// labels regardless of device-clock skew.
 DateTime get serverTime;
/// Create a copy of ScheduledJobsListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduledJobsListStateCopyWith<ScheduledJobsListState> get copyWith => _$ScheduledJobsListStateCopyWithImpl<ScheduledJobsListState>(this as ScheduledJobsListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduledJobsListState&&(identical(other.segment, segment) || other.segment == segment)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}


@override
int get hashCode => Object.hash(runtimeType,segment,const DeepCollectionEquality().hash(items),nextCursor,hasMore,isLoadingMore,isStaleCache,cachedAt,serverTime);

@override
String toString() {
  return 'ScheduledJobsListState(segment: $segment, items: $items, nextCursor: $nextCursor, hasMore: $hasMore, isLoadingMore: $isLoadingMore, isStaleCache: $isStaleCache, cachedAt: $cachedAt, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class $ScheduledJobsListStateCopyWith<$Res>  {
  factory $ScheduledJobsListStateCopyWith(ScheduledJobsListState value, $Res Function(ScheduledJobsListState) _then) = _$ScheduledJobsListStateCopyWithImpl;
@useResult
$Res call({
 ScheduledJobSegment segment, List<ScheduledJob> items, String? nextCursor, bool hasMore, bool isLoadingMore, bool isStaleCache, DateTime? cachedAt, DateTime serverTime
});




}
/// @nodoc
class _$ScheduledJobsListStateCopyWithImpl<$Res>
    implements $ScheduledJobsListStateCopyWith<$Res> {
  _$ScheduledJobsListStateCopyWithImpl(this._self, this._then);

  final ScheduledJobsListState _self;
  final $Res Function(ScheduledJobsListState) _then;

/// Create a copy of ScheduledJobsListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segment = null,Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? isLoadingMore = null,Object? isStaleCache = null,Object? cachedAt = freezed,Object? serverTime = null,}) {
  return _then(_self.copyWith(
segment: null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as ScheduledJobSegment,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<ScheduledJob>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduledJobsListState].
extension ScheduledJobsListStatePatterns on ScheduledJobsListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduledJobsListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduledJobsListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduledJobsListState value)  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobsListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduledJobsListState value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduledJobsListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ScheduledJobSegment segment,  List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  bool isLoadingMore,  bool isStaleCache,  DateTime? cachedAt,  DateTime serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduledJobsListState() when $default != null:
return $default(_that.segment,_that.items,_that.nextCursor,_that.hasMore,_that.isLoadingMore,_that.isStaleCache,_that.cachedAt,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ScheduledJobSegment segment,  List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  bool isLoadingMore,  bool isStaleCache,  DateTime? cachedAt,  DateTime serverTime)  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobsListState():
return $default(_that.segment,_that.items,_that.nextCursor,_that.hasMore,_that.isLoadingMore,_that.isStaleCache,_that.cachedAt,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ScheduledJobSegment segment,  List<ScheduledJob> items,  String? nextCursor,  bool hasMore,  bool isLoadingMore,  bool isStaleCache,  DateTime? cachedAt,  DateTime serverTime)?  $default,) {final _that = this;
switch (_that) {
case _ScheduledJobsListState() when $default != null:
return $default(_that.segment,_that.items,_that.nextCursor,_that.hasMore,_that.isLoadingMore,_that.isStaleCache,_that.cachedAt,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduledJobsListState implements ScheduledJobsListState {
  const _ScheduledJobsListState({required this.segment, final  List<ScheduledJob> items = const <ScheduledJob>[], this.nextCursor, this.hasMore = false, this.isLoadingMore = false, this.isStaleCache = false, this.cachedAt, required this.serverTime}): _items = items;
  

/// Which segment this state belongs to. The notifier sets it on
/// build; the screen reads it when deciding whether to re-issue a
/// load (rare belt-and-suspenders — the watched
/// `selectedScheduleSegmentProvider` already triggers a re-build).
@override final  ScheduledJobSegment segment;
/// All jobs loaded so far for [segment]. Pagination appends to this
/// list; pull-to-refresh replaces it.
 final  List<ScheduledJob> _items;
/// All jobs loaded so far for [segment]. Pagination appends to this
/// list; pull-to-refresh replaces it.
@override@JsonKey() List<ScheduledJob> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Cursor to fetch the next page. Null when no more pages.
@override final  String? nextCursor;
/// Whether the underlying queryset has rows beyond what's loaded.
/// Drives both the list-footer loading spinner and the `loadMore()`
/// guard.
@override@JsonKey() final  bool hasMore;
/// True while a `loadMore()` request is in flight. The screen
/// renders a footer spinner while true and gates further
/// `loadMore()` calls.
@override@JsonKey() final  bool isLoadingMore;
/// True when the items currently shown were served from local cache
/// after a `SocketException`. The screen surfaces an offline banner
/// with the [cachedAt] timestamp when true.
@override@JsonKey() final  bool isStaleCache;
/// When the cached page was originally fetched. Null when [items]
/// is fresh-from-network.
@override final  DateTime? cachedAt;
/// Server clock at the time the page was assembled. Used by the
/// card's date formatter to anchor "Today / Tomorrow / In 30 min"
/// labels regardless of device-clock skew.
@override final  DateTime serverTime;

/// Create a copy of ScheduledJobsListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduledJobsListStateCopyWith<_ScheduledJobsListState> get copyWith => __$ScheduledJobsListStateCopyWithImpl<_ScheduledJobsListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduledJobsListState&&(identical(other.segment, segment) || other.segment == segment)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.nextCursor, nextCursor) || other.nextCursor == nextCursor)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.isStaleCache, isStaleCache) || other.isStaleCache == isStaleCache)&&(identical(other.cachedAt, cachedAt) || other.cachedAt == cachedAt)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}


@override
int get hashCode => Object.hash(runtimeType,segment,const DeepCollectionEquality().hash(_items),nextCursor,hasMore,isLoadingMore,isStaleCache,cachedAt,serverTime);

@override
String toString() {
  return 'ScheduledJobsListState(segment: $segment, items: $items, nextCursor: $nextCursor, hasMore: $hasMore, isLoadingMore: $isLoadingMore, isStaleCache: $isStaleCache, cachedAt: $cachedAt, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$ScheduledJobsListStateCopyWith<$Res> implements $ScheduledJobsListStateCopyWith<$Res> {
  factory _$ScheduledJobsListStateCopyWith(_ScheduledJobsListState value, $Res Function(_ScheduledJobsListState) _then) = __$ScheduledJobsListStateCopyWithImpl;
@override @useResult
$Res call({
 ScheduledJobSegment segment, List<ScheduledJob> items, String? nextCursor, bool hasMore, bool isLoadingMore, bool isStaleCache, DateTime? cachedAt, DateTime serverTime
});




}
/// @nodoc
class __$ScheduledJobsListStateCopyWithImpl<$Res>
    implements _$ScheduledJobsListStateCopyWith<$Res> {
  __$ScheduledJobsListStateCopyWithImpl(this._self, this._then);

  final _ScheduledJobsListState _self;
  final $Res Function(_ScheduledJobsListState) _then;

/// Create a copy of ScheduledJobsListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segment = null,Object? items = null,Object? nextCursor = freezed,Object? hasMore = null,Object? isLoadingMore = null,Object? isStaleCache = null,Object? cachedAt = freezed,Object? serverTime = null,}) {
  return _then(_ScheduledJobsListState(
segment: null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as ScheduledJobSegment,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ScheduledJob>,nextCursor: freezed == nextCursor ? _self.nextCursor : nextCursor // ignore: cast_nullable_to_non_nullable
as String?,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,isStaleCache: null == isStaleCache ? _self.isStaleCache : isStaleCache // ignore: cast_nullable_to_non_nullable
as bool,cachedAt: freezed == cachedAt ? _self.cachedAt : cachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on

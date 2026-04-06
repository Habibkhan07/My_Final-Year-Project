// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiscoveryState {

/// The current page of results.
 DiscoveryResultEntity? get discoveryResult;/// Current search/filter parameters to allow refresh or pagination.
 String? get query; int? get serviceId; int? get subServiceId; int? get promotionId; double? get lat; double? get lng;/// Tracks if we are currently fetching the NEXT page.
 bool get isPaginationLoading;
/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryStateCopyWith<DiscoveryState> get copyWith => _$DiscoveryStateCopyWithImpl<DiscoveryState>(this as DiscoveryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryState&&(identical(other.discoveryResult, discoveryResult) || other.discoveryResult == discoveryResult)&&(identical(other.query, query) || other.query == query)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.promotionId, promotionId) || other.promotionId == promotionId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.isPaginationLoading, isPaginationLoading) || other.isPaginationLoading == isPaginationLoading));
}


@override
int get hashCode => Object.hash(runtimeType,discoveryResult,query,serviceId,subServiceId,promotionId,lat,lng,isPaginationLoading);

@override
String toString() {
  return 'DiscoveryState(discoveryResult: $discoveryResult, query: $query, serviceId: $serviceId, subServiceId: $subServiceId, promotionId: $promotionId, lat: $lat, lng: $lng, isPaginationLoading: $isPaginationLoading)';
}


}

/// @nodoc
abstract mixin class $DiscoveryStateCopyWith<$Res>  {
  factory $DiscoveryStateCopyWith(DiscoveryState value, $Res Function(DiscoveryState) _then) = _$DiscoveryStateCopyWithImpl;
@useResult
$Res call({
 DiscoveryResultEntity? discoveryResult, String? query, int? serviceId, int? subServiceId, int? promotionId, double? lat, double? lng, bool isPaginationLoading
});


$DiscoveryResultEntityCopyWith<$Res>? get discoveryResult;

}
/// @nodoc
class _$DiscoveryStateCopyWithImpl<$Res>
    implements $DiscoveryStateCopyWith<$Res> {
  _$DiscoveryStateCopyWithImpl(this._self, this._then);

  final DiscoveryState _self;
  final $Res Function(DiscoveryState) _then;

/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? discoveryResult = freezed,Object? query = freezed,Object? serviceId = freezed,Object? subServiceId = freezed,Object? promotionId = freezed,Object? lat = freezed,Object? lng = freezed,Object? isPaginationLoading = null,}) {
  return _then(_self.copyWith(
discoveryResult: freezed == discoveryResult ? _self.discoveryResult : discoveryResult // ignore: cast_nullable_to_non_nullable
as DiscoveryResultEntity?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int?,subServiceId: freezed == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int?,promotionId: freezed == promotionId ? _self.promotionId : promotionId // ignore: cast_nullable_to_non_nullable
as int?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,isPaginationLoading: null == isPaginationLoading ? _self.isPaginationLoading : isPaginationLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoveryResultEntityCopyWith<$Res>? get discoveryResult {
    if (_self.discoveryResult == null) {
    return null;
  }

  return $DiscoveryResultEntityCopyWith<$Res>(_self.discoveryResult!, (value) {
    return _then(_self.copyWith(discoveryResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [DiscoveryState].
extension DiscoveryStatePatterns on DiscoveryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryState value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryState value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DiscoveryResultEntity? discoveryResult,  String? query,  int? serviceId,  int? subServiceId,  int? promotionId,  double? lat,  double? lng,  bool isPaginationLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryState() when $default != null:
return $default(_that.discoveryResult,_that.query,_that.serviceId,_that.subServiceId,_that.promotionId,_that.lat,_that.lng,_that.isPaginationLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DiscoveryResultEntity? discoveryResult,  String? query,  int? serviceId,  int? subServiceId,  int? promotionId,  double? lat,  double? lng,  bool isPaginationLoading)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryState():
return $default(_that.discoveryResult,_that.query,_that.serviceId,_that.subServiceId,_that.promotionId,_that.lat,_that.lng,_that.isPaginationLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DiscoveryResultEntity? discoveryResult,  String? query,  int? serviceId,  int? subServiceId,  int? promotionId,  double? lat,  double? lng,  bool isPaginationLoading)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryState() when $default != null:
return $default(_that.discoveryResult,_that.query,_that.serviceId,_that.subServiceId,_that.promotionId,_that.lat,_that.lng,_that.isPaginationLoading);case _:
  return null;

}
}

}

/// @nodoc


class _DiscoveryState implements DiscoveryState {
  const _DiscoveryState({this.discoveryResult, this.query, this.serviceId, this.subServiceId, this.promotionId, this.lat, this.lng, this.isPaginationLoading = false});
  

/// The current page of results.
@override final  DiscoveryResultEntity? discoveryResult;
/// Current search/filter parameters to allow refresh or pagination.
@override final  String? query;
@override final  int? serviceId;
@override final  int? subServiceId;
@override final  int? promotionId;
@override final  double? lat;
@override final  double? lng;
/// Tracks if we are currently fetching the NEXT page.
@override@JsonKey() final  bool isPaginationLoading;

/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryStateCopyWith<_DiscoveryState> get copyWith => __$DiscoveryStateCopyWithImpl<_DiscoveryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryState&&(identical(other.discoveryResult, discoveryResult) || other.discoveryResult == discoveryResult)&&(identical(other.query, query) || other.query == query)&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.promotionId, promotionId) || other.promotionId == promotionId)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.isPaginationLoading, isPaginationLoading) || other.isPaginationLoading == isPaginationLoading));
}


@override
int get hashCode => Object.hash(runtimeType,discoveryResult,query,serviceId,subServiceId,promotionId,lat,lng,isPaginationLoading);

@override
String toString() {
  return 'DiscoveryState(discoveryResult: $discoveryResult, query: $query, serviceId: $serviceId, subServiceId: $subServiceId, promotionId: $promotionId, lat: $lat, lng: $lng, isPaginationLoading: $isPaginationLoading)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryStateCopyWith<$Res> implements $DiscoveryStateCopyWith<$Res> {
  factory _$DiscoveryStateCopyWith(_DiscoveryState value, $Res Function(_DiscoveryState) _then) = __$DiscoveryStateCopyWithImpl;
@override @useResult
$Res call({
 DiscoveryResultEntity? discoveryResult, String? query, int? serviceId, int? subServiceId, int? promotionId, double? lat, double? lng, bool isPaginationLoading
});


@override $DiscoveryResultEntityCopyWith<$Res>? get discoveryResult;

}
/// @nodoc
class __$DiscoveryStateCopyWithImpl<$Res>
    implements _$DiscoveryStateCopyWith<$Res> {
  __$DiscoveryStateCopyWithImpl(this._self, this._then);

  final _DiscoveryState _self;
  final $Res Function(_DiscoveryState) _then;

/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? discoveryResult = freezed,Object? query = freezed,Object? serviceId = freezed,Object? subServiceId = freezed,Object? promotionId = freezed,Object? lat = freezed,Object? lng = freezed,Object? isPaginationLoading = null,}) {
  return _then(_DiscoveryState(
discoveryResult: freezed == discoveryResult ? _self.discoveryResult : discoveryResult // ignore: cast_nullable_to_non_nullable
as DiscoveryResultEntity?,query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,serviceId: freezed == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int?,subServiceId: freezed == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int?,promotionId: freezed == promotionId ? _self.promotionId : promotionId // ignore: cast_nullable_to_non_nullable
as int?,lat: freezed == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double?,lng: freezed == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double?,isPaginationLoading: null == isPaginationLoading ? _self.isPaginationLoading : isPaginationLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DiscoveryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DiscoveryResultEntityCopyWith<$Res>? get discoveryResult {
    if (_self.discoveryResult == null) {
    return null;
  }

  return $DiscoveryResultEntityCopyWith<$Res>(_self.discoveryResult!, (value) {
    return _then(_self.copyWith(discoveryResult: value));
  });
}
}

// dart format on

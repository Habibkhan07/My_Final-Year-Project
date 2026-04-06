// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

 HomeFeedEntity? get homeFeed; double? get lastLat; double? get lastLng;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&(identical(other.homeFeed, homeFeed) || other.homeFeed == homeFeed)&&(identical(other.lastLat, lastLat) || other.lastLat == lastLat)&&(identical(other.lastLng, lastLng) || other.lastLng == lastLng));
}


@override
int get hashCode => Object.hash(runtimeType,homeFeed,lastLat,lastLng);

@override
String toString() {
  return 'HomeState(homeFeed: $homeFeed, lastLat: $lastLat, lastLng: $lastLng)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 HomeFeedEntity? homeFeed, double? lastLat, double? lastLng
});


$HomeFeedEntityCopyWith<$Res>? get homeFeed;

}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? homeFeed = freezed,Object? lastLat = freezed,Object? lastLng = freezed,}) {
  return _then(_self.copyWith(
homeFeed: freezed == homeFeed ? _self.homeFeed : homeFeed // ignore: cast_nullable_to_non_nullable
as HomeFeedEntity?,lastLat: freezed == lastLat ? _self.lastLat : lastLat // ignore: cast_nullable_to_non_nullable
as double?,lastLng: freezed == lastLng ? _self.lastLng : lastLng // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeFeedEntityCopyWith<$Res>? get homeFeed {
    if (_self.homeFeed == null) {
    return null;
  }

  return $HomeFeedEntityCopyWith<$Res>(_self.homeFeed!, (value) {
    return _then(_self.copyWith(homeFeed: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( HomeFeedEntity? homeFeed,  double? lastLat,  double? lastLng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.homeFeed,_that.lastLat,_that.lastLng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( HomeFeedEntity? homeFeed,  double? lastLat,  double? lastLng)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.homeFeed,_that.lastLat,_that.lastLng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( HomeFeedEntity? homeFeed,  double? lastLat,  double? lastLng)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.homeFeed,_that.lastLat,_that.lastLng);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState extends HomeState {
  const _HomeState({this.homeFeed, this.lastLat, this.lastLng}): super._();
  

@override final  HomeFeedEntity? homeFeed;
@override final  double? lastLat;
@override final  double? lastLng;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&(identical(other.homeFeed, homeFeed) || other.homeFeed == homeFeed)&&(identical(other.lastLat, lastLat) || other.lastLat == lastLat)&&(identical(other.lastLng, lastLng) || other.lastLng == lastLng));
}


@override
int get hashCode => Object.hash(runtimeType,homeFeed,lastLat,lastLng);

@override
String toString() {
  return 'HomeState(homeFeed: $homeFeed, lastLat: $lastLat, lastLng: $lastLng)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 HomeFeedEntity? homeFeed, double? lastLat, double? lastLng
});


@override $HomeFeedEntityCopyWith<$Res>? get homeFeed;

}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? homeFeed = freezed,Object? lastLat = freezed,Object? lastLng = freezed,}) {
  return _then(_HomeState(
homeFeed: freezed == homeFeed ? _self.homeFeed : homeFeed // ignore: cast_nullable_to_non_nullable
as HomeFeedEntity?,lastLat: freezed == lastLat ? _self.lastLat : lastLat // ignore: cast_nullable_to_non_nullable
as double?,lastLng: freezed == lastLng ? _self.lastLng : lastLng // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeFeedEntityCopyWith<$Res>? get homeFeed {
    if (_self.homeFeed == null) {
    return null;
  }

  return $HomeFeedEntityCopyWith<$Res>(_self.homeFeed!, (value) {
    return _then(_self.copyWith(homeFeed: value));
  });
}
}

// dart format on

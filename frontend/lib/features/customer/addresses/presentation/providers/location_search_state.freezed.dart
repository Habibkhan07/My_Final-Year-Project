// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'location_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LocationSearchState {

 String get query; List<PlaceSearchEntity> get results; bool get isLoading; String? get errorMessage; String get sessionToken;
/// Create a copy of LocationSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LocationSearchStateCopyWith<LocationSearchState> get copyWith => _$LocationSearchStateCopyWithImpl<LocationSearchState>(this as LocationSearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LocationSearchState&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.sessionToken, sessionToken) || other.sessionToken == sessionToken));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(results),isLoading,errorMessage,sessionToken);

@override
String toString() {
  return 'LocationSearchState(query: $query, results: $results, isLoading: $isLoading, errorMessage: $errorMessage, sessionToken: $sessionToken)';
}


}

/// @nodoc
abstract mixin class $LocationSearchStateCopyWith<$Res>  {
  factory $LocationSearchStateCopyWith(LocationSearchState value, $Res Function(LocationSearchState) _then) = _$LocationSearchStateCopyWithImpl;
@useResult
$Res call({
 String query, List<PlaceSearchEntity> results, bool isLoading, String? errorMessage, String sessionToken
});




}
/// @nodoc
class _$LocationSearchStateCopyWithImpl<$Res>
    implements $LocationSearchStateCopyWith<$Res> {
  _$LocationSearchStateCopyWithImpl(this._self, this._then);

  final LocationSearchState _self;
  final $Res Function(LocationSearchState) _then;

/// Create a copy of LocationSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? results = null,Object? isLoading = null,Object? errorMessage = freezed,Object? sessionToken = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<PlaceSearchEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LocationSearchState].
extension LocationSearchStatePatterns on LocationSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LocationSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LocationSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LocationSearchState value)  $default,){
final _that = this;
switch (_that) {
case _LocationSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LocationSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _LocationSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  List<PlaceSearchEntity> results,  bool isLoading,  String? errorMessage,  String sessionToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LocationSearchState() when $default != null:
return $default(_that.query,_that.results,_that.isLoading,_that.errorMessage,_that.sessionToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  List<PlaceSearchEntity> results,  bool isLoading,  String? errorMessage,  String sessionToken)  $default,) {final _that = this;
switch (_that) {
case _LocationSearchState():
return $default(_that.query,_that.results,_that.isLoading,_that.errorMessage,_that.sessionToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  List<PlaceSearchEntity> results,  bool isLoading,  String? errorMessage,  String sessionToken)?  $default,) {final _that = this;
switch (_that) {
case _LocationSearchState() when $default != null:
return $default(_that.query,_that.results,_that.isLoading,_that.errorMessage,_that.sessionToken);case _:
  return null;

}
}

}

/// @nodoc


class _LocationSearchState implements LocationSearchState {
  const _LocationSearchState({this.query = '', final  List<PlaceSearchEntity> results = const [], this.isLoading = false, this.errorMessage, required this.sessionToken}): _results = results;
  

@override@JsonKey() final  String query;
 final  List<PlaceSearchEntity> _results;
@override@JsonKey() List<PlaceSearchEntity> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override@JsonKey() final  bool isLoading;
@override final  String? errorMessage;
@override final  String sessionToken;

/// Create a copy of LocationSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LocationSearchStateCopyWith<_LocationSearchState> get copyWith => __$LocationSearchStateCopyWithImpl<_LocationSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LocationSearchState&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.sessionToken, sessionToken) || other.sessionToken == sessionToken));
}


@override
int get hashCode => Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_results),isLoading,errorMessage,sessionToken);

@override
String toString() {
  return 'LocationSearchState(query: $query, results: $results, isLoading: $isLoading, errorMessage: $errorMessage, sessionToken: $sessionToken)';
}


}

/// @nodoc
abstract mixin class _$LocationSearchStateCopyWith<$Res> implements $LocationSearchStateCopyWith<$Res> {
  factory _$LocationSearchStateCopyWith(_LocationSearchState value, $Res Function(_LocationSearchState) _then) = __$LocationSearchStateCopyWithImpl;
@override @useResult
$Res call({
 String query, List<PlaceSearchEntity> results, bool isLoading, String? errorMessage, String sessionToken
});




}
/// @nodoc
class __$LocationSearchStateCopyWithImpl<$Res>
    implements _$LocationSearchStateCopyWith<$Res> {
  __$LocationSearchStateCopyWithImpl(this._self, this._then);

  final _LocationSearchState _self;
  final $Res Function(_LocationSearchState) _then;

/// Create a copy of LocationSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? results = null,Object? isLoading = null,Object? errorMessage = freezed,Object? sessionToken = null,}) {
  return _then(_LocationSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<PlaceSearchEntity>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,sessionToken: null == sessionToken ? _self.sessionToken : sessionToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

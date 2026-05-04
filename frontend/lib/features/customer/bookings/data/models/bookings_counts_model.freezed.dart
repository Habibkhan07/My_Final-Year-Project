// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookings_counts_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingsCountsModel {

 int get upcoming; int get past;@JsonKey(name: 'server_time') String get serverTime;
/// Create a copy of BookingsCountsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingsCountsModelCopyWith<BookingsCountsModel> get copyWith => _$BookingsCountsModelCopyWithImpl<BookingsCountsModel>(this as BookingsCountsModel, _$identity);

  /// Serializes this BookingsCountsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingsCountsModel&&(identical(other.upcoming, upcoming) || other.upcoming == upcoming)&&(identical(other.past, past) || other.past == past)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upcoming,past,serverTime);

@override
String toString() {
  return 'BookingsCountsModel(upcoming: $upcoming, past: $past, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class $BookingsCountsModelCopyWith<$Res>  {
  factory $BookingsCountsModelCopyWith(BookingsCountsModel value, $Res Function(BookingsCountsModel) _then) = _$BookingsCountsModelCopyWithImpl;
@useResult
$Res call({
 int upcoming, int past,@JsonKey(name: 'server_time') String serverTime
});




}
/// @nodoc
class _$BookingsCountsModelCopyWithImpl<$Res>
    implements $BookingsCountsModelCopyWith<$Res> {
  _$BookingsCountsModelCopyWithImpl(this._self, this._then);

  final BookingsCountsModel _self;
  final $Res Function(BookingsCountsModel) _then;

/// Create a copy of BookingsCountsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? upcoming = null,Object? past = null,Object? serverTime = null,}) {
  return _then(_self.copyWith(
upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingsCountsModel].
extension BookingsCountsModelPatterns on BookingsCountsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingsCountsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingsCountsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingsCountsModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingsCountsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingsCountsModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingsCountsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int upcoming,  int past, @JsonKey(name: 'server_time')  String serverTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingsCountsModel() when $default != null:
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int upcoming,  int past, @JsonKey(name: 'server_time')  String serverTime)  $default,) {final _that = this;
switch (_that) {
case _BookingsCountsModel():
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int upcoming,  int past, @JsonKey(name: 'server_time')  String serverTime)?  $default,) {final _that = this;
switch (_that) {
case _BookingsCountsModel() when $default != null:
return $default(_that.upcoming,_that.past,_that.serverTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingsCountsModel implements BookingsCountsModel {
  const _BookingsCountsModel({required this.upcoming, required this.past, @JsonKey(name: 'server_time') required this.serverTime});
  factory _BookingsCountsModel.fromJson(Map<String, dynamic> json) => _$BookingsCountsModelFromJson(json);

@override final  int upcoming;
@override final  int past;
@override@JsonKey(name: 'server_time') final  String serverTime;

/// Create a copy of BookingsCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingsCountsModelCopyWith<_BookingsCountsModel> get copyWith => __$BookingsCountsModelCopyWithImpl<_BookingsCountsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingsCountsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingsCountsModel&&(identical(other.upcoming, upcoming) || other.upcoming == upcoming)&&(identical(other.past, past) || other.past == past)&&(identical(other.serverTime, serverTime) || other.serverTime == serverTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upcoming,past,serverTime);

@override
String toString() {
  return 'BookingsCountsModel(upcoming: $upcoming, past: $past, serverTime: $serverTime)';
}


}

/// @nodoc
abstract mixin class _$BookingsCountsModelCopyWith<$Res> implements $BookingsCountsModelCopyWith<$Res> {
  factory _$BookingsCountsModelCopyWith(_BookingsCountsModel value, $Res Function(_BookingsCountsModel) _then) = __$BookingsCountsModelCopyWithImpl;
@override @useResult
$Res call({
 int upcoming, int past,@JsonKey(name: 'server_time') String serverTime
});




}
/// @nodoc
class __$BookingsCountsModelCopyWithImpl<$Res>
    implements _$BookingsCountsModelCopyWith<$Res> {
  __$BookingsCountsModelCopyWithImpl(this._self, this._then);

  final _BookingsCountsModel _self;
  final $Res Function(_BookingsCountsModel) _then;

/// Create a copy of BookingsCountsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? upcoming = null,Object? past = null,Object? serverTime = null,}) {
  return _then(_BookingsCountsModel(
upcoming: null == upcoming ? _self.upcoming : upcoming // ignore: cast_nullable_to_non_nullable
as int,past: null == past ? _self.past : past // ignore: cast_nullable_to_non_nullable
as int,serverTime: null == serverTime ? _self.serverTime : serverTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_search_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceSearchEntity {

 String get placeId; String get description; String get mainText; String get secondaryText;
/// Create a copy of PlaceSearchEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceSearchEntityCopyWith<PlaceSearchEntity> get copyWith => _$PlaceSearchEntityCopyWithImpl<PlaceSearchEntity>(this as PlaceSearchEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceSearchEntity&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.description, description) || other.description == description)&&(identical(other.mainText, mainText) || other.mainText == mainText)&&(identical(other.secondaryText, secondaryText) || other.secondaryText == secondaryText));
}


@override
int get hashCode => Object.hash(runtimeType,placeId,description,mainText,secondaryText);

@override
String toString() {
  return 'PlaceSearchEntity(placeId: $placeId, description: $description, mainText: $mainText, secondaryText: $secondaryText)';
}


}

/// @nodoc
abstract mixin class $PlaceSearchEntityCopyWith<$Res>  {
  factory $PlaceSearchEntityCopyWith(PlaceSearchEntity value, $Res Function(PlaceSearchEntity) _then) = _$PlaceSearchEntityCopyWithImpl;
@useResult
$Res call({
 String placeId, String description, String mainText, String secondaryText
});




}
/// @nodoc
class _$PlaceSearchEntityCopyWithImpl<$Res>
    implements $PlaceSearchEntityCopyWith<$Res> {
  _$PlaceSearchEntityCopyWithImpl(this._self, this._then);

  final PlaceSearchEntity _self;
  final $Res Function(PlaceSearchEntity) _then;

/// Create a copy of PlaceSearchEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? placeId = null,Object? description = null,Object? mainText = null,Object? secondaryText = null,}) {
  return _then(_self.copyWith(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mainText: null == mainText ? _self.mainText : mainText // ignore: cast_nullable_to_non_nullable
as String,secondaryText: null == secondaryText ? _self.secondaryText : secondaryText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaceSearchEntity].
extension PlaceSearchEntityPatterns on PlaceSearchEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceSearchEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceSearchEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceSearchEntity value)  $default,){
final _that = this;
switch (_that) {
case _PlaceSearchEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceSearchEntity value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceSearchEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String placeId,  String description,  String mainText,  String secondaryText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceSearchEntity() when $default != null:
return $default(_that.placeId,_that.description,_that.mainText,_that.secondaryText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String placeId,  String description,  String mainText,  String secondaryText)  $default,) {final _that = this;
switch (_that) {
case _PlaceSearchEntity():
return $default(_that.placeId,_that.description,_that.mainText,_that.secondaryText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String placeId,  String description,  String mainText,  String secondaryText)?  $default,) {final _that = this;
switch (_that) {
case _PlaceSearchEntity() when $default != null:
return $default(_that.placeId,_that.description,_that.mainText,_that.secondaryText);case _:
  return null;

}
}

}

/// @nodoc


class _PlaceSearchEntity implements PlaceSearchEntity {
  const _PlaceSearchEntity({required this.placeId, required this.description, required this.mainText, required this.secondaryText});
  

@override final  String placeId;
@override final  String description;
@override final  String mainText;
@override final  String secondaryText;

/// Create a copy of PlaceSearchEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceSearchEntityCopyWith<_PlaceSearchEntity> get copyWith => __$PlaceSearchEntityCopyWithImpl<_PlaceSearchEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceSearchEntity&&(identical(other.placeId, placeId) || other.placeId == placeId)&&(identical(other.description, description) || other.description == description)&&(identical(other.mainText, mainText) || other.mainText == mainText)&&(identical(other.secondaryText, secondaryText) || other.secondaryText == secondaryText));
}


@override
int get hashCode => Object.hash(runtimeType,placeId,description,mainText,secondaryText);

@override
String toString() {
  return 'PlaceSearchEntity(placeId: $placeId, description: $description, mainText: $mainText, secondaryText: $secondaryText)';
}


}

/// @nodoc
abstract mixin class _$PlaceSearchEntityCopyWith<$Res> implements $PlaceSearchEntityCopyWith<$Res> {
  factory _$PlaceSearchEntityCopyWith(_PlaceSearchEntity value, $Res Function(_PlaceSearchEntity) _then) = __$PlaceSearchEntityCopyWithImpl;
@override @useResult
$Res call({
 String placeId, String description, String mainText, String secondaryText
});




}
/// @nodoc
class __$PlaceSearchEntityCopyWithImpl<$Res>
    implements _$PlaceSearchEntityCopyWith<$Res> {
  __$PlaceSearchEntityCopyWithImpl(this._self, this._then);

  final _PlaceSearchEntity _self;
  final $Res Function(_PlaceSearchEntity) _then;

/// Create a copy of PlaceSearchEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? placeId = null,Object? description = null,Object? mainText = null,Object? secondaryText = null,}) {
  return _then(_PlaceSearchEntity(
placeId: null == placeId ? _self.placeId : placeId // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,mainText: null == mainText ? _self.mainText : mainText // ignore: cast_nullable_to_non_nullable
as String,secondaryText: null == secondaryText ? _self.secondaryText : secondaryText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

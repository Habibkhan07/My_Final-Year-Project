// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_location_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkLocationEntity {

 bool get isSet; int get maxTravelRadiusKm; double? get latitude; double? get longitude; String? get workAddressLabel;
/// Create a copy of WorkLocationEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkLocationEntityCopyWith<WorkLocationEntity> get copyWith => _$WorkLocationEntityCopyWithImpl<WorkLocationEntity>(this as WorkLocationEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkLocationEntity&&(identical(other.isSet, isSet) || other.isSet == isSet)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.workAddressLabel, workAddressLabel) || other.workAddressLabel == workAddressLabel));
}


@override
int get hashCode => Object.hash(runtimeType,isSet,maxTravelRadiusKm,latitude,longitude,workAddressLabel);

@override
String toString() {
  return 'WorkLocationEntity(isSet: $isSet, maxTravelRadiusKm: $maxTravelRadiusKm, latitude: $latitude, longitude: $longitude, workAddressLabel: $workAddressLabel)';
}


}

/// @nodoc
abstract mixin class $WorkLocationEntityCopyWith<$Res>  {
  factory $WorkLocationEntityCopyWith(WorkLocationEntity value, $Res Function(WorkLocationEntity) _then) = _$WorkLocationEntityCopyWithImpl;
@useResult
$Res call({
 bool isSet, int maxTravelRadiusKm, double? latitude, double? longitude, String? workAddressLabel
});




}
/// @nodoc
class _$WorkLocationEntityCopyWithImpl<$Res>
    implements $WorkLocationEntityCopyWith<$Res> {
  _$WorkLocationEntityCopyWithImpl(this._self, this._then);

  final WorkLocationEntity _self;
  final $Res Function(WorkLocationEntity) _then;

/// Create a copy of WorkLocationEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSet = null,Object? maxTravelRadiusKm = null,Object? latitude = freezed,Object? longitude = freezed,Object? workAddressLabel = freezed,}) {
  return _then(_self.copyWith(
isSet: null == isSet ? _self.isSet : isSet // ignore: cast_nullable_to_non_nullable
as bool,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,workAddressLabel: freezed == workAddressLabel ? _self.workAddressLabel : workAddressLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkLocationEntity].
extension WorkLocationEntityPatterns on WorkLocationEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkLocationEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkLocationEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkLocationEntity value)  $default,){
final _that = this;
switch (_that) {
case _WorkLocationEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkLocationEntity value)?  $default,){
final _that = this;
switch (_that) {
case _WorkLocationEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSet,  int maxTravelRadiusKm,  double? latitude,  double? longitude,  String? workAddressLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkLocationEntity() when $default != null:
return $default(_that.isSet,_that.maxTravelRadiusKm,_that.latitude,_that.longitude,_that.workAddressLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSet,  int maxTravelRadiusKm,  double? latitude,  double? longitude,  String? workAddressLabel)  $default,) {final _that = this;
switch (_that) {
case _WorkLocationEntity():
return $default(_that.isSet,_that.maxTravelRadiusKm,_that.latitude,_that.longitude,_that.workAddressLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSet,  int maxTravelRadiusKm,  double? latitude,  double? longitude,  String? workAddressLabel)?  $default,) {final _that = this;
switch (_that) {
case _WorkLocationEntity() when $default != null:
return $default(_that.isSet,_that.maxTravelRadiusKm,_that.latitude,_that.longitude,_that.workAddressLabel);case _:
  return null;

}
}

}

/// @nodoc


class _WorkLocationEntity implements WorkLocationEntity {
  const _WorkLocationEntity({required this.isSet, required this.maxTravelRadiusKm, this.latitude, this.longitude, this.workAddressLabel});
  

@override final  bool isSet;
@override final  int maxTravelRadiusKm;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? workAddressLabel;

/// Create a copy of WorkLocationEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkLocationEntityCopyWith<_WorkLocationEntity> get copyWith => __$WorkLocationEntityCopyWithImpl<_WorkLocationEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkLocationEntity&&(identical(other.isSet, isSet) || other.isSet == isSet)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.workAddressLabel, workAddressLabel) || other.workAddressLabel == workAddressLabel));
}


@override
int get hashCode => Object.hash(runtimeType,isSet,maxTravelRadiusKm,latitude,longitude,workAddressLabel);

@override
String toString() {
  return 'WorkLocationEntity(isSet: $isSet, maxTravelRadiusKm: $maxTravelRadiusKm, latitude: $latitude, longitude: $longitude, workAddressLabel: $workAddressLabel)';
}


}

/// @nodoc
abstract mixin class _$WorkLocationEntityCopyWith<$Res> implements $WorkLocationEntityCopyWith<$Res> {
  factory _$WorkLocationEntityCopyWith(_WorkLocationEntity value, $Res Function(_WorkLocationEntity) _then) = __$WorkLocationEntityCopyWithImpl;
@override @useResult
$Res call({
 bool isSet, int maxTravelRadiusKm, double? latitude, double? longitude, String? workAddressLabel
});




}
/// @nodoc
class __$WorkLocationEntityCopyWithImpl<$Res>
    implements _$WorkLocationEntityCopyWith<$Res> {
  __$WorkLocationEntityCopyWithImpl(this._self, this._then);

  final _WorkLocationEntity _self;
  final $Res Function(_WorkLocationEntity) _then;

/// Create a copy of WorkLocationEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSet = null,Object? maxTravelRadiusKm = null,Object? latitude = freezed,Object? longitude = freezed,Object? workAddressLabel = freezed,}) {
  return _then(_WorkLocationEntity(
isSet: null == isSet ? _self.isSet : isSet // ignore: cast_nullable_to_non_nullable
as bool,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,workAddressLabel: freezed == workAddressLabel ? _self.workAddressLabel : workAddressLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

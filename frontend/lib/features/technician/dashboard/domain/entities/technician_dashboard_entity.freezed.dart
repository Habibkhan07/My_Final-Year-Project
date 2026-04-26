// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_dashboard_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpNextJobEntity {

 int get jobId; String get serviceTitle; DateTime get scheduledTime; String get customerName; String get addressText; double get lat; double get lng;
/// Create a copy of UpNextJobEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpNextJobEntityCopyWith<UpNextJobEntity> get copyWith => _$UpNextJobEntityCopyWithImpl<UpNextJobEntity>(this as UpNextJobEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpNextJobEntity&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceTitle, serviceTitle) || other.serviceTitle == serviceTitle)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceTitle,scheduledTime,customerName,addressText,lat,lng);

@override
String toString() {
  return 'UpNextJobEntity(jobId: $jobId, serviceTitle: $serviceTitle, scheduledTime: $scheduledTime, customerName: $customerName, addressText: $addressText, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class $UpNextJobEntityCopyWith<$Res>  {
  factory $UpNextJobEntityCopyWith(UpNextJobEntity value, $Res Function(UpNextJobEntity) _then) = _$UpNextJobEntityCopyWithImpl;
@useResult
$Res call({
 int jobId, String serviceTitle, DateTime scheduledTime, String customerName, String addressText, double lat, double lng
});




}
/// @nodoc
class _$UpNextJobEntityCopyWithImpl<$Res>
    implements $UpNextJobEntityCopyWith<$Res> {
  _$UpNextJobEntityCopyWithImpl(this._self, this._then);

  final UpNextJobEntity _self;
  final $Res Function(UpNextJobEntity) _then;

/// Create a copy of UpNextJobEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? serviceTitle = null,Object? scheduledTime = null,Object? customerName = null,Object? addressText = null,Object? lat = null,Object? lng = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceTitle: null == serviceTitle ? _self.serviceTitle : serviceTitle // ignore: cast_nullable_to_non_nullable
as String,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [UpNextJobEntity].
extension UpNextJobEntityPatterns on UpNextJobEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpNextJobEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpNextJobEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpNextJobEntity value)  $default,){
final _that = this;
switch (_that) {
case _UpNextJobEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpNextJobEntity value)?  $default,){
final _that = this;
switch (_that) {
case _UpNextJobEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String customerName,  String addressText,  double lat,  double lng)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpNextJobEntity() when $default != null:
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.customerName,_that.addressText,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String customerName,  String addressText,  double lat,  double lng)  $default,) {final _that = this;
switch (_that) {
case _UpNextJobEntity():
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.customerName,_that.addressText,_that.lat,_that.lng);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String customerName,  String addressText,  double lat,  double lng)?  $default,) {final _that = this;
switch (_that) {
case _UpNextJobEntity() when $default != null:
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.customerName,_that.addressText,_that.lat,_that.lng);case _:
  return null;

}
}

}

/// @nodoc


class _UpNextJobEntity implements UpNextJobEntity {
  const _UpNextJobEntity({required this.jobId, required this.serviceTitle, required this.scheduledTime, required this.customerName, required this.addressText, required this.lat, required this.lng});
  

@override final  int jobId;
@override final  String serviceTitle;
@override final  DateTime scheduledTime;
@override final  String customerName;
@override final  String addressText;
@override final  double lat;
@override final  double lng;

/// Create a copy of UpNextJobEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpNextJobEntityCopyWith<_UpNextJobEntity> get copyWith => __$UpNextJobEntityCopyWithImpl<_UpNextJobEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpNextJobEntity&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceTitle, serviceTitle) || other.serviceTitle == serviceTitle)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.addressText, addressText) || other.addressText == addressText)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceTitle,scheduledTime,customerName,addressText,lat,lng);

@override
String toString() {
  return 'UpNextJobEntity(jobId: $jobId, serviceTitle: $serviceTitle, scheduledTime: $scheduledTime, customerName: $customerName, addressText: $addressText, lat: $lat, lng: $lng)';
}


}

/// @nodoc
abstract mixin class _$UpNextJobEntityCopyWith<$Res> implements $UpNextJobEntityCopyWith<$Res> {
  factory _$UpNextJobEntityCopyWith(_UpNextJobEntity value, $Res Function(_UpNextJobEntity) _then) = __$UpNextJobEntityCopyWithImpl;
@override @useResult
$Res call({
 int jobId, String serviceTitle, DateTime scheduledTime, String customerName, String addressText, double lat, double lng
});




}
/// @nodoc
class __$UpNextJobEntityCopyWithImpl<$Res>
    implements _$UpNextJobEntityCopyWith<$Res> {
  __$UpNextJobEntityCopyWithImpl(this._self, this._then);

  final _UpNextJobEntity _self;
  final $Res Function(_UpNextJobEntity) _then;

/// Create a copy of UpNextJobEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? serviceTitle = null,Object? scheduledTime = null,Object? customerName = null,Object? addressText = null,Object? lat = null,Object? lng = null,}) {
  return _then(_UpNextJobEntity(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceTitle: null == serviceTitle ? _self.serviceTitle : serviceTitle // ignore: cast_nullable_to_non_nullable
as String,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,customerName: null == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$LaterTodayJobEntity {

 int get jobId; String get serviceTitle; DateTime get scheduledTime; String get addressText;
/// Create a copy of LaterTodayJobEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LaterTodayJobEntityCopyWith<LaterTodayJobEntity> get copyWith => _$LaterTodayJobEntityCopyWithImpl<LaterTodayJobEntity>(this as LaterTodayJobEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LaterTodayJobEntity&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceTitle, serviceTitle) || other.serviceTitle == serviceTitle)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceTitle,scheduledTime,addressText);

@override
String toString() {
  return 'LaterTodayJobEntity(jobId: $jobId, serviceTitle: $serviceTitle, scheduledTime: $scheduledTime, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class $LaterTodayJobEntityCopyWith<$Res>  {
  factory $LaterTodayJobEntityCopyWith(LaterTodayJobEntity value, $Res Function(LaterTodayJobEntity) _then) = _$LaterTodayJobEntityCopyWithImpl;
@useResult
$Res call({
 int jobId, String serviceTitle, DateTime scheduledTime, String addressText
});




}
/// @nodoc
class _$LaterTodayJobEntityCopyWithImpl<$Res>
    implements $LaterTodayJobEntityCopyWith<$Res> {
  _$LaterTodayJobEntityCopyWithImpl(this._self, this._then);

  final LaterTodayJobEntity _self;
  final $Res Function(LaterTodayJobEntity) _then;

/// Create a copy of LaterTodayJobEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? serviceTitle = null,Object? scheduledTime = null,Object? addressText = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceTitle: null == serviceTitle ? _self.serviceTitle : serviceTitle // ignore: cast_nullable_to_non_nullable
as String,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LaterTodayJobEntity].
extension LaterTodayJobEntityPatterns on LaterTodayJobEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LaterTodayJobEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LaterTodayJobEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LaterTodayJobEntity value)  $default,){
final _that = this;
switch (_that) {
case _LaterTodayJobEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LaterTodayJobEntity value)?  $default,){
final _that = this;
switch (_that) {
case _LaterTodayJobEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String addressText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LaterTodayJobEntity() when $default != null:
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.addressText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String addressText)  $default,) {final _that = this;
switch (_that) {
case _LaterTodayJobEntity():
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.addressText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jobId,  String serviceTitle,  DateTime scheduledTime,  String addressText)?  $default,) {final _that = this;
switch (_that) {
case _LaterTodayJobEntity() when $default != null:
return $default(_that.jobId,_that.serviceTitle,_that.scheduledTime,_that.addressText);case _:
  return null;

}
}

}

/// @nodoc


class _LaterTodayJobEntity implements LaterTodayJobEntity {
  const _LaterTodayJobEntity({required this.jobId, required this.serviceTitle, required this.scheduledTime, required this.addressText});
  

@override final  int jobId;
@override final  String serviceTitle;
@override final  DateTime scheduledTime;
@override final  String addressText;

/// Create a copy of LaterTodayJobEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LaterTodayJobEntityCopyWith<_LaterTodayJobEntity> get copyWith => __$LaterTodayJobEntityCopyWithImpl<_LaterTodayJobEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LaterTodayJobEntity&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceTitle, serviceTitle) || other.serviceTitle == serviceTitle)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.addressText, addressText) || other.addressText == addressText));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceTitle,scheduledTime,addressText);

@override
String toString() {
  return 'LaterTodayJobEntity(jobId: $jobId, serviceTitle: $serviceTitle, scheduledTime: $scheduledTime, addressText: $addressText)';
}


}

/// @nodoc
abstract mixin class _$LaterTodayJobEntityCopyWith<$Res> implements $LaterTodayJobEntityCopyWith<$Res> {
  factory _$LaterTodayJobEntityCopyWith(_LaterTodayJobEntity value, $Res Function(_LaterTodayJobEntity) _then) = __$LaterTodayJobEntityCopyWithImpl;
@override @useResult
$Res call({
 int jobId, String serviceTitle, DateTime scheduledTime, String addressText
});




}
/// @nodoc
class __$LaterTodayJobEntityCopyWithImpl<$Res>
    implements _$LaterTodayJobEntityCopyWith<$Res> {
  __$LaterTodayJobEntityCopyWithImpl(this._self, this._then);

  final _LaterTodayJobEntity _self;
  final $Res Function(_LaterTodayJobEntity) _then;

/// Create a copy of LaterTodayJobEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? serviceTitle = null,Object? scheduledTime = null,Object? addressText = null,}) {
  return _then(_LaterTodayJobEntity(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceTitle: null == serviceTitle ? _self.serviceTitle : serviceTitle // ignore: cast_nullable_to_non_nullable
as String,scheduledTime: null == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as DateTime,addressText: null == addressText ? _self.addressText : addressText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DashboardMetricsEntity {

 int get jobsCompletedToday; double get cashCollectedToday;
/// Create a copy of DashboardMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardMetricsEntityCopyWith<DashboardMetricsEntity> get copyWith => _$DashboardMetricsEntityCopyWithImpl<DashboardMetricsEntity>(this as DashboardMetricsEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardMetricsEntity&&(identical(other.jobsCompletedToday, jobsCompletedToday) || other.jobsCompletedToday == jobsCompletedToday)&&(identical(other.cashCollectedToday, cashCollectedToday) || other.cashCollectedToday == cashCollectedToday));
}


@override
int get hashCode => Object.hash(runtimeType,jobsCompletedToday,cashCollectedToday);

@override
String toString() {
  return 'DashboardMetricsEntity(jobsCompletedToday: $jobsCompletedToday, cashCollectedToday: $cashCollectedToday)';
}


}

/// @nodoc
abstract mixin class $DashboardMetricsEntityCopyWith<$Res>  {
  factory $DashboardMetricsEntityCopyWith(DashboardMetricsEntity value, $Res Function(DashboardMetricsEntity) _then) = _$DashboardMetricsEntityCopyWithImpl;
@useResult
$Res call({
 int jobsCompletedToday, double cashCollectedToday
});




}
/// @nodoc
class _$DashboardMetricsEntityCopyWithImpl<$Res>
    implements $DashboardMetricsEntityCopyWith<$Res> {
  _$DashboardMetricsEntityCopyWithImpl(this._self, this._then);

  final DashboardMetricsEntity _self;
  final $Res Function(DashboardMetricsEntity) _then;

/// Create a copy of DashboardMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobsCompletedToday = null,Object? cashCollectedToday = null,}) {
  return _then(_self.copyWith(
jobsCompletedToday: null == jobsCompletedToday ? _self.jobsCompletedToday : jobsCompletedToday // ignore: cast_nullable_to_non_nullable
as int,cashCollectedToday: null == cashCollectedToday ? _self.cashCollectedToday : cashCollectedToday // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardMetricsEntity].
extension DashboardMetricsEntityPatterns on DashboardMetricsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardMetricsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardMetricsEntity value)  $default,){
final _that = this;
switch (_that) {
case _DashboardMetricsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardMetricsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jobsCompletedToday,  double cashCollectedToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardMetricsEntity() when $default != null:
return $default(_that.jobsCompletedToday,_that.cashCollectedToday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jobsCompletedToday,  double cashCollectedToday)  $default,) {final _that = this;
switch (_that) {
case _DashboardMetricsEntity():
return $default(_that.jobsCompletedToday,_that.cashCollectedToday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jobsCompletedToday,  double cashCollectedToday)?  $default,) {final _that = this;
switch (_that) {
case _DashboardMetricsEntity() when $default != null:
return $default(_that.jobsCompletedToday,_that.cashCollectedToday);case _:
  return null;

}
}

}

/// @nodoc


class _DashboardMetricsEntity implements DashboardMetricsEntity {
  const _DashboardMetricsEntity({required this.jobsCompletedToday, required this.cashCollectedToday});
  

@override final  int jobsCompletedToday;
@override final  double cashCollectedToday;

/// Create a copy of DashboardMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardMetricsEntityCopyWith<_DashboardMetricsEntity> get copyWith => __$DashboardMetricsEntityCopyWithImpl<_DashboardMetricsEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardMetricsEntity&&(identical(other.jobsCompletedToday, jobsCompletedToday) || other.jobsCompletedToday == jobsCompletedToday)&&(identical(other.cashCollectedToday, cashCollectedToday) || other.cashCollectedToday == cashCollectedToday));
}


@override
int get hashCode => Object.hash(runtimeType,jobsCompletedToday,cashCollectedToday);

@override
String toString() {
  return 'DashboardMetricsEntity(jobsCompletedToday: $jobsCompletedToday, cashCollectedToday: $cashCollectedToday)';
}


}

/// @nodoc
abstract mixin class _$DashboardMetricsEntityCopyWith<$Res> implements $DashboardMetricsEntityCopyWith<$Res> {
  factory _$DashboardMetricsEntityCopyWith(_DashboardMetricsEntity value, $Res Function(_DashboardMetricsEntity) _then) = __$DashboardMetricsEntityCopyWithImpl;
@override @useResult
$Res call({
 int jobsCompletedToday, double cashCollectedToday
});




}
/// @nodoc
class __$DashboardMetricsEntityCopyWithImpl<$Res>
    implements _$DashboardMetricsEntityCopyWith<$Res> {
  __$DashboardMetricsEntityCopyWithImpl(this._self, this._then);

  final _DashboardMetricsEntity _self;
  final $Res Function(_DashboardMetricsEntity) _then;

/// Create a copy of DashboardMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobsCompletedToday = null,Object? cashCollectedToday = null,}) {
  return _then(_DashboardMetricsEntity(
jobsCompletedToday: null == jobsCompletedToday ? _self.jobsCompletedToday : jobsCompletedToday // ignore: cast_nullable_to_non_nullable
as int,cashCollectedToday: null == cashCollectedToday ? _self.cashCollectedToday : cashCollectedToday // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TechnicianDashboardEntity {

 double get walletBalance; bool get isOnline; String? get profilePicture; UpNextJobEntity? get upNextJob; List<LaterTodayJobEntity> get laterTodayJobs; DashboardMetricsEntity get metrics;
/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianDashboardEntityCopyWith<TechnicianDashboardEntity> get copyWith => _$TechnicianDashboardEntityCopyWithImpl<TechnicianDashboardEntity>(this as TechnicianDashboardEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianDashboardEntity&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.upNextJob, upNextJob) || other.upNextJob == upNextJob)&&const DeepCollectionEquality().equals(other.laterTodayJobs, laterTodayJobs)&&(identical(other.metrics, metrics) || other.metrics == metrics));
}


@override
int get hashCode => Object.hash(runtimeType,walletBalance,isOnline,profilePicture,upNextJob,const DeepCollectionEquality().hash(laterTodayJobs),metrics);

@override
String toString() {
  return 'TechnicianDashboardEntity(walletBalance: $walletBalance, isOnline: $isOnline, profilePicture: $profilePicture, upNextJob: $upNextJob, laterTodayJobs: $laterTodayJobs, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class $TechnicianDashboardEntityCopyWith<$Res>  {
  factory $TechnicianDashboardEntityCopyWith(TechnicianDashboardEntity value, $Res Function(TechnicianDashboardEntity) _then) = _$TechnicianDashboardEntityCopyWithImpl;
@useResult
$Res call({
 double walletBalance, bool isOnline, String? profilePicture, UpNextJobEntity? upNextJob, List<LaterTodayJobEntity> laterTodayJobs, DashboardMetricsEntity metrics
});


$UpNextJobEntityCopyWith<$Res>? get upNextJob;$DashboardMetricsEntityCopyWith<$Res> get metrics;

}
/// @nodoc
class _$TechnicianDashboardEntityCopyWithImpl<$Res>
    implements $TechnicianDashboardEntityCopyWith<$Res> {
  _$TechnicianDashboardEntityCopyWithImpl(this._self, this._then);

  final TechnicianDashboardEntity _self;
  final $Res Function(TechnicianDashboardEntity) _then;

/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? walletBalance = null,Object? isOnline = null,Object? profilePicture = freezed,Object? upNextJob = freezed,Object? laterTodayJobs = null,Object? metrics = null,}) {
  return _then(_self.copyWith(
walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,upNextJob: freezed == upNextJob ? _self.upNextJob : upNextJob // ignore: cast_nullable_to_non_nullable
as UpNextJobEntity?,laterTodayJobs: null == laterTodayJobs ? _self.laterTodayJobs : laterTodayJobs // ignore: cast_nullable_to_non_nullable
as List<LaterTodayJobEntity>,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as DashboardMetricsEntity,
  ));
}
/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpNextJobEntityCopyWith<$Res>? get upNextJob {
    if (_self.upNextJob == null) {
    return null;
  }

  return $UpNextJobEntityCopyWith<$Res>(_self.upNextJob!, (value) {
    return _then(_self.copyWith(upNextJob: value));
  });
}/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardMetricsEntityCopyWith<$Res> get metrics {
  
  return $DashboardMetricsEntityCopyWith<$Res>(_self.metrics, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [TechnicianDashboardEntity].
extension TechnicianDashboardEntityPatterns on TechnicianDashboardEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianDashboardEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianDashboardEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianDashboardEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianDashboardEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianDashboardEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianDashboardEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double walletBalance,  bool isOnline,  String? profilePicture,  UpNextJobEntity? upNextJob,  List<LaterTodayJobEntity> laterTodayJobs,  DashboardMetricsEntity metrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianDashboardEntity() when $default != null:
return $default(_that.walletBalance,_that.isOnline,_that.profilePicture,_that.upNextJob,_that.laterTodayJobs,_that.metrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double walletBalance,  bool isOnline,  String? profilePicture,  UpNextJobEntity? upNextJob,  List<LaterTodayJobEntity> laterTodayJobs,  DashboardMetricsEntity metrics)  $default,) {final _that = this;
switch (_that) {
case _TechnicianDashboardEntity():
return $default(_that.walletBalance,_that.isOnline,_that.profilePicture,_that.upNextJob,_that.laterTodayJobs,_that.metrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double walletBalance,  bool isOnline,  String? profilePicture,  UpNextJobEntity? upNextJob,  List<LaterTodayJobEntity> laterTodayJobs,  DashboardMetricsEntity metrics)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianDashboardEntity() when $default != null:
return $default(_that.walletBalance,_that.isOnline,_that.profilePicture,_that.upNextJob,_that.laterTodayJobs,_that.metrics);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianDashboardEntity implements TechnicianDashboardEntity {
  const _TechnicianDashboardEntity({required this.walletBalance, required this.isOnline, this.profilePicture, this.upNextJob, required final  List<LaterTodayJobEntity> laterTodayJobs, required this.metrics}): _laterTodayJobs = laterTodayJobs;
  

@override final  double walletBalance;
@override final  bool isOnline;
@override final  String? profilePicture;
@override final  UpNextJobEntity? upNextJob;
 final  List<LaterTodayJobEntity> _laterTodayJobs;
@override List<LaterTodayJobEntity> get laterTodayJobs {
  if (_laterTodayJobs is EqualUnmodifiableListView) return _laterTodayJobs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_laterTodayJobs);
}

@override final  DashboardMetricsEntity metrics;

/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianDashboardEntityCopyWith<_TechnicianDashboardEntity> get copyWith => __$TechnicianDashboardEntityCopyWithImpl<_TechnicianDashboardEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianDashboardEntity&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.isOnline, isOnline) || other.isOnline == isOnline)&&(identical(other.profilePicture, profilePicture) || other.profilePicture == profilePicture)&&(identical(other.upNextJob, upNextJob) || other.upNextJob == upNextJob)&&const DeepCollectionEquality().equals(other._laterTodayJobs, _laterTodayJobs)&&(identical(other.metrics, metrics) || other.metrics == metrics));
}


@override
int get hashCode => Object.hash(runtimeType,walletBalance,isOnline,profilePicture,upNextJob,const DeepCollectionEquality().hash(_laterTodayJobs),metrics);

@override
String toString() {
  return 'TechnicianDashboardEntity(walletBalance: $walletBalance, isOnline: $isOnline, profilePicture: $profilePicture, upNextJob: $upNextJob, laterTodayJobs: $laterTodayJobs, metrics: $metrics)';
}


}

/// @nodoc
abstract mixin class _$TechnicianDashboardEntityCopyWith<$Res> implements $TechnicianDashboardEntityCopyWith<$Res> {
  factory _$TechnicianDashboardEntityCopyWith(_TechnicianDashboardEntity value, $Res Function(_TechnicianDashboardEntity) _then) = __$TechnicianDashboardEntityCopyWithImpl;
@override @useResult
$Res call({
 double walletBalance, bool isOnline, String? profilePicture, UpNextJobEntity? upNextJob, List<LaterTodayJobEntity> laterTodayJobs, DashboardMetricsEntity metrics
});


@override $UpNextJobEntityCopyWith<$Res>? get upNextJob;@override $DashboardMetricsEntityCopyWith<$Res> get metrics;

}
/// @nodoc
class __$TechnicianDashboardEntityCopyWithImpl<$Res>
    implements _$TechnicianDashboardEntityCopyWith<$Res> {
  __$TechnicianDashboardEntityCopyWithImpl(this._self, this._then);

  final _TechnicianDashboardEntity _self;
  final $Res Function(_TechnicianDashboardEntity) _then;

/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? walletBalance = null,Object? isOnline = null,Object? profilePicture = freezed,Object? upNextJob = freezed,Object? laterTodayJobs = null,Object? metrics = null,}) {
  return _then(_TechnicianDashboardEntity(
walletBalance: null == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as double,isOnline: null == isOnline ? _self.isOnline : isOnline // ignore: cast_nullable_to_non_nullable
as bool,profilePicture: freezed == profilePicture ? _self.profilePicture : profilePicture // ignore: cast_nullable_to_non_nullable
as String?,upNextJob: freezed == upNextJob ? _self.upNextJob : upNextJob // ignore: cast_nullable_to_non_nullable
as UpNextJobEntity?,laterTodayJobs: null == laterTodayJobs ? _self._laterTodayJobs : laterTodayJobs // ignore: cast_nullable_to_non_nullable
as List<LaterTodayJobEntity>,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as DashboardMetricsEntity,
  ));
}

/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UpNextJobEntityCopyWith<$Res>? get upNextJob {
    if (_self.upNextJob == null) {
    return null;
  }

  return $UpNextJobEntityCopyWith<$Res>(_self.upNextJob!, (value) {
    return _then(_self.copyWith(upNextJob: value));
  });
}/// Create a copy of TechnicianDashboardEntity
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DashboardMetricsEntityCopyWith<$Res> get metrics {
  
  return $DashboardMetricsEntityCopyWith<$Res>(_self.metrics, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}

// dart format on

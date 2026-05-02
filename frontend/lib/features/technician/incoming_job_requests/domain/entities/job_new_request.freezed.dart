// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_new_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JobNewRequest {

 int get jobId; String get serviceName; BookingType get bookingType; int get payoutRupees; String? get payoutContext; DateTime get scheduledStart; DateTime get expiresAt; Duration get slaWindow; String? get locationLabel;
/// Create a copy of JobNewRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobNewRequestCopyWith<JobNewRequest> get copyWith => _$JobNewRequestCopyWithImpl<JobNewRequest>(this as JobNewRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobNewRequest&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.bookingType, bookingType) || other.bookingType == bookingType)&&(identical(other.payoutRupees, payoutRupees) || other.payoutRupees == payoutRupees)&&(identical(other.payoutContext, payoutContext) || other.payoutContext == payoutContext)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.slaWindow, slaWindow) || other.slaWindow == slaWindow)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceName,bookingType,payoutRupees,payoutContext,scheduledStart,expiresAt,slaWindow,locationLabel);

@override
String toString() {
  return 'JobNewRequest(jobId: $jobId, serviceName: $serviceName, bookingType: $bookingType, payoutRupees: $payoutRupees, payoutContext: $payoutContext, scheduledStart: $scheduledStart, expiresAt: $expiresAt, slaWindow: $slaWindow, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class $JobNewRequestCopyWith<$Res>  {
  factory $JobNewRequestCopyWith(JobNewRequest value, $Res Function(JobNewRequest) _then) = _$JobNewRequestCopyWithImpl;
@useResult
$Res call({
 int jobId, String serviceName, BookingType bookingType, int payoutRupees, String? payoutContext, DateTime scheduledStart, DateTime expiresAt, Duration slaWindow, String? locationLabel
});




}
/// @nodoc
class _$JobNewRequestCopyWithImpl<$Res>
    implements $JobNewRequestCopyWith<$Res> {
  _$JobNewRequestCopyWithImpl(this._self, this._then);

  final JobNewRequest _self;
  final $Res Function(JobNewRequest) _then;

/// Create a copy of JobNewRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? serviceName = null,Object? bookingType = null,Object? payoutRupees = null,Object? payoutContext = freezed,Object? scheduledStart = null,Object? expiresAt = null,Object? slaWindow = null,Object? locationLabel = freezed,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,bookingType: null == bookingType ? _self.bookingType : bookingType // ignore: cast_nullable_to_non_nullable
as BookingType,payoutRupees: null == payoutRupees ? _self.payoutRupees : payoutRupees // ignore: cast_nullable_to_non_nullable
as int,payoutContext: freezed == payoutContext ? _self.payoutContext : payoutContext // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,slaWindow: null == slaWindow ? _self.slaWindow : slaWindow // ignore: cast_nullable_to_non_nullable
as Duration,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobNewRequest].
extension JobNewRequestPatterns on JobNewRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobNewRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobNewRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobNewRequest value)  $default,){
final _that = this;
switch (_that) {
case _JobNewRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobNewRequest value)?  $default,){
final _that = this;
switch (_that) {
case _JobNewRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jobId,  String serviceName,  BookingType bookingType,  int payoutRupees,  String? payoutContext,  DateTime scheduledStart,  DateTime expiresAt,  Duration slaWindow,  String? locationLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobNewRequest() when $default != null:
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.payoutRupees,_that.payoutContext,_that.scheduledStart,_that.expiresAt,_that.slaWindow,_that.locationLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jobId,  String serviceName,  BookingType bookingType,  int payoutRupees,  String? payoutContext,  DateTime scheduledStart,  DateTime expiresAt,  Duration slaWindow,  String? locationLabel)  $default,) {final _that = this;
switch (_that) {
case _JobNewRequest():
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.payoutRupees,_that.payoutContext,_that.scheduledStart,_that.expiresAt,_that.slaWindow,_that.locationLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jobId,  String serviceName,  BookingType bookingType,  int payoutRupees,  String? payoutContext,  DateTime scheduledStart,  DateTime expiresAt,  Duration slaWindow,  String? locationLabel)?  $default,) {final _that = this;
switch (_that) {
case _JobNewRequest() when $default != null:
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.payoutRupees,_that.payoutContext,_that.scheduledStart,_that.expiresAt,_that.slaWindow,_that.locationLabel);case _:
  return null;

}
}

}

/// @nodoc


class _JobNewRequest implements JobNewRequest {
  const _JobNewRequest({required this.jobId, required this.serviceName, required this.bookingType, required this.payoutRupees, required this.payoutContext, required this.scheduledStart, required this.expiresAt, required this.slaWindow, required this.locationLabel});
  

@override final  int jobId;
@override final  String serviceName;
@override final  BookingType bookingType;
@override final  int payoutRupees;
@override final  String? payoutContext;
@override final  DateTime scheduledStart;
@override final  DateTime expiresAt;
@override final  Duration slaWindow;
@override final  String? locationLabel;

/// Create a copy of JobNewRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobNewRequestCopyWith<_JobNewRequest> get copyWith => __$JobNewRequestCopyWithImpl<_JobNewRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobNewRequest&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.bookingType, bookingType) || other.bookingType == bookingType)&&(identical(other.payoutRupees, payoutRupees) || other.payoutRupees == payoutRupees)&&(identical(other.payoutContext, payoutContext) || other.payoutContext == payoutContext)&&(identical(other.scheduledStart, scheduledStart) || other.scheduledStart == scheduledStart)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.slaWindow, slaWindow) || other.slaWindow == slaWindow)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}


@override
int get hashCode => Object.hash(runtimeType,jobId,serviceName,bookingType,payoutRupees,payoutContext,scheduledStart,expiresAt,slaWindow,locationLabel);

@override
String toString() {
  return 'JobNewRequest(jobId: $jobId, serviceName: $serviceName, bookingType: $bookingType, payoutRupees: $payoutRupees, payoutContext: $payoutContext, scheduledStart: $scheduledStart, expiresAt: $expiresAt, slaWindow: $slaWindow, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class _$JobNewRequestCopyWith<$Res> implements $JobNewRequestCopyWith<$Res> {
  factory _$JobNewRequestCopyWith(_JobNewRequest value, $Res Function(_JobNewRequest) _then) = __$JobNewRequestCopyWithImpl;
@override @useResult
$Res call({
 int jobId, String serviceName, BookingType bookingType, int payoutRupees, String? payoutContext, DateTime scheduledStart, DateTime expiresAt, Duration slaWindow, String? locationLabel
});




}
/// @nodoc
class __$JobNewRequestCopyWithImpl<$Res>
    implements _$JobNewRequestCopyWith<$Res> {
  __$JobNewRequestCopyWithImpl(this._self, this._then);

  final _JobNewRequest _self;
  final $Res Function(_JobNewRequest) _then;

/// Create a copy of JobNewRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? serviceName = null,Object? bookingType = null,Object? payoutRupees = null,Object? payoutContext = freezed,Object? scheduledStart = null,Object? expiresAt = null,Object? slaWindow = null,Object? locationLabel = freezed,}) {
  return _then(_JobNewRequest(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,bookingType: null == bookingType ? _self.bookingType : bookingType // ignore: cast_nullable_to_non_nullable
as BookingType,payoutRupees: null == payoutRupees ? _self.payoutRupees : payoutRupees // ignore: cast_nullable_to_non_nullable
as int,payoutContext: freezed == payoutContext ? _self.payoutContext : payoutContext // ignore: cast_nullable_to_non_nullable
as String?,scheduledStart: null == scheduledStart ? _self.scheduledStart : scheduledStart // ignore: cast_nullable_to_non_nullable
as DateTime,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,slaWindow: null == slaWindow ? _self.slaWindow : slaWindow // ignore: cast_nullable_to_non_nullable
as Duration,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

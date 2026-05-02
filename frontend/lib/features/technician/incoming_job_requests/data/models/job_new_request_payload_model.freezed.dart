// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_new_request_payload_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobNewRequestPayloadModel {

@JsonKey(name: 'job_id') int get jobId;@JsonKey(name: 'service_name') String get serviceName;@JsonKey(name: 'booking_type') String? get bookingType;@JsonKey(name: 'scheduled_start_iso') String get scheduledStartIso;/// Backend deliberately wires `payout` as an integer-string (e.g. `"1200"`)
/// to avoid client-side float drift. The domain entity holds `int`; parsing
/// happens in the mapper.
 String get payout;@JsonKey(name: 'payout_context') String? get payoutContext;@JsonKey(name: 'expires_in_seconds') int get expiresInSeconds;/// Pre-composed locality string (e.g. `"Gulberg, Lahore"`) sourced
/// server-side from `JobBooking.address.locality_label`. Null on two
/// paths: (a) the booking's address FK is SET_NULL, (b) the address
/// pre-dates the locality columns and has not been backfilled. The
/// technician's card hides the row entirely when null — never shows
/// a placeholder. Full street address is never broadcast pre-accept.
@JsonKey(name: 'ui_location_label') String? get locationLabel;
/// Create a copy of JobNewRequestPayloadModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobNewRequestPayloadModelCopyWith<JobNewRequestPayloadModel> get copyWith => _$JobNewRequestPayloadModelCopyWithImpl<JobNewRequestPayloadModel>(this as JobNewRequestPayloadModel, _$identity);

  /// Serializes this JobNewRequestPayloadModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobNewRequestPayloadModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.bookingType, bookingType) || other.bookingType == bookingType)&&(identical(other.scheduledStartIso, scheduledStartIso) || other.scheduledStartIso == scheduledStartIso)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.payoutContext, payoutContext) || other.payoutContext == payoutContext)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,serviceName,bookingType,scheduledStartIso,payout,payoutContext,expiresInSeconds,locationLabel);

@override
String toString() {
  return 'JobNewRequestPayloadModel(jobId: $jobId, serviceName: $serviceName, bookingType: $bookingType, scheduledStartIso: $scheduledStartIso, payout: $payout, payoutContext: $payoutContext, expiresInSeconds: $expiresInSeconds, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class $JobNewRequestPayloadModelCopyWith<$Res>  {
  factory $JobNewRequestPayloadModelCopyWith(JobNewRequestPayloadModel value, $Res Function(JobNewRequestPayloadModel) _then) = _$JobNewRequestPayloadModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'service_name') String serviceName,@JsonKey(name: 'booking_type') String? bookingType,@JsonKey(name: 'scheduled_start_iso') String scheduledStartIso, String payout,@JsonKey(name: 'payout_context') String? payoutContext,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'ui_location_label') String? locationLabel
});




}
/// @nodoc
class _$JobNewRequestPayloadModelCopyWithImpl<$Res>
    implements $JobNewRequestPayloadModelCopyWith<$Res> {
  _$JobNewRequestPayloadModelCopyWithImpl(this._self, this._then);

  final JobNewRequestPayloadModel _self;
  final $Res Function(JobNewRequestPayloadModel) _then;

/// Create a copy of JobNewRequestPayloadModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? serviceName = null,Object? bookingType = freezed,Object? scheduledStartIso = null,Object? payout = null,Object? payoutContext = freezed,Object? expiresInSeconds = null,Object? locationLabel = freezed,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,bookingType: freezed == bookingType ? _self.bookingType : bookingType // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartIso: null == scheduledStartIso ? _self.scheduledStartIso : scheduledStartIso // ignore: cast_nullable_to_non_nullable
as String,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as String,payoutContext: freezed == payoutContext ? _self.payoutContext : payoutContext // ignore: cast_nullable_to_non_nullable
as String?,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [JobNewRequestPayloadModel].
extension JobNewRequestPayloadModelPatterns on JobNewRequestPayloadModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobNewRequestPayloadModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobNewRequestPayloadModel value)  $default,){
final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobNewRequestPayloadModel value)?  $default,){
final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'service_name')  String serviceName, @JsonKey(name: 'booking_type')  String? bookingType, @JsonKey(name: 'scheduled_start_iso')  String scheduledStartIso,  String payout, @JsonKey(name: 'payout_context')  String? payoutContext, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'ui_location_label')  String? locationLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel() when $default != null:
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.scheduledStartIso,_that.payout,_that.payoutContext,_that.expiresInSeconds,_that.locationLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'service_name')  String serviceName, @JsonKey(name: 'booking_type')  String? bookingType, @JsonKey(name: 'scheduled_start_iso')  String scheduledStartIso,  String payout, @JsonKey(name: 'payout_context')  String? payoutContext, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'ui_location_label')  String? locationLabel)  $default,) {final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel():
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.scheduledStartIso,_that.payout,_that.payoutContext,_that.expiresInSeconds,_that.locationLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'service_name')  String serviceName, @JsonKey(name: 'booking_type')  String? bookingType, @JsonKey(name: 'scheduled_start_iso')  String scheduledStartIso,  String payout, @JsonKey(name: 'payout_context')  String? payoutContext, @JsonKey(name: 'expires_in_seconds')  int expiresInSeconds, @JsonKey(name: 'ui_location_label')  String? locationLabel)?  $default,) {final _that = this;
switch (_that) {
case _JobNewRequestPayloadModel() when $default != null:
return $default(_that.jobId,_that.serviceName,_that.bookingType,_that.scheduledStartIso,_that.payout,_that.payoutContext,_that.expiresInSeconds,_that.locationLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobNewRequestPayloadModel implements JobNewRequestPayloadModel {
  const _JobNewRequestPayloadModel({@JsonKey(name: 'job_id') required this.jobId, @JsonKey(name: 'service_name') required this.serviceName, @JsonKey(name: 'booking_type') required this.bookingType, @JsonKey(name: 'scheduled_start_iso') required this.scheduledStartIso, required this.payout, @JsonKey(name: 'payout_context') required this.payoutContext, @JsonKey(name: 'expires_in_seconds') required this.expiresInSeconds, @JsonKey(name: 'ui_location_label') required this.locationLabel});
  factory _JobNewRequestPayloadModel.fromJson(Map<String, dynamic> json) => _$JobNewRequestPayloadModelFromJson(json);

@override@JsonKey(name: 'job_id') final  int jobId;
@override@JsonKey(name: 'service_name') final  String serviceName;
@override@JsonKey(name: 'booking_type') final  String? bookingType;
@override@JsonKey(name: 'scheduled_start_iso') final  String scheduledStartIso;
/// Backend deliberately wires `payout` as an integer-string (e.g. `"1200"`)
/// to avoid client-side float drift. The domain entity holds `int`; parsing
/// happens in the mapper.
@override final  String payout;
@override@JsonKey(name: 'payout_context') final  String? payoutContext;
@override@JsonKey(name: 'expires_in_seconds') final  int expiresInSeconds;
/// Pre-composed locality string (e.g. `"Gulberg, Lahore"`) sourced
/// server-side from `JobBooking.address.locality_label`. Null on two
/// paths: (a) the booking's address FK is SET_NULL, (b) the address
/// pre-dates the locality columns and has not been backfilled. The
/// technician's card hides the row entirely when null — never shows
/// a placeholder. Full street address is never broadcast pre-accept.
@override@JsonKey(name: 'ui_location_label') final  String? locationLabel;

/// Create a copy of JobNewRequestPayloadModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobNewRequestPayloadModelCopyWith<_JobNewRequestPayloadModel> get copyWith => __$JobNewRequestPayloadModelCopyWithImpl<_JobNewRequestPayloadModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobNewRequestPayloadModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobNewRequestPayloadModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.bookingType, bookingType) || other.bookingType == bookingType)&&(identical(other.scheduledStartIso, scheduledStartIso) || other.scheduledStartIso == scheduledStartIso)&&(identical(other.payout, payout) || other.payout == payout)&&(identical(other.payoutContext, payoutContext) || other.payoutContext == payoutContext)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds)&&(identical(other.locationLabel, locationLabel) || other.locationLabel == locationLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,serviceName,bookingType,scheduledStartIso,payout,payoutContext,expiresInSeconds,locationLabel);

@override
String toString() {
  return 'JobNewRequestPayloadModel(jobId: $jobId, serviceName: $serviceName, bookingType: $bookingType, scheduledStartIso: $scheduledStartIso, payout: $payout, payoutContext: $payoutContext, expiresInSeconds: $expiresInSeconds, locationLabel: $locationLabel)';
}


}

/// @nodoc
abstract mixin class _$JobNewRequestPayloadModelCopyWith<$Res> implements $JobNewRequestPayloadModelCopyWith<$Res> {
  factory _$JobNewRequestPayloadModelCopyWith(_JobNewRequestPayloadModel value, $Res Function(_JobNewRequestPayloadModel) _then) = __$JobNewRequestPayloadModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'service_name') String serviceName,@JsonKey(name: 'booking_type') String? bookingType,@JsonKey(name: 'scheduled_start_iso') String scheduledStartIso, String payout,@JsonKey(name: 'payout_context') String? payoutContext,@JsonKey(name: 'expires_in_seconds') int expiresInSeconds,@JsonKey(name: 'ui_location_label') String? locationLabel
});




}
/// @nodoc
class __$JobNewRequestPayloadModelCopyWithImpl<$Res>
    implements _$JobNewRequestPayloadModelCopyWith<$Res> {
  __$JobNewRequestPayloadModelCopyWithImpl(this._self, this._then);

  final _JobNewRequestPayloadModel _self;
  final $Res Function(_JobNewRequestPayloadModel) _then;

/// Create a copy of JobNewRequestPayloadModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? serviceName = null,Object? bookingType = freezed,Object? scheduledStartIso = null,Object? payout = null,Object? payoutContext = freezed,Object? expiresInSeconds = null,Object? locationLabel = freezed,}) {
  return _then(_JobNewRequestPayloadModel(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,bookingType: freezed == bookingType ? _self.bookingType : bookingType // ignore: cast_nullable_to_non_nullable
as String?,scheduledStartIso: null == scheduledStartIso ? _self.scheduledStartIso : scheduledStartIso // ignore: cast_nullable_to_non_nullable
as String,payout: null == payout ? _self.payout : payout // ignore: cast_nullable_to_non_nullable
as String,payoutContext: freezed == payoutContext ? _self.payoutContext : payoutContext // ignore: cast_nullable_to_non_nullable
as String?,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,locationLabel: freezed == locationLabel ? _self.locationLabel : locationLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

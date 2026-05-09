// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_event_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JobIdPayload {

@JsonKey(name: 'job_id') int get jobId;
/// Create a copy of JobIdPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobIdPayloadCopyWith<JobIdPayload> get copyWith => _$JobIdPayloadCopyWithImpl<JobIdPayload>(this as JobIdPayload, _$identity);

  /// Serializes this JobIdPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobIdPayload&&(identical(other.jobId, jobId) || other.jobId == jobId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId);

@override
String toString() {
  return 'JobIdPayload(jobId: $jobId)';
}


}

/// @nodoc
abstract mixin class $JobIdPayloadCopyWith<$Res>  {
  factory $JobIdPayloadCopyWith(JobIdPayload value, $Res Function(JobIdPayload) _then) = _$JobIdPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'job_id') int jobId
});




}
/// @nodoc
class _$JobIdPayloadCopyWithImpl<$Res>
    implements $JobIdPayloadCopyWith<$Res> {
  _$JobIdPayloadCopyWithImpl(this._self, this._then);

  final JobIdPayload _self;
  final $Res Function(JobIdPayload) _then;

/// Create a copy of JobIdPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [JobIdPayload].
extension JobIdPayloadPatterns on JobIdPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobIdPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobIdPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobIdPayload value)  $default,){
final _that = this;
switch (_that) {
case _JobIdPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobIdPayload value)?  $default,){
final _that = this;
switch (_that) {
case _JobIdPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobIdPayload() when $default != null:
return $default(_that.jobId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId)  $default,) {final _that = this;
switch (_that) {
case _JobIdPayload():
return $default(_that.jobId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'job_id')  int jobId)?  $default,) {final _that = this;
switch (_that) {
case _JobIdPayload() when $default != null:
return $default(_that.jobId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JobIdPayload implements JobIdPayload {
  const _JobIdPayload({@JsonKey(name: 'job_id') required this.jobId});
  factory _JobIdPayload.fromJson(Map<String, dynamic> json) => _$JobIdPayloadFromJson(json);

@override@JsonKey(name: 'job_id') final  int jobId;

/// Create a copy of JobIdPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobIdPayloadCopyWith<_JobIdPayload> get copyWith => __$JobIdPayloadCopyWithImpl<_JobIdPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobIdPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobIdPayload&&(identical(other.jobId, jobId) || other.jobId == jobId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId);

@override
String toString() {
  return 'JobIdPayload(jobId: $jobId)';
}


}

/// @nodoc
abstract mixin class _$JobIdPayloadCopyWith<$Res> implements $JobIdPayloadCopyWith<$Res> {
  factory _$JobIdPayloadCopyWith(_JobIdPayload value, $Res Function(_JobIdPayload) _then) = __$JobIdPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'job_id') int jobId
});




}
/// @nodoc
class __$JobIdPayloadCopyWithImpl<$Res>
    implements _$JobIdPayloadCopyWith<$Res> {
  __$JobIdPayloadCopyWithImpl(this._self, this._then);

  final _JobIdPayload _self;
  final $Res Function(_JobIdPayload) _then;

/// Create a copy of JobIdPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,}) {
  return _then(_JobIdPayload(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QuoteGeneratedPayload {

@JsonKey(name: 'job_id') int get jobId;@JsonKey(name: 'quote_id') int get quoteId;@JsonKey(name: 'revision_number') int get revisionNumber;@JsonKey(name: 'total_amount') String get totalAmount;
/// Create a copy of QuoteGeneratedPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteGeneratedPayloadCopyWith<QuoteGeneratedPayload> get copyWith => _$QuoteGeneratedPayloadCopyWithImpl<QuoteGeneratedPayload>(this as QuoteGeneratedPayload, _$identity);

  /// Serializes this QuoteGeneratedPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteGeneratedPayload&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,quoteId,revisionNumber,totalAmount);

@override
String toString() {
  return 'QuoteGeneratedPayload(jobId: $jobId, quoteId: $quoteId, revisionNumber: $revisionNumber, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class $QuoteGeneratedPayloadCopyWith<$Res>  {
  factory $QuoteGeneratedPayloadCopyWith(QuoteGeneratedPayload value, $Res Function(QuoteGeneratedPayload) _then) = _$QuoteGeneratedPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'quote_id') int quoteId,@JsonKey(name: 'revision_number') int revisionNumber,@JsonKey(name: 'total_amount') String totalAmount
});




}
/// @nodoc
class _$QuoteGeneratedPayloadCopyWithImpl<$Res>
    implements $QuoteGeneratedPayloadCopyWith<$Res> {
  _$QuoteGeneratedPayloadCopyWithImpl(this._self, this._then);

  final QuoteGeneratedPayload _self;
  final $Res Function(QuoteGeneratedPayload) _then;

/// Create a copy of QuoteGeneratedPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? quoteId = null,Object? revisionNumber = null,Object? totalAmount = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [QuoteGeneratedPayload].
extension QuoteGeneratedPayloadPatterns on QuoteGeneratedPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuoteGeneratedPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuoteGeneratedPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuoteGeneratedPayload value)  $default,){
final _that = this;
switch (_that) {
case _QuoteGeneratedPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuoteGeneratedPayload value)?  $default,){
final _that = this;
switch (_that) {
case _QuoteGeneratedPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'quote_id')  int quoteId, @JsonKey(name: 'revision_number')  int revisionNumber, @JsonKey(name: 'total_amount')  String totalAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuoteGeneratedPayload() when $default != null:
return $default(_that.jobId,_that.quoteId,_that.revisionNumber,_that.totalAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'quote_id')  int quoteId, @JsonKey(name: 'revision_number')  int revisionNumber, @JsonKey(name: 'total_amount')  String totalAmount)  $default,) {final _that = this;
switch (_that) {
case _QuoteGeneratedPayload():
return $default(_that.jobId,_that.quoteId,_that.revisionNumber,_that.totalAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'quote_id')  int quoteId, @JsonKey(name: 'revision_number')  int revisionNumber, @JsonKey(name: 'total_amount')  String totalAmount)?  $default,) {final _that = this;
switch (_that) {
case _QuoteGeneratedPayload() when $default != null:
return $default(_that.jobId,_that.quoteId,_that.revisionNumber,_that.totalAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuoteGeneratedPayload implements QuoteGeneratedPayload {
  const _QuoteGeneratedPayload({@JsonKey(name: 'job_id') required this.jobId, @JsonKey(name: 'quote_id') required this.quoteId, @JsonKey(name: 'revision_number') required this.revisionNumber, @JsonKey(name: 'total_amount') required this.totalAmount});
  factory _QuoteGeneratedPayload.fromJson(Map<String, dynamic> json) => _$QuoteGeneratedPayloadFromJson(json);

@override@JsonKey(name: 'job_id') final  int jobId;
@override@JsonKey(name: 'quote_id') final  int quoteId;
@override@JsonKey(name: 'revision_number') final  int revisionNumber;
@override@JsonKey(name: 'total_amount') final  String totalAmount;

/// Create a copy of QuoteGeneratedPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuoteGeneratedPayloadCopyWith<_QuoteGeneratedPayload> get copyWith => __$QuoteGeneratedPayloadCopyWithImpl<_QuoteGeneratedPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuoteGeneratedPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuoteGeneratedPayload&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.quoteId, quoteId) || other.quoteId == quoteId)&&(identical(other.revisionNumber, revisionNumber) || other.revisionNumber == revisionNumber)&&(identical(other.totalAmount, totalAmount) || other.totalAmount == totalAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,quoteId,revisionNumber,totalAmount);

@override
String toString() {
  return 'QuoteGeneratedPayload(jobId: $jobId, quoteId: $quoteId, revisionNumber: $revisionNumber, totalAmount: $totalAmount)';
}


}

/// @nodoc
abstract mixin class _$QuoteGeneratedPayloadCopyWith<$Res> implements $QuoteGeneratedPayloadCopyWith<$Res> {
  factory _$QuoteGeneratedPayloadCopyWith(_QuoteGeneratedPayload value, $Res Function(_QuoteGeneratedPayload) _then) = __$QuoteGeneratedPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'quote_id') int quoteId,@JsonKey(name: 'revision_number') int revisionNumber,@JsonKey(name: 'total_amount') String totalAmount
});




}
/// @nodoc
class __$QuoteGeneratedPayloadCopyWithImpl<$Res>
    implements _$QuoteGeneratedPayloadCopyWith<$Res> {
  __$QuoteGeneratedPayloadCopyWithImpl(this._self, this._then);

  final _QuoteGeneratedPayload _self;
  final $Res Function(_QuoteGeneratedPayload) _then;

/// Create a copy of QuoteGeneratedPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? quoteId = null,Object? revisionNumber = null,Object? totalAmount = null,}) {
  return _then(_QuoteGeneratedPayload(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,quoteId: null == quoteId ? _self.quoteId : quoteId // ignore: cast_nullable_to_non_nullable
as int,revisionNumber: null == revisionNumber ? _self.revisionNumber : revisionNumber // ignore: cast_nullable_to_non_nullable
as int,totalAmount: null == totalAmount ? _self.totalAmount : totalAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BookingRescheduledPayload {

@JsonKey(name: 'job_id') int get jobId;@JsonKey(name: 'child_booking_id') int get childBookingId;
/// Create a copy of BookingRescheduledPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingRescheduledPayloadCopyWith<BookingRescheduledPayload> get copyWith => _$BookingRescheduledPayloadCopyWithImpl<BookingRescheduledPayload>(this as BookingRescheduledPayload, _$identity);

  /// Serializes this BookingRescheduledPayload to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingRescheduledPayload&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,childBookingId);

@override
String toString() {
  return 'BookingRescheduledPayload(jobId: $jobId, childBookingId: $childBookingId)';
}


}

/// @nodoc
abstract mixin class $BookingRescheduledPayloadCopyWith<$Res>  {
  factory $BookingRescheduledPayloadCopyWith(BookingRescheduledPayload value, $Res Function(BookingRescheduledPayload) _then) = _$BookingRescheduledPayloadCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'child_booking_id') int childBookingId
});




}
/// @nodoc
class _$BookingRescheduledPayloadCopyWithImpl<$Res>
    implements $BookingRescheduledPayloadCopyWith<$Res> {
  _$BookingRescheduledPayloadCopyWithImpl(this._self, this._then);

  final BookingRescheduledPayload _self;
  final $Res Function(BookingRescheduledPayload) _then;

/// Create a copy of BookingRescheduledPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? childBookingId = null,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,childBookingId: null == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingRescheduledPayload].
extension BookingRescheduledPayloadPatterns on BookingRescheduledPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingRescheduledPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingRescheduledPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingRescheduledPayload value)  $default,){
final _that = this;
switch (_that) {
case _BookingRescheduledPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingRescheduledPayload value)?  $default,){
final _that = this;
switch (_that) {
case _BookingRescheduledPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'child_booking_id')  int childBookingId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingRescheduledPayload() when $default != null:
return $default(_that.jobId,_that.childBookingId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'child_booking_id')  int childBookingId)  $default,) {final _that = this;
switch (_that) {
case _BookingRescheduledPayload():
return $default(_that.jobId,_that.childBookingId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'job_id')  int jobId, @JsonKey(name: 'child_booking_id')  int childBookingId)?  $default,) {final _that = this;
switch (_that) {
case _BookingRescheduledPayload() when $default != null:
return $default(_that.jobId,_that.childBookingId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingRescheduledPayload implements BookingRescheduledPayload {
  const _BookingRescheduledPayload({@JsonKey(name: 'job_id') required this.jobId, @JsonKey(name: 'child_booking_id') required this.childBookingId});
  factory _BookingRescheduledPayload.fromJson(Map<String, dynamic> json) => _$BookingRescheduledPayloadFromJson(json);

@override@JsonKey(name: 'job_id') final  int jobId;
@override@JsonKey(name: 'child_booking_id') final  int childBookingId;

/// Create a copy of BookingRescheduledPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingRescheduledPayloadCopyWith<_BookingRescheduledPayload> get copyWith => __$BookingRescheduledPayloadCopyWithImpl<_BookingRescheduledPayload>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingRescheduledPayloadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingRescheduledPayload&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.childBookingId, childBookingId) || other.childBookingId == childBookingId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,childBookingId);

@override
String toString() {
  return 'BookingRescheduledPayload(jobId: $jobId, childBookingId: $childBookingId)';
}


}

/// @nodoc
abstract mixin class _$BookingRescheduledPayloadCopyWith<$Res> implements $BookingRescheduledPayloadCopyWith<$Res> {
  factory _$BookingRescheduledPayloadCopyWith(_BookingRescheduledPayload value, $Res Function(_BookingRescheduledPayload) _then) = __$BookingRescheduledPayloadCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'job_id') int jobId,@JsonKey(name: 'child_booking_id') int childBookingId
});




}
/// @nodoc
class __$BookingRescheduledPayloadCopyWithImpl<$Res>
    implements _$BookingRescheduledPayloadCopyWith<$Res> {
  __$BookingRescheduledPayloadCopyWithImpl(this._self, this._then);

  final _BookingRescheduledPayload _self;
  final $Res Function(_BookingRescheduledPayload) _then;

/// Create a copy of BookingRescheduledPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? childBookingId = null,}) {
  return _then(_BookingRescheduledPayload(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as int,childBookingId: null == childBookingId ? _self.childBookingId : childBookingId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

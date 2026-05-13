// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_metrics_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MetricsBucket {

 String get label; int get jobs; double get cash;
/// Create a copy of MetricsBucket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MetricsBucketCopyWith<MetricsBucket> get copyWith => _$MetricsBucketCopyWithImpl<MetricsBucket>(this as MetricsBucket, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MetricsBucket&&(identical(other.label, label) || other.label == label)&&(identical(other.jobs, jobs) || other.jobs == jobs)&&(identical(other.cash, cash) || other.cash == cash));
}


@override
int get hashCode => Object.hash(runtimeType,label,jobs,cash);

@override
String toString() {
  return 'MetricsBucket(label: $label, jobs: $jobs, cash: $cash)';
}


}

/// @nodoc
abstract mixin class $MetricsBucketCopyWith<$Res>  {
  factory $MetricsBucketCopyWith(MetricsBucket value, $Res Function(MetricsBucket) _then) = _$MetricsBucketCopyWithImpl;
@useResult
$Res call({
 String label, int jobs, double cash
});




}
/// @nodoc
class _$MetricsBucketCopyWithImpl<$Res>
    implements $MetricsBucketCopyWith<$Res> {
  _$MetricsBucketCopyWithImpl(this._self, this._then);

  final MetricsBucket _self;
  final $Res Function(MetricsBucket) _then;

/// Create a copy of MetricsBucket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? jobs = null,Object? cash = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as int,cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MetricsBucket].
extension MetricsBucketPatterns on MetricsBucket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MetricsBucket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MetricsBucket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MetricsBucket value)  $default,){
final _that = this;
switch (_that) {
case _MetricsBucket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MetricsBucket value)?  $default,){
final _that = this;
switch (_that) {
case _MetricsBucket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  int jobs,  double cash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MetricsBucket() when $default != null:
return $default(_that.label,_that.jobs,_that.cash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  int jobs,  double cash)  $default,) {final _that = this;
switch (_that) {
case _MetricsBucket():
return $default(_that.label,_that.jobs,_that.cash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  int jobs,  double cash)?  $default,) {final _that = this;
switch (_that) {
case _MetricsBucket() when $default != null:
return $default(_that.label,_that.jobs,_that.cash);case _:
  return null;

}
}

}

/// @nodoc


class _MetricsBucket implements MetricsBucket {
  const _MetricsBucket({required this.label, required this.jobs, required this.cash});
  

@override final  String label;
@override final  int jobs;
@override final  double cash;

/// Create a copy of MetricsBucket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MetricsBucketCopyWith<_MetricsBucket> get copyWith => __$MetricsBucketCopyWithImpl<_MetricsBucket>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MetricsBucket&&(identical(other.label, label) || other.label == label)&&(identical(other.jobs, jobs) || other.jobs == jobs)&&(identical(other.cash, cash) || other.cash == cash));
}


@override
int get hashCode => Object.hash(runtimeType,label,jobs,cash);

@override
String toString() {
  return 'MetricsBucket(label: $label, jobs: $jobs, cash: $cash)';
}


}

/// @nodoc
abstract mixin class _$MetricsBucketCopyWith<$Res> implements $MetricsBucketCopyWith<$Res> {
  factory _$MetricsBucketCopyWith(_MetricsBucket value, $Res Function(_MetricsBucket) _then) = __$MetricsBucketCopyWithImpl;
@override @useResult
$Res call({
 String label, int jobs, double cash
});




}
/// @nodoc
class __$MetricsBucketCopyWithImpl<$Res>
    implements _$MetricsBucketCopyWith<$Res> {
  __$MetricsBucketCopyWithImpl(this._self, this._then);

  final _MetricsBucket _self;
  final $Res Function(_MetricsBucket) _then;

/// Create a copy of MetricsBucket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? jobs = null,Object? cash = null,}) {
  return _then(_MetricsBucket(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,jobs: null == jobs ? _self.jobs : jobs // ignore: cast_nullable_to_non_nullable
as int,cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$TechnicianMetricsEntity {

 MetricsPeriod get period; int get totalJobs; double get totalCash; List<MetricsBucket> get buckets;
/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianMetricsEntityCopyWith<TechnicianMetricsEntity> get copyWith => _$TechnicianMetricsEntityCopyWithImpl<TechnicianMetricsEntity>(this as TechnicianMetricsEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianMetricsEntity&&(identical(other.period, period) || other.period == period)&&(identical(other.totalJobs, totalJobs) || other.totalJobs == totalJobs)&&(identical(other.totalCash, totalCash) || other.totalCash == totalCash)&&const DeepCollectionEquality().equals(other.buckets, buckets));
}


@override
int get hashCode => Object.hash(runtimeType,period,totalJobs,totalCash,const DeepCollectionEquality().hash(buckets));

@override
String toString() {
  return 'TechnicianMetricsEntity(period: $period, totalJobs: $totalJobs, totalCash: $totalCash, buckets: $buckets)';
}


}

/// @nodoc
abstract mixin class $TechnicianMetricsEntityCopyWith<$Res>  {
  factory $TechnicianMetricsEntityCopyWith(TechnicianMetricsEntity value, $Res Function(TechnicianMetricsEntity) _then) = _$TechnicianMetricsEntityCopyWithImpl;
@useResult
$Res call({
 MetricsPeriod period, int totalJobs, double totalCash, List<MetricsBucket> buckets
});




}
/// @nodoc
class _$TechnicianMetricsEntityCopyWithImpl<$Res>
    implements $TechnicianMetricsEntityCopyWith<$Res> {
  _$TechnicianMetricsEntityCopyWithImpl(this._self, this._then);

  final TechnicianMetricsEntity _self;
  final $Res Function(TechnicianMetricsEntity) _then;

/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? totalJobs = null,Object? totalCash = null,Object? buckets = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as MetricsPeriod,totalJobs: null == totalJobs ? _self.totalJobs : totalJobs // ignore: cast_nullable_to_non_nullable
as int,totalCash: null == totalCash ? _self.totalCash : totalCash // ignore: cast_nullable_to_non_nullable
as double,buckets: null == buckets ? _self.buckets : buckets // ignore: cast_nullable_to_non_nullable
as List<MetricsBucket>,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianMetricsEntity].
extension TechnicianMetricsEntityPatterns on TechnicianMetricsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianMetricsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianMetricsEntity value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianMetricsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MetricsPeriod period,  int totalJobs,  double totalCash,  List<MetricsBucket> buckets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
return $default(_that.period,_that.totalJobs,_that.totalCash,_that.buckets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MetricsPeriod period,  int totalJobs,  double totalCash,  List<MetricsBucket> buckets)  $default,) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity():
return $default(_that.period,_that.totalJobs,_that.totalCash,_that.buckets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MetricsPeriod period,  int totalJobs,  double totalCash,  List<MetricsBucket> buckets)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianMetricsEntity() when $default != null:
return $default(_that.period,_that.totalJobs,_that.totalCash,_that.buckets);case _:
  return null;

}
}

}

/// @nodoc


class _TechnicianMetricsEntity implements TechnicianMetricsEntity {
  const _TechnicianMetricsEntity({required this.period, required this.totalJobs, required this.totalCash, required final  List<MetricsBucket> buckets}): _buckets = buckets;
  

@override final  MetricsPeriod period;
@override final  int totalJobs;
@override final  double totalCash;
 final  List<MetricsBucket> _buckets;
@override List<MetricsBucket> get buckets {
  if (_buckets is EqualUnmodifiableListView) return _buckets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buckets);
}


/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianMetricsEntityCopyWith<_TechnicianMetricsEntity> get copyWith => __$TechnicianMetricsEntityCopyWithImpl<_TechnicianMetricsEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianMetricsEntity&&(identical(other.period, period) || other.period == period)&&(identical(other.totalJobs, totalJobs) || other.totalJobs == totalJobs)&&(identical(other.totalCash, totalCash) || other.totalCash == totalCash)&&const DeepCollectionEquality().equals(other._buckets, _buckets));
}


@override
int get hashCode => Object.hash(runtimeType,period,totalJobs,totalCash,const DeepCollectionEquality().hash(_buckets));

@override
String toString() {
  return 'TechnicianMetricsEntity(period: $period, totalJobs: $totalJobs, totalCash: $totalCash, buckets: $buckets)';
}


}

/// @nodoc
abstract mixin class _$TechnicianMetricsEntityCopyWith<$Res> implements $TechnicianMetricsEntityCopyWith<$Res> {
  factory _$TechnicianMetricsEntityCopyWith(_TechnicianMetricsEntity value, $Res Function(_TechnicianMetricsEntity) _then) = __$TechnicianMetricsEntityCopyWithImpl;
@override @useResult
$Res call({
 MetricsPeriod period, int totalJobs, double totalCash, List<MetricsBucket> buckets
});




}
/// @nodoc
class __$TechnicianMetricsEntityCopyWithImpl<$Res>
    implements _$TechnicianMetricsEntityCopyWith<$Res> {
  __$TechnicianMetricsEntityCopyWithImpl(this._self, this._then);

  final _TechnicianMetricsEntity _self;
  final $Res Function(_TechnicianMetricsEntity) _then;

/// Create a copy of TechnicianMetricsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? totalJobs = null,Object? totalCash = null,Object? buckets = null,}) {
  return _then(_TechnicianMetricsEntity(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as MetricsPeriod,totalJobs: null == totalJobs ? _self.totalJobs : totalJobs // ignore: cast_nullable_to_non_nullable
as int,totalCash: null == totalCash ? _self.totalCash : totalCash // ignore: cast_nullable_to_non_nullable
as double,buckets: null == buckets ? _self._buckets : buckets // ignore: cast_nullable_to_non_nullable
as List<MetricsBucket>,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'system_event_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SystemEventModel {

 String get kind; String get id;@JsonKey(name: 'rawType') String get rawType;@JsonKey(name: 'targetRole') String get targetRole; String get timestamp; Map<String, dynamic> get payload;@JsonKey(name: 'expires_at') String? get expiresAt;@JsonKey(name: 'recipient_user_id') int? get recipientUserId;
/// Create a copy of SystemEventModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SystemEventModelCopyWith<SystemEventModel> get copyWith => _$SystemEventModelCopyWithImpl<SystemEventModel>(this as SystemEventModel, _$identity);

  /// Serializes this SystemEventModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SystemEventModel&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.rawType, rawType) || other.rawType == rawType)&&(identical(other.targetRole, targetRole) || other.targetRole == targetRole)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.recipientUserId, recipientUserId) || other.recipientUserId == recipientUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id,rawType,targetRole,timestamp,const DeepCollectionEquality().hash(payload),expiresAt,recipientUserId);

@override
String toString() {
  return 'SystemEventModel(kind: $kind, id: $id, rawType: $rawType, targetRole: $targetRole, timestamp: $timestamp, payload: $payload, expiresAt: $expiresAt, recipientUserId: $recipientUserId)';
}


}

/// @nodoc
abstract mixin class $SystemEventModelCopyWith<$Res>  {
  factory $SystemEventModelCopyWith(SystemEventModel value, $Res Function(SystemEventModel) _then) = _$SystemEventModelCopyWithImpl;
@useResult
$Res call({
 String kind, String id,@JsonKey(name: 'rawType') String rawType,@JsonKey(name: 'targetRole') String targetRole, String timestamp, Map<String, dynamic> payload,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'recipient_user_id') int? recipientUserId
});




}
/// @nodoc
class _$SystemEventModelCopyWithImpl<$Res>
    implements $SystemEventModelCopyWith<$Res> {
  _$SystemEventModelCopyWithImpl(this._self, this._then);

  final SystemEventModel _self;
  final $Res Function(SystemEventModel) _then;

/// Create a copy of SystemEventModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? id = null,Object? rawType = null,Object? targetRole = null,Object? timestamp = null,Object? payload = null,Object? expiresAt = freezed,Object? recipientUserId = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawType: null == rawType ? _self.rawType : rawType // ignore: cast_nullable_to_non_nullable
as String,targetRole: null == targetRole ? _self.targetRole : targetRole // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,recipientUserId: freezed == recipientUserId ? _self.recipientUserId : recipientUserId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SystemEventModel].
extension SystemEventModelPatterns on SystemEventModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SystemEventModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SystemEventModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SystemEventModel value)  $default,){
final _that = this;
switch (_that) {
case _SystemEventModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SystemEventModel value)?  $default,){
final _that = this;
switch (_that) {
case _SystemEventModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String id, @JsonKey(name: 'rawType')  String rawType, @JsonKey(name: 'targetRole')  String targetRole,  String timestamp,  Map<String, dynamic> payload, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'recipient_user_id')  int? recipientUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SystemEventModel() when $default != null:
return $default(_that.kind,_that.id,_that.rawType,_that.targetRole,_that.timestamp,_that.payload,_that.expiresAt,_that.recipientUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String id, @JsonKey(name: 'rawType')  String rawType, @JsonKey(name: 'targetRole')  String targetRole,  String timestamp,  Map<String, dynamic> payload, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'recipient_user_id')  int? recipientUserId)  $default,) {final _that = this;
switch (_that) {
case _SystemEventModel():
return $default(_that.kind,_that.id,_that.rawType,_that.targetRole,_that.timestamp,_that.payload,_that.expiresAt,_that.recipientUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String id, @JsonKey(name: 'rawType')  String rawType, @JsonKey(name: 'targetRole')  String targetRole,  String timestamp,  Map<String, dynamic> payload, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'recipient_user_id')  int? recipientUserId)?  $default,) {final _that = this;
switch (_that) {
case _SystemEventModel() when $default != null:
return $default(_that.kind,_that.id,_that.rawType,_that.targetRole,_that.timestamp,_that.payload,_that.expiresAt,_that.recipientUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SystemEventModel implements SystemEventModel {
  const _SystemEventModel({required this.kind, required this.id, @JsonKey(name: 'rawType') required this.rawType, @JsonKey(name: 'targetRole') required this.targetRole, required this.timestamp, required final  Map<String, dynamic> payload, @JsonKey(name: 'expires_at') this.expiresAt, @JsonKey(name: 'recipient_user_id') this.recipientUserId}): _payload = payload;
  factory _SystemEventModel.fromJson(Map<String, dynamic> json) => _$SystemEventModelFromJson(json);

@override final  String kind;
@override final  String id;
@override@JsonKey(name: 'rawType') final  String rawType;
@override@JsonKey(name: 'targetRole') final  String targetRole;
@override final  String timestamp;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override@JsonKey(name: 'expires_at') final  String? expiresAt;
@override@JsonKey(name: 'recipient_user_id') final  int? recipientUserId;

/// Create a copy of SystemEventModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SystemEventModelCopyWith<_SystemEventModel> get copyWith => __$SystemEventModelCopyWithImpl<_SystemEventModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SystemEventModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SystemEventModel&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.id, id) || other.id == id)&&(identical(other.rawType, rawType) || other.rawType == rawType)&&(identical(other.targetRole, targetRole) || other.targetRole == targetRole)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.recipientUserId, recipientUserId) || other.recipientUserId == recipientUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,id,rawType,targetRole,timestamp,const DeepCollectionEquality().hash(_payload),expiresAt,recipientUserId);

@override
String toString() {
  return 'SystemEventModel(kind: $kind, id: $id, rawType: $rawType, targetRole: $targetRole, timestamp: $timestamp, payload: $payload, expiresAt: $expiresAt, recipientUserId: $recipientUserId)';
}


}

/// @nodoc
abstract mixin class _$SystemEventModelCopyWith<$Res> implements $SystemEventModelCopyWith<$Res> {
  factory _$SystemEventModelCopyWith(_SystemEventModel value, $Res Function(_SystemEventModel) _then) = __$SystemEventModelCopyWithImpl;
@override @useResult
$Res call({
 String kind, String id,@JsonKey(name: 'rawType') String rawType,@JsonKey(name: 'targetRole') String targetRole, String timestamp, Map<String, dynamic> payload,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'recipient_user_id') int? recipientUserId
});




}
/// @nodoc
class __$SystemEventModelCopyWithImpl<$Res>
    implements _$SystemEventModelCopyWith<$Res> {
  __$SystemEventModelCopyWithImpl(this._self, this._then);

  final _SystemEventModel _self;
  final $Res Function(_SystemEventModel) _then;

/// Create a copy of SystemEventModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? id = null,Object? rawType = null,Object? targetRole = null,Object? timestamp = null,Object? payload = null,Object? expiresAt = freezed,Object? recipientUserId = freezed,}) {
  return _then(_SystemEventModel(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rawType: null == rawType ? _self.rawType : rawType // ignore: cast_nullable_to_non_nullable
as String,targetRole: null == targetRole ? _self.targetRole : targetRole // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,recipientUserId: freezed == recipientUserId ? _self.recipientUserId : recipientUserId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

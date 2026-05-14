// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'output_refs_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OutputRefsModel {

@JsonKey(name: 'support_ticket_id') int? get supportTicketId;
/// Create a copy of OutputRefsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutputRefsModelCopyWith<OutputRefsModel> get copyWith => _$OutputRefsModelCopyWithImpl<OutputRefsModel>(this as OutputRefsModel, _$identity);

  /// Serializes this OutputRefsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutputRefsModel&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,supportTicketId);

@override
String toString() {
  return 'OutputRefsModel(supportTicketId: $supportTicketId)';
}


}

/// @nodoc
abstract mixin class $OutputRefsModelCopyWith<$Res>  {
  factory $OutputRefsModelCopyWith(OutputRefsModel value, $Res Function(OutputRefsModel) _then) = _$OutputRefsModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'support_ticket_id') int? supportTicketId
});




}
/// @nodoc
class _$OutputRefsModelCopyWithImpl<$Res>
    implements $OutputRefsModelCopyWith<$Res> {
  _$OutputRefsModelCopyWithImpl(this._self, this._then);

  final OutputRefsModel _self;
  final $Res Function(OutputRefsModel) _then;

/// Create a copy of OutputRefsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? supportTicketId = freezed,}) {
  return _then(_self.copyWith(
supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OutputRefsModel].
extension OutputRefsModelPatterns on OutputRefsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutputRefsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutputRefsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutputRefsModel value)  $default,){
final _that = this;
switch (_that) {
case _OutputRefsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutputRefsModel value)?  $default,){
final _that = this;
switch (_that) {
case _OutputRefsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'support_ticket_id')  int? supportTicketId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutputRefsModel() when $default != null:
return $default(_that.supportTicketId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'support_ticket_id')  int? supportTicketId)  $default,) {final _that = this;
switch (_that) {
case _OutputRefsModel():
return $default(_that.supportTicketId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'support_ticket_id')  int? supportTicketId)?  $default,) {final _that = this;
switch (_that) {
case _OutputRefsModel() when $default != null:
return $default(_that.supportTicketId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OutputRefsModel implements OutputRefsModel {
  const _OutputRefsModel({@JsonKey(name: 'support_ticket_id') this.supportTicketId});
  factory _OutputRefsModel.fromJson(Map<String, dynamic> json) => _$OutputRefsModelFromJson(json);

@override@JsonKey(name: 'support_ticket_id') final  int? supportTicketId;

/// Create a copy of OutputRefsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutputRefsModelCopyWith<_OutputRefsModel> get copyWith => __$OutputRefsModelCopyWithImpl<_OutputRefsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OutputRefsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutputRefsModel&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,supportTicketId);

@override
String toString() {
  return 'OutputRefsModel(supportTicketId: $supportTicketId)';
}


}

/// @nodoc
abstract mixin class _$OutputRefsModelCopyWith<$Res> implements $OutputRefsModelCopyWith<$Res> {
  factory _$OutputRefsModelCopyWith(_OutputRefsModel value, $Res Function(_OutputRefsModel) _then) = __$OutputRefsModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'support_ticket_id') int? supportTicketId
});




}
/// @nodoc
class __$OutputRefsModelCopyWithImpl<$Res>
    implements _$OutputRefsModelCopyWith<$Res> {
  __$OutputRefsModelCopyWithImpl(this._self, this._then);

  final _OutputRefsModel _self;
  final $Res Function(_OutputRefsModel) _then;

/// Create a copy of OutputRefsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? supportTicketId = freezed,}) {
  return _then(_OutputRefsModel(
supportTicketId: freezed == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on

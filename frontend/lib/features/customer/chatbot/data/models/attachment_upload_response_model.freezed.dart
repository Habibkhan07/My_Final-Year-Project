// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_upload_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AttachmentUploadResponseModel {

@JsonKey(name: 'attachment_id') int get attachmentId;@JsonKey(name: 'attachments_count') int get attachmentsCount;
/// Create a copy of AttachmentUploadResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentUploadResponseModelCopyWith<AttachmentUploadResponseModel> get copyWith => _$AttachmentUploadResponseModelCopyWithImpl<AttachmentUploadResponseModel>(this as AttachmentUploadResponseModel, _$identity);

  /// Serializes this AttachmentUploadResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AttachmentUploadResponseModel&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,attachmentsCount);

@override
String toString() {
  return 'AttachmentUploadResponseModel(attachmentId: $attachmentId, attachmentsCount: $attachmentsCount)';
}


}

/// @nodoc
abstract mixin class $AttachmentUploadResponseModelCopyWith<$Res>  {
  factory $AttachmentUploadResponseModelCopyWith(AttachmentUploadResponseModel value, $Res Function(AttachmentUploadResponseModel) _then) = _$AttachmentUploadResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'attachment_id') int attachmentId,@JsonKey(name: 'attachments_count') int attachmentsCount
});




}
/// @nodoc
class _$AttachmentUploadResponseModelCopyWithImpl<$Res>
    implements $AttachmentUploadResponseModelCopyWith<$Res> {
  _$AttachmentUploadResponseModelCopyWithImpl(this._self, this._then);

  final AttachmentUploadResponseModel _self;
  final $Res Function(AttachmentUploadResponseModel) _then;

/// Create a copy of AttachmentUploadResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? attachmentId = null,Object? attachmentsCount = null,}) {
  return _then(_self.copyWith(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as int,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AttachmentUploadResponseModel].
extension AttachmentUploadResponseModelPatterns on AttachmentUploadResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AttachmentUploadResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AttachmentUploadResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AttachmentUploadResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  int attachmentId, @JsonKey(name: 'attachments_count')  int attachmentsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel() when $default != null:
return $default(_that.attachmentId,_that.attachmentsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'attachment_id')  int attachmentId, @JsonKey(name: 'attachments_count')  int attachmentsCount)  $default,) {final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel():
return $default(_that.attachmentId,_that.attachmentsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'attachment_id')  int attachmentId, @JsonKey(name: 'attachments_count')  int attachmentsCount)?  $default,) {final _that = this;
switch (_that) {
case _AttachmentUploadResponseModel() when $default != null:
return $default(_that.attachmentId,_that.attachmentsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AttachmentUploadResponseModel implements AttachmentUploadResponseModel {
  const _AttachmentUploadResponseModel({@JsonKey(name: 'attachment_id') required this.attachmentId, @JsonKey(name: 'attachments_count') required this.attachmentsCount});
  factory _AttachmentUploadResponseModel.fromJson(Map<String, dynamic> json) => _$AttachmentUploadResponseModelFromJson(json);

@override@JsonKey(name: 'attachment_id') final  int attachmentId;
@override@JsonKey(name: 'attachments_count') final  int attachmentsCount;

/// Create a copy of AttachmentUploadResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentUploadResponseModelCopyWith<_AttachmentUploadResponseModel> get copyWith => __$AttachmentUploadResponseModelCopyWithImpl<_AttachmentUploadResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AttachmentUploadResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AttachmentUploadResponseModel&&(identical(other.attachmentId, attachmentId) || other.attachmentId == attachmentId)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,attachmentId,attachmentsCount);

@override
String toString() {
  return 'AttachmentUploadResponseModel(attachmentId: $attachmentId, attachmentsCount: $attachmentsCount)';
}


}

/// @nodoc
abstract mixin class _$AttachmentUploadResponseModelCopyWith<$Res> implements $AttachmentUploadResponseModelCopyWith<$Res> {
  factory _$AttachmentUploadResponseModelCopyWith(_AttachmentUploadResponseModel value, $Res Function(_AttachmentUploadResponseModel) _then) = __$AttachmentUploadResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'attachment_id') int attachmentId,@JsonKey(name: 'attachments_count') int attachmentsCount
});




}
/// @nodoc
class __$AttachmentUploadResponseModelCopyWithImpl<$Res>
    implements _$AttachmentUploadResponseModelCopyWith<$Res> {
  __$AttachmentUploadResponseModelCopyWithImpl(this._self, this._then);

  final _AttachmentUploadResponseModel _self;
  final $Res Function(_AttachmentUploadResponseModel) _then;

/// Create a copy of AttachmentUploadResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? attachmentId = null,Object? attachmentsCount = null,}) {
  return _then(_AttachmentUploadResponseModel(
attachmentId: null == attachmentId ? _self.attachmentId : attachmentId // ignore: cast_nullable_to_non_nullable
as int,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

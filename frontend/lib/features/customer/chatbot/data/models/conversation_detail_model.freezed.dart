// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_detail_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationDetailModel {

@JsonKey(name: 'conversation_id') int get conversationId;@JsonKey(name: 'persona_key') String get personaKey;@JsonKey(name: 'current_phase') String get currentPhase;@JsonKey(name: 'is_closed') bool get isClosed;@JsonKey(name: 'closed_at') String? get closedAt;@JsonKey(name: 'state_summary') StateSummaryModel get stateSummary; List<MessageModel> get messages; List<AttachmentModel> get attachments;@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs;
/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationDetailModelCopyWith<ConversationDetailModel> get copyWith => _$ConversationDetailModelCopyWithImpl<ConversationDetailModel>(this as ConversationDetailModel, _$identity);

  /// Serializes this ConversationDetailModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationDetailModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary)&&const DeepCollectionEquality().equals(other.messages, messages)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.outputRefs, outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,currentPhase,isClosed,closedAt,stateSummary,const DeepCollectionEquality().hash(messages),const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(outputRefs));

@override
String toString() {
  return 'ConversationDetailModel(conversationId: $conversationId, personaKey: $personaKey, currentPhase: $currentPhase, isClosed: $isClosed, closedAt: $closedAt, stateSummary: $stateSummary, messages: $messages, attachments: $attachments, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class $ConversationDetailModelCopyWith<$Res>  {
  factory $ConversationDetailModelCopyWith(ConversationDetailModel value, $Res Function(ConversationDetailModel) _then) = _$ConversationDetailModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'persona_key') String personaKey,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary, List<MessageModel> messages, List<AttachmentModel> attachments,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});


$StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class _$ConversationDetailModelCopyWithImpl<$Res>
    implements $ConversationDetailModelCopyWith<$Res> {
  _$ConversationDetailModelCopyWithImpl(this._self, this._then);

  final ConversationDetailModel _self;
  final $Res Function(ConversationDetailModel) _then;

/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? personaKey = null,Object? currentPhase = null,Object? isClosed = null,Object? closedAt = freezed,Object? stateSummary = null,Object? messages = null,Object? attachments = null,Object? outputRefs = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AttachmentModel>,outputRefs: null == outputRefs ? _self.outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateSummaryModelCopyWith<$Res> get stateSummary {
  
  return $StateSummaryModelCopyWith<$Res>(_self.stateSummary, (value) {
    return _then(_self.copyWith(stateSummary: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationDetailModel].
extension ConversationDetailModelPatterns on ConversationDetailModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationDetailModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationDetailModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationDetailModel value)  $default,){
final _that = this;
switch (_that) {
case _ConversationDetailModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationDetailModel value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationDetailModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary,  List<MessageModel> messages,  List<AttachmentModel> attachments, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationDetailModel() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.isClosed,_that.closedAt,_that.stateSummary,_that.messages,_that.attachments,_that.outputRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary,  List<MessageModel> messages,  List<AttachmentModel> attachments, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)  $default,) {final _that = this;
switch (_that) {
case _ConversationDetailModel():
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.isClosed,_that.closedAt,_that.stateSummary,_that.messages,_that.attachments,_that.outputRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'closed_at')  String? closedAt, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary,  List<MessageModel> messages,  List<AttachmentModel> attachments, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,) {final _that = this;
switch (_that) {
case _ConversationDetailModel() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.isClosed,_that.closedAt,_that.stateSummary,_that.messages,_that.attachments,_that.outputRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationDetailModel implements ConversationDetailModel {
  const _ConversationDetailModel({@JsonKey(name: 'conversation_id') required this.conversationId, @JsonKey(name: 'persona_key') required this.personaKey, @JsonKey(name: 'current_phase') this.currentPhase = '', @JsonKey(name: 'is_closed') this.isClosed = false, @JsonKey(name: 'closed_at') this.closedAt, @JsonKey(name: 'state_summary') this.stateSummary = const StateSummaryModel(), final  List<MessageModel> messages = const [], final  List<AttachmentModel> attachments = const [], @JsonKey(name: 'output_refs') final  Map<String, dynamic> outputRefs = const {}}): _messages = messages,_attachments = attachments,_outputRefs = outputRefs;
  factory _ConversationDetailModel.fromJson(Map<String, dynamic> json) => _$ConversationDetailModelFromJson(json);

@override@JsonKey(name: 'conversation_id') final  int conversationId;
@override@JsonKey(name: 'persona_key') final  String personaKey;
@override@JsonKey(name: 'current_phase') final  String currentPhase;
@override@JsonKey(name: 'is_closed') final  bool isClosed;
@override@JsonKey(name: 'closed_at') final  String? closedAt;
@override@JsonKey(name: 'state_summary') final  StateSummaryModel stateSummary;
 final  List<MessageModel> _messages;
@override@JsonKey() List<MessageModel> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

 final  List<AttachmentModel> _attachments;
@override@JsonKey() List<AttachmentModel> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

 final  Map<String, dynamic> _outputRefs;
@override@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs {
  if (_outputRefs is EqualUnmodifiableMapView) return _outputRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outputRefs);
}


/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationDetailModelCopyWith<_ConversationDetailModel> get copyWith => __$ConversationDetailModelCopyWithImpl<_ConversationDetailModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationDetailModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationDetailModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary)&&const DeepCollectionEquality().equals(other._messages, _messages)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._outputRefs, _outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,currentPhase,isClosed,closedAt,stateSummary,const DeepCollectionEquality().hash(_messages),const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_outputRefs));

@override
String toString() {
  return 'ConversationDetailModel(conversationId: $conversationId, personaKey: $personaKey, currentPhase: $currentPhase, isClosed: $isClosed, closedAt: $closedAt, stateSummary: $stateSummary, messages: $messages, attachments: $attachments, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class _$ConversationDetailModelCopyWith<$Res> implements $ConversationDetailModelCopyWith<$Res> {
  factory _$ConversationDetailModelCopyWith(_ConversationDetailModel value, $Res Function(_ConversationDetailModel) _then) = __$ConversationDetailModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'persona_key') String personaKey,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'closed_at') String? closedAt,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary, List<MessageModel> messages, List<AttachmentModel> attachments,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});


@override $StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class __$ConversationDetailModelCopyWithImpl<$Res>
    implements _$ConversationDetailModelCopyWith<$Res> {
  __$ConversationDetailModelCopyWithImpl(this._self, this._then);

  final _ConversationDetailModel _self;
  final $Res Function(_ConversationDetailModel) _then;

/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? personaKey = null,Object? currentPhase = null,Object? isClosed = null,Object? closedAt = freezed,Object? stateSummary = null,Object? messages = null,Object? attachments = null,Object? outputRefs = null,}) {
  return _then(_ConversationDetailModel(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<MessageModel>,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<AttachmentModel>,outputRefs: null == outputRefs ? _self._outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of ConversationDetailModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateSummaryModelCopyWith<$Res> get stateSummary {
  
  return $StateSummaryModelCopyWith<$Res>(_self.stateSummary, (value) {
    return _then(_self.copyWith(stateSummary: value));
  });
}
}

// dart format on

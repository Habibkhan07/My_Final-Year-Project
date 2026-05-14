// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation_start_response_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ConversationStartResponseModel {

@JsonKey(name: 'conversation_id') int get conversationId;@JsonKey(name: 'persona_key') String get personaKey;@JsonKey(name: 'current_phase') String get currentPhase;@JsonKey(name: 'bot_message') String get botMessage;@JsonKey(name: 'ui_input_kind') String get uiInputKind;@JsonKey(name: 'ui_form_schema') FormSchemaModel? get uiFormSchema;@JsonKey(name: 'ui_hint') String get uiHint;@JsonKey(name: 'state_summary') StateSummaryModel get stateSummary;
/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationStartResponseModelCopyWith<ConversationStartResponseModel> get copyWith => _$ConversationStartResponseModelCopyWithImpl<ConversationStartResponseModel>(this as ConversationStartResponseModel, _$identity);

  /// Serializes this ConversationStartResponseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationStartResponseModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.botMessage, botMessage) || other.botMessage == botMessage)&&(identical(other.uiInputKind, uiInputKind) || other.uiInputKind == uiInputKind)&&(identical(other.uiFormSchema, uiFormSchema) || other.uiFormSchema == uiFormSchema)&&(identical(other.uiHint, uiHint) || other.uiHint == uiHint)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,currentPhase,botMessage,uiInputKind,uiFormSchema,uiHint,stateSummary);

@override
String toString() {
  return 'ConversationStartResponseModel(conversationId: $conversationId, personaKey: $personaKey, currentPhase: $currentPhase, botMessage: $botMessage, uiInputKind: $uiInputKind, uiFormSchema: $uiFormSchema, uiHint: $uiHint, stateSummary: $stateSummary)';
}


}

/// @nodoc
abstract mixin class $ConversationStartResponseModelCopyWith<$Res>  {
  factory $ConversationStartResponseModelCopyWith(ConversationStartResponseModel value, $Res Function(ConversationStartResponseModel) _then) = _$ConversationStartResponseModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'persona_key') String personaKey,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'bot_message') String botMessage,@JsonKey(name: 'ui_input_kind') String uiInputKind,@JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,@JsonKey(name: 'ui_hint') String uiHint,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary
});


$FormSchemaModelCopyWith<$Res>? get uiFormSchema;$StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class _$ConversationStartResponseModelCopyWithImpl<$Res>
    implements $ConversationStartResponseModelCopyWith<$Res> {
  _$ConversationStartResponseModelCopyWithImpl(this._self, this._then);

  final ConversationStartResponseModel _self;
  final $Res Function(ConversationStartResponseModel) _then;

/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? personaKey = null,Object? currentPhase = null,Object? botMessage = null,Object? uiInputKind = null,Object? uiFormSchema = freezed,Object? uiHint = null,Object? stateSummary = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,botMessage: null == botMessage ? _self.botMessage : botMessage // ignore: cast_nullable_to_non_nullable
as String,uiInputKind: null == uiInputKind ? _self.uiInputKind : uiInputKind // ignore: cast_nullable_to_non_nullable
as String,uiFormSchema: freezed == uiFormSchema ? _self.uiFormSchema : uiFormSchema // ignore: cast_nullable_to_non_nullable
as FormSchemaModel?,uiHint: null == uiHint ? _self.uiHint : uiHint // ignore: cast_nullable_to_non_nullable
as String,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,
  ));
}
/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FormSchemaModelCopyWith<$Res>? get uiFormSchema {
    if (_self.uiFormSchema == null) {
    return null;
  }

  return $FormSchemaModelCopyWith<$Res>(_self.uiFormSchema!, (value) {
    return _then(_self.copyWith(uiFormSchema: value));
  });
}/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateSummaryModelCopyWith<$Res> get stateSummary {
  
  return $StateSummaryModelCopyWith<$Res>(_self.stateSummary, (value) {
    return _then(_self.copyWith(stateSummary: value));
  });
}
}


/// Adds pattern-matching-related methods to [ConversationStartResponseModel].
extension ConversationStartResponseModelPatterns on ConversationStartResponseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationStartResponseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationStartResponseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationStartResponseModel value)  $default,){
final _that = this;
switch (_that) {
case _ConversationStartResponseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationStartResponseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationStartResponseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationStartResponseModel() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary)  $default,) {final _that = this;
switch (_that) {
case _ConversationStartResponseModel():
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'persona_key')  String personaKey, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary)?  $default,) {final _that = this;
switch (_that) {
case _ConversationStartResponseModel() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationStartResponseModel implements ConversationStartResponseModel {
  const _ConversationStartResponseModel({@JsonKey(name: 'conversation_id') required this.conversationId, @JsonKey(name: 'persona_key') required this.personaKey, @JsonKey(name: 'current_phase') this.currentPhase = '', @JsonKey(name: 'bot_message') this.botMessage = '', @JsonKey(name: 'ui_input_kind') this.uiInputKind = 'text', @JsonKey(name: 'ui_form_schema') this.uiFormSchema, @JsonKey(name: 'ui_hint') this.uiHint = '', @JsonKey(name: 'state_summary') this.stateSummary = const StateSummaryModel()});
  factory _ConversationStartResponseModel.fromJson(Map<String, dynamic> json) => _$ConversationStartResponseModelFromJson(json);

@override@JsonKey(name: 'conversation_id') final  int conversationId;
@override@JsonKey(name: 'persona_key') final  String personaKey;
@override@JsonKey(name: 'current_phase') final  String currentPhase;
@override@JsonKey(name: 'bot_message') final  String botMessage;
@override@JsonKey(name: 'ui_input_kind') final  String uiInputKind;
@override@JsonKey(name: 'ui_form_schema') final  FormSchemaModel? uiFormSchema;
@override@JsonKey(name: 'ui_hint') final  String uiHint;
@override@JsonKey(name: 'state_summary') final  StateSummaryModel stateSummary;

/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationStartResponseModelCopyWith<_ConversationStartResponseModel> get copyWith => __$ConversationStartResponseModelCopyWithImpl<_ConversationStartResponseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationStartResponseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationStartResponseModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.botMessage, botMessage) || other.botMessage == botMessage)&&(identical(other.uiInputKind, uiInputKind) || other.uiInputKind == uiInputKind)&&(identical(other.uiFormSchema, uiFormSchema) || other.uiFormSchema == uiFormSchema)&&(identical(other.uiHint, uiHint) || other.uiHint == uiHint)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,currentPhase,botMessage,uiInputKind,uiFormSchema,uiHint,stateSummary);

@override
String toString() {
  return 'ConversationStartResponseModel(conversationId: $conversationId, personaKey: $personaKey, currentPhase: $currentPhase, botMessage: $botMessage, uiInputKind: $uiInputKind, uiFormSchema: $uiFormSchema, uiHint: $uiHint, stateSummary: $stateSummary)';
}


}

/// @nodoc
abstract mixin class _$ConversationStartResponseModelCopyWith<$Res> implements $ConversationStartResponseModelCopyWith<$Res> {
  factory _$ConversationStartResponseModelCopyWith(_ConversationStartResponseModel value, $Res Function(_ConversationStartResponseModel) _then) = __$ConversationStartResponseModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'persona_key') String personaKey,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'bot_message') String botMessage,@JsonKey(name: 'ui_input_kind') String uiInputKind,@JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,@JsonKey(name: 'ui_hint') String uiHint,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary
});


@override $FormSchemaModelCopyWith<$Res>? get uiFormSchema;@override $StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class __$ConversationStartResponseModelCopyWithImpl<$Res>
    implements _$ConversationStartResponseModelCopyWith<$Res> {
  __$ConversationStartResponseModelCopyWithImpl(this._self, this._then);

  final _ConversationStartResponseModel _self;
  final $Res Function(_ConversationStartResponseModel) _then;

/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? personaKey = null,Object? currentPhase = null,Object? botMessage = null,Object? uiInputKind = null,Object? uiFormSchema = freezed,Object? uiHint = null,Object? stateSummary = null,}) {
  return _then(_ConversationStartResponseModel(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,botMessage: null == botMessage ? _self.botMessage : botMessage // ignore: cast_nullable_to_non_nullable
as String,uiInputKind: null == uiInputKind ? _self.uiInputKind : uiInputKind // ignore: cast_nullable_to_non_nullable
as String,uiFormSchema: freezed == uiFormSchema ? _self.uiFormSchema : uiFormSchema // ignore: cast_nullable_to_non_nullable
as FormSchemaModel?,uiHint: null == uiHint ? _self.uiHint : uiHint // ignore: cast_nullable_to_non_nullable
as String,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,
  ));
}

/// Create a copy of ConversationStartResponseModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FormSchemaModelCopyWith<$Res>? get uiFormSchema {
    if (_self.uiFormSchema == null) {
    return null;
  }

  return $FormSchemaModelCopyWith<$Res>(_self.uiFormSchema!, (value) {
    return _then(_self.copyWith(uiFormSchema: value));
  });
}/// Create a copy of ConversationStartResponseModel
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

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'turn_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TurnResultModel {

@JsonKey(name: 'conversation_id') int get conversationId;@JsonKey(name: 'current_phase') String get currentPhase;@JsonKey(name: 'bot_message') String get botMessage;@JsonKey(name: 'ui_input_kind') String get uiInputKind;@JsonKey(name: 'ui_form_schema') FormSchemaModel? get uiFormSchema;@JsonKey(name: 'ui_hint') String get uiHint;@JsonKey(name: 'state_summary') StateSummaryModel get stateSummary;@JsonKey(name: 'is_closed') bool get isClosed;// Wire shape: `{"support_ticket_id": <int>}` once closed, else `{}`.
// We carry the raw map because the model's caller (the mapper)
// already knows how to read it through `OutputRefsModel.fromJson`.
@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs;
/// Create a copy of TurnResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TurnResultModelCopyWith<TurnResultModel> get copyWith => _$TurnResultModelCopyWithImpl<TurnResultModel>(this as TurnResultModel, _$identity);

  /// Serializes this TurnResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TurnResultModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.botMessage, botMessage) || other.botMessage == botMessage)&&(identical(other.uiInputKind, uiInputKind) || other.uiInputKind == uiInputKind)&&(identical(other.uiFormSchema, uiFormSchema) || other.uiFormSchema == uiFormSchema)&&(identical(other.uiHint, uiHint) || other.uiHint == uiHint)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other.outputRefs, outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,currentPhase,botMessage,uiInputKind,uiFormSchema,uiHint,stateSummary,isClosed,const DeepCollectionEquality().hash(outputRefs));

@override
String toString() {
  return 'TurnResultModel(conversationId: $conversationId, currentPhase: $currentPhase, botMessage: $botMessage, uiInputKind: $uiInputKind, uiFormSchema: $uiFormSchema, uiHint: $uiHint, stateSummary: $stateSummary, isClosed: $isClosed, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class $TurnResultModelCopyWith<$Res>  {
  factory $TurnResultModelCopyWith(TurnResultModel value, $Res Function(TurnResultModel) _then) = _$TurnResultModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'bot_message') String botMessage,@JsonKey(name: 'ui_input_kind') String uiInputKind,@JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,@JsonKey(name: 'ui_hint') String uiHint,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});


$FormSchemaModelCopyWith<$Res>? get uiFormSchema;$StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class _$TurnResultModelCopyWithImpl<$Res>
    implements $TurnResultModelCopyWith<$Res> {
  _$TurnResultModelCopyWithImpl(this._self, this._then);

  final TurnResultModel _self;
  final $Res Function(TurnResultModel) _then;

/// Create a copy of TurnResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? currentPhase = null,Object? botMessage = null,Object? uiInputKind = null,Object? uiFormSchema = freezed,Object? uiHint = null,Object? stateSummary = null,Object? isClosed = null,Object? outputRefs = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,botMessage: null == botMessage ? _self.botMessage : botMessage // ignore: cast_nullable_to_non_nullable
as String,uiInputKind: null == uiInputKind ? _self.uiInputKind : uiInputKind // ignore: cast_nullable_to_non_nullable
as String,uiFormSchema: freezed == uiFormSchema ? _self.uiFormSchema : uiFormSchema // ignore: cast_nullable_to_non_nullable
as FormSchemaModel?,uiHint: null == uiHint ? _self.uiHint : uiHint // ignore: cast_nullable_to_non_nullable
as String,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,outputRefs: null == outputRefs ? _self.outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}
/// Create a copy of TurnResultModel
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
}/// Create a copy of TurnResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StateSummaryModelCopyWith<$Res> get stateSummary {
  
  return $StateSummaryModelCopyWith<$Res>(_self.stateSummary, (value) {
    return _then(_self.copyWith(stateSummary: value));
  });
}
}


/// Adds pattern-matching-related methods to [TurnResultModel].
extension TurnResultModelPatterns on TurnResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TurnResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TurnResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TurnResultModel value)  $default,){
final _that = this;
switch (_that) {
case _TurnResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TurnResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _TurnResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TurnResultModel() when $default != null:
return $default(_that.conversationId,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary,_that.isClosed,_that.outputRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)  $default,) {final _that = this;
switch (_that) {
case _TurnResultModel():
return $default(_that.conversationId,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary,_that.isClosed,_that.outputRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversation_id')  int conversationId, @JsonKey(name: 'current_phase')  String currentPhase, @JsonKey(name: 'bot_message')  String botMessage, @JsonKey(name: 'ui_input_kind')  String uiInputKind, @JsonKey(name: 'ui_form_schema')  FormSchemaModel? uiFormSchema, @JsonKey(name: 'ui_hint')  String uiHint, @JsonKey(name: 'state_summary')  StateSummaryModel stateSummary, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'output_refs')  Map<String, dynamic> outputRefs)?  $default,) {final _that = this;
switch (_that) {
case _TurnResultModel() when $default != null:
return $default(_that.conversationId,_that.currentPhase,_that.botMessage,_that.uiInputKind,_that.uiFormSchema,_that.uiHint,_that.stateSummary,_that.isClosed,_that.outputRefs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TurnResultModel implements TurnResultModel {
  const _TurnResultModel({@JsonKey(name: 'conversation_id') required this.conversationId, @JsonKey(name: 'current_phase') this.currentPhase = '', @JsonKey(name: 'bot_message') this.botMessage = '', @JsonKey(name: 'ui_input_kind') this.uiInputKind = 'text', @JsonKey(name: 'ui_form_schema') this.uiFormSchema, @JsonKey(name: 'ui_hint') this.uiHint = '', @JsonKey(name: 'state_summary') this.stateSummary = const StateSummaryModel(), @JsonKey(name: 'is_closed') this.isClosed = false, @JsonKey(name: 'output_refs') final  Map<String, dynamic> outputRefs = const {}}): _outputRefs = outputRefs;
  factory _TurnResultModel.fromJson(Map<String, dynamic> json) => _$TurnResultModelFromJson(json);

@override@JsonKey(name: 'conversation_id') final  int conversationId;
@override@JsonKey(name: 'current_phase') final  String currentPhase;
@override@JsonKey(name: 'bot_message') final  String botMessage;
@override@JsonKey(name: 'ui_input_kind') final  String uiInputKind;
@override@JsonKey(name: 'ui_form_schema') final  FormSchemaModel? uiFormSchema;
@override@JsonKey(name: 'ui_hint') final  String uiHint;
@override@JsonKey(name: 'state_summary') final  StateSummaryModel stateSummary;
@override@JsonKey(name: 'is_closed') final  bool isClosed;
// Wire shape: `{"support_ticket_id": <int>}` once closed, else `{}`.
// We carry the raw map because the model's caller (the mapper)
// already knows how to read it through `OutputRefsModel.fromJson`.
 final  Map<String, dynamic> _outputRefs;
// Wire shape: `{"support_ticket_id": <int>}` once closed, else `{}`.
// We carry the raw map because the model's caller (the mapper)
// already knows how to read it through `OutputRefsModel.fromJson`.
@override@JsonKey(name: 'output_refs') Map<String, dynamic> get outputRefs {
  if (_outputRefs is EqualUnmodifiableMapView) return _outputRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_outputRefs);
}


/// Create a copy of TurnResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TurnResultModelCopyWith<_TurnResultModel> get copyWith => __$TurnResultModelCopyWithImpl<_TurnResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TurnResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TurnResultModel&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.currentPhase, currentPhase) || other.currentPhase == currentPhase)&&(identical(other.botMessage, botMessage) || other.botMessage == botMessage)&&(identical(other.uiInputKind, uiInputKind) || other.uiInputKind == uiInputKind)&&(identical(other.uiFormSchema, uiFormSchema) || other.uiFormSchema == uiFormSchema)&&(identical(other.uiHint, uiHint) || other.uiHint == uiHint)&&(identical(other.stateSummary, stateSummary) || other.stateSummary == stateSummary)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other._outputRefs, _outputRefs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,currentPhase,botMessage,uiInputKind,uiFormSchema,uiHint,stateSummary,isClosed,const DeepCollectionEquality().hash(_outputRefs));

@override
String toString() {
  return 'TurnResultModel(conversationId: $conversationId, currentPhase: $currentPhase, botMessage: $botMessage, uiInputKind: $uiInputKind, uiFormSchema: $uiFormSchema, uiHint: $uiHint, stateSummary: $stateSummary, isClosed: $isClosed, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class _$TurnResultModelCopyWith<$Res> implements $TurnResultModelCopyWith<$Res> {
  factory _$TurnResultModelCopyWith(_TurnResultModel value, $Res Function(_TurnResultModel) _then) = __$TurnResultModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversation_id') int conversationId,@JsonKey(name: 'current_phase') String currentPhase,@JsonKey(name: 'bot_message') String botMessage,@JsonKey(name: 'ui_input_kind') String uiInputKind,@JsonKey(name: 'ui_form_schema') FormSchemaModel? uiFormSchema,@JsonKey(name: 'ui_hint') String uiHint,@JsonKey(name: 'state_summary') StateSummaryModel stateSummary,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'output_refs') Map<String, dynamic> outputRefs
});


@override $FormSchemaModelCopyWith<$Res>? get uiFormSchema;@override $StateSummaryModelCopyWith<$Res> get stateSummary;

}
/// @nodoc
class __$TurnResultModelCopyWithImpl<$Res>
    implements _$TurnResultModelCopyWith<$Res> {
  __$TurnResultModelCopyWithImpl(this._self, this._then);

  final _TurnResultModel _self;
  final $Res Function(_TurnResultModel) _then;

/// Create a copy of TurnResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? currentPhase = null,Object? botMessage = null,Object? uiInputKind = null,Object? uiFormSchema = freezed,Object? uiHint = null,Object? stateSummary = null,Object? isClosed = null,Object? outputRefs = null,}) {
  return _then(_TurnResultModel(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,currentPhase: null == currentPhase ? _self.currentPhase : currentPhase // ignore: cast_nullable_to_non_nullable
as String,botMessage: null == botMessage ? _self.botMessage : botMessage // ignore: cast_nullable_to_non_nullable
as String,uiInputKind: null == uiInputKind ? _self.uiInputKind : uiInputKind // ignore: cast_nullable_to_non_nullable
as String,uiFormSchema: freezed == uiFormSchema ? _self.uiFormSchema : uiFormSchema // ignore: cast_nullable_to_non_nullable
as FormSchemaModel?,uiHint: null == uiHint ? _self.uiHint : uiHint // ignore: cast_nullable_to_non_nullable
as String,stateSummary: null == stateSummary ? _self.stateSummary : stateSummary // ignore: cast_nullable_to_non_nullable
as StateSummaryModel,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,outputRefs: null == outputRefs ? _self._outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

/// Create a copy of TurnResultModel
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
}/// Create a copy of TurnResultModel
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

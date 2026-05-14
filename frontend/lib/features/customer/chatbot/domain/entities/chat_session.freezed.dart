// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatSession {

 int get conversationId; String get personaKey; ChatPhase get phase; List<ChatMessage> get transcript; UiDirective get directive; int get attachmentsCount; bool get isClosed; DateTime? get closedAt; OutputRefs? get outputRefs;
/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatSessionCopyWith<ChatSession> get copyWith => _$ChatSessionCopyWithImpl<ChatSession>(this as ChatSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatSession&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.transcript, transcript)&&(identical(other.directive, directive) || other.directive == directive)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.outputRefs, outputRefs) || other.outputRefs == outputRefs));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,phase,const DeepCollectionEquality().hash(transcript),directive,attachmentsCount,isClosed,closedAt,outputRefs);

@override
String toString() {
  return 'ChatSession(conversationId: $conversationId, personaKey: $personaKey, phase: $phase, transcript: $transcript, directive: $directive, attachmentsCount: $attachmentsCount, isClosed: $isClosed, closedAt: $closedAt, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class $ChatSessionCopyWith<$Res>  {
  factory $ChatSessionCopyWith(ChatSession value, $Res Function(ChatSession) _then) = _$ChatSessionCopyWithImpl;
@useResult
$Res call({
 int conversationId, String personaKey, ChatPhase phase, List<ChatMessage> transcript, UiDirective directive, int attachmentsCount, bool isClosed, DateTime? closedAt, OutputRefs? outputRefs
});


$OutputRefsCopyWith<$Res>? get outputRefs;

}
/// @nodoc
class _$ChatSessionCopyWithImpl<$Res>
    implements $ChatSessionCopyWith<$Res> {
  _$ChatSessionCopyWithImpl(this._self, this._then);

  final ChatSession _self;
  final $Res Function(ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? personaKey = null,Object? phase = null,Object? transcript = null,Object? directive = null,Object? attachmentsCount = null,Object? isClosed = null,Object? closedAt = freezed,Object? outputRefs = freezed,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,directive: null == directive ? _self.directive : directive // ignore: cast_nullable_to_non_nullable
as UiDirective,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,outputRefs: freezed == outputRefs ? _self.outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as OutputRefs?,
  ));
}
/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutputRefsCopyWith<$Res>? get outputRefs {
    if (_self.outputRefs == null) {
    return null;
  }

  return $OutputRefsCopyWith<$Res>(_self.outputRefs!, (value) {
    return _then(_self.copyWith(outputRefs: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatSession].
extension ChatSessionPatterns on ChatSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatSession value)  $default,){
final _that = this;
switch (_that) {
case _ChatSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatSession value)?  $default,){
final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int conversationId,  String personaKey,  ChatPhase phase,  List<ChatMessage> transcript,  UiDirective directive,  int attachmentsCount,  bool isClosed,  DateTime? closedAt,  OutputRefs? outputRefs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.phase,_that.transcript,_that.directive,_that.attachmentsCount,_that.isClosed,_that.closedAt,_that.outputRefs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int conversationId,  String personaKey,  ChatPhase phase,  List<ChatMessage> transcript,  UiDirective directive,  int attachmentsCount,  bool isClosed,  DateTime? closedAt,  OutputRefs? outputRefs)  $default,) {final _that = this;
switch (_that) {
case _ChatSession():
return $default(_that.conversationId,_that.personaKey,_that.phase,_that.transcript,_that.directive,_that.attachmentsCount,_that.isClosed,_that.closedAt,_that.outputRefs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int conversationId,  String personaKey,  ChatPhase phase,  List<ChatMessage> transcript,  UiDirective directive,  int attachmentsCount,  bool isClosed,  DateTime? closedAt,  OutputRefs? outputRefs)?  $default,) {final _that = this;
switch (_that) {
case _ChatSession() when $default != null:
return $default(_that.conversationId,_that.personaKey,_that.phase,_that.transcript,_that.directive,_that.attachmentsCount,_that.isClosed,_that.closedAt,_that.outputRefs);case _:
  return null;

}
}

}

/// @nodoc


class _ChatSession implements ChatSession {
  const _ChatSession({required this.conversationId, required this.personaKey, required this.phase, required final  List<ChatMessage> transcript, required this.directive, required this.attachmentsCount, required this.isClosed, this.closedAt, this.outputRefs}): _transcript = transcript;
  

@override final  int conversationId;
@override final  String personaKey;
@override final  ChatPhase phase;
 final  List<ChatMessage> _transcript;
@override List<ChatMessage> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override final  UiDirective directive;
@override final  int attachmentsCount;
@override final  bool isClosed;
@override final  DateTime? closedAt;
@override final  OutputRefs? outputRefs;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatSessionCopyWith<_ChatSession> get copyWith => __$ChatSessionCopyWithImpl<_ChatSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatSession&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.personaKey, personaKey) || other.personaKey == personaKey)&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.directive, directive) || other.directive == directive)&&(identical(other.attachmentsCount, attachmentsCount) || other.attachmentsCount == attachmentsCount)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.outputRefs, outputRefs) || other.outputRefs == outputRefs));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,personaKey,phase,const DeepCollectionEquality().hash(_transcript),directive,attachmentsCount,isClosed,closedAt,outputRefs);

@override
String toString() {
  return 'ChatSession(conversationId: $conversationId, personaKey: $personaKey, phase: $phase, transcript: $transcript, directive: $directive, attachmentsCount: $attachmentsCount, isClosed: $isClosed, closedAt: $closedAt, outputRefs: $outputRefs)';
}


}

/// @nodoc
abstract mixin class _$ChatSessionCopyWith<$Res> implements $ChatSessionCopyWith<$Res> {
  factory _$ChatSessionCopyWith(_ChatSession value, $Res Function(_ChatSession) _then) = __$ChatSessionCopyWithImpl;
@override @useResult
$Res call({
 int conversationId, String personaKey, ChatPhase phase, List<ChatMessage> transcript, UiDirective directive, int attachmentsCount, bool isClosed, DateTime? closedAt, OutputRefs? outputRefs
});


@override $OutputRefsCopyWith<$Res>? get outputRefs;

}
/// @nodoc
class __$ChatSessionCopyWithImpl<$Res>
    implements _$ChatSessionCopyWith<$Res> {
  __$ChatSessionCopyWithImpl(this._self, this._then);

  final _ChatSession _self;
  final $Res Function(_ChatSession) _then;

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? personaKey = null,Object? phase = null,Object? transcript = null,Object? directive = null,Object? attachmentsCount = null,Object? isClosed = null,Object? closedAt = freezed,Object? outputRefs = freezed,}) {
  return _then(_ChatSession(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,personaKey: null == personaKey ? _self.personaKey : personaKey // ignore: cast_nullable_to_non_nullable
as String,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as ChatPhase,transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,directive: null == directive ? _self.directive : directive // ignore: cast_nullable_to_non_nullable
as UiDirective,attachmentsCount: null == attachmentsCount ? _self.attachmentsCount : attachmentsCount // ignore: cast_nullable_to_non_nullable
as int,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,outputRefs: freezed == outputRefs ? _self.outputRefs : outputRefs // ignore: cast_nullable_to_non_nullable
as OutputRefs?,
  ));
}

/// Create a copy of ChatSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OutputRefsCopyWith<$Res>? get outputRefs {
    if (_self.outputRefs == null) {
    return null;
  }

  return $OutputRefsCopyWith<$Res>(_self.outputRefs!, (value) {
    return _then(_self.copyWith(outputRefs: value));
  });
}
}

// dart format on

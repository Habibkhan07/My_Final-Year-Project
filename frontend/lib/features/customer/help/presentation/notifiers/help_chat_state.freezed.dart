// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_chat_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HelpChatState {

 int get conversationId; List<ChatMessage> get transcript; bool get isSending;
/// Create a copy of HelpChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpChatStateCopyWith<HelpChatState> get copyWith => _$HelpChatStateCopyWithImpl<HelpChatState>(this as HelpChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpChatState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&const DeepCollectionEquality().equals(other.transcript, transcript)&&(identical(other.isSending, isSending) || other.isSending == isSending));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,const DeepCollectionEquality().hash(transcript),isSending);

@override
String toString() {
  return 'HelpChatState(conversationId: $conversationId, transcript: $transcript, isSending: $isSending)';
}


}

/// @nodoc
abstract mixin class $HelpChatStateCopyWith<$Res>  {
  factory $HelpChatStateCopyWith(HelpChatState value, $Res Function(HelpChatState) _then) = _$HelpChatStateCopyWithImpl;
@useResult
$Res call({
 int conversationId, List<ChatMessage> transcript, bool isSending
});




}
/// @nodoc
class _$HelpChatStateCopyWithImpl<$Res>
    implements $HelpChatStateCopyWith<$Res> {
  _$HelpChatStateCopyWithImpl(this._self, this._then);

  final HelpChatState _self;
  final $Res Function(HelpChatState) _then;

/// Create a copy of HelpChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? transcript = null,Object? isSending = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [HelpChatState].
extension HelpChatStatePatterns on HelpChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpChatState value)  $default,){
final _that = this;
switch (_that) {
case _HelpChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpChatState value)?  $default,){
final _that = this;
switch (_that) {
case _HelpChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int conversationId,  List<ChatMessage> transcript,  bool isSending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpChatState() when $default != null:
return $default(_that.conversationId,_that.transcript,_that.isSending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int conversationId,  List<ChatMessage> transcript,  bool isSending)  $default,) {final _that = this;
switch (_that) {
case _HelpChatState():
return $default(_that.conversationId,_that.transcript,_that.isSending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int conversationId,  List<ChatMessage> transcript,  bool isSending)?  $default,) {final _that = this;
switch (_that) {
case _HelpChatState() when $default != null:
return $default(_that.conversationId,_that.transcript,_that.isSending);case _:
  return null;

}
}

}

/// @nodoc


class _HelpChatState implements HelpChatState {
  const _HelpChatState({required this.conversationId, required final  List<ChatMessage> transcript, this.isSending = false}): _transcript = transcript;
  

@override final  int conversationId;
 final  List<ChatMessage> _transcript;
@override List<ChatMessage> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override@JsonKey() final  bool isSending;

/// Create a copy of HelpChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpChatStateCopyWith<_HelpChatState> get copyWith => __$HelpChatStateCopyWithImpl<_HelpChatState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpChatState&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.isSending, isSending) || other.isSending == isSending));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,const DeepCollectionEquality().hash(_transcript),isSending);

@override
String toString() {
  return 'HelpChatState(conversationId: $conversationId, transcript: $transcript, isSending: $isSending)';
}


}

/// @nodoc
abstract mixin class _$HelpChatStateCopyWith<$Res> implements $HelpChatStateCopyWith<$Res> {
  factory _$HelpChatStateCopyWith(_HelpChatState value, $Res Function(_HelpChatState) _then) = __$HelpChatStateCopyWithImpl;
@override @useResult
$Res call({
 int conversationId, List<ChatMessage> transcript, bool isSending
});




}
/// @nodoc
class __$HelpChatStateCopyWithImpl<$Res>
    implements _$HelpChatStateCopyWith<$Res> {
  __$HelpChatStateCopyWithImpl(this._self, this._then);

  final _HelpChatState _self;
  final $Res Function(_HelpChatState) _then;

/// Create a copy of HelpChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? transcript = null,Object? isSending = null,}) {
  return _then(_HelpChatState(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as int,transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

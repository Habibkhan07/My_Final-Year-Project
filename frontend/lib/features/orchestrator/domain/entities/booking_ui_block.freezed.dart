// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_ui_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookingUiBlock {

/// Top-of-screen status badge text. e.g. "Confirmed", "On the way".
 String get statusLabel;/// Prose for the body slot. May be empty for terminal states where
/// the body is purely visual (timeline + receipt summary).
 String get bodyText;/// Call-to-action button rendered at the bottom. Null when the user's
/// role has no actionable verb at this status (e.g. customer waiting
/// for tech to mark arrival).
 BookingUiAction? get primaryAction;/// Secondary actions rendered as text buttons above the primary.
/// Order is server-controlled; widgets render verbatim.
 List<BookingUiAction> get secondaryActions;/// Whether to render the live-tracking widget (session 4 fills in).
/// Currently only true for EN_ROUTE / ARRIVED on customer view.
 bool get showTracking;/// Whether to render the quote line-item card.
 bool get showQuoteCard;/// Whether to surface the "Open dispute" button. Customer-side after
/// IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW per
/// `bookings/services/orchestrator.open_dispute` validation.
 bool get showDisputeButton;/// Background tint for the header slot. Maps to a design token in
/// the widget — never to a literal color in code.
 BookingUiTone get tone;
/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiBlockCopyWith<BookingUiBlock> get copyWith => _$BookingUiBlockCopyWithImpl<BookingUiBlock>(this as BookingUiBlock, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUiBlock&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.bodyText, bodyText) || other.bodyText == bodyText)&&(identical(other.primaryAction, primaryAction) || other.primaryAction == primaryAction)&&const DeepCollectionEquality().equals(other.secondaryActions, secondaryActions)&&(identical(other.showTracking, showTracking) || other.showTracking == showTracking)&&(identical(other.showQuoteCard, showQuoteCard) || other.showQuoteCard == showQuoteCard)&&(identical(other.showDisputeButton, showDisputeButton) || other.showDisputeButton == showDisputeButton)&&(identical(other.tone, tone) || other.tone == tone));
}


@override
int get hashCode => Object.hash(runtimeType,statusLabel,bodyText,primaryAction,const DeepCollectionEquality().hash(secondaryActions),showTracking,showQuoteCard,showDisputeButton,tone);

@override
String toString() {
  return 'BookingUiBlock(statusLabel: $statusLabel, bodyText: $bodyText, primaryAction: $primaryAction, secondaryActions: $secondaryActions, showTracking: $showTracking, showQuoteCard: $showQuoteCard, showDisputeButton: $showDisputeButton, tone: $tone)';
}


}

/// @nodoc
abstract mixin class $BookingUiBlockCopyWith<$Res>  {
  factory $BookingUiBlockCopyWith(BookingUiBlock value, $Res Function(BookingUiBlock) _then) = _$BookingUiBlockCopyWithImpl;
@useResult
$Res call({
 String statusLabel, String bodyText, BookingUiAction? primaryAction, List<BookingUiAction> secondaryActions, bool showTracking, bool showQuoteCard, bool showDisputeButton, BookingUiTone tone
});


$BookingUiActionCopyWith<$Res>? get primaryAction;

}
/// @nodoc
class _$BookingUiBlockCopyWithImpl<$Res>
    implements $BookingUiBlockCopyWith<$Res> {
  _$BookingUiBlockCopyWithImpl(this._self, this._then);

  final BookingUiBlock _self;
  final $Res Function(BookingUiBlock) _then;

/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? statusLabel = null,Object? bodyText = null,Object? primaryAction = freezed,Object? secondaryActions = null,Object? showTracking = null,Object? showQuoteCard = null,Object? showDisputeButton = null,Object? tone = null,}) {
  return _then(_self.copyWith(
statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,bodyText: null == bodyText ? _self.bodyText : bodyText // ignore: cast_nullable_to_non_nullable
as String,primaryAction: freezed == primaryAction ? _self.primaryAction : primaryAction // ignore: cast_nullable_to_non_nullable
as BookingUiAction?,secondaryActions: null == secondaryActions ? _self.secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<BookingUiAction>,showTracking: null == showTracking ? _self.showTracking : showTracking // ignore: cast_nullable_to_non_nullable
as bool,showQuoteCard: null == showQuoteCard ? _self.showQuoteCard : showQuoteCard // ignore: cast_nullable_to_non_nullable
as bool,showDisputeButton: null == showDisputeButton ? _self.showDisputeButton : showDisputeButton // ignore: cast_nullable_to_non_nullable
as bool,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as BookingUiTone,
  ));
}
/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiActionCopyWith<$Res>? get primaryAction {
    if (_self.primaryAction == null) {
    return null;
  }

  return $BookingUiActionCopyWith<$Res>(_self.primaryAction!, (value) {
    return _then(_self.copyWith(primaryAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingUiBlock].
extension BookingUiBlockPatterns on BookingUiBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUiBlock value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUiBlock() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUiBlock value)  $default,){
final _that = this;
switch (_that) {
case _BookingUiBlock():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUiBlock value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUiBlock() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String statusLabel,  String bodyText,  BookingUiAction? primaryAction,  List<BookingUiAction> secondaryActions,  bool showTracking,  bool showQuoteCard,  bool showDisputeButton,  BookingUiTone tone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingUiBlock() when $default != null:
return $default(_that.statusLabel,_that.bodyText,_that.primaryAction,_that.secondaryActions,_that.showTracking,_that.showQuoteCard,_that.showDisputeButton,_that.tone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String statusLabel,  String bodyText,  BookingUiAction? primaryAction,  List<BookingUiAction> secondaryActions,  bool showTracking,  bool showQuoteCard,  bool showDisputeButton,  BookingUiTone tone)  $default,) {final _that = this;
switch (_that) {
case _BookingUiBlock():
return $default(_that.statusLabel,_that.bodyText,_that.primaryAction,_that.secondaryActions,_that.showTracking,_that.showQuoteCard,_that.showDisputeButton,_that.tone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String statusLabel,  String bodyText,  BookingUiAction? primaryAction,  List<BookingUiAction> secondaryActions,  bool showTracking,  bool showQuoteCard,  bool showDisputeButton,  BookingUiTone tone)?  $default,) {final _that = this;
switch (_that) {
case _BookingUiBlock() when $default != null:
return $default(_that.statusLabel,_that.bodyText,_that.primaryAction,_that.secondaryActions,_that.showTracking,_that.showQuoteCard,_that.showDisputeButton,_that.tone);case _:
  return null;

}
}

}

/// @nodoc


class _BookingUiBlock implements BookingUiBlock {
  const _BookingUiBlock({required this.statusLabel, required this.bodyText, this.primaryAction, final  List<BookingUiAction> secondaryActions = const [], required this.showTracking, required this.showQuoteCard, required this.showDisputeButton, required this.tone}): _secondaryActions = secondaryActions;
  

/// Top-of-screen status badge text. e.g. "Confirmed", "On the way".
@override final  String statusLabel;
/// Prose for the body slot. May be empty for terminal states where
/// the body is purely visual (timeline + receipt summary).
@override final  String bodyText;
/// Call-to-action button rendered at the bottom. Null when the user's
/// role has no actionable verb at this status (e.g. customer waiting
/// for tech to mark arrival).
@override final  BookingUiAction? primaryAction;
/// Secondary actions rendered as text buttons above the primary.
/// Order is server-controlled; widgets render verbatim.
 final  List<BookingUiAction> _secondaryActions;
/// Secondary actions rendered as text buttons above the primary.
/// Order is server-controlled; widgets render verbatim.
@override@JsonKey() List<BookingUiAction> get secondaryActions {
  if (_secondaryActions is EqualUnmodifiableListView) return _secondaryActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryActions);
}

/// Whether to render the live-tracking widget (session 4 fills in).
/// Currently only true for EN_ROUTE / ARRIVED on customer view.
@override final  bool showTracking;
/// Whether to render the quote line-item card.
@override final  bool showQuoteCard;
/// Whether to surface the "Open dispute" button. Customer-side after
/// IN_PROGRESS / COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW per
/// `bookings/services/orchestrator.open_dispute` validation.
@override final  bool showDisputeButton;
/// Background tint for the header slot. Maps to a design token in
/// the widget — never to a literal color in code.
@override final  BookingUiTone tone;

/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiBlockCopyWith<_BookingUiBlock> get copyWith => __$BookingUiBlockCopyWithImpl<_BookingUiBlock>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUiBlock&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.bodyText, bodyText) || other.bodyText == bodyText)&&(identical(other.primaryAction, primaryAction) || other.primaryAction == primaryAction)&&const DeepCollectionEquality().equals(other._secondaryActions, _secondaryActions)&&(identical(other.showTracking, showTracking) || other.showTracking == showTracking)&&(identical(other.showQuoteCard, showQuoteCard) || other.showQuoteCard == showQuoteCard)&&(identical(other.showDisputeButton, showDisputeButton) || other.showDisputeButton == showDisputeButton)&&(identical(other.tone, tone) || other.tone == tone));
}


@override
int get hashCode => Object.hash(runtimeType,statusLabel,bodyText,primaryAction,const DeepCollectionEquality().hash(_secondaryActions),showTracking,showQuoteCard,showDisputeButton,tone);

@override
String toString() {
  return 'BookingUiBlock(statusLabel: $statusLabel, bodyText: $bodyText, primaryAction: $primaryAction, secondaryActions: $secondaryActions, showTracking: $showTracking, showQuoteCard: $showQuoteCard, showDisputeButton: $showDisputeButton, tone: $tone)';
}


}

/// @nodoc
abstract mixin class _$BookingUiBlockCopyWith<$Res> implements $BookingUiBlockCopyWith<$Res> {
  factory _$BookingUiBlockCopyWith(_BookingUiBlock value, $Res Function(_BookingUiBlock) _then) = __$BookingUiBlockCopyWithImpl;
@override @useResult
$Res call({
 String statusLabel, String bodyText, BookingUiAction? primaryAction, List<BookingUiAction> secondaryActions, bool showTracking, bool showQuoteCard, bool showDisputeButton, BookingUiTone tone
});


@override $BookingUiActionCopyWith<$Res>? get primaryAction;

}
/// @nodoc
class __$BookingUiBlockCopyWithImpl<$Res>
    implements _$BookingUiBlockCopyWith<$Res> {
  __$BookingUiBlockCopyWithImpl(this._self, this._then);

  final _BookingUiBlock _self;
  final $Res Function(_BookingUiBlock) _then;

/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusLabel = null,Object? bodyText = null,Object? primaryAction = freezed,Object? secondaryActions = null,Object? showTracking = null,Object? showQuoteCard = null,Object? showDisputeButton = null,Object? tone = null,}) {
  return _then(_BookingUiBlock(
statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,bodyText: null == bodyText ? _self.bodyText : bodyText // ignore: cast_nullable_to_non_nullable
as String,primaryAction: freezed == primaryAction ? _self.primaryAction : primaryAction // ignore: cast_nullable_to_non_nullable
as BookingUiAction?,secondaryActions: null == secondaryActions ? _self._secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<BookingUiAction>,showTracking: null == showTracking ? _self.showTracking : showTracking // ignore: cast_nullable_to_non_nullable
as bool,showQuoteCard: null == showQuoteCard ? _self.showQuoteCard : showQuoteCard // ignore: cast_nullable_to_non_nullable
as bool,showDisputeButton: null == showDisputeButton ? _self.showDisputeButton : showDisputeButton // ignore: cast_nullable_to_non_nullable
as bool,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as BookingUiTone,
  ));
}

/// Create a copy of BookingUiBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiActionCopyWith<$Res>? get primaryAction {
    if (_self.primaryAction == null) {
    return null;
  }

  return $BookingUiActionCopyWith<$Res>(_self.primaryAction!, (value) {
    return _then(_self.copyWith(primaryAction: value));
  });
}
}

/// @nodoc
mixin _$BookingUiAction {

 String get label; String get endpoint; String get method; BookingUiActionStyle? get style;
/// Create a copy of BookingUiAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiActionCopyWith<BookingUiAction> get copyWith => _$BookingUiActionCopyWithImpl<BookingUiAction>(this as BookingUiAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUiAction&&(identical(other.label, label) || other.label == label)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.method, method) || other.method == method)&&(identical(other.style, style) || other.style == style));
}


@override
int get hashCode => Object.hash(runtimeType,label,endpoint,method,style);

@override
String toString() {
  return 'BookingUiAction(label: $label, endpoint: $endpoint, method: $method, style: $style)';
}


}

/// @nodoc
abstract mixin class $BookingUiActionCopyWith<$Res>  {
  factory $BookingUiActionCopyWith(BookingUiAction value, $Res Function(BookingUiAction) _then) = _$BookingUiActionCopyWithImpl;
@useResult
$Res call({
 String label, String endpoint, String method, BookingUiActionStyle? style
});




}
/// @nodoc
class _$BookingUiActionCopyWithImpl<$Res>
    implements $BookingUiActionCopyWith<$Res> {
  _$BookingUiActionCopyWithImpl(this._self, this._then);

  final BookingUiAction _self;
  final $Res Function(BookingUiAction) _then;

/// Create a copy of BookingUiAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? endpoint = null,Object? method = null,Object? style = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as BookingUiActionStyle?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingUiAction].
extension BookingUiActionPatterns on BookingUiAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUiAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUiAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUiAction value)  $default,){
final _that = this;
switch (_that) {
case _BookingUiAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUiAction value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUiAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String endpoint,  String method,  BookingUiActionStyle? style)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingUiAction() when $default != null:
return $default(_that.label,_that.endpoint,_that.method,_that.style);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String endpoint,  String method,  BookingUiActionStyle? style)  $default,) {final _that = this;
switch (_that) {
case _BookingUiAction():
return $default(_that.label,_that.endpoint,_that.method,_that.style);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String endpoint,  String method,  BookingUiActionStyle? style)?  $default,) {final _that = this;
switch (_that) {
case _BookingUiAction() when $default != null:
return $default(_that.label,_that.endpoint,_that.method,_that.style);case _:
  return null;

}
}

}

/// @nodoc


class _BookingUiAction implements BookingUiAction {
  const _BookingUiAction({required this.label, required this.endpoint, required this.method, this.style});
  

@override final  String label;
@override final  String endpoint;
@override final  String method;
@override final  BookingUiActionStyle? style;

/// Create a copy of BookingUiAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiActionCopyWith<_BookingUiAction> get copyWith => __$BookingUiActionCopyWithImpl<_BookingUiAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUiAction&&(identical(other.label, label) || other.label == label)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.method, method) || other.method == method)&&(identical(other.style, style) || other.style == style));
}


@override
int get hashCode => Object.hash(runtimeType,label,endpoint,method,style);

@override
String toString() {
  return 'BookingUiAction(label: $label, endpoint: $endpoint, method: $method, style: $style)';
}


}

/// @nodoc
abstract mixin class _$BookingUiActionCopyWith<$Res> implements $BookingUiActionCopyWith<$Res> {
  factory _$BookingUiActionCopyWith(_BookingUiAction value, $Res Function(_BookingUiAction) _then) = __$BookingUiActionCopyWithImpl;
@override @useResult
$Res call({
 String label, String endpoint, String method, BookingUiActionStyle? style
});




}
/// @nodoc
class __$BookingUiActionCopyWithImpl<$Res>
    implements _$BookingUiActionCopyWith<$Res> {
  __$BookingUiActionCopyWithImpl(this._self, this._then);

  final _BookingUiAction _self;
  final $Res Function(_BookingUiAction) _then;

/// Create a copy of BookingUiAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? endpoint = null,Object? method = null,Object? style = freezed,}) {
  return _then(_BookingUiAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as BookingUiActionStyle?,
  ));
}


}

// dart format on

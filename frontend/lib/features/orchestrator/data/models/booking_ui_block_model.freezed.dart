// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_ui_block_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookingUiBlockModel {

@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'body_text') String get bodyText;@JsonKey(name: 'primary_action') BookingUiActionModel? get primaryAction;@JsonKey(name: 'secondary_actions') List<BookingUiActionModel> get secondaryActions;@JsonKey(name: 'show_tracking') bool get showTracking;@JsonKey(name: 'show_quote_card') bool get showQuoteCard;@JsonKey(name: 'show_dispute_button') bool get showDisputeButton; String get tone;
/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiBlockModelCopyWith<BookingUiBlockModel> get copyWith => _$BookingUiBlockModelCopyWithImpl<BookingUiBlockModel>(this as BookingUiBlockModel, _$identity);

  /// Serializes this BookingUiBlockModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUiBlockModel&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.bodyText, bodyText) || other.bodyText == bodyText)&&(identical(other.primaryAction, primaryAction) || other.primaryAction == primaryAction)&&const DeepCollectionEquality().equals(other.secondaryActions, secondaryActions)&&(identical(other.showTracking, showTracking) || other.showTracking == showTracking)&&(identical(other.showQuoteCard, showQuoteCard) || other.showQuoteCard == showQuoteCard)&&(identical(other.showDisputeButton, showDisputeButton) || other.showDisputeButton == showDisputeButton)&&(identical(other.tone, tone) || other.tone == tone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statusLabel,bodyText,primaryAction,const DeepCollectionEquality().hash(secondaryActions),showTracking,showQuoteCard,showDisputeButton,tone);

@override
String toString() {
  return 'BookingUiBlockModel(statusLabel: $statusLabel, bodyText: $bodyText, primaryAction: $primaryAction, secondaryActions: $secondaryActions, showTracking: $showTracking, showQuoteCard: $showQuoteCard, showDisputeButton: $showDisputeButton, tone: $tone)';
}


}

/// @nodoc
abstract mixin class $BookingUiBlockModelCopyWith<$Res>  {
  factory $BookingUiBlockModelCopyWith(BookingUiBlockModel value, $Res Function(BookingUiBlockModel) _then) = _$BookingUiBlockModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'body_text') String bodyText,@JsonKey(name: 'primary_action') BookingUiActionModel? primaryAction,@JsonKey(name: 'secondary_actions') List<BookingUiActionModel> secondaryActions,@JsonKey(name: 'show_tracking') bool showTracking,@JsonKey(name: 'show_quote_card') bool showQuoteCard,@JsonKey(name: 'show_dispute_button') bool showDisputeButton, String tone
});


$BookingUiActionModelCopyWith<$Res>? get primaryAction;

}
/// @nodoc
class _$BookingUiBlockModelCopyWithImpl<$Res>
    implements $BookingUiBlockModelCopyWith<$Res> {
  _$BookingUiBlockModelCopyWithImpl(this._self, this._then);

  final BookingUiBlockModel _self;
  final $Res Function(BookingUiBlockModel) _then;

/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? statusLabel = null,Object? bodyText = null,Object? primaryAction = freezed,Object? secondaryActions = null,Object? showTracking = null,Object? showQuoteCard = null,Object? showDisputeButton = null,Object? tone = null,}) {
  return _then(_self.copyWith(
statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,bodyText: null == bodyText ? _self.bodyText : bodyText // ignore: cast_nullable_to_non_nullable
as String,primaryAction: freezed == primaryAction ? _self.primaryAction : primaryAction // ignore: cast_nullable_to_non_nullable
as BookingUiActionModel?,secondaryActions: null == secondaryActions ? _self.secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<BookingUiActionModel>,showTracking: null == showTracking ? _self.showTracking : showTracking // ignore: cast_nullable_to_non_nullable
as bool,showQuoteCard: null == showQuoteCard ? _self.showQuoteCard : showQuoteCard // ignore: cast_nullable_to_non_nullable
as bool,showDisputeButton: null == showDisputeButton ? _self.showDisputeButton : showDisputeButton // ignore: cast_nullable_to_non_nullable
as bool,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiActionModelCopyWith<$Res>? get primaryAction {
    if (_self.primaryAction == null) {
    return null;
  }

  return $BookingUiActionModelCopyWith<$Res>(_self.primaryAction!, (value) {
    return _then(_self.copyWith(primaryAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingUiBlockModel].
extension BookingUiBlockModelPatterns on BookingUiBlockModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUiBlockModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUiBlockModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUiBlockModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingUiBlockModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUiBlockModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUiBlockModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'body_text')  String bodyText, @JsonKey(name: 'primary_action')  BookingUiActionModel? primaryAction, @JsonKey(name: 'secondary_actions')  List<BookingUiActionModel> secondaryActions, @JsonKey(name: 'show_tracking')  bool showTracking, @JsonKey(name: 'show_quote_card')  bool showQuoteCard, @JsonKey(name: 'show_dispute_button')  bool showDisputeButton,  String tone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingUiBlockModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'body_text')  String bodyText, @JsonKey(name: 'primary_action')  BookingUiActionModel? primaryAction, @JsonKey(name: 'secondary_actions')  List<BookingUiActionModel> secondaryActions, @JsonKey(name: 'show_tracking')  bool showTracking, @JsonKey(name: 'show_quote_card')  bool showQuoteCard, @JsonKey(name: 'show_dispute_button')  bool showDisputeButton,  String tone)  $default,) {final _that = this;
switch (_that) {
case _BookingUiBlockModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'body_text')  String bodyText, @JsonKey(name: 'primary_action')  BookingUiActionModel? primaryAction, @JsonKey(name: 'secondary_actions')  List<BookingUiActionModel> secondaryActions, @JsonKey(name: 'show_tracking')  bool showTracking, @JsonKey(name: 'show_quote_card')  bool showQuoteCard, @JsonKey(name: 'show_dispute_button')  bool showDisputeButton,  String tone)?  $default,) {final _that = this;
switch (_that) {
case _BookingUiBlockModel() when $default != null:
return $default(_that.statusLabel,_that.bodyText,_that.primaryAction,_that.secondaryActions,_that.showTracking,_that.showQuoteCard,_that.showDisputeButton,_that.tone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingUiBlockModel implements BookingUiBlockModel {
  const _BookingUiBlockModel({@JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'body_text') required this.bodyText, @JsonKey(name: 'primary_action') this.primaryAction, @JsonKey(name: 'secondary_actions') final  List<BookingUiActionModel> secondaryActions = const <BookingUiActionModel>[], @JsonKey(name: 'show_tracking') required this.showTracking, @JsonKey(name: 'show_quote_card') required this.showQuoteCard, @JsonKey(name: 'show_dispute_button') required this.showDisputeButton, required this.tone}): _secondaryActions = secondaryActions;
  factory _BookingUiBlockModel.fromJson(Map<String, dynamic> json) => _$BookingUiBlockModelFromJson(json);

@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'body_text') final  String bodyText;
@override@JsonKey(name: 'primary_action') final  BookingUiActionModel? primaryAction;
 final  List<BookingUiActionModel> _secondaryActions;
@override@JsonKey(name: 'secondary_actions') List<BookingUiActionModel> get secondaryActions {
  if (_secondaryActions is EqualUnmodifiableListView) return _secondaryActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryActions);
}

@override@JsonKey(name: 'show_tracking') final  bool showTracking;
@override@JsonKey(name: 'show_quote_card') final  bool showQuoteCard;
@override@JsonKey(name: 'show_dispute_button') final  bool showDisputeButton;
@override final  String tone;

/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiBlockModelCopyWith<_BookingUiBlockModel> get copyWith => __$BookingUiBlockModelCopyWithImpl<_BookingUiBlockModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingUiBlockModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUiBlockModel&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.bodyText, bodyText) || other.bodyText == bodyText)&&(identical(other.primaryAction, primaryAction) || other.primaryAction == primaryAction)&&const DeepCollectionEquality().equals(other._secondaryActions, _secondaryActions)&&(identical(other.showTracking, showTracking) || other.showTracking == showTracking)&&(identical(other.showQuoteCard, showQuoteCard) || other.showQuoteCard == showQuoteCard)&&(identical(other.showDisputeButton, showDisputeButton) || other.showDisputeButton == showDisputeButton)&&(identical(other.tone, tone) || other.tone == tone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statusLabel,bodyText,primaryAction,const DeepCollectionEquality().hash(_secondaryActions),showTracking,showQuoteCard,showDisputeButton,tone);

@override
String toString() {
  return 'BookingUiBlockModel(statusLabel: $statusLabel, bodyText: $bodyText, primaryAction: $primaryAction, secondaryActions: $secondaryActions, showTracking: $showTracking, showQuoteCard: $showQuoteCard, showDisputeButton: $showDisputeButton, tone: $tone)';
}


}

/// @nodoc
abstract mixin class _$BookingUiBlockModelCopyWith<$Res> implements $BookingUiBlockModelCopyWith<$Res> {
  factory _$BookingUiBlockModelCopyWith(_BookingUiBlockModel value, $Res Function(_BookingUiBlockModel) _then) = __$BookingUiBlockModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'body_text') String bodyText,@JsonKey(name: 'primary_action') BookingUiActionModel? primaryAction,@JsonKey(name: 'secondary_actions') List<BookingUiActionModel> secondaryActions,@JsonKey(name: 'show_tracking') bool showTracking,@JsonKey(name: 'show_quote_card') bool showQuoteCard,@JsonKey(name: 'show_dispute_button') bool showDisputeButton, String tone
});


@override $BookingUiActionModelCopyWith<$Res>? get primaryAction;

}
/// @nodoc
class __$BookingUiBlockModelCopyWithImpl<$Res>
    implements _$BookingUiBlockModelCopyWith<$Res> {
  __$BookingUiBlockModelCopyWithImpl(this._self, this._then);

  final _BookingUiBlockModel _self;
  final $Res Function(_BookingUiBlockModel) _then;

/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? statusLabel = null,Object? bodyText = null,Object? primaryAction = freezed,Object? secondaryActions = null,Object? showTracking = null,Object? showQuoteCard = null,Object? showDisputeButton = null,Object? tone = null,}) {
  return _then(_BookingUiBlockModel(
statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,bodyText: null == bodyText ? _self.bodyText : bodyText // ignore: cast_nullable_to_non_nullable
as String,primaryAction: freezed == primaryAction ? _self.primaryAction : primaryAction // ignore: cast_nullable_to_non_nullable
as BookingUiActionModel?,secondaryActions: null == secondaryActions ? _self._secondaryActions : secondaryActions // ignore: cast_nullable_to_non_nullable
as List<BookingUiActionModel>,showTracking: null == showTracking ? _self.showTracking : showTracking // ignore: cast_nullable_to_non_nullable
as bool,showQuoteCard: null == showQuoteCard ? _self.showQuoteCard : showQuoteCard // ignore: cast_nullable_to_non_nullable
as bool,showDisputeButton: null == showDisputeButton ? _self.showDisputeButton : showDisputeButton // ignore: cast_nullable_to_non_nullable
as bool,tone: null == tone ? _self.tone : tone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of BookingUiBlockModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BookingUiActionModelCopyWith<$Res>? get primaryAction {
    if (_self.primaryAction == null) {
    return null;
  }

  return $BookingUiActionModelCopyWith<$Res>(_self.primaryAction!, (value) {
    return _then(_self.copyWith(primaryAction: value));
  });
}
}


/// @nodoc
mixin _$BookingUiActionModel {

 String get label; String get endpoint; String get method; String? get style;
/// Create a copy of BookingUiActionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingUiActionModelCopyWith<BookingUiActionModel> get copyWith => _$BookingUiActionModelCopyWithImpl<BookingUiActionModel>(this as BookingUiActionModel, _$identity);

  /// Serializes this BookingUiActionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingUiActionModel&&(identical(other.label, label) || other.label == label)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.method, method) || other.method == method)&&(identical(other.style, style) || other.style == style));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,endpoint,method,style);

@override
String toString() {
  return 'BookingUiActionModel(label: $label, endpoint: $endpoint, method: $method, style: $style)';
}


}

/// @nodoc
abstract mixin class $BookingUiActionModelCopyWith<$Res>  {
  factory $BookingUiActionModelCopyWith(BookingUiActionModel value, $Res Function(BookingUiActionModel) _then) = _$BookingUiActionModelCopyWithImpl;
@useResult
$Res call({
 String label, String endpoint, String method, String? style
});




}
/// @nodoc
class _$BookingUiActionModelCopyWithImpl<$Res>
    implements $BookingUiActionModelCopyWith<$Res> {
  _$BookingUiActionModelCopyWithImpl(this._self, this._then);

  final BookingUiActionModel _self;
  final $Res Function(BookingUiActionModel) _then;

/// Create a copy of BookingUiActionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? endpoint = null,Object? method = null,Object? style = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingUiActionModel].
extension BookingUiActionModelPatterns on BookingUiActionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingUiActionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingUiActionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingUiActionModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingUiActionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingUiActionModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingUiActionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String endpoint,  String method,  String? style)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingUiActionModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String endpoint,  String method,  String? style)  $default,) {final _that = this;
switch (_that) {
case _BookingUiActionModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String endpoint,  String method,  String? style)?  $default,) {final _that = this;
switch (_that) {
case _BookingUiActionModel() when $default != null:
return $default(_that.label,_that.endpoint,_that.method,_that.style);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingUiActionModel implements BookingUiActionModel {
  const _BookingUiActionModel({required this.label, required this.endpoint, required this.method, this.style});
  factory _BookingUiActionModel.fromJson(Map<String, dynamic> json) => _$BookingUiActionModelFromJson(json);

@override final  String label;
@override final  String endpoint;
@override final  String method;
@override final  String? style;

/// Create a copy of BookingUiActionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingUiActionModelCopyWith<_BookingUiActionModel> get copyWith => __$BookingUiActionModelCopyWithImpl<_BookingUiActionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingUiActionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingUiActionModel&&(identical(other.label, label) || other.label == label)&&(identical(other.endpoint, endpoint) || other.endpoint == endpoint)&&(identical(other.method, method) || other.method == method)&&(identical(other.style, style) || other.style == style));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,endpoint,method,style);

@override
String toString() {
  return 'BookingUiActionModel(label: $label, endpoint: $endpoint, method: $method, style: $style)';
}


}

/// @nodoc
abstract mixin class _$BookingUiActionModelCopyWith<$Res> implements $BookingUiActionModelCopyWith<$Res> {
  factory _$BookingUiActionModelCopyWith(_BookingUiActionModel value, $Res Function(_BookingUiActionModel) _then) = __$BookingUiActionModelCopyWithImpl;
@override @useResult
$Res call({
 String label, String endpoint, String method, String? style
});




}
/// @nodoc
class __$BookingUiActionModelCopyWithImpl<$Res>
    implements _$BookingUiActionModelCopyWith<$Res> {
  __$BookingUiActionModelCopyWithImpl(this._self, this._then);

  final _BookingUiActionModel _self;
  final $Res Function(_BookingUiActionModel) _then;

/// Create a copy of BookingUiActionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? endpoint = null,Object? method = null,Object? style = freezed,}) {
  return _then(_BookingUiActionModel(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,endpoint: null == endpoint ? _self.endpoint : endpoint // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

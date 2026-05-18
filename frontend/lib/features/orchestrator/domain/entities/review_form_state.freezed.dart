// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewFormState {

 int? get rating; Set<String> get selectedTagKeys; String get text;
/// Create a copy of ReviewFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewFormStateCopyWith<ReviewFormState> get copyWith => _$ReviewFormStateCopyWithImpl<ReviewFormState>(this as ReviewFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewFormState&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.selectedTagKeys, selectedTagKeys)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rating,const DeepCollectionEquality().hash(selectedTagKeys),text);

@override
String toString() {
  return 'ReviewFormState(rating: $rating, selectedTagKeys: $selectedTagKeys, text: $text)';
}


}

/// @nodoc
abstract mixin class $ReviewFormStateCopyWith<$Res>  {
  factory $ReviewFormStateCopyWith(ReviewFormState value, $Res Function(ReviewFormState) _then) = _$ReviewFormStateCopyWithImpl;
@useResult
$Res call({
 int? rating, Set<String> selectedTagKeys, String text
});




}
/// @nodoc
class _$ReviewFormStateCopyWithImpl<$Res>
    implements $ReviewFormStateCopyWith<$Res> {
  _$ReviewFormStateCopyWithImpl(this._self, this._then);

  final ReviewFormState _self;
  final $Res Function(ReviewFormState) _then;

/// Create a copy of ReviewFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rating = freezed,Object? selectedTagKeys = null,Object? text = null,}) {
  return _then(_self.copyWith(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,selectedTagKeys: null == selectedTagKeys ? _self.selectedTagKeys : selectedTagKeys // ignore: cast_nullable_to_non_nullable
as Set<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewFormState].
extension ReviewFormStatePatterns on ReviewFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewFormState value)  $default,){
final _that = this;
switch (_that) {
case _ReviewFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewFormState value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? rating,  Set<String> selectedTagKeys,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewFormState() when $default != null:
return $default(_that.rating,_that.selectedTagKeys,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? rating,  Set<String> selectedTagKeys,  String text)  $default,) {final _that = this;
switch (_that) {
case _ReviewFormState():
return $default(_that.rating,_that.selectedTagKeys,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? rating,  Set<String> selectedTagKeys,  String text)?  $default,) {final _that = this;
switch (_that) {
case _ReviewFormState() when $default != null:
return $default(_that.rating,_that.selectedTagKeys,_that.text);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewFormState extends ReviewFormState {
  const _ReviewFormState({this.rating, final  Set<String> selectedTagKeys = const <String>{}, this.text = ''}): _selectedTagKeys = selectedTagKeys,super._();
  

@override final  int? rating;
 final  Set<String> _selectedTagKeys;
@override@JsonKey() Set<String> get selectedTagKeys {
  if (_selectedTagKeys is EqualUnmodifiableSetView) return _selectedTagKeys;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedTagKeys);
}

@override@JsonKey() final  String text;

/// Create a copy of ReviewFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewFormStateCopyWith<_ReviewFormState> get copyWith => __$ReviewFormStateCopyWithImpl<_ReviewFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewFormState&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._selectedTagKeys, _selectedTagKeys)&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,rating,const DeepCollectionEquality().hash(_selectedTagKeys),text);

@override
String toString() {
  return 'ReviewFormState(rating: $rating, selectedTagKeys: $selectedTagKeys, text: $text)';
}


}

/// @nodoc
abstract mixin class _$ReviewFormStateCopyWith<$Res> implements $ReviewFormStateCopyWith<$Res> {
  factory _$ReviewFormStateCopyWith(_ReviewFormState value, $Res Function(_ReviewFormState) _then) = __$ReviewFormStateCopyWithImpl;
@override @useResult
$Res call({
 int? rating, Set<String> selectedTagKeys, String text
});




}
/// @nodoc
class __$ReviewFormStateCopyWithImpl<$Res>
    implements _$ReviewFormStateCopyWith<$Res> {
  __$ReviewFormStateCopyWithImpl(this._self, this._then);

  final _ReviewFormState _self;
  final $Res Function(_ReviewFormState) _then;

/// Create a copy of ReviewFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rating = freezed,Object? selectedTagKeys = null,Object? text = null,}) {
  return _then(_ReviewFormState(
rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,selectedTagKeys: null == selectedTagKeys ? _self._selectedTagKeys : selectedTagKeys // ignore: cast_nullable_to_non_nullable
as Set<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on

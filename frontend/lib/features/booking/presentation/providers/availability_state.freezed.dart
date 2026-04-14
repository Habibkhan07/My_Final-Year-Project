// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AvailabilityState {

 List<AvailabilitySlotEntity> get slots; AvailabilitySlotEntity? get selectedSlot;
/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailabilityStateCopyWith<AvailabilityState> get copyWith => _$AvailabilityStateCopyWithImpl<AvailabilityState>(this as AvailabilityState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailabilityState&&const DeepCollectionEquality().equals(other.slots, slots)&&(identical(other.selectedSlot, selectedSlot) || other.selectedSlot == selectedSlot));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(slots),selectedSlot);

@override
String toString() {
  return 'AvailabilityState(slots: $slots, selectedSlot: $selectedSlot)';
}


}

/// @nodoc
abstract mixin class $AvailabilityStateCopyWith<$Res>  {
  factory $AvailabilityStateCopyWith(AvailabilityState value, $Res Function(AvailabilityState) _then) = _$AvailabilityStateCopyWithImpl;
@useResult
$Res call({
 List<AvailabilitySlotEntity> slots, AvailabilitySlotEntity? selectedSlot
});


$AvailabilitySlotEntityCopyWith<$Res>? get selectedSlot;

}
/// @nodoc
class _$AvailabilityStateCopyWithImpl<$Res>
    implements $AvailabilityStateCopyWith<$Res> {
  _$AvailabilityStateCopyWithImpl(this._self, this._then);

  final AvailabilityState _self;
  final $Res Function(AvailabilityState) _then;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slots = null,Object? selectedSlot = freezed,}) {
  return _then(_self.copyWith(
slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<AvailabilitySlotEntity>,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as AvailabilitySlotEntity?,
  ));
}
/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvailabilitySlotEntityCopyWith<$Res>? get selectedSlot {
    if (_self.selectedSlot == null) {
    return null;
  }

  return $AvailabilitySlotEntityCopyWith<$Res>(_self.selectedSlot!, (value) {
    return _then(_self.copyWith(selectedSlot: value));
  });
}
}


/// Adds pattern-matching-related methods to [AvailabilityState].
extension AvailabilityStatePatterns on AvailabilityState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailabilityState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailabilityState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailabilityState value)  $default,){
final _that = this;
switch (_that) {
case _AvailabilityState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailabilityState value)?  $default,){
final _that = this;
switch (_that) {
case _AvailabilityState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AvailabilitySlotEntity> slots,  AvailabilitySlotEntity? selectedSlot)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailabilityState() when $default != null:
return $default(_that.slots,_that.selectedSlot);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AvailabilitySlotEntity> slots,  AvailabilitySlotEntity? selectedSlot)  $default,) {final _that = this;
switch (_that) {
case _AvailabilityState():
return $default(_that.slots,_that.selectedSlot);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AvailabilitySlotEntity> slots,  AvailabilitySlotEntity? selectedSlot)?  $default,) {final _that = this;
switch (_that) {
case _AvailabilityState() when $default != null:
return $default(_that.slots,_that.selectedSlot);case _:
  return null;

}
}

}

/// @nodoc


class _AvailabilityState implements AvailabilityState {
  const _AvailabilityState({required final  List<AvailabilitySlotEntity> slots, this.selectedSlot}): _slots = slots;
  

 final  List<AvailabilitySlotEntity> _slots;
@override List<AvailabilitySlotEntity> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}

@override final  AvailabilitySlotEntity? selectedSlot;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailabilityStateCopyWith<_AvailabilityState> get copyWith => __$AvailabilityStateCopyWithImpl<_AvailabilityState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailabilityState&&const DeepCollectionEquality().equals(other._slots, _slots)&&(identical(other.selectedSlot, selectedSlot) || other.selectedSlot == selectedSlot));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_slots),selectedSlot);

@override
String toString() {
  return 'AvailabilityState(slots: $slots, selectedSlot: $selectedSlot)';
}


}

/// @nodoc
abstract mixin class _$AvailabilityStateCopyWith<$Res> implements $AvailabilityStateCopyWith<$Res> {
  factory _$AvailabilityStateCopyWith(_AvailabilityState value, $Res Function(_AvailabilityState) _then) = __$AvailabilityStateCopyWithImpl;
@override @useResult
$Res call({
 List<AvailabilitySlotEntity> slots, AvailabilitySlotEntity? selectedSlot
});


@override $AvailabilitySlotEntityCopyWith<$Res>? get selectedSlot;

}
/// @nodoc
class __$AvailabilityStateCopyWithImpl<$Res>
    implements _$AvailabilityStateCopyWith<$Res> {
  __$AvailabilityStateCopyWithImpl(this._self, this._then);

  final _AvailabilityState _self;
  final $Res Function(_AvailabilityState) _then;

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slots = null,Object? selectedSlot = freezed,}) {
  return _then(_AvailabilityState(
slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<AvailabilitySlotEntity>,selectedSlot: freezed == selectedSlot ? _self.selectedSlot : selectedSlot // ignore: cast_nullable_to_non_nullable
as AvailabilitySlotEntity?,
  ));
}

/// Create a copy of AvailabilityState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AvailabilitySlotEntityCopyWith<$Res>? get selectedSlot {
    if (_self.selectedSlot == null) {
    return null;
  }

  return $AvailabilitySlotEntityCopyWith<$Res>(_self.selectedSlot!, (value) {
    return _then(_self.copyWith(selectedSlot: value));
  });
}
}

// dart format on

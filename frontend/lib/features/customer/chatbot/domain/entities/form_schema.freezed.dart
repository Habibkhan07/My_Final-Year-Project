// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'form_schema.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FormFieldSpec {

 String get name; String get label; FormFieldKind get kind; String? get validationPattern;
/// Create a copy of FormFieldSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormFieldSpecCopyWith<FormFieldSpec> get copyWith => _$FormFieldSpecCopyWithImpl<FormFieldSpec>(this as FormFieldSpec, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormFieldSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.validationPattern, validationPattern) || other.validationPattern == validationPattern));
}


@override
int get hashCode => Object.hash(runtimeType,name,label,kind,validationPattern);

@override
String toString() {
  return 'FormFieldSpec(name: $name, label: $label, kind: $kind, validationPattern: $validationPattern)';
}


}

/// @nodoc
abstract mixin class $FormFieldSpecCopyWith<$Res>  {
  factory $FormFieldSpecCopyWith(FormFieldSpec value, $Res Function(FormFieldSpec) _then) = _$FormFieldSpecCopyWithImpl;
@useResult
$Res call({
 String name, String label, FormFieldKind kind, String? validationPattern
});




}
/// @nodoc
class _$FormFieldSpecCopyWithImpl<$Res>
    implements $FormFieldSpecCopyWith<$Res> {
  _$FormFieldSpecCopyWithImpl(this._self, this._then);

  final FormFieldSpec _self;
  final $Res Function(FormFieldSpec) _then;

/// Create a copy of FormFieldSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? label = null,Object? kind = null,Object? validationPattern = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FormFieldKind,validationPattern: freezed == validationPattern ? _self.validationPattern : validationPattern // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FormFieldSpec].
extension FormFieldSpecPatterns on FormFieldSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormFieldSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormFieldSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormFieldSpec value)  $default,){
final _that = this;
switch (_that) {
case _FormFieldSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormFieldSpec value)?  $default,){
final _that = this;
switch (_that) {
case _FormFieldSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String label,  FormFieldKind kind,  String? validationPattern)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormFieldSpec() when $default != null:
return $default(_that.name,_that.label,_that.kind,_that.validationPattern);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String label,  FormFieldKind kind,  String? validationPattern)  $default,) {final _that = this;
switch (_that) {
case _FormFieldSpec():
return $default(_that.name,_that.label,_that.kind,_that.validationPattern);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String label,  FormFieldKind kind,  String? validationPattern)?  $default,) {final _that = this;
switch (_that) {
case _FormFieldSpec() when $default != null:
return $default(_that.name,_that.label,_that.kind,_that.validationPattern);case _:
  return null;

}
}

}

/// @nodoc


class _FormFieldSpec implements FormFieldSpec {
  const _FormFieldSpec({required this.name, required this.label, required this.kind, this.validationPattern});
  

@override final  String name;
@override final  String label;
@override final  FormFieldKind kind;
@override final  String? validationPattern;

/// Create a copy of FormFieldSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormFieldSpecCopyWith<_FormFieldSpec> get copyWith => __$FormFieldSpecCopyWithImpl<_FormFieldSpec>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormFieldSpec&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.validationPattern, validationPattern) || other.validationPattern == validationPattern));
}


@override
int get hashCode => Object.hash(runtimeType,name,label,kind,validationPattern);

@override
String toString() {
  return 'FormFieldSpec(name: $name, label: $label, kind: $kind, validationPattern: $validationPattern)';
}


}

/// @nodoc
abstract mixin class _$FormFieldSpecCopyWith<$Res> implements $FormFieldSpecCopyWith<$Res> {
  factory _$FormFieldSpecCopyWith(_FormFieldSpec value, $Res Function(_FormFieldSpec) _then) = __$FormFieldSpecCopyWithImpl;
@override @useResult
$Res call({
 String name, String label, FormFieldKind kind, String? validationPattern
});




}
/// @nodoc
class __$FormFieldSpecCopyWithImpl<$Res>
    implements _$FormFieldSpecCopyWith<$Res> {
  __$FormFieldSpecCopyWithImpl(this._self, this._then);

  final _FormFieldSpec _self;
  final $Res Function(_FormFieldSpec) _then;

/// Create a copy of FormFieldSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? label = null,Object? kind = null,Object? validationPattern = freezed,}) {
  return _then(_FormFieldSpec(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as FormFieldKind,validationPattern: freezed == validationPattern ? _self.validationPattern : validationPattern // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FormSchema {

 List<FormFieldSpec> get fields;
/// Create a copy of FormSchema
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormSchemaCopyWith<FormSchema> get copyWith => _$FormSchemaCopyWithImpl<FormSchema>(this as FormSchema, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormSchema&&const DeepCollectionEquality().equals(other.fields, fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fields));

@override
String toString() {
  return 'FormSchema(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $FormSchemaCopyWith<$Res>  {
  factory $FormSchemaCopyWith(FormSchema value, $Res Function(FormSchema) _then) = _$FormSchemaCopyWithImpl;
@useResult
$Res call({
 List<FormFieldSpec> fields
});




}
/// @nodoc
class _$FormSchemaCopyWithImpl<$Res>
    implements $FormSchemaCopyWith<$Res> {
  _$FormSchemaCopyWithImpl(this._self, this._then);

  final FormSchema _self;
  final $Res Function(FormSchema) _then;

/// Create a copy of FormSchema
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fields = null,}) {
  return _then(_self.copyWith(
fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormFieldSpec>,
  ));
}

}


/// Adds pattern-matching-related methods to [FormSchema].
extension FormSchemaPatterns on FormSchema {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormSchema value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormSchema() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormSchema value)  $default,){
final _that = this;
switch (_that) {
case _FormSchema():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormSchema value)?  $default,){
final _that = this;
switch (_that) {
case _FormSchema() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FormFieldSpec> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormSchema() when $default != null:
return $default(_that.fields);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FormFieldSpec> fields)  $default,) {final _that = this;
switch (_that) {
case _FormSchema():
return $default(_that.fields);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FormFieldSpec> fields)?  $default,) {final _that = this;
switch (_that) {
case _FormSchema() when $default != null:
return $default(_that.fields);case _:
  return null;

}
}

}

/// @nodoc


class _FormSchema implements FormSchema {
  const _FormSchema({required final  List<FormFieldSpec> fields}): _fields = fields;
  

 final  List<FormFieldSpec> _fields;
@override List<FormFieldSpec> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of FormSchema
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormSchemaCopyWith<_FormSchema> get copyWith => __$FormSchemaCopyWithImpl<_FormSchema>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormSchema&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'FormSchema(fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$FormSchemaCopyWith<$Res> implements $FormSchemaCopyWith<$Res> {
  factory _$FormSchemaCopyWith(_FormSchema value, $Res Function(_FormSchema) _then) = __$FormSchemaCopyWithImpl;
@override @useResult
$Res call({
 List<FormFieldSpec> fields
});




}
/// @nodoc
class __$FormSchemaCopyWithImpl<$Res>
    implements _$FormSchemaCopyWith<$Res> {
  __$FormSchemaCopyWithImpl(this._self, this._then);

  final _FormSchema _self;
  final $Res Function(_FormSchema) _then;

/// Create a copy of FormSchema
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(_FormSchema(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormFieldSpec>,
  ));
}


}

// dart format on

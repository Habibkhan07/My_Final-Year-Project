// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'form_schema_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FormFieldModel {

 String get key; String get label; String get type; bool get required;@JsonKey(name: 'max_length') int? get maxLength; String? get pattern; String? get hint;
/// Create a copy of FormFieldModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormFieldModelCopyWith<FormFieldModel> get copyWith => _$FormFieldModelCopyWithImpl<FormFieldModel>(this as FormFieldModel, _$identity);

  /// Serializes this FormFieldModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormFieldModel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.required, required) || other.required == required)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.hint, hint) || other.hint == hint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,type,required,maxLength,pattern,hint);

@override
String toString() {
  return 'FormFieldModel(key: $key, label: $label, type: $type, required: $required, maxLength: $maxLength, pattern: $pattern, hint: $hint)';
}


}

/// @nodoc
abstract mixin class $FormFieldModelCopyWith<$Res>  {
  factory $FormFieldModelCopyWith(FormFieldModel value, $Res Function(FormFieldModel) _then) = _$FormFieldModelCopyWithImpl;
@useResult
$Res call({
 String key, String label, String type, bool required,@JsonKey(name: 'max_length') int? maxLength, String? pattern, String? hint
});




}
/// @nodoc
class _$FormFieldModelCopyWithImpl<$Res>
    implements $FormFieldModelCopyWith<$Res> {
  _$FormFieldModelCopyWithImpl(this._self, this._then);

  final FormFieldModel _self;
  final $Res Function(FormFieldModel) _then;

/// Create a copy of FormFieldModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,Object? type = null,Object? required = null,Object? maxLength = freezed,Object? pattern = freezed,Object? hint = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,maxLength: freezed == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int?,pattern: freezed == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String?,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FormFieldModel].
extension FormFieldModelPatterns on FormFieldModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormFieldModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormFieldModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormFieldModel value)  $default,){
final _that = this;
switch (_that) {
case _FormFieldModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormFieldModel value)?  $default,){
final _that = this;
switch (_that) {
case _FormFieldModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label,  String type,  bool required, @JsonKey(name: 'max_length')  int? maxLength,  String? pattern,  String? hint)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormFieldModel() when $default != null:
return $default(_that.key,_that.label,_that.type,_that.required,_that.maxLength,_that.pattern,_that.hint);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label,  String type,  bool required, @JsonKey(name: 'max_length')  int? maxLength,  String? pattern,  String? hint)  $default,) {final _that = this;
switch (_that) {
case _FormFieldModel():
return $default(_that.key,_that.label,_that.type,_that.required,_that.maxLength,_that.pattern,_that.hint);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label,  String type,  bool required, @JsonKey(name: 'max_length')  int? maxLength,  String? pattern,  String? hint)?  $default,) {final _that = this;
switch (_that) {
case _FormFieldModel() when $default != null:
return $default(_that.key,_that.label,_that.type,_that.required,_that.maxLength,_that.pattern,_that.hint);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FormFieldModel implements FormFieldModel {
  const _FormFieldModel({required this.key, required this.label, required this.type, this.required = false, @JsonKey(name: 'max_length') this.maxLength, this.pattern, this.hint});
  factory _FormFieldModel.fromJson(Map<String, dynamic> json) => _$FormFieldModelFromJson(json);

@override final  String key;
@override final  String label;
@override final  String type;
@override@JsonKey() final  bool required;
@override@JsonKey(name: 'max_length') final  int? maxLength;
@override final  String? pattern;
@override final  String? hint;

/// Create a copy of FormFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormFieldModelCopyWith<_FormFieldModel> get copyWith => __$FormFieldModelCopyWithImpl<_FormFieldModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormFieldModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormFieldModel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label)&&(identical(other.type, type) || other.type == type)&&(identical(other.required, required) || other.required == required)&&(identical(other.maxLength, maxLength) || other.maxLength == maxLength)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.hint, hint) || other.hint == hint));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label,type,required,maxLength,pattern,hint);

@override
String toString() {
  return 'FormFieldModel(key: $key, label: $label, type: $type, required: $required, maxLength: $maxLength, pattern: $pattern, hint: $hint)';
}


}

/// @nodoc
abstract mixin class _$FormFieldModelCopyWith<$Res> implements $FormFieldModelCopyWith<$Res> {
  factory _$FormFieldModelCopyWith(_FormFieldModel value, $Res Function(_FormFieldModel) _then) = __$FormFieldModelCopyWithImpl;
@override @useResult
$Res call({
 String key, String label, String type, bool required,@JsonKey(name: 'max_length') int? maxLength, String? pattern, String? hint
});




}
/// @nodoc
class __$FormFieldModelCopyWithImpl<$Res>
    implements _$FormFieldModelCopyWith<$Res> {
  __$FormFieldModelCopyWithImpl(this._self, this._then);

  final _FormFieldModel _self;
  final $Res Function(_FormFieldModel) _then;

/// Create a copy of FormFieldModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,Object? type = null,Object? required = null,Object? maxLength = freezed,Object? pattern = freezed,Object? hint = freezed,}) {
  return _then(_FormFieldModel(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,maxLength: freezed == maxLength ? _self.maxLength : maxLength // ignore: cast_nullable_to_non_nullable
as int?,pattern: freezed == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as String?,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FormSchemaModel {

 List<FormFieldModel> get fields;
/// Create a copy of FormSchemaModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FormSchemaModelCopyWith<FormSchemaModel> get copyWith => _$FormSchemaModelCopyWithImpl<FormSchemaModel>(this as FormSchemaModel, _$identity);

  /// Serializes this FormSchemaModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FormSchemaModel&&const DeepCollectionEquality().equals(other.fields, fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(fields));

@override
String toString() {
  return 'FormSchemaModel(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $FormSchemaModelCopyWith<$Res>  {
  factory $FormSchemaModelCopyWith(FormSchemaModel value, $Res Function(FormSchemaModel) _then) = _$FormSchemaModelCopyWithImpl;
@useResult
$Res call({
 List<FormFieldModel> fields
});




}
/// @nodoc
class _$FormSchemaModelCopyWithImpl<$Res>
    implements $FormSchemaModelCopyWith<$Res> {
  _$FormSchemaModelCopyWithImpl(this._self, this._then);

  final FormSchemaModel _self;
  final $Res Function(FormSchemaModel) _then;

/// Create a copy of FormSchemaModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fields = null,}) {
  return _then(_self.copyWith(
fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormFieldModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [FormSchemaModel].
extension FormSchemaModelPatterns on FormSchemaModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FormSchemaModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FormSchemaModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FormSchemaModel value)  $default,){
final _that = this;
switch (_that) {
case _FormSchemaModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FormSchemaModel value)?  $default,){
final _that = this;
switch (_that) {
case _FormSchemaModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<FormFieldModel> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FormSchemaModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<FormFieldModel> fields)  $default,) {final _that = this;
switch (_that) {
case _FormSchemaModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<FormFieldModel> fields)?  $default,) {final _that = this;
switch (_that) {
case _FormSchemaModel() when $default != null:
return $default(_that.fields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FormSchemaModel implements FormSchemaModel {
  const _FormSchemaModel({required final  List<FormFieldModel> fields}): _fields = fields;
  factory _FormSchemaModel.fromJson(Map<String, dynamic> json) => _$FormSchemaModelFromJson(json);

 final  List<FormFieldModel> _fields;
@override List<FormFieldModel> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of FormSchemaModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FormSchemaModelCopyWith<_FormSchemaModel> get copyWith => __$FormSchemaModelCopyWithImpl<_FormSchemaModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FormSchemaModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FormSchemaModel&&const DeepCollectionEquality().equals(other._fields, _fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'FormSchemaModel(fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$FormSchemaModelCopyWith<$Res> implements $FormSchemaModelCopyWith<$Res> {
  factory _$FormSchemaModelCopyWith(_FormSchemaModel value, $Res Function(_FormSchemaModel) _then) = __$FormSchemaModelCopyWithImpl;
@override @useResult
$Res call({
 List<FormFieldModel> fields
});




}
/// @nodoc
class __$FormSchemaModelCopyWithImpl<$Res>
    implements _$FormSchemaModelCopyWith<$Res> {
  __$FormSchemaModelCopyWithImpl(this._self, this._then);

  final _FormSchemaModel _self;
  final $Res Function(_FormSchemaModel) _then;

/// Create a copy of FormSchemaModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(_FormSchemaModel(
fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<FormFieldModel>,
  ));
}


}

// dart format on

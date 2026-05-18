// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewModel {

 int get id; int get rating; List<String> get tags; String get text;@JsonKey(name: 'created_at') String get createdAt;@JsonKey(name: 'reviewer_name') String get reviewerName;
/// Create a copy of ReviewModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewModelCopyWith<ReviewModel> get copyWith => _$ReviewModelCopyWithImpl<ReviewModel>(this as ReviewModel, _$identity);

  /// Serializes this ReviewModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rating,const DeepCollectionEquality().hash(tags),text,createdAt,reviewerName);

@override
String toString() {
  return 'ReviewModel(id: $id, rating: $rating, tags: $tags, text: $text, createdAt: $createdAt, reviewerName: $reviewerName)';
}


}

/// @nodoc
abstract mixin class $ReviewModelCopyWith<$Res>  {
  factory $ReviewModelCopyWith(ReviewModel value, $Res Function(ReviewModel) _then) = _$ReviewModelCopyWithImpl;
@useResult
$Res call({
 int id, int rating, List<String> tags, String text,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'reviewer_name') String reviewerName
});




}
/// @nodoc
class _$ReviewModelCopyWithImpl<$Res>
    implements $ReviewModelCopyWith<$Res> {
  _$ReviewModelCopyWithImpl(this._self, this._then);

  final ReviewModel _self;
  final $Res Function(ReviewModel) _then;

/// Create a copy of ReviewModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rating = null,Object? tags = null,Object? text = null,Object? createdAt = null,Object? reviewerName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewModel].
extension ReviewModelPatterns on ReviewModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewModel value)  $default,){
final _that = this;
switch (_that) {
case _ReviewModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewModel value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int rating,  List<String> tags,  String text, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reviewer_name')  String reviewerName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewModel() when $default != null:
return $default(_that.id,_that.rating,_that.tags,_that.text,_that.createdAt,_that.reviewerName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int rating,  List<String> tags,  String text, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reviewer_name')  String reviewerName)  $default,) {final _that = this;
switch (_that) {
case _ReviewModel():
return $default(_that.id,_that.rating,_that.tags,_that.text,_that.createdAt,_that.reviewerName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int rating,  List<String> tags,  String text, @JsonKey(name: 'created_at')  String createdAt, @JsonKey(name: 'reviewer_name')  String reviewerName)?  $default,) {final _that = this;
switch (_that) {
case _ReviewModel() when $default != null:
return $default(_that.id,_that.rating,_that.tags,_that.text,_that.createdAt,_that.reviewerName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewModel implements ReviewModel {
  const _ReviewModel({required this.id, required this.rating, final  List<String> tags = const <String>[], this.text = '', @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'reviewer_name') required this.reviewerName}): _tags = tags;
  factory _ReviewModel.fromJson(Map<String, dynamic> json) => _$ReviewModelFromJson(json);

@override final  int id;
@override final  int rating;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  String text;
@override@JsonKey(name: 'created_at') final  String createdAt;
@override@JsonKey(name: 'reviewer_name') final  String reviewerName;

/// Create a copy of ReviewModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewModelCopyWith<_ReviewModel> get copyWith => __$ReviewModelCopyWithImpl<_ReviewModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewModel&&(identical(other.id, id) || other.id == id)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rating,const DeepCollectionEquality().hash(_tags),text,createdAt,reviewerName);

@override
String toString() {
  return 'ReviewModel(id: $id, rating: $rating, tags: $tags, text: $text, createdAt: $createdAt, reviewerName: $reviewerName)';
}


}

/// @nodoc
abstract mixin class _$ReviewModelCopyWith<$Res> implements $ReviewModelCopyWith<$Res> {
  factory _$ReviewModelCopyWith(_ReviewModel value, $Res Function(_ReviewModel) _then) = __$ReviewModelCopyWithImpl;
@override @useResult
$Res call({
 int id, int rating, List<String> tags, String text,@JsonKey(name: 'created_at') String createdAt,@JsonKey(name: 'reviewer_name') String reviewerName
});




}
/// @nodoc
class __$ReviewModelCopyWithImpl<$Res>
    implements _$ReviewModelCopyWith<$Res> {
  __$ReviewModelCopyWithImpl(this._self, this._then);

  final _ReviewModel _self;
  final $Res Function(_ReviewModel) _then;

/// Create a copy of ReviewModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rating = null,Object? tags = null,Object? text = null,Object? createdAt = null,Object? reviewerName = null,}) {
  return _then(_ReviewModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PredefinedTagModel {

 String get key; String get label;
/// Create a copy of PredefinedTagModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredefinedTagModelCopyWith<PredefinedTagModel> get copyWith => _$PredefinedTagModelCopyWithImpl<PredefinedTagModel>(this as PredefinedTagModel, _$identity);

  /// Serializes this PredefinedTagModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredefinedTagModel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label);

@override
String toString() {
  return 'PredefinedTagModel(key: $key, label: $label)';
}


}

/// @nodoc
abstract mixin class $PredefinedTagModelCopyWith<$Res>  {
  factory $PredefinedTagModelCopyWith(PredefinedTagModel value, $Res Function(PredefinedTagModel) _then) = _$PredefinedTagModelCopyWithImpl;
@useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class _$PredefinedTagModelCopyWithImpl<$Res>
    implements $PredefinedTagModelCopyWith<$Res> {
  _$PredefinedTagModelCopyWithImpl(this._self, this._then);

  final PredefinedTagModel _self;
  final $Res Function(PredefinedTagModel) _then;

/// Create a copy of PredefinedTagModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PredefinedTagModel].
extension PredefinedTagModelPatterns on PredefinedTagModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredefinedTagModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredefinedTagModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredefinedTagModel value)  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredefinedTagModel value)?  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredefinedTagModel() when $default != null:
return $default(_that.key,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String label)  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagModel():
return $default(_that.key,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String label)?  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagModel() when $default != null:
return $default(_that.key,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredefinedTagModel implements PredefinedTagModel {
  const _PredefinedTagModel({required this.key, required this.label});
  factory _PredefinedTagModel.fromJson(Map<String, dynamic> json) => _$PredefinedTagModelFromJson(json);

@override final  String key;
@override final  String label;

/// Create a copy of PredefinedTagModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredefinedTagModelCopyWith<_PredefinedTagModel> get copyWith => __$PredefinedTagModelCopyWithImpl<_PredefinedTagModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredefinedTagModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredefinedTagModel&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,label);

@override
String toString() {
  return 'PredefinedTagModel(key: $key, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PredefinedTagModelCopyWith<$Res> implements $PredefinedTagModelCopyWith<$Res> {
  factory _$PredefinedTagModelCopyWith(_PredefinedTagModel value, $Res Function(_PredefinedTagModel) _then) = __$PredefinedTagModelCopyWithImpl;
@override @useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class __$PredefinedTagModelCopyWithImpl<$Res>
    implements _$PredefinedTagModelCopyWith<$Res> {
  __$PredefinedTagModelCopyWithImpl(this._self, this._then);

  final _PredefinedTagModel _self;
  final $Res Function(_PredefinedTagModel) _then;

/// Create a copy of PredefinedTagModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,}) {
  return _then(_PredefinedTagModel(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PredefinedTagBucketsModel {

 List<PredefinedTagModel> get positive; List<PredefinedTagModel> get constructive;
/// Create a copy of PredefinedTagBucketsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredefinedTagBucketsModelCopyWith<PredefinedTagBucketsModel> get copyWith => _$PredefinedTagBucketsModelCopyWithImpl<PredefinedTagBucketsModel>(this as PredefinedTagBucketsModel, _$identity);

  /// Serializes this PredefinedTagBucketsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredefinedTagBucketsModel&&const DeepCollectionEquality().equals(other.positive, positive)&&const DeepCollectionEquality().equals(other.constructive, constructive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(positive),const DeepCollectionEquality().hash(constructive));

@override
String toString() {
  return 'PredefinedTagBucketsModel(positive: $positive, constructive: $constructive)';
}


}

/// @nodoc
abstract mixin class $PredefinedTagBucketsModelCopyWith<$Res>  {
  factory $PredefinedTagBucketsModelCopyWith(PredefinedTagBucketsModel value, $Res Function(PredefinedTagBucketsModel) _then) = _$PredefinedTagBucketsModelCopyWithImpl;
@useResult
$Res call({
 List<PredefinedTagModel> positive, List<PredefinedTagModel> constructive
});




}
/// @nodoc
class _$PredefinedTagBucketsModelCopyWithImpl<$Res>
    implements $PredefinedTagBucketsModelCopyWith<$Res> {
  _$PredefinedTagBucketsModelCopyWithImpl(this._self, this._then);

  final PredefinedTagBucketsModel _self;
  final $Res Function(PredefinedTagBucketsModel) _then;

/// Create a copy of PredefinedTagBucketsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positive = null,Object? constructive = null,}) {
  return _then(_self.copyWith(
positive: null == positive ? _self.positive : positive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTagModel>,constructive: null == constructive ? _self.constructive : constructive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTagModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [PredefinedTagBucketsModel].
extension PredefinedTagBucketsModelPatterns on PredefinedTagBucketsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredefinedTagBucketsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredefinedTagBucketsModel value)  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredefinedTagBucketsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PredefinedTagModel> positive,  List<PredefinedTagModel> constructive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel() when $default != null:
return $default(_that.positive,_that.constructive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PredefinedTagModel> positive,  List<PredefinedTagModel> constructive)  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel():
return $default(_that.positive,_that.constructive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PredefinedTagModel> positive,  List<PredefinedTagModel> constructive)?  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagBucketsModel() when $default != null:
return $default(_that.positive,_that.constructive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PredefinedTagBucketsModel implements PredefinedTagBucketsModel {
  const _PredefinedTagBucketsModel({final  List<PredefinedTagModel> positive = const <PredefinedTagModel>[], final  List<PredefinedTagModel> constructive = const <PredefinedTagModel>[]}): _positive = positive,_constructive = constructive;
  factory _PredefinedTagBucketsModel.fromJson(Map<String, dynamic> json) => _$PredefinedTagBucketsModelFromJson(json);

 final  List<PredefinedTagModel> _positive;
@override@JsonKey() List<PredefinedTagModel> get positive {
  if (_positive is EqualUnmodifiableListView) return _positive;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positive);
}

 final  List<PredefinedTagModel> _constructive;
@override@JsonKey() List<PredefinedTagModel> get constructive {
  if (_constructive is EqualUnmodifiableListView) return _constructive;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constructive);
}


/// Create a copy of PredefinedTagBucketsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredefinedTagBucketsModelCopyWith<_PredefinedTagBucketsModel> get copyWith => __$PredefinedTagBucketsModelCopyWithImpl<_PredefinedTagBucketsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PredefinedTagBucketsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredefinedTagBucketsModel&&const DeepCollectionEquality().equals(other._positive, _positive)&&const DeepCollectionEquality().equals(other._constructive, _constructive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_positive),const DeepCollectionEquality().hash(_constructive));

@override
String toString() {
  return 'PredefinedTagBucketsModel(positive: $positive, constructive: $constructive)';
}


}

/// @nodoc
abstract mixin class _$PredefinedTagBucketsModelCopyWith<$Res> implements $PredefinedTagBucketsModelCopyWith<$Res> {
  factory _$PredefinedTagBucketsModelCopyWith(_PredefinedTagBucketsModel value, $Res Function(_PredefinedTagBucketsModel) _then) = __$PredefinedTagBucketsModelCopyWithImpl;
@override @useResult
$Res call({
 List<PredefinedTagModel> positive, List<PredefinedTagModel> constructive
});




}
/// @nodoc
class __$PredefinedTagBucketsModelCopyWithImpl<$Res>
    implements _$PredefinedTagBucketsModelCopyWith<$Res> {
  __$PredefinedTagBucketsModelCopyWithImpl(this._self, this._then);

  final _PredefinedTagBucketsModel _self;
  final $Res Function(_PredefinedTagBucketsModel) _then;

/// Create a copy of PredefinedTagBucketsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positive = null,Object? constructive = null,}) {
  return _then(_PredefinedTagBucketsModel(
positive: null == positive ? _self._positive : positive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTagModel>,constructive: null == constructive ? _self._constructive : constructive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTagModel>,
  ));
}


}


/// @nodoc
mixin _$BookingReviewSnapshotModel {

 ReviewModel? get review;@JsonKey(name: 'predefined_tags') PredefinedTagBucketsModel get predefinedTags;
/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingReviewSnapshotModelCopyWith<BookingReviewSnapshotModel> get copyWith => _$BookingReviewSnapshotModelCopyWithImpl<BookingReviewSnapshotModel>(this as BookingReviewSnapshotModel, _$identity);

  /// Serializes this BookingReviewSnapshotModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingReviewSnapshotModel&&(identical(other.review, review) || other.review == review)&&(identical(other.predefinedTags, predefinedTags) || other.predefinedTags == predefinedTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,review,predefinedTags);

@override
String toString() {
  return 'BookingReviewSnapshotModel(review: $review, predefinedTags: $predefinedTags)';
}


}

/// @nodoc
abstract mixin class $BookingReviewSnapshotModelCopyWith<$Res>  {
  factory $BookingReviewSnapshotModelCopyWith(BookingReviewSnapshotModel value, $Res Function(BookingReviewSnapshotModel) _then) = _$BookingReviewSnapshotModelCopyWithImpl;
@useResult
$Res call({
 ReviewModel? review,@JsonKey(name: 'predefined_tags') PredefinedTagBucketsModel predefinedTags
});


$ReviewModelCopyWith<$Res>? get review;$PredefinedTagBucketsModelCopyWith<$Res> get predefinedTags;

}
/// @nodoc
class _$BookingReviewSnapshotModelCopyWithImpl<$Res>
    implements $BookingReviewSnapshotModelCopyWith<$Res> {
  _$BookingReviewSnapshotModelCopyWithImpl(this._self, this._then);

  final BookingReviewSnapshotModel _self;
  final $Res Function(BookingReviewSnapshotModel) _then;

/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? review = freezed,Object? predefinedTags = null,}) {
  return _then(_self.copyWith(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as ReviewModel?,predefinedTags: null == predefinedTags ? _self.predefinedTags : predefinedTags // ignore: cast_nullable_to_non_nullable
as PredefinedTagBucketsModel,
  ));
}
/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewModelCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewModelCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredefinedTagBucketsModelCopyWith<$Res> get predefinedTags {
  
  return $PredefinedTagBucketsModelCopyWith<$Res>(_self.predefinedTags, (value) {
    return _then(_self.copyWith(predefinedTags: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingReviewSnapshotModel].
extension BookingReviewSnapshotModelPatterns on BookingReviewSnapshotModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingReviewSnapshotModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingReviewSnapshotModel value)  $default,){
final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingReviewSnapshotModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReviewModel? review, @JsonKey(name: 'predefined_tags')  PredefinedTagBucketsModel predefinedTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel() when $default != null:
return $default(_that.review,_that.predefinedTags);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReviewModel? review, @JsonKey(name: 'predefined_tags')  PredefinedTagBucketsModel predefinedTags)  $default,) {final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel():
return $default(_that.review,_that.predefinedTags);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReviewModel? review, @JsonKey(name: 'predefined_tags')  PredefinedTagBucketsModel predefinedTags)?  $default,) {final _that = this;
switch (_that) {
case _BookingReviewSnapshotModel() when $default != null:
return $default(_that.review,_that.predefinedTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingReviewSnapshotModel implements BookingReviewSnapshotModel {
  const _BookingReviewSnapshotModel({this.review, @JsonKey(name: 'predefined_tags') required this.predefinedTags});
  factory _BookingReviewSnapshotModel.fromJson(Map<String, dynamic> json) => _$BookingReviewSnapshotModelFromJson(json);

@override final  ReviewModel? review;
@override@JsonKey(name: 'predefined_tags') final  PredefinedTagBucketsModel predefinedTags;

/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingReviewSnapshotModelCopyWith<_BookingReviewSnapshotModel> get copyWith => __$BookingReviewSnapshotModelCopyWithImpl<_BookingReviewSnapshotModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingReviewSnapshotModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingReviewSnapshotModel&&(identical(other.review, review) || other.review == review)&&(identical(other.predefinedTags, predefinedTags) || other.predefinedTags == predefinedTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,review,predefinedTags);

@override
String toString() {
  return 'BookingReviewSnapshotModel(review: $review, predefinedTags: $predefinedTags)';
}


}

/// @nodoc
abstract mixin class _$BookingReviewSnapshotModelCopyWith<$Res> implements $BookingReviewSnapshotModelCopyWith<$Res> {
  factory _$BookingReviewSnapshotModelCopyWith(_BookingReviewSnapshotModel value, $Res Function(_BookingReviewSnapshotModel) _then) = __$BookingReviewSnapshotModelCopyWithImpl;
@override @useResult
$Res call({
 ReviewModel? review,@JsonKey(name: 'predefined_tags') PredefinedTagBucketsModel predefinedTags
});


@override $ReviewModelCopyWith<$Res>? get review;@override $PredefinedTagBucketsModelCopyWith<$Res> get predefinedTags;

}
/// @nodoc
class __$BookingReviewSnapshotModelCopyWithImpl<$Res>
    implements _$BookingReviewSnapshotModelCopyWith<$Res> {
  __$BookingReviewSnapshotModelCopyWithImpl(this._self, this._then);

  final _BookingReviewSnapshotModel _self;
  final $Res Function(_BookingReviewSnapshotModel) _then;

/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? review = freezed,Object? predefinedTags = null,}) {
  return _then(_BookingReviewSnapshotModel(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as ReviewModel?,predefinedTags: null == predefinedTags ? _self.predefinedTags : predefinedTags // ignore: cast_nullable_to_non_nullable
as PredefinedTagBucketsModel,
  ));
}

/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewModelCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewModelCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of BookingReviewSnapshotModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredefinedTagBucketsModelCopyWith<$Res> get predefinedTags {
  
  return $PredefinedTagBucketsModelCopyWith<$Res>(_self.predefinedTags, (value) {
    return _then(_self.copyWith(predefinedTags: value));
  });
}
}

// dart format on

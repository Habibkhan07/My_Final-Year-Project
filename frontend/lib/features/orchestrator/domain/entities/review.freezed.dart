// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Review {

 int get id; int get rating;// 1-5 inclusive
 List<String> get tags; String get text; DateTime get createdAt; String get reviewerName;
/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewCopyWith<Review> get copyWith => _$ReviewCopyWithImpl<Review>(this as Review, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Review&&(identical(other.id, id) || other.id == id)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName));
}


@override
int get hashCode => Object.hash(runtimeType,id,rating,const DeepCollectionEquality().hash(tags),text,createdAt,reviewerName);

@override
String toString() {
  return 'Review(id: $id, rating: $rating, tags: $tags, text: $text, createdAt: $createdAt, reviewerName: $reviewerName)';
}


}

/// @nodoc
abstract mixin class $ReviewCopyWith<$Res>  {
  factory $ReviewCopyWith(Review value, $Res Function(Review) _then) = _$ReviewCopyWithImpl;
@useResult
$Res call({
 int id, int rating, List<String> tags, String text, DateTime createdAt, String reviewerName
});




}
/// @nodoc
class _$ReviewCopyWithImpl<$Res>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._self, this._then);

  final Review _self;
  final $Res Function(Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rating = null,Object? tags = null,Object? text = null,Object? createdAt = null,Object? reviewerName = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Review].
extension ReviewPatterns on Review {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Review value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Review value)  $default,){
final _that = this;
switch (_that) {
case _Review():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Review value)?  $default,){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int rating,  List<String> tags,  String text,  DateTime createdAt,  String reviewerName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int rating,  List<String> tags,  String text,  DateTime createdAt,  String reviewerName)  $default,) {final _that = this;
switch (_that) {
case _Review():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int rating,  List<String> tags,  String text,  DateTime createdAt,  String reviewerName)?  $default,) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.id,_that.rating,_that.tags,_that.text,_that.createdAt,_that.reviewerName);case _:
  return null;

}
}

}

/// @nodoc


class _Review implements Review {
  const _Review({required this.id, required this.rating, required final  List<String> tags, required this.text, required this.createdAt, required this.reviewerName}): _tags = tags;
  

@override final  int id;
@override final  int rating;
// 1-5 inclusive
 final  List<String> _tags;
// 1-5 inclusive
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String text;
@override final  DateTime createdAt;
@override final  String reviewerName;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewCopyWith<_Review> get copyWith => __$ReviewCopyWithImpl<_Review>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Review&&(identical(other.id, id) || other.id == id)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewerName, reviewerName) || other.reviewerName == reviewerName));
}


@override
int get hashCode => Object.hash(runtimeType,id,rating,const DeepCollectionEquality().hash(_tags),text,createdAt,reviewerName);

@override
String toString() {
  return 'Review(id: $id, rating: $rating, tags: $tags, text: $text, createdAt: $createdAt, reviewerName: $reviewerName)';
}


}

/// @nodoc
abstract mixin class _$ReviewCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$ReviewCopyWith(_Review value, $Res Function(_Review) _then) = __$ReviewCopyWithImpl;
@override @useResult
$Res call({
 int id, int rating, List<String> tags, String text, DateTime createdAt, String reviewerName
});




}
/// @nodoc
class __$ReviewCopyWithImpl<$Res>
    implements _$ReviewCopyWith<$Res> {
  __$ReviewCopyWithImpl(this._self, this._then);

  final _Review _self;
  final $Res Function(_Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rating = null,Object? tags = null,Object? text = null,Object? createdAt = null,Object? reviewerName = null,}) {
  return _then(_Review(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewerName: null == reviewerName ? _self.reviewerName : reviewerName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PredefinedTag {

 String get key; String get label;
/// Create a copy of PredefinedTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredefinedTagCopyWith<PredefinedTag> get copyWith => _$PredefinedTagCopyWithImpl<PredefinedTag>(this as PredefinedTag, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredefinedTag&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,key,label);

@override
String toString() {
  return 'PredefinedTag(key: $key, label: $label)';
}


}

/// @nodoc
abstract mixin class $PredefinedTagCopyWith<$Res>  {
  factory $PredefinedTagCopyWith(PredefinedTag value, $Res Function(PredefinedTag) _then) = _$PredefinedTagCopyWithImpl;
@useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class _$PredefinedTagCopyWithImpl<$Res>
    implements $PredefinedTagCopyWith<$Res> {
  _$PredefinedTagCopyWithImpl(this._self, this._then);

  final PredefinedTag _self;
  final $Res Function(PredefinedTag) _then;

/// Create a copy of PredefinedTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? label = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PredefinedTag].
extension PredefinedTagPatterns on PredefinedTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredefinedTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredefinedTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredefinedTag value)  $default,){
final _that = this;
switch (_that) {
case _PredefinedTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredefinedTag value)?  $default,){
final _that = this;
switch (_that) {
case _PredefinedTag() when $default != null:
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
case _PredefinedTag() when $default != null:
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
case _PredefinedTag():
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
case _PredefinedTag() when $default != null:
return $default(_that.key,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _PredefinedTag implements PredefinedTag {
  const _PredefinedTag({required this.key, required this.label});
  

@override final  String key;
@override final  String label;

/// Create a copy of PredefinedTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredefinedTagCopyWith<_PredefinedTag> get copyWith => __$PredefinedTagCopyWithImpl<_PredefinedTag>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredefinedTag&&(identical(other.key, key) || other.key == key)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,key,label);

@override
String toString() {
  return 'PredefinedTag(key: $key, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PredefinedTagCopyWith<$Res> implements $PredefinedTagCopyWith<$Res> {
  factory _$PredefinedTagCopyWith(_PredefinedTag value, $Res Function(_PredefinedTag) _then) = __$PredefinedTagCopyWithImpl;
@override @useResult
$Res call({
 String key, String label
});




}
/// @nodoc
class __$PredefinedTagCopyWithImpl<$Res>
    implements _$PredefinedTagCopyWith<$Res> {
  __$PredefinedTagCopyWithImpl(this._self, this._then);

  final _PredefinedTag _self;
  final $Res Function(_PredefinedTag) _then;

/// Create a copy of PredefinedTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? label = null,}) {
  return _then(_PredefinedTag(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$PredefinedTagBuckets {

 List<PredefinedTag> get positive; List<PredefinedTag> get constructive;
/// Create a copy of PredefinedTagBuckets
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PredefinedTagBucketsCopyWith<PredefinedTagBuckets> get copyWith => _$PredefinedTagBucketsCopyWithImpl<PredefinedTagBuckets>(this as PredefinedTagBuckets, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PredefinedTagBuckets&&const DeepCollectionEquality().equals(other.positive, positive)&&const DeepCollectionEquality().equals(other.constructive, constructive));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(positive),const DeepCollectionEquality().hash(constructive));

@override
String toString() {
  return 'PredefinedTagBuckets(positive: $positive, constructive: $constructive)';
}


}

/// @nodoc
abstract mixin class $PredefinedTagBucketsCopyWith<$Res>  {
  factory $PredefinedTagBucketsCopyWith(PredefinedTagBuckets value, $Res Function(PredefinedTagBuckets) _then) = _$PredefinedTagBucketsCopyWithImpl;
@useResult
$Res call({
 List<PredefinedTag> positive, List<PredefinedTag> constructive
});




}
/// @nodoc
class _$PredefinedTagBucketsCopyWithImpl<$Res>
    implements $PredefinedTagBucketsCopyWith<$Res> {
  _$PredefinedTagBucketsCopyWithImpl(this._self, this._then);

  final PredefinedTagBuckets _self;
  final $Res Function(PredefinedTagBuckets) _then;

/// Create a copy of PredefinedTagBuckets
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? positive = null,Object? constructive = null,}) {
  return _then(_self.copyWith(
positive: null == positive ? _self.positive : positive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTag>,constructive: null == constructive ? _self.constructive : constructive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTag>,
  ));
}

}


/// Adds pattern-matching-related methods to [PredefinedTagBuckets].
extension PredefinedTagBucketsPatterns on PredefinedTagBuckets {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PredefinedTagBuckets value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PredefinedTagBuckets() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PredefinedTagBuckets value)  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagBuckets():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PredefinedTagBuckets value)?  $default,){
final _that = this;
switch (_that) {
case _PredefinedTagBuckets() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PredefinedTag> positive,  List<PredefinedTag> constructive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PredefinedTagBuckets() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PredefinedTag> positive,  List<PredefinedTag> constructive)  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagBuckets():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PredefinedTag> positive,  List<PredefinedTag> constructive)?  $default,) {final _that = this;
switch (_that) {
case _PredefinedTagBuckets() when $default != null:
return $default(_that.positive,_that.constructive);case _:
  return null;

}
}

}

/// @nodoc


class _PredefinedTagBuckets implements PredefinedTagBuckets {
  const _PredefinedTagBuckets({required final  List<PredefinedTag> positive, required final  List<PredefinedTag> constructive}): _positive = positive,_constructive = constructive;
  

 final  List<PredefinedTag> _positive;
@override List<PredefinedTag> get positive {
  if (_positive is EqualUnmodifiableListView) return _positive;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_positive);
}

 final  List<PredefinedTag> _constructive;
@override List<PredefinedTag> get constructive {
  if (_constructive is EqualUnmodifiableListView) return _constructive;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_constructive);
}


/// Create a copy of PredefinedTagBuckets
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PredefinedTagBucketsCopyWith<_PredefinedTagBuckets> get copyWith => __$PredefinedTagBucketsCopyWithImpl<_PredefinedTagBuckets>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PredefinedTagBuckets&&const DeepCollectionEquality().equals(other._positive, _positive)&&const DeepCollectionEquality().equals(other._constructive, _constructive));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_positive),const DeepCollectionEquality().hash(_constructive));

@override
String toString() {
  return 'PredefinedTagBuckets(positive: $positive, constructive: $constructive)';
}


}

/// @nodoc
abstract mixin class _$PredefinedTagBucketsCopyWith<$Res> implements $PredefinedTagBucketsCopyWith<$Res> {
  factory _$PredefinedTagBucketsCopyWith(_PredefinedTagBuckets value, $Res Function(_PredefinedTagBuckets) _then) = __$PredefinedTagBucketsCopyWithImpl;
@override @useResult
$Res call({
 List<PredefinedTag> positive, List<PredefinedTag> constructive
});




}
/// @nodoc
class __$PredefinedTagBucketsCopyWithImpl<$Res>
    implements _$PredefinedTagBucketsCopyWith<$Res> {
  __$PredefinedTagBucketsCopyWithImpl(this._self, this._then);

  final _PredefinedTagBuckets _self;
  final $Res Function(_PredefinedTagBuckets) _then;

/// Create a copy of PredefinedTagBuckets
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? positive = null,Object? constructive = null,}) {
  return _then(_PredefinedTagBuckets(
positive: null == positive ? _self._positive : positive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTag>,constructive: null == constructive ? _self._constructive : constructive // ignore: cast_nullable_to_non_nullable
as List<PredefinedTag>,
  ));
}


}

/// @nodoc
mixin _$BookingReviewSnapshot {

 Review? get review; PredefinedTagBuckets get predefinedTags;
/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingReviewSnapshotCopyWith<BookingReviewSnapshot> get copyWith => _$BookingReviewSnapshotCopyWithImpl<BookingReviewSnapshot>(this as BookingReviewSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingReviewSnapshot&&(identical(other.review, review) || other.review == review)&&(identical(other.predefinedTags, predefinedTags) || other.predefinedTags == predefinedTags));
}


@override
int get hashCode => Object.hash(runtimeType,review,predefinedTags);

@override
String toString() {
  return 'BookingReviewSnapshot(review: $review, predefinedTags: $predefinedTags)';
}


}

/// @nodoc
abstract mixin class $BookingReviewSnapshotCopyWith<$Res>  {
  factory $BookingReviewSnapshotCopyWith(BookingReviewSnapshot value, $Res Function(BookingReviewSnapshot) _then) = _$BookingReviewSnapshotCopyWithImpl;
@useResult
$Res call({
 Review? review, PredefinedTagBuckets predefinedTags
});


$ReviewCopyWith<$Res>? get review;$PredefinedTagBucketsCopyWith<$Res> get predefinedTags;

}
/// @nodoc
class _$BookingReviewSnapshotCopyWithImpl<$Res>
    implements $BookingReviewSnapshotCopyWith<$Res> {
  _$BookingReviewSnapshotCopyWithImpl(this._self, this._then);

  final BookingReviewSnapshot _self;
  final $Res Function(BookingReviewSnapshot) _then;

/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? review = freezed,Object? predefinedTags = null,}) {
  return _then(_self.copyWith(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,predefinedTags: null == predefinedTags ? _self.predefinedTags : predefinedTags // ignore: cast_nullable_to_non_nullable
as PredefinedTagBuckets,
  ));
}
/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredefinedTagBucketsCopyWith<$Res> get predefinedTags {
  
  return $PredefinedTagBucketsCopyWith<$Res>(_self.predefinedTags, (value) {
    return _then(_self.copyWith(predefinedTags: value));
  });
}
}


/// Adds pattern-matching-related methods to [BookingReviewSnapshot].
extension BookingReviewSnapshotPatterns on BookingReviewSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingReviewSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingReviewSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingReviewSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _BookingReviewSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingReviewSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _BookingReviewSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Review? review,  PredefinedTagBuckets predefinedTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingReviewSnapshot() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Review? review,  PredefinedTagBuckets predefinedTags)  $default,) {final _that = this;
switch (_that) {
case _BookingReviewSnapshot():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Review? review,  PredefinedTagBuckets predefinedTags)?  $default,) {final _that = this;
switch (_that) {
case _BookingReviewSnapshot() when $default != null:
return $default(_that.review,_that.predefinedTags);case _:
  return null;

}
}

}

/// @nodoc


class _BookingReviewSnapshot implements BookingReviewSnapshot {
  const _BookingReviewSnapshot({required this.review, required this.predefinedTags});
  

@override final  Review? review;
@override final  PredefinedTagBuckets predefinedTags;

/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingReviewSnapshotCopyWith<_BookingReviewSnapshot> get copyWith => __$BookingReviewSnapshotCopyWithImpl<_BookingReviewSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingReviewSnapshot&&(identical(other.review, review) || other.review == review)&&(identical(other.predefinedTags, predefinedTags) || other.predefinedTags == predefinedTags));
}


@override
int get hashCode => Object.hash(runtimeType,review,predefinedTags);

@override
String toString() {
  return 'BookingReviewSnapshot(review: $review, predefinedTags: $predefinedTags)';
}


}

/// @nodoc
abstract mixin class _$BookingReviewSnapshotCopyWith<$Res> implements $BookingReviewSnapshotCopyWith<$Res> {
  factory _$BookingReviewSnapshotCopyWith(_BookingReviewSnapshot value, $Res Function(_BookingReviewSnapshot) _then) = __$BookingReviewSnapshotCopyWithImpl;
@override @useResult
$Res call({
 Review? review, PredefinedTagBuckets predefinedTags
});


@override $ReviewCopyWith<$Res>? get review;@override $PredefinedTagBucketsCopyWith<$Res> get predefinedTags;

}
/// @nodoc
class __$BookingReviewSnapshotCopyWithImpl<$Res>
    implements _$BookingReviewSnapshotCopyWith<$Res> {
  __$BookingReviewSnapshotCopyWithImpl(this._self, this._then);

  final _BookingReviewSnapshot _self;
  final $Res Function(_BookingReviewSnapshot) _then;

/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? review = freezed,Object? predefinedTags = null,}) {
  return _then(_BookingReviewSnapshot(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,predefinedTags: null == predefinedTags ? _self.predefinedTags : predefinedTags // ignore: cast_nullable_to_non_nullable
as PredefinedTagBuckets,
  ));
}

/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}/// Create a copy of BookingReviewSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PredefinedTagBucketsCopyWith<$Res> get predefinedTags {
  
  return $PredefinedTagBucketsCopyWith<$Res>(_self.predefinedTags, (value) {
    return _then(_self.copyWith(predefinedTags: value));
  });
}
}

// dart format on

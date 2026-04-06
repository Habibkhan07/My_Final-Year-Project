// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'technician_registration_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TechnicianRegistrationModel {

@JsonKey(name: 'first_name') String get firstName;@JsonKey(name: 'last_name') String get lastName; String get city;@JsonKey(name: 'cnic_number') String get cnicNumber;@JsonKey(name: 'experience_years') int get experienceYears; String get bio;@JsonKey(name: 'profile_picture_uuid') String get profilePictureUuid;@JsonKey(name: 'cnic_picture_uuid') String get cnicPictureUuid;@JsonKey(name: 'category_licenses') List<CategoryLicenseInputModel> get categoryLicenses; List<SkillInputModel> get skills;
/// Create a copy of TechnicianRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TechnicianRegistrationModelCopyWith<TechnicianRegistrationModel> get copyWith => _$TechnicianRegistrationModelCopyWithImpl<TechnicianRegistrationModel>(this as TechnicianRegistrationModel, _$identity);

  /// Serializes this TechnicianRegistrationModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TechnicianRegistrationModel&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.city, city) || other.city == city)&&(identical(other.cnicNumber, cnicNumber) || other.cnicNumber == cnicNumber)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profilePictureUuid, profilePictureUuid) || other.profilePictureUuid == profilePictureUuid)&&(identical(other.cnicPictureUuid, cnicPictureUuid) || other.cnicPictureUuid == cnicPictureUuid)&&const DeepCollectionEquality().equals(other.categoryLicenses, categoryLicenses)&&const DeepCollectionEquality().equals(other.skills, skills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,city,cnicNumber,experienceYears,bio,profilePictureUuid,cnicPictureUuid,const DeepCollectionEquality().hash(categoryLicenses),const DeepCollectionEquality().hash(skills));

@override
String toString() {
  return 'TechnicianRegistrationModel(firstName: $firstName, lastName: $lastName, city: $city, cnicNumber: $cnicNumber, experienceYears: $experienceYears, bio: $bio, profilePictureUuid: $profilePictureUuid, cnicPictureUuid: $cnicPictureUuid, categoryLicenses: $categoryLicenses, skills: $skills)';
}


}

/// @nodoc
abstract mixin class $TechnicianRegistrationModelCopyWith<$Res>  {
  factory $TechnicianRegistrationModelCopyWith(TechnicianRegistrationModel value, $Res Function(TechnicianRegistrationModel) _then) = _$TechnicianRegistrationModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String city,@JsonKey(name: 'cnic_number') String cnicNumber,@JsonKey(name: 'experience_years') int experienceYears, String bio,@JsonKey(name: 'profile_picture_uuid') String profilePictureUuid,@JsonKey(name: 'cnic_picture_uuid') String cnicPictureUuid,@JsonKey(name: 'category_licenses') List<CategoryLicenseInputModel> categoryLicenses, List<SkillInputModel> skills
});




}
/// @nodoc
class _$TechnicianRegistrationModelCopyWithImpl<$Res>
    implements $TechnicianRegistrationModelCopyWith<$Res> {
  _$TechnicianRegistrationModelCopyWithImpl(this._self, this._then);

  final TechnicianRegistrationModel _self;
  final $Res Function(TechnicianRegistrationModel) _then;

/// Create a copy of TechnicianRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? firstName = null,Object? lastName = null,Object? city = null,Object? cnicNumber = null,Object? experienceYears = null,Object? bio = null,Object? profilePictureUuid = null,Object? cnicPictureUuid = null,Object? categoryLicenses = null,Object? skills = null,}) {
  return _then(_self.copyWith(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,cnicNumber: null == cnicNumber ? _self.cnicNumber : cnicNumber // ignore: cast_nullable_to_non_nullable
as String,experienceYears: null == experienceYears ? _self.experienceYears : experienceYears // ignore: cast_nullable_to_non_nullable
as int,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,profilePictureUuid: null == profilePictureUuid ? _self.profilePictureUuid : profilePictureUuid // ignore: cast_nullable_to_non_nullable
as String,cnicPictureUuid: null == cnicPictureUuid ? _self.cnicPictureUuid : cnicPictureUuid // ignore: cast_nullable_to_non_nullable
as String,categoryLicenses: null == categoryLicenses ? _self.categoryLicenses : categoryLicenses // ignore: cast_nullable_to_non_nullable
as List<CategoryLicenseInputModel>,skills: null == skills ? _self.skills : skills // ignore: cast_nullable_to_non_nullable
as List<SkillInputModel>,
  ));
}

}


/// Adds pattern-matching-related methods to [TechnicianRegistrationModel].
extension TechnicianRegistrationModelPatterns on TechnicianRegistrationModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TechnicianRegistrationModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TechnicianRegistrationModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TechnicianRegistrationModel value)  $default,){
final _that = this;
switch (_that) {
case _TechnicianRegistrationModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TechnicianRegistrationModel value)?  $default,){
final _that = this;
switch (_that) {
case _TechnicianRegistrationModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String city, @JsonKey(name: 'cnic_number')  String cnicNumber, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'profile_picture_uuid')  String profilePictureUuid, @JsonKey(name: 'cnic_picture_uuid')  String cnicPictureUuid, @JsonKey(name: 'category_licenses')  List<CategoryLicenseInputModel> categoryLicenses,  List<SkillInputModel> skills)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TechnicianRegistrationModel() when $default != null:
return $default(_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.experienceYears,_that.bio,_that.profilePictureUuid,_that.cnicPictureUuid,_that.categoryLicenses,_that.skills);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String city, @JsonKey(name: 'cnic_number')  String cnicNumber, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'profile_picture_uuid')  String profilePictureUuid, @JsonKey(name: 'cnic_picture_uuid')  String cnicPictureUuid, @JsonKey(name: 'category_licenses')  List<CategoryLicenseInputModel> categoryLicenses,  List<SkillInputModel> skills)  $default,) {final _that = this;
switch (_that) {
case _TechnicianRegistrationModel():
return $default(_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.experienceYears,_that.bio,_that.profilePictureUuid,_that.cnicPictureUuid,_that.categoryLicenses,_that.skills);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'first_name')  String firstName, @JsonKey(name: 'last_name')  String lastName,  String city, @JsonKey(name: 'cnic_number')  String cnicNumber, @JsonKey(name: 'experience_years')  int experienceYears,  String bio, @JsonKey(name: 'profile_picture_uuid')  String profilePictureUuid, @JsonKey(name: 'cnic_picture_uuid')  String cnicPictureUuid, @JsonKey(name: 'category_licenses')  List<CategoryLicenseInputModel> categoryLicenses,  List<SkillInputModel> skills)?  $default,) {final _that = this;
switch (_that) {
case _TechnicianRegistrationModel() when $default != null:
return $default(_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.experienceYears,_that.bio,_that.profilePictureUuid,_that.cnicPictureUuid,_that.categoryLicenses,_that.skills);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TechnicianRegistrationModel implements TechnicianRegistrationModel {
  const _TechnicianRegistrationModel({@JsonKey(name: 'first_name') required this.firstName, @JsonKey(name: 'last_name') required this.lastName, required this.city, @JsonKey(name: 'cnic_number') required this.cnicNumber, @JsonKey(name: 'experience_years') required this.experienceYears, required this.bio, @JsonKey(name: 'profile_picture_uuid') required this.profilePictureUuid, @JsonKey(name: 'cnic_picture_uuid') required this.cnicPictureUuid, @JsonKey(name: 'category_licenses') required final  List<CategoryLicenseInputModel> categoryLicenses, required final  List<SkillInputModel> skills}): _categoryLicenses = categoryLicenses,_skills = skills;
  factory _TechnicianRegistrationModel.fromJson(Map<String, dynamic> json) => _$TechnicianRegistrationModelFromJson(json);

@override@JsonKey(name: 'first_name') final  String firstName;
@override@JsonKey(name: 'last_name') final  String lastName;
@override final  String city;
@override@JsonKey(name: 'cnic_number') final  String cnicNumber;
@override@JsonKey(name: 'experience_years') final  int experienceYears;
@override final  String bio;
@override@JsonKey(name: 'profile_picture_uuid') final  String profilePictureUuid;
@override@JsonKey(name: 'cnic_picture_uuid') final  String cnicPictureUuid;
 final  List<CategoryLicenseInputModel> _categoryLicenses;
@override@JsonKey(name: 'category_licenses') List<CategoryLicenseInputModel> get categoryLicenses {
  if (_categoryLicenses is EqualUnmodifiableListView) return _categoryLicenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryLicenses);
}

 final  List<SkillInputModel> _skills;
@override List<SkillInputModel> get skills {
  if (_skills is EqualUnmodifiableListView) return _skills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_skills);
}


/// Create a copy of TechnicianRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TechnicianRegistrationModelCopyWith<_TechnicianRegistrationModel> get copyWith => __$TechnicianRegistrationModelCopyWithImpl<_TechnicianRegistrationModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TechnicianRegistrationModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TechnicianRegistrationModel&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.city, city) || other.city == city)&&(identical(other.cnicNumber, cnicNumber) || other.cnicNumber == cnicNumber)&&(identical(other.experienceYears, experienceYears) || other.experienceYears == experienceYears)&&(identical(other.bio, bio) || other.bio == bio)&&(identical(other.profilePictureUuid, profilePictureUuid) || other.profilePictureUuid == profilePictureUuid)&&(identical(other.cnicPictureUuid, cnicPictureUuid) || other.cnicPictureUuid == cnicPictureUuid)&&const DeepCollectionEquality().equals(other._categoryLicenses, _categoryLicenses)&&const DeepCollectionEquality().equals(other._skills, _skills));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,firstName,lastName,city,cnicNumber,experienceYears,bio,profilePictureUuid,cnicPictureUuid,const DeepCollectionEquality().hash(_categoryLicenses),const DeepCollectionEquality().hash(_skills));

@override
String toString() {
  return 'TechnicianRegistrationModel(firstName: $firstName, lastName: $lastName, city: $city, cnicNumber: $cnicNumber, experienceYears: $experienceYears, bio: $bio, profilePictureUuid: $profilePictureUuid, cnicPictureUuid: $cnicPictureUuid, categoryLicenses: $categoryLicenses, skills: $skills)';
}


}

/// @nodoc
abstract mixin class _$TechnicianRegistrationModelCopyWith<$Res> implements $TechnicianRegistrationModelCopyWith<$Res> {
  factory _$TechnicianRegistrationModelCopyWith(_TechnicianRegistrationModel value, $Res Function(_TechnicianRegistrationModel) _then) = __$TechnicianRegistrationModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'first_name') String firstName,@JsonKey(name: 'last_name') String lastName, String city,@JsonKey(name: 'cnic_number') String cnicNumber,@JsonKey(name: 'experience_years') int experienceYears, String bio,@JsonKey(name: 'profile_picture_uuid') String profilePictureUuid,@JsonKey(name: 'cnic_picture_uuid') String cnicPictureUuid,@JsonKey(name: 'category_licenses') List<CategoryLicenseInputModel> categoryLicenses, List<SkillInputModel> skills
});




}
/// @nodoc
class __$TechnicianRegistrationModelCopyWithImpl<$Res>
    implements _$TechnicianRegistrationModelCopyWith<$Res> {
  __$TechnicianRegistrationModelCopyWithImpl(this._self, this._then);

  final _TechnicianRegistrationModel _self;
  final $Res Function(_TechnicianRegistrationModel) _then;

/// Create a copy of TechnicianRegistrationModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? firstName = null,Object? lastName = null,Object? city = null,Object? cnicNumber = null,Object? experienceYears = null,Object? bio = null,Object? profilePictureUuid = null,Object? cnicPictureUuid = null,Object? categoryLicenses = null,Object? skills = null,}) {
  return _then(_TechnicianRegistrationModel(
firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,cnicNumber: null == cnicNumber ? _self.cnicNumber : cnicNumber // ignore: cast_nullable_to_non_nullable
as String,experienceYears: null == experienceYears ? _self.experienceYears : experienceYears // ignore: cast_nullable_to_non_nullable
as int,bio: null == bio ? _self.bio : bio // ignore: cast_nullable_to_non_nullable
as String,profilePictureUuid: null == profilePictureUuid ? _self.profilePictureUuid : profilePictureUuid // ignore: cast_nullable_to_non_nullable
as String,cnicPictureUuid: null == cnicPictureUuid ? _self.cnicPictureUuid : cnicPictureUuid // ignore: cast_nullable_to_non_nullable
as String,categoryLicenses: null == categoryLicenses ? _self._categoryLicenses : categoryLicenses // ignore: cast_nullable_to_non_nullable
as List<CategoryLicenseInputModel>,skills: null == skills ? _self._skills : skills // ignore: cast_nullable_to_non_nullable
as List<SkillInputModel>,
  ));
}


}


/// @nodoc
mixin _$CategoryLicenseInputModel {

@JsonKey(name: 'service_id') int get serviceId;@JsonKey(name: 'media_uuid') String get mediaUuid;
/// Create a copy of CategoryLicenseInputModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryLicenseInputModelCopyWith<CategoryLicenseInputModel> get copyWith => _$CategoryLicenseInputModelCopyWithImpl<CategoryLicenseInputModel>(this as CategoryLicenseInputModel, _$identity);

  /// Serializes this CategoryLicenseInputModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryLicenseInputModel&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.mediaUuid, mediaUuid) || other.mediaUuid == mediaUuid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceId,mediaUuid);

@override
String toString() {
  return 'CategoryLicenseInputModel(serviceId: $serviceId, mediaUuid: $mediaUuid)';
}


}

/// @nodoc
abstract mixin class $CategoryLicenseInputModelCopyWith<$Res>  {
  factory $CategoryLicenseInputModelCopyWith(CategoryLicenseInputModel value, $Res Function(CategoryLicenseInputModel) _then) = _$CategoryLicenseInputModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'service_id') int serviceId,@JsonKey(name: 'media_uuid') String mediaUuid
});




}
/// @nodoc
class _$CategoryLicenseInputModelCopyWithImpl<$Res>
    implements $CategoryLicenseInputModelCopyWith<$Res> {
  _$CategoryLicenseInputModelCopyWithImpl(this._self, this._then);

  final CategoryLicenseInputModel _self;
  final $Res Function(CategoryLicenseInputModel) _then;

/// Create a copy of CategoryLicenseInputModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serviceId = null,Object? mediaUuid = null,}) {
  return _then(_self.copyWith(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int,mediaUuid: null == mediaUuid ? _self.mediaUuid : mediaUuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryLicenseInputModel].
extension CategoryLicenseInputModelPatterns on CategoryLicenseInputModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryLicenseInputModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryLicenseInputModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryLicenseInputModel value)  $default,){
final _that = this;
switch (_that) {
case _CategoryLicenseInputModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryLicenseInputModel value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryLicenseInputModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'service_id')  int serviceId, @JsonKey(name: 'media_uuid')  String mediaUuid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryLicenseInputModel() when $default != null:
return $default(_that.serviceId,_that.mediaUuid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'service_id')  int serviceId, @JsonKey(name: 'media_uuid')  String mediaUuid)  $default,) {final _that = this;
switch (_that) {
case _CategoryLicenseInputModel():
return $default(_that.serviceId,_that.mediaUuid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'service_id')  int serviceId, @JsonKey(name: 'media_uuid')  String mediaUuid)?  $default,) {final _that = this;
switch (_that) {
case _CategoryLicenseInputModel() when $default != null:
return $default(_that.serviceId,_that.mediaUuid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryLicenseInputModel implements CategoryLicenseInputModel {
  const _CategoryLicenseInputModel({@JsonKey(name: 'service_id') required this.serviceId, @JsonKey(name: 'media_uuid') required this.mediaUuid});
  factory _CategoryLicenseInputModel.fromJson(Map<String, dynamic> json) => _$CategoryLicenseInputModelFromJson(json);

@override@JsonKey(name: 'service_id') final  int serviceId;
@override@JsonKey(name: 'media_uuid') final  String mediaUuid;

/// Create a copy of CategoryLicenseInputModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryLicenseInputModelCopyWith<_CategoryLicenseInputModel> get copyWith => __$CategoryLicenseInputModelCopyWithImpl<_CategoryLicenseInputModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryLicenseInputModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryLicenseInputModel&&(identical(other.serviceId, serviceId) || other.serviceId == serviceId)&&(identical(other.mediaUuid, mediaUuid) || other.mediaUuid == mediaUuid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceId,mediaUuid);

@override
String toString() {
  return 'CategoryLicenseInputModel(serviceId: $serviceId, mediaUuid: $mediaUuid)';
}


}

/// @nodoc
abstract mixin class _$CategoryLicenseInputModelCopyWith<$Res> implements $CategoryLicenseInputModelCopyWith<$Res> {
  factory _$CategoryLicenseInputModelCopyWith(_CategoryLicenseInputModel value, $Res Function(_CategoryLicenseInputModel) _then) = __$CategoryLicenseInputModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'service_id') int serviceId,@JsonKey(name: 'media_uuid') String mediaUuid
});




}
/// @nodoc
class __$CategoryLicenseInputModelCopyWithImpl<$Res>
    implements _$CategoryLicenseInputModelCopyWith<$Res> {
  __$CategoryLicenseInputModelCopyWithImpl(this._self, this._then);

  final _CategoryLicenseInputModel _self;
  final $Res Function(_CategoryLicenseInputModel) _then;

/// Create a copy of CategoryLicenseInputModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serviceId = null,Object? mediaUuid = null,}) {
  return _then(_CategoryLicenseInputModel(
serviceId: null == serviceId ? _self.serviceId : serviceId // ignore: cast_nullable_to_non_nullable
as int,mediaUuid: null == mediaUuid ? _self.mediaUuid : mediaUuid // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SkillInputModel {

@JsonKey(name: 'sub_service_id') int get subServiceId;@JsonKey(name: 'years_of_experience') int get yearsOfExperience;@JsonKey(name: 'base_rate') String? get baseRate;@JsonKey(name: 'max_rate') String? get maxRate;
/// Create a copy of SkillInputModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkillInputModelCopyWith<SkillInputModel> get copyWith => _$SkillInputModelCopyWithImpl<SkillInputModel>(this as SkillInputModel, _$identity);

  /// Serializes this SkillInputModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkillInputModel&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&(identical(other.baseRate, baseRate) || other.baseRate == baseRate)&&(identical(other.maxRate, maxRate) || other.maxRate == maxRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subServiceId,yearsOfExperience,baseRate,maxRate);

@override
String toString() {
  return 'SkillInputModel(subServiceId: $subServiceId, yearsOfExperience: $yearsOfExperience, baseRate: $baseRate, maxRate: $maxRate)';
}


}

/// @nodoc
abstract mixin class $SkillInputModelCopyWith<$Res>  {
  factory $SkillInputModelCopyWith(SkillInputModel value, $Res Function(SkillInputModel) _then) = _$SkillInputModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'years_of_experience') int yearsOfExperience,@JsonKey(name: 'base_rate') String? baseRate,@JsonKey(name: 'max_rate') String? maxRate
});




}
/// @nodoc
class _$SkillInputModelCopyWithImpl<$Res>
    implements $SkillInputModelCopyWith<$Res> {
  _$SkillInputModelCopyWithImpl(this._self, this._then);

  final SkillInputModel _self;
  final $Res Function(SkillInputModel) _then;

/// Create a copy of SkillInputModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subServiceId = null,Object? yearsOfExperience = null,Object? baseRate = freezed,Object? maxRate = freezed,}) {
  return _then(_self.copyWith(
subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as int,baseRate: freezed == baseRate ? _self.baseRate : baseRate // ignore: cast_nullable_to_non_nullable
as String?,maxRate: freezed == maxRate ? _self.maxRate : maxRate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SkillInputModel].
extension SkillInputModelPatterns on SkillInputModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkillInputModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkillInputModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkillInputModel value)  $default,){
final _that = this;
switch (_that) {
case _SkillInputModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkillInputModel value)?  $default,){
final _that = this;
switch (_that) {
case _SkillInputModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'years_of_experience')  int yearsOfExperience, @JsonKey(name: 'base_rate')  String? baseRate, @JsonKey(name: 'max_rate')  String? maxRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkillInputModel() when $default != null:
return $default(_that.subServiceId,_that.yearsOfExperience,_that.baseRate,_that.maxRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'years_of_experience')  int yearsOfExperience, @JsonKey(name: 'base_rate')  String? baseRate, @JsonKey(name: 'max_rate')  String? maxRate)  $default,) {final _that = this;
switch (_that) {
case _SkillInputModel():
return $default(_that.subServiceId,_that.yearsOfExperience,_that.baseRate,_that.maxRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'sub_service_id')  int subServiceId, @JsonKey(name: 'years_of_experience')  int yearsOfExperience, @JsonKey(name: 'base_rate')  String? baseRate, @JsonKey(name: 'max_rate')  String? maxRate)?  $default,) {final _that = this;
switch (_that) {
case _SkillInputModel() when $default != null:
return $default(_that.subServiceId,_that.yearsOfExperience,_that.baseRate,_that.maxRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SkillInputModel implements SkillInputModel {
  const _SkillInputModel({@JsonKey(name: 'sub_service_id') required this.subServiceId, @JsonKey(name: 'years_of_experience') required this.yearsOfExperience, @JsonKey(name: 'base_rate') this.baseRate, @JsonKey(name: 'max_rate') this.maxRate});
  factory _SkillInputModel.fromJson(Map<String, dynamic> json) => _$SkillInputModelFromJson(json);

@override@JsonKey(name: 'sub_service_id') final  int subServiceId;
@override@JsonKey(name: 'years_of_experience') final  int yearsOfExperience;
@override@JsonKey(name: 'base_rate') final  String? baseRate;
@override@JsonKey(name: 'max_rate') final  String? maxRate;

/// Create a copy of SkillInputModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkillInputModelCopyWith<_SkillInputModel> get copyWith => __$SkillInputModelCopyWithImpl<_SkillInputModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkillInputModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkillInputModel&&(identical(other.subServiceId, subServiceId) || other.subServiceId == subServiceId)&&(identical(other.yearsOfExperience, yearsOfExperience) || other.yearsOfExperience == yearsOfExperience)&&(identical(other.baseRate, baseRate) || other.baseRate == baseRate)&&(identical(other.maxRate, maxRate) || other.maxRate == maxRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,subServiceId,yearsOfExperience,baseRate,maxRate);

@override
String toString() {
  return 'SkillInputModel(subServiceId: $subServiceId, yearsOfExperience: $yearsOfExperience, baseRate: $baseRate, maxRate: $maxRate)';
}


}

/// @nodoc
abstract mixin class _$SkillInputModelCopyWith<$Res> implements $SkillInputModelCopyWith<$Res> {
  factory _$SkillInputModelCopyWith(_SkillInputModel value, $Res Function(_SkillInputModel) _then) = __$SkillInputModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sub_service_id') int subServiceId,@JsonKey(name: 'years_of_experience') int yearsOfExperience,@JsonKey(name: 'base_rate') String? baseRate,@JsonKey(name: 'max_rate') String? maxRate
});




}
/// @nodoc
class __$SkillInputModelCopyWithImpl<$Res>
    implements _$SkillInputModelCopyWith<$Res> {
  __$SkillInputModelCopyWithImpl(this._self, this._then);

  final _SkillInputModel _self;
  final $Res Function(_SkillInputModel) _then;

/// Create a copy of SkillInputModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subServiceId = null,Object? yearsOfExperience = null,Object? baseRate = freezed,Object? maxRate = freezed,}) {
  return _then(_SkillInputModel(
subServiceId: null == subServiceId ? _self.subServiceId : subServiceId // ignore: cast_nullable_to_non_nullable
as int,yearsOfExperience: null == yearsOfExperience ? _self.yearsOfExperience : yearsOfExperience // ignore: cast_nullable_to_non_nullable
as int,baseRate: freezed == baseRate ? _self.baseRate : baseRate // ignore: cast_nullable_to_non_nullable
as String?,maxRate: freezed == maxRate ? _self.maxRate : maxRate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

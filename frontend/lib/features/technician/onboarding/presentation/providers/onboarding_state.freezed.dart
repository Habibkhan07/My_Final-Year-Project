// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingState {

 int get currentStep; String get firstName; String get lastName; String get city; String get cnicNumber; String? get profilePictureUuid; String? get cnicPictureUuid;// Local file paths for in-wizard thumbnail previews. The wire payload
// only carries the UUIDs (above); these stay on the client so the
// user can see what they captured and decide whether to retake.
// Cleared on submit; never persisted.
 String? get profilePicturePath; String? get cnicPicturePath; Map<int, String> get categoryLicensePaths;// Storing the metadata fetched from the backend
 List<ServiceEntity> get services; List<SkillSelectionEntity> get selectedSkills; List<CategoryLicenseEntity> get categoryLicenses;// Work location — captured in the final wizard step. Optional on
// the wire, but the wizard's "Submit" gate requires both lat/lng
// to be non-null so an approved tech is bookable from day one.
 double? get baseLatitude; double? get baseLongitude; int get maxTravelRadiusKm; String get workAddressLabel; AsyncValue<TechnicianEntity?> get submissionStatus;
/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingStateCopyWith<OnboardingState> get copyWith => _$OnboardingStateCopyWithImpl<OnboardingState>(this as OnboardingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.city, city) || other.city == city)&&(identical(other.cnicNumber, cnicNumber) || other.cnicNumber == cnicNumber)&&(identical(other.profilePictureUuid, profilePictureUuid) || other.profilePictureUuid == profilePictureUuid)&&(identical(other.cnicPictureUuid, cnicPictureUuid) || other.cnicPictureUuid == cnicPictureUuid)&&(identical(other.profilePicturePath, profilePicturePath) || other.profilePicturePath == profilePicturePath)&&(identical(other.cnicPicturePath, cnicPicturePath) || other.cnicPicturePath == cnicPicturePath)&&const DeepCollectionEquality().equals(other.categoryLicensePaths, categoryLicensePaths)&&const DeepCollectionEquality().equals(other.services, services)&&const DeepCollectionEquality().equals(other.selectedSkills, selectedSkills)&&const DeepCollectionEquality().equals(other.categoryLicenses, categoryLicenses)&&(identical(other.baseLatitude, baseLatitude) || other.baseLatitude == baseLatitude)&&(identical(other.baseLongitude, baseLongitude) || other.baseLongitude == baseLongitude)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.workAddressLabel, workAddressLabel) || other.workAddressLabel == workAddressLabel)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,firstName,lastName,city,cnicNumber,profilePictureUuid,cnicPictureUuid,profilePicturePath,cnicPicturePath,const DeepCollectionEquality().hash(categoryLicensePaths),const DeepCollectionEquality().hash(services),const DeepCollectionEquality().hash(selectedSkills),const DeepCollectionEquality().hash(categoryLicenses),baseLatitude,baseLongitude,maxTravelRadiusKm,workAddressLabel,submissionStatus);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, firstName: $firstName, lastName: $lastName, city: $city, cnicNumber: $cnicNumber, profilePictureUuid: $profilePictureUuid, cnicPictureUuid: $cnicPictureUuid, profilePicturePath: $profilePicturePath, cnicPicturePath: $cnicPicturePath, categoryLicensePaths: $categoryLicensePaths, services: $services, selectedSkills: $selectedSkills, categoryLicenses: $categoryLicenses, baseLatitude: $baseLatitude, baseLongitude: $baseLongitude, maxTravelRadiusKm: $maxTravelRadiusKm, workAddressLabel: $workAddressLabel, submissionStatus: $submissionStatus)';
}


}

/// @nodoc
abstract mixin class $OnboardingStateCopyWith<$Res>  {
  factory $OnboardingStateCopyWith(OnboardingState value, $Res Function(OnboardingState) _then) = _$OnboardingStateCopyWithImpl;
@useResult
$Res call({
 int currentStep, String firstName, String lastName, String city, String cnicNumber, String? profilePictureUuid, String? cnicPictureUuid, String? profilePicturePath, String? cnicPicturePath, Map<int, String> categoryLicensePaths, List<ServiceEntity> services, List<SkillSelectionEntity> selectedSkills, List<CategoryLicenseEntity> categoryLicenses, double? baseLatitude, double? baseLongitude, int maxTravelRadiusKm, String workAddressLabel, AsyncValue<TechnicianEntity?> submissionStatus
});




}
/// @nodoc
class _$OnboardingStateCopyWithImpl<$Res>
    implements $OnboardingStateCopyWith<$Res> {
  _$OnboardingStateCopyWithImpl(this._self, this._then);

  final OnboardingState _self;
  final $Res Function(OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStep = null,Object? firstName = null,Object? lastName = null,Object? city = null,Object? cnicNumber = null,Object? profilePictureUuid = freezed,Object? cnicPictureUuid = freezed,Object? profilePicturePath = freezed,Object? cnicPicturePath = freezed,Object? categoryLicensePaths = null,Object? services = null,Object? selectedSkills = null,Object? categoryLicenses = null,Object? baseLatitude = freezed,Object? baseLongitude = freezed,Object? maxTravelRadiusKm = null,Object? workAddressLabel = null,Object? submissionStatus = null,}) {
  return _then(_self.copyWith(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,cnicNumber: null == cnicNumber ? _self.cnicNumber : cnicNumber // ignore: cast_nullable_to_non_nullable
as String,profilePictureUuid: freezed == profilePictureUuid ? _self.profilePictureUuid : profilePictureUuid // ignore: cast_nullable_to_non_nullable
as String?,cnicPictureUuid: freezed == cnicPictureUuid ? _self.cnicPictureUuid : cnicPictureUuid // ignore: cast_nullable_to_non_nullable
as String?,profilePicturePath: freezed == profilePicturePath ? _self.profilePicturePath : profilePicturePath // ignore: cast_nullable_to_non_nullable
as String?,cnicPicturePath: freezed == cnicPicturePath ? _self.cnicPicturePath : cnicPicturePath // ignore: cast_nullable_to_non_nullable
as String?,categoryLicensePaths: null == categoryLicensePaths ? _self.categoryLicensePaths : categoryLicensePaths // ignore: cast_nullable_to_non_nullable
as Map<int, String>,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<ServiceEntity>,selectedSkills: null == selectedSkills ? _self.selectedSkills : selectedSkills // ignore: cast_nullable_to_non_nullable
as List<SkillSelectionEntity>,categoryLicenses: null == categoryLicenses ? _self.categoryLicenses : categoryLicenses // ignore: cast_nullable_to_non_nullable
as List<CategoryLicenseEntity>,baseLatitude: freezed == baseLatitude ? _self.baseLatitude : baseLatitude // ignore: cast_nullable_to_non_nullable
as double?,baseLongitude: freezed == baseLongitude ? _self.baseLongitude : baseLongitude // ignore: cast_nullable_to_non_nullable
as double?,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,workAddressLabel: null == workAddressLabel ? _self.workAddressLabel : workAddressLabel // ignore: cast_nullable_to_non_nullable
as String,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as AsyncValue<TechnicianEntity?>,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingState].
extension OnboardingStatePatterns on OnboardingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStep,  String firstName,  String lastName,  String city,  String cnicNumber,  String? profilePictureUuid,  String? cnicPictureUuid,  String? profilePicturePath,  String? cnicPicturePath,  Map<int, String> categoryLicensePaths,  List<ServiceEntity> services,  List<SkillSelectionEntity> selectedSkills,  List<CategoryLicenseEntity> categoryLicenses,  double? baseLatitude,  double? baseLongitude,  int maxTravelRadiusKm,  String workAddressLabel,  AsyncValue<TechnicianEntity?> submissionStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.profilePictureUuid,_that.cnicPictureUuid,_that.profilePicturePath,_that.cnicPicturePath,_that.categoryLicensePaths,_that.services,_that.selectedSkills,_that.categoryLicenses,_that.baseLatitude,_that.baseLongitude,_that.maxTravelRadiusKm,_that.workAddressLabel,_that.submissionStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStep,  String firstName,  String lastName,  String city,  String cnicNumber,  String? profilePictureUuid,  String? cnicPictureUuid,  String? profilePicturePath,  String? cnicPicturePath,  Map<int, String> categoryLicensePaths,  List<ServiceEntity> services,  List<SkillSelectionEntity> selectedSkills,  List<CategoryLicenseEntity> categoryLicenses,  double? baseLatitude,  double? baseLongitude,  int maxTravelRadiusKm,  String workAddressLabel,  AsyncValue<TechnicianEntity?> submissionStatus)  $default,) {final _that = this;
switch (_that) {
case _OnboardingState():
return $default(_that.currentStep,_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.profilePictureUuid,_that.cnicPictureUuid,_that.profilePicturePath,_that.cnicPicturePath,_that.categoryLicensePaths,_that.services,_that.selectedSkills,_that.categoryLicenses,_that.baseLatitude,_that.baseLongitude,_that.maxTravelRadiusKm,_that.workAddressLabel,_that.submissionStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStep,  String firstName,  String lastName,  String city,  String cnicNumber,  String? profilePictureUuid,  String? cnicPictureUuid,  String? profilePicturePath,  String? cnicPicturePath,  Map<int, String> categoryLicensePaths,  List<ServiceEntity> services,  List<SkillSelectionEntity> selectedSkills,  List<CategoryLicenseEntity> categoryLicenses,  double? baseLatitude,  double? baseLongitude,  int maxTravelRadiusKm,  String workAddressLabel,  AsyncValue<TechnicianEntity?> submissionStatus)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingState() when $default != null:
return $default(_that.currentStep,_that.firstName,_that.lastName,_that.city,_that.cnicNumber,_that.profilePictureUuid,_that.cnicPictureUuid,_that.profilePicturePath,_that.cnicPicturePath,_that.categoryLicensePaths,_that.services,_that.selectedSkills,_that.categoryLicenses,_that.baseLatitude,_that.baseLongitude,_that.maxTravelRadiusKm,_that.workAddressLabel,_that.submissionStatus);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingState extends OnboardingState {
  const _OnboardingState({this.currentStep = 0, this.firstName = '', this.lastName = '', this.city = '', this.cnicNumber = '', this.profilePictureUuid, this.cnicPictureUuid, this.profilePicturePath, this.cnicPicturePath, final  Map<int, String> categoryLicensePaths = const <int, String>{}, final  List<ServiceEntity> services = const [], final  List<SkillSelectionEntity> selectedSkills = const [], final  List<CategoryLicenseEntity> categoryLicenses = const [], this.baseLatitude, this.baseLongitude, this.maxTravelRadiusKm = 10, this.workAddressLabel = '', this.submissionStatus = const AsyncValue.data(null)}): _categoryLicensePaths = categoryLicensePaths,_services = services,_selectedSkills = selectedSkills,_categoryLicenses = categoryLicenses,super._();
  

@override@JsonKey() final  int currentStep;
@override@JsonKey() final  String firstName;
@override@JsonKey() final  String lastName;
@override@JsonKey() final  String city;
@override@JsonKey() final  String cnicNumber;
@override final  String? profilePictureUuid;
@override final  String? cnicPictureUuid;
// Local file paths for in-wizard thumbnail previews. The wire payload
// only carries the UUIDs (above); these stay on the client so the
// user can see what they captured and decide whether to retake.
// Cleared on submit; never persisted.
@override final  String? profilePicturePath;
@override final  String? cnicPicturePath;
 final  Map<int, String> _categoryLicensePaths;
@override@JsonKey() Map<int, String> get categoryLicensePaths {
  if (_categoryLicensePaths is EqualUnmodifiableMapView) return _categoryLicensePaths;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryLicensePaths);
}

// Storing the metadata fetched from the backend
 final  List<ServiceEntity> _services;
// Storing the metadata fetched from the backend
@override@JsonKey() List<ServiceEntity> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

 final  List<SkillSelectionEntity> _selectedSkills;
@override@JsonKey() List<SkillSelectionEntity> get selectedSkills {
  if (_selectedSkills is EqualUnmodifiableListView) return _selectedSkills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedSkills);
}

 final  List<CategoryLicenseEntity> _categoryLicenses;
@override@JsonKey() List<CategoryLicenseEntity> get categoryLicenses {
  if (_categoryLicenses is EqualUnmodifiableListView) return _categoryLicenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryLicenses);
}

// Work location — captured in the final wizard step. Optional on
// the wire, but the wizard's "Submit" gate requires both lat/lng
// to be non-null so an approved tech is bookable from day one.
@override final  double? baseLatitude;
@override final  double? baseLongitude;
@override@JsonKey() final  int maxTravelRadiusKm;
@override@JsonKey() final  String workAddressLabel;
@override@JsonKey() final  AsyncValue<TechnicianEntity?> submissionStatus;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingStateCopyWith<_OnboardingState> get copyWith => __$OnboardingStateCopyWithImpl<_OnboardingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingState&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.city, city) || other.city == city)&&(identical(other.cnicNumber, cnicNumber) || other.cnicNumber == cnicNumber)&&(identical(other.profilePictureUuid, profilePictureUuid) || other.profilePictureUuid == profilePictureUuid)&&(identical(other.cnicPictureUuid, cnicPictureUuid) || other.cnicPictureUuid == cnicPictureUuid)&&(identical(other.profilePicturePath, profilePicturePath) || other.profilePicturePath == profilePicturePath)&&(identical(other.cnicPicturePath, cnicPicturePath) || other.cnicPicturePath == cnicPicturePath)&&const DeepCollectionEquality().equals(other._categoryLicensePaths, _categoryLicensePaths)&&const DeepCollectionEquality().equals(other._services, _services)&&const DeepCollectionEquality().equals(other._selectedSkills, _selectedSkills)&&const DeepCollectionEquality().equals(other._categoryLicenses, _categoryLicenses)&&(identical(other.baseLatitude, baseLatitude) || other.baseLatitude == baseLatitude)&&(identical(other.baseLongitude, baseLongitude) || other.baseLongitude == baseLongitude)&&(identical(other.maxTravelRadiusKm, maxTravelRadiusKm) || other.maxTravelRadiusKm == maxTravelRadiusKm)&&(identical(other.workAddressLabel, workAddressLabel) || other.workAddressLabel == workAddressLabel)&&(identical(other.submissionStatus, submissionStatus) || other.submissionStatus == submissionStatus));
}


@override
int get hashCode => Object.hash(runtimeType,currentStep,firstName,lastName,city,cnicNumber,profilePictureUuid,cnicPictureUuid,profilePicturePath,cnicPicturePath,const DeepCollectionEquality().hash(_categoryLicensePaths),const DeepCollectionEquality().hash(_services),const DeepCollectionEquality().hash(_selectedSkills),const DeepCollectionEquality().hash(_categoryLicenses),baseLatitude,baseLongitude,maxTravelRadiusKm,workAddressLabel,submissionStatus);

@override
String toString() {
  return 'OnboardingState(currentStep: $currentStep, firstName: $firstName, lastName: $lastName, city: $city, cnicNumber: $cnicNumber, profilePictureUuid: $profilePictureUuid, cnicPictureUuid: $cnicPictureUuid, profilePicturePath: $profilePicturePath, cnicPicturePath: $cnicPicturePath, categoryLicensePaths: $categoryLicensePaths, services: $services, selectedSkills: $selectedSkills, categoryLicenses: $categoryLicenses, baseLatitude: $baseLatitude, baseLongitude: $baseLongitude, maxTravelRadiusKm: $maxTravelRadiusKm, workAddressLabel: $workAddressLabel, submissionStatus: $submissionStatus)';
}


}

/// @nodoc
abstract mixin class _$OnboardingStateCopyWith<$Res> implements $OnboardingStateCopyWith<$Res> {
  factory _$OnboardingStateCopyWith(_OnboardingState value, $Res Function(_OnboardingState) _then) = __$OnboardingStateCopyWithImpl;
@override @useResult
$Res call({
 int currentStep, String firstName, String lastName, String city, String cnicNumber, String? profilePictureUuid, String? cnicPictureUuid, String? profilePicturePath, String? cnicPicturePath, Map<int, String> categoryLicensePaths, List<ServiceEntity> services, List<SkillSelectionEntity> selectedSkills, List<CategoryLicenseEntity> categoryLicenses, double? baseLatitude, double? baseLongitude, int maxTravelRadiusKm, String workAddressLabel, AsyncValue<TechnicianEntity?> submissionStatus
});




}
/// @nodoc
class __$OnboardingStateCopyWithImpl<$Res>
    implements _$OnboardingStateCopyWith<$Res> {
  __$OnboardingStateCopyWithImpl(this._self, this._then);

  final _OnboardingState _self;
  final $Res Function(_OnboardingState) _then;

/// Create a copy of OnboardingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStep = null,Object? firstName = null,Object? lastName = null,Object? city = null,Object? cnicNumber = null,Object? profilePictureUuid = freezed,Object? cnicPictureUuid = freezed,Object? profilePicturePath = freezed,Object? cnicPicturePath = freezed,Object? categoryLicensePaths = null,Object? services = null,Object? selectedSkills = null,Object? categoryLicenses = null,Object? baseLatitude = freezed,Object? baseLongitude = freezed,Object? maxTravelRadiusKm = null,Object? workAddressLabel = null,Object? submissionStatus = null,}) {
  return _then(_OnboardingState(
currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as int,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,cnicNumber: null == cnicNumber ? _self.cnicNumber : cnicNumber // ignore: cast_nullable_to_non_nullable
as String,profilePictureUuid: freezed == profilePictureUuid ? _self.profilePictureUuid : profilePictureUuid // ignore: cast_nullable_to_non_nullable
as String?,cnicPictureUuid: freezed == cnicPictureUuid ? _self.cnicPictureUuid : cnicPictureUuid // ignore: cast_nullable_to_non_nullable
as String?,profilePicturePath: freezed == profilePicturePath ? _self.profilePicturePath : profilePicturePath // ignore: cast_nullable_to_non_nullable
as String?,cnicPicturePath: freezed == cnicPicturePath ? _self.cnicPicturePath : cnicPicturePath // ignore: cast_nullable_to_non_nullable
as String?,categoryLicensePaths: null == categoryLicensePaths ? _self._categoryLicensePaths : categoryLicensePaths // ignore: cast_nullable_to_non_nullable
as Map<int, String>,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<ServiceEntity>,selectedSkills: null == selectedSkills ? _self._selectedSkills : selectedSkills // ignore: cast_nullable_to_non_nullable
as List<SkillSelectionEntity>,categoryLicenses: null == categoryLicenses ? _self._categoryLicenses : categoryLicenses // ignore: cast_nullable_to_non_nullable
as List<CategoryLicenseEntity>,baseLatitude: freezed == baseLatitude ? _self.baseLatitude : baseLatitude // ignore: cast_nullable_to_non_nullable
as double?,baseLongitude: freezed == baseLongitude ? _self.baseLongitude : baseLongitude // ignore: cast_nullable_to_non_nullable
as double?,maxTravelRadiusKm: null == maxTravelRadiusKm ? _self.maxTravelRadiusKm : maxTravelRadiusKm // ignore: cast_nullable_to_non_nullable
as int,workAddressLabel: null == workAddressLabel ? _self.workAddressLabel : workAddressLabel // ignore: cast_nullable_to_non_nullable
as String,submissionStatus: null == submissionStatus ? _self.submissionStatus : submissionStatus // ignore: cast_nullable_to_non_nullable
as AsyncValue<TechnicianEntity?>,
  ));
}


}

// dart format on

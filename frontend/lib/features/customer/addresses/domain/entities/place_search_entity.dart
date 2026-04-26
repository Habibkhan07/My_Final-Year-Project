import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_search_entity.freezed.dart';

@freezed
abstract class PlaceSearchEntity with _$PlaceSearchEntity {
  const factory PlaceSearchEntity({
    required String placeId,
    required String description,
    required String mainText,
    required String secondaryText,
  }) = _PlaceSearchEntity;
}

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/place_search_entity.dart';

part 'location_search_state.freezed.dart';

@freezed
abstract class LocationSearchState with _$LocationSearchState {
  const factory LocationSearchState({
    @Default('') String query,
    @Default([]) List<PlaceSearchEntity> results,
    @Default(false) bool isLoading,
    String? errorMessage,
    required String sessionToken,
  }) = _LocationSearchState;
}

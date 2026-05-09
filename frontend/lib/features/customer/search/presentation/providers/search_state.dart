import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/search_result_entity.dart';

part 'search_state.freezed.dart';

@freezed
abstract class SearchState with _$SearchState {
  const factory SearchState({
    @Default('') String query,
    @Default([]) List<String> recentSearches,
    @Default(AsyncValue.data([]))
    AsyncValue<List<SearchResultEntity>> suggestions,
  }) = _SearchState;
}

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'search_state.dart';
import 'dependency_injection.dart';

part 'search_notifier.g.dart';

@riverpod
class Search extends _$Search {
  Timer? _debounceTimer;

  @override
  FutureOr<SearchState> build() async {
    // Cleanup timer on provider disposal
    ref.onDispose(() => _debounceTimer?.cancel());

    // Initialize with recent searches from local storage
    final recent = await ref.read(getRecentSearchesUseCaseProvider).execute();
    return SearchState(recentSearches: recent);
  }

  /// Entry point for UI text field. Implements advanced debouncing.
  void onQueryChanged(String query) {
    // We use .value to get the current state without triggering a rebuild if it's not ready
    final current = state.value ?? const SearchState();
    
    // 1. Immediately update the query text in state
    state = AsyncData(current.copyWith(query: query));

    // 2. Cancel existing timer
    _debounceTimer?.cancel();

    // 3. Logic: If < 2 chars, reset suggestions. Else, start debounce.
    if (query.trim().length < 2) {
      state = AsyncData(state.requireValue.copyWith(
        suggestions: const AsyncData([]),
      ));
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  /// Internal method to trigger the remote search
  Future<void> _performSearch(String query) async {
    final current = state.requireValue;

    // Set suggestions sub-state to loading
    state = AsyncData(current.copyWith(
      suggestions: const AsyncLoading(),
    ));

    // Mandatory AsyncValue.guard for all asynchronous mutations (Section 3C)
    final result = await AsyncValue.guard(() async {
      return await ref.read(getSearchSuggestionsUseCaseProvider).execute(query);
    });

    // --- BULLETPROOF PROTECTION: Race Condition Check ---
    // If the user continued typing while this request was in flight, 
    // the query in the state will no longer match the query we searched for.
    if (!ref.mounted || state.requireValue.query != query) {
      return;
    }

    // Update state with the result (success or error)
    state = AsyncData(state.requireValue.copyWith(
      suggestions: result,
    ));
  }

  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    await ref.read(saveRecentSearchUseCaseProvider).execute(query.trim());
    
    // Sync local state
    final recent = await ref.read(getRecentSearchesUseCaseProvider).execute();
    state = AsyncData(state.requireValue.copyWith(recentSearches: recent));
  }

  Future<void> clearHistory() async {
    await ref.read(clearRecentSearchesUseCaseProvider).execute();
    state = AsyncData(state.requireValue.copyWith(recentSearches: const []));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../home/presentation/providers/home_notifier.dart';
import '../../../home/presentation/providers/home_state.dart';
import '../providers/search_notifier.dart';
import '../providers/search_state.dart';
import '../widgets/search_history_tile.dart';
import '../widgets/category_browse_tile.dart';
import '../widgets/suggestion_result_tile.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final homeState = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: (val) =>
                ref.read(searchProvider.notifier).onQueryChanged(val),
            decoration: InputDecoration(
              hintText: 'Search for services...',
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel,
                        color: Color(0xFFD1D5DB),
                        size: 20,
                      ),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).onQueryChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: searchState.when(
        data: (state) {
          // --- LOGIC: If query is empty, show History & Categories ---
          if (state.query.isEmpty) {
            return _buildInitialDiscoveryView(context, state, homeState);
          }

          // --- LOGIC: If typing, show Suggestions ---
          return _buildSuggestionsView(context, state);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildInitialDiscoveryView(
    BuildContext context,
    SearchState state,
    AsyncValue<HomeState> homeState,
  ) {
    return ListView(
      children: [
        // 1. Recent Searches Section
        if (state.recentSearches.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(searchProvider.notifier).clearHistory(),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          ...state.recentSearches
              .take(5)
              .map(
                (q) => SearchHistoryTile(
                  query: q,
                  onTap: () {
                    _controller.text = q;
                    ref.read(searchProvider.notifier).onQueryChanged(q);
                  },
                ),
              ),
        ],

        // 2. Browse Categories Section (Fed by Home Metadata)
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            'Browse Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        homeState.when(
          data: (hState) {
            final categories = hState.homeFeed?.categories ?? [];
            if (categories.isEmpty) return const SizedBox();
            return Column(
              children: categories
                  .map(
                    (cat) => CategoryBrowseTile(
                      name: cat.name,
                      iconUrl: cat.iconName,
                      onTap: () {
                        // Navigate to Category results
                        context.push(
                          Uri(
                            path: '/discovery',
                            queryParameters: {
                              'title': cat.name,
                              'serviceId': cat.id.toString(),
                            },
                          ).toString(),
                        );
                      },
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => _buildCategoryShimmer(),
          error: (err, stack) => const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildSuggestionsView(BuildContext context, SearchState state) {
    return state.suggestions.when(
      data: (results) {
        if (results.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text('No services found matching your search.'),
            ),
          );
        }
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final item = results[index];
            return SuggestionResultTile(
              title: item.name,
              categoryName: item.categoryName,
              onTap: () {
                ref.read(searchProvider.notifier).saveSearch(item.name);
                // Navigate to results
                context.push(
                  Uri(
                    path: '/discovery',
                    queryParameters: {'title': item.name, 'query': item.name},
                  ).toString(),
                );
              },
            );
          },
        );
      },
      loading: () => _buildSuggestionsShimmer(),
      error: (err, _) => Center(child: Text('Search failed: $err')),
    );
  }

  Widget _buildCategoryShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: List.generate(
          3,
          (index) => ListTile(
            leading: Container(width: 40, height: 40, color: Colors.white),
            title: Container(width: 100, height: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, index) => ListTile(
          leading: const CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
          ),
          title: Container(height: 16, color: Colors.white),
        ),
      ),
    );
  }
}

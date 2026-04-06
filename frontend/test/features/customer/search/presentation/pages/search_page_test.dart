import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:frontend/features/customer/search/presentation/pages/search_page.dart';
import 'package:frontend/features/customer/search/presentation/providers/search_notifier.dart';
import 'package:frontend/features/customer/search/presentation/providers/search_state.dart';
import 'package:frontend/features/customer/search/presentation/widgets/search_history_tile.dart';
import 'package:frontend/features/customer/search/presentation/widgets/category_browse_tile.dart';
import 'package:frontend/features/customer/search/presentation/widgets/suggestion_result_tile.dart';
import 'package:frontend/features/customer/search/domain/entities/search_result_entity.dart';
import 'package:frontend/features/customer/home/presentation/providers/home_notifier.dart';
import 'package:frontend/features/customer/home/presentation/providers/home_state.dart';
import 'package:frontend/features/customer/home/domain/entities/home_feed_entity.dart';

class MockSearchNotifier extends Search {
  final SearchState mockState;

  MockSearchNotifier(this.mockState);

  @override
  FutureOr<SearchState> build() {
    return mockState;
  }

  @override
  void onQueryChanged(String query) {}
  
  @override
  Future<void> clearHistory() async {}
}

class MockHomeNotifier extends HomeNotifier {
  final HomeState mockState;

  MockHomeNotifier(this.mockState);

  @override
  FutureOr<HomeState> build() {
    return mockState;
  }
}

void main() {
  Widget createWidgetUnderTest(SearchState searchState, HomeState homeState) {
    return ProviderScope(
      overrides: [
        searchProvider.overrideWith(() => MockSearchNotifier(searchState)),
        homeProvider.overrideWith(() => MockHomeNotifier(homeState)),
      ],
      child: const MaterialApp(
        home: SearchPage(),
      ),
    );
  }

  group('SearchPage', () {
    testWidgets('renders Discovery View correctly on empty query', (WidgetTester tester) async {
      const searchState = SearchState(
        query: '',
        recentSearches: ['plumber', 'electrician'],
      );

      const homeState = HomeState(
        homeFeed: HomeFeedEntity(
          categories: [
            CategoryEntity(id: 1, name: 'Cleaning', iconName: 'cleaning'),
          ],
          promotions: [],
          fixedGigs: [],
          topTechnicians: [],
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest(searchState, homeState));
      // wait for the providers to initialize
      await tester.pumpAndSettle();

      // Ensure Recent Searches and Categories are shown
      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('Browse Categories'), findsOneWidget);

      // Verify the list of recent searches is there
      expect(find.byType(SearchHistoryTile), findsNWidgets(2));
      expect(find.text('plumber'), findsOneWidget);
      expect(find.text('electrician'), findsOneWidget);

      // Verify categories are rendered
      expect(find.byType(CategoryBrowseTile), findsOneWidget);
      expect(find.text('Cleaning'), findsOneWidget);
    });

    testWidgets('renders Suggestions View with loading state', (WidgetTester tester) async {
      const searchState = SearchState(
        query: 'fix',
        suggestions: AsyncLoading(),
      );
      const homeState = HomeState();

      await tester.pumpWidget(createWidgetUnderTest(searchState, homeState));
      await tester.pump();

      // Shimmer loading should be visible
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders Suggestions View with empty results', (WidgetTester tester) async {
      const searchState = SearchState(
        query: 'fix',
        suggestions: AsyncData([]),
      );
      const homeState = HomeState();

      await tester.pumpWidget(createWidgetUnderTest(searchState, homeState));
      await tester.pumpAndSettle();

      // Empty results message
      expect(find.text('No services found matching your search.'), findsOneWidget);
    });

    testWidgets('renders Suggestions View with results', (WidgetTester tester) async {
      const results = [
        SearchResultEntity(
          id: 1,
          name: 'Pipe Fix',
          categoryName: 'Plumbing',
          basePrice: '500.0',
          isFixedPrice: false,
        ),
        SearchResultEntity(
          id: 2,
          name: 'Drain Cleaning',
          categoryName: 'Plumbing',
          basePrice: '300.0',
          isFixedPrice: true,
        ),
      ];
      const searchState = SearchState(
        query: 'pip',
        suggestions: AsyncData(results),
      );
      const homeState = HomeState();

      await tester.pumpWidget(createWidgetUnderTest(searchState, homeState));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.byType(SuggestionResultTile), findsNWidgets(2));
      
      final tiles = tester.widgetList<SuggestionResultTile>(find.byType(SuggestionResultTile)).toList();
      expect(tiles[0].title, 'Pipe Fix');
      expect(tiles[1].title, 'Drain Cleaning');
    });

    testWidgets('renders Error state for suggestions', (WidgetTester tester) async {
      final searchState = SearchState(
        query: 'pip',
        suggestions: AsyncError('Failed to fetch', StackTrace.empty),
      );
      const homeState = HomeState();

      await tester.pumpWidget(createWidgetUnderTest(searchState, homeState));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Search failed: Failed to fetch'), findsOneWidget);
    });
  });
}

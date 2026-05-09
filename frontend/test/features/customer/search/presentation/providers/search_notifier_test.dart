import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_async/fake_async.dart';
import 'package:frontend/features/customer/search/domain/entities/search_result_entity.dart';
import 'package:frontend/features/customer/search/domain/failures/search_failure.dart';
import 'package:frontend/features/customer/search/domain/use_cases/get_search_suggestions_use_case.dart';
import 'package:frontend/features/customer/search/domain/use_cases/get_recent_searches_use_case.dart';
import 'package:frontend/features/customer/search/domain/use_cases/save_recent_search_use_case.dart';
import 'package:frontend/features/customer/search/domain/use_cases/clear_recent_searches_use_case.dart';
import 'package:frontend/features/customer/search/presentation/providers/search_notifier.dart';
import 'package:frontend/features/customer/search/presentation/providers/dependency_injection.dart';

class MockGetSearchSuggestionsUseCase extends Mock
    implements GetSearchSuggestionsUseCase {}

class MockGetRecentSearchesUseCase extends Mock
    implements GetRecentSearchesUseCase {}

class MockSaveRecentSearchUseCase extends Mock
    implements SaveRecentSearchUseCase {}

class MockClearRecentSearchesUseCase extends Mock
    implements ClearRecentSearchesUseCase {}

void main() {
  late MockGetSearchSuggestionsUseCase mockSuggestions;
  late MockGetRecentSearchesUseCase mockGetRecent;
  late MockSaveRecentSearchUseCase mockSaveRecent;
  late MockClearRecentSearchesUseCase mockClearRecent;

  const tRecent = ['sofa cleaning', 'ac repair'];
  const tQuery = 'plumbing';
  const tResults = [
    SearchResultEntity(
      id: 1,
      name: 'Pipe Fix',
      categoryName: 'Plumbing',
      basePrice: '500.00',
      isFixedPrice: true,
    ),
  ];

  setUp(() {
    mockSuggestions = MockGetSearchSuggestionsUseCase();
    mockGetRecent = MockGetRecentSearchesUseCase();
    mockSaveRecent = MockSaveRecentSearchUseCase();
    mockClearRecent = MockClearRecentSearchesUseCase();

    when(() => mockGetRecent.execute()).thenAnswer((_) async => tRecent);
  });

  ProviderContainer initContainer(FakeAsync async) {
    final container = ProviderContainer(
      overrides: [
        getSearchSuggestionsUseCaseProvider.overrideWithValue(mockSuggestions),
        getRecentSearchesUseCaseProvider.overrideWithValue(mockGetRecent),
        saveRecentSearchUseCaseProvider.overrideWithValue(mockSaveRecent),
        clearRecentSearchesUseCaseProvider.overrideWithValue(mockClearRecent),
      ],
    );
    // Initialize provider and add listener to prevent auto-dispose
    container.listen(searchProvider, (_, __) {});
    async.flushMicrotasks();
    return container;
  }

  group('SearchNotifier (State & Debouncing)', () {
    test(
      'initial state loads recent searches correctly',
      () => fakeAsync((async) {
        final container = initContainer(async);

        final state = container.read(searchProvider).requireValue;
        expect(state.recentSearches, tRecent);
        expect(state.query, '');
        expect(state.suggestions.value, isEmpty);
      }),
    );

    test(
      'onQueryChanged updates query text immediately',
      () => fakeAsync((async) {
        final container = initContainer(async);

        container.read(searchProvider.notifier).onQueryChanged('p');
        async.flushMicrotasks();

        final state = container.read(searchProvider).requireValue;
        expect(state.query, 'p');
      }),
    );

    test(
      'advanced debouncing: triggers API call only after 500ms',
      () => fakeAsync((async) {
        final container = initContainer(async);
        when(
          () => mockSuggestions.execute(any()),
        ).thenAnswer((_) async => tResults);

        // Act
        container.read(searchProvider.notifier).onQueryChanged(tQuery);
        async.flushMicrotasks();

        // Verify NO API call immediately
        verifyNever(() => mockSuggestions.execute(any()));

        // Wait for debounce timer (500ms)
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        // Verify API call
        verify(() => mockSuggestions.execute(tQuery)).called(1);

        final state = container.read(searchProvider).requireValue;
        expect(state.suggestions.value, tResults);
      }),
    );

    test(
      'advanced debouncing: multiple rapid keystrokes triggers only ONE API call',
      () => fakeAsync((async) {
        final container = initContainer(async);
        when(
          () => mockSuggestions.execute(any()),
        ).thenAnswer((_) async => tResults);

        // Rapid fire keystrokes
        container.read(searchProvider.notifier).onQueryChanged('p');
        async.elapse(const Duration(milliseconds: 100));
        container.read(searchProvider.notifier).onQueryChanged('pl');
        async.elapse(const Duration(milliseconds: 100));
        container.read(searchProvider.notifier).onQueryChanged('plu');
        async.flushMicrotasks();

        // Still should not have called because timer reset twice
        verifyNever(() => mockSuggestions.execute(any()));

        // Wait for final timer
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => mockSuggestions.execute('plu')).called(1);
        verifyNever(() => mockSuggestions.execute('p'));
        verifyNever(() => mockSuggestions.execute('pl'));
      }),
    );

    test(
      'min-character failsafe: does not search if query < 2 chars',
      () => fakeAsync((async) {
        final container = initContainer(async);

        container.read(searchProvider.notifier).onQueryChanged('a');
        async.elapse(const Duration(milliseconds: 600));
        async.flushMicrotasks();

        verifyNever(() => mockSuggestions.execute(any()));
      }),
    );

    test(
      'error propagation: suggestions sub-state captures AsyncError',
      () => fakeAsync((async) {
        final container = initContainer(async);
        const tError = SearchServerFailure('Server exploded');
        when(() => mockSuggestions.execute(any())).thenThrow(tError);

        container.read(searchProvider.notifier).onQueryChanged(tQuery);
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        final state = container.read(searchProvider).requireValue;
        expect(state.suggestions, isA<AsyncError>());
        expect(state.suggestions.error, tError);
      }),
    );
  });

  group('SearchNotifier (History Actions)', () {
    test(
      'saveSearch updates local state and repository',
      () => fakeAsync((async) {
        final container = initContainer(async);
        final newSearch = 'new query';
        final updatedHistory = [newSearch, ...tRecent];

        when(
          () => mockSaveRecent.execute(any()),
        ).thenAnswer((_) async => Future.value());
        when(
          () => mockGetRecent.execute(),
        ).thenAnswer((_) async => updatedHistory);

        container.read(searchProvider.notifier).saveSearch(newSearch);
        async.flushMicrotasks();

        verify(() => mockSaveRecent.execute(newSearch)).called(1);
        expect(
          container.read(searchProvider).requireValue.recentSearches,
          updatedHistory,
        );
      }),
    );

    test(
      'clearHistory resets recent searches',
      () => fakeAsync((async) {
        final container = initContainer(async);
        when(
          () => mockClearRecent.execute(),
        ).thenAnswer((_) async => Future.value());

        container.read(searchProvider.notifier).clearHistory();
        async.flushMicrotasks();

        verify(() => mockClearRecent.execute()).called(1);
        expect(
          container.read(searchProvider).requireValue.recentSearches,
          isEmpty,
        );
      }),
    );
  });
}

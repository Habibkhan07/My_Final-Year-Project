import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/customer/search/data/data_sources/search_local_data_source.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SearchLocalDataSource dataSource;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = SearchLocalDataSource(mockPrefs);
  });

  const kKey = 'recent_searches_history';

  group('SearchLocalDataSource', () {
    test('getRecentSearches returns empty list if null in prefs', () async {
      when(() => mockPrefs.getStringList(kKey)).thenReturn(null);
      final result = await dataSource.getRecentSearches();
      expect(result, []);
    });

    test('saveRecentSearch adds to top and deduplicates', () async {
      // Arrange: Current history is [A, B]
      when(() => mockPrefs.getStringList(kKey)).thenReturn(['A', 'B']);
      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);

      // Act: Save B
      await dataSource.saveRecentSearch('B');

      // Assert: B is now at index 0, list is [B, A]
      verify(() => mockPrefs.setStringList(kKey, ['B', 'A'])).called(1);
    });

    test('saveRecentSearch caps history at 10 items', () async {
      // Arrange: History has 10 items
      final tenItems = List.generate(10, (i) => 'Item $i');
      when(() => mockPrefs.getStringList(kKey)).thenReturn(List.from(tenItems));
      when(() => mockPrefs.setStringList(any(), any())).thenAnswer((_) async => true);

      // Act: Add 11th item
      await dataSource.saveRecentSearch('New Item');

      // Assert: New list has 10 items, 'Item 9' (last) is gone
      final expected = ['New Item', ...tenItems.sublist(0, 9)];
      verify(() => mockPrefs.setStringList(kKey, expected)).called(1);
    });
  });
}

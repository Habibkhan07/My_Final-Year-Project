import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/common/errors/http_failure.dart';
import 'package:frontend/features/customer/discovery/data/data_sources/discovery_remote_data_source.dart';
import 'package:frontend/features/customer/discovery/data/models/discovery_models.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late DiscoveryRemoteDataSource dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = DiscoveryRemoteDataSource(client: mockHttpClient);
  });

  group('getNearbyTechnicians', () {
    const tLat = 31.5204;
    const tLng = 74.3587;
    const tQuery = 'plumber';
    const tPage = 1;

    final tDiscoveryResultJson = {
      'count': 1,
      'next': null,
      'previous': null,
      'ui_promo_banner_text': 'Promo text',
      'results': [
        {
          'id': 1,
          'full_name': 'Ali Raza',
          'primary_category': 'Plumbing',
          'city': 'LHR',
          'profile_picture': null,
          'rating_average': 4.9,
          'review_count': 120,
          'distance_km': 2.4,
          'bayesian_score': 4.8,
          'is_active': true,
          'ui_rating_text': '4.9 (120)',
          'primary_price': 'Rs. 500',
          'price_context': 'per visit',
          'promo_tag': null,
          'ui_subtitle_text': 'Expert',
        },
      ],
    };

    test(
      'should perform a GET request on a URL with query parameters',
      () async {
        // Arrange
        when(() => mockHttpClient.get(any())).thenAnswer(
          (_) async => http.Response(jsonEncode(tDiscoveryResultJson), 200),
        );

        // Act
        await dataSource.getNearbyTechnicians(
          lat: tLat,
          lng: tLng,
          query: tQuery,
          page: tPage,
        );

        // Assert
        final capturedUri =
            verify(() => mockHttpClient.get(captureAny())).captured.first
                as Uri;
        expect(capturedUri.queryParameters['lat'], tLat.toString());
        expect(capturedUri.queryParameters['lng'], tLng.toString());
        expect(capturedUri.queryParameters['q'], tQuery);
        expect(capturedUri.queryParameters['page'], tPage.toString());
      },
    );

    test(
      'should return DiscoveryResultModel when the response code is 200 (success)',
      () async {
        // Arrange
        when(() => mockHttpClient.get(any())).thenAnswer(
          (_) async => http.Response(jsonEncode(tDiscoveryResultJson), 200),
        );

        // Act
        final result = await dataSource.getNearbyTechnicians();

        // Assert
        expect(result, isA<DiscoveryResultModel>());
        expect(result.count, 1);
        expect(result.results.first.fullName, 'Ali Raza');
      },
    );

    test(
      'should throw HttpFailure when the response code is 400 (validation_error)',
      () async {
        // Arrange
        final errorJson = {
          'code': 'validation_error',
          'message': 'Invalid query',
          'errors': {
            'q': ['Too short'],
          },
        };
        when(
          () => mockHttpClient.get(any()),
        ).thenAnswer((_) async => http.Response(jsonEncode(errorJson), 400));

        // Act & Assert
        expect(
          () => dataSource.getNearbyTechnicians(),
          throwsA(
            isA<HttpFailure>()
                .having((e) => e.statusCode, 'statusCode', 400)
                .having((e) => e.code, 'code', 'validation_error')
                .having((e) => e.message, 'message', 'Invalid query'),
          ),
        );
      },
    );

    test(
      'should throw HttpFailure with server_error when response is 500 and body is not JSON',
      () async {
        // Arrange
        when(
          () => mockHttpClient.get(any()),
        ).thenAnswer((_) async => http.Response('Server Crash', 500));

        // Act & Assert
        expect(
          () => dataSource.getNearbyTechnicians(),
          throwsA(
            isA<HttpFailure>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having((e) => e.code, 'code', 'server_error'),
          ),
        );
      },
    );
  });
}

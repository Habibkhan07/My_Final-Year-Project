// Widget tests for `OrchestratorErrorCard`.
//
// Contract:
//   * Per-failure icon (search_off for NotFound, lock_outline for
//     NotParticipant, cloud_off for OfflineNoCache, wifi_off for
//     NetworkFailure, sentiment_dissatisfied for ServerFailure).
//   * Per-failure copy (title + body).
//   * Brand-blue "Try again" button invokes onRetry.
//   * "Contact support" button visible when supportPhoneNumber non-empty;
//     tapping calls IUrlLauncher.launch(tel:<number>).
//   * "Contact support" omitted when supportPhoneNumber is empty (dev
//     without --dart-define).
//   * On launcher returning false, a snackbar surfaces the dialler
//     fallback message.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/map/map_provider.dart';
import 'package:frontend/core/widgets/map/url_launcher_port.dart';
import 'package:frontend/features/orchestrator/domain/failures/booking_detail_failure.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/orchestrator_error_card.dart';

class _FakeUrlLauncher implements IUrlLauncher {
  bool nextResult = true;
  final List<Uri> launched = [];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return nextResult;
  }
}

Widget _wrap({
  required Object failure,
  required VoidCallback onRetry,
  String supportPhoneNumber = '+923001112233',
  IUrlLauncher? launcher,
}) {
  return ProviderScope(
    overrides: [
      if (launcher != null) urlLauncherProvider.overrideWith((ref) => launcher),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: OrchestratorErrorCard(
          failure: failure,
          onRetry: onRetry,
          supportPhoneNumber: supportPhoneNumber,
        ),
      ),
    ),
  );
}

void main() {
  group('OrchestratorErrorCard', () {
    testWidgets('NotFound → search_off + "Not found" copy', (tester) async {
      await tester.pumpWidget(_wrap(
        failure: const BookingDetailNotFound(42),
        onRetry: () {},
      ));
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
      expect(find.text('Not found'), findsOneWidget);
    });

    testWidgets('NotParticipant → lock_outline + "Not allowed" copy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        failure: const BookingDetailNotParticipant(),
        onRetry: () {},
      ));
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Not allowed'), findsOneWidget);
    });

    testWidgets('OfflineNoCache → cloud_off + "You are offline" copy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        failure: const BookingDetailOfflineNoCache(),
        onRetry: () {},
      ));
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
      expect(find.text('You are offline'), findsOneWidget);
    });

    testWidgets('NetworkFailure → wifi_off + "Network error" copy', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        failure: const BookingDetailNetworkFailure(),
        onRetry: () {},
      ));
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets(
      'ServerFailure → sentiment_dissatisfied + "Something went wrong"',
      (tester) async {
        await tester.pumpWidget(_wrap(
          failure: const BookingDetailServerFailure(),
          onRetry: () {},
        ));
        expect(
          find.byIcon(Icons.sentiment_dissatisfied_rounded),
          findsOneWidget,
        );
        expect(find.text('Something went wrong'), findsOneWidget);
      },
    );

    testWidgets('Try again invokes onRetry', (tester) async {
      var retryCount = 0;
      await tester.pumpWidget(_wrap(
        failure: const BookingDetailNetworkFailure(),
        onRetry: () => retryCount++,
      ));
      await tester.tap(find.text('Try again'));
      expect(retryCount, 1);
    });

    testWidgets(
      'Contact support invokes IUrlLauncher with tel: scheme',
      (tester) async {
        final launcher = _FakeUrlLauncher();
        await tester.pumpWidget(_wrap(
          failure: const BookingDetailNetworkFailure(),
          onRetry: () {},
          supportPhoneNumber: '+923001112233',
          launcher: launcher,
        ));
        await tester.tap(find.text('Contact support'));
        await tester.pump();
        expect(launcher.launched, hasLength(1));
        expect(launcher.launched.single.scheme, 'tel');
        expect(launcher.launched.single.path, '+923001112233');
      },
    );

    testWidgets(
      'Contact support is omitted when supportPhoneNumber is empty',
      (tester) async {
        await tester.pumpWidget(_wrap(
          failure: const BookingDetailNetworkFailure(),
          onRetry: () {},
          supportPhoneNumber: '',
        ));
        expect(find.text('Contact support'), findsNothing);
      },
    );

    testWidgets(
      'launcher false → snackbar surfaces dialler fallback message',
      (tester) async {
        final launcher = _FakeUrlLauncher()..nextResult = false;
        await tester.pumpWidget(_wrap(
          failure: const BookingDetailNetworkFailure(),
          onRetry: () {},
          supportPhoneNumber: '+923001112233',
          launcher: launcher,
        ));
        await tester.tap(find.text('Contact support'));
        await tester.pump(); // dispatch launch
        await tester.pump(); // settle snackbar
        expect(
          find.textContaining('Could not open dialler'),
          findsOneWidget,
        );
      },
    );
  });
}

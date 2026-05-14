// Pins the sealed-hierarchy contract that the repository's `_mapFailure`
// switch and the host's `_surfaceResult` switch expressions depend on.
// If a subtype is added or removed, the exhaustive-switch test below fails
// to compile — that's the load-bearing pin (compile-time, not runtime).
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/technician/incoming_job_requests/domain/failures/incoming_job_failure.dart';

/// Materializes every concrete subtype as an `IncomingJobFailure` so the
/// switch below is forced to be exhaustive. If a new subtype is added
/// without an entry here, the switch becomes non-exhaustive and the
/// compiler reports it; if a subtype is removed, the constructor reference
/// breaks. This is the ratchet that keeps the hierarchy honest.
List<IncomingJobFailure> _allFailureCases() => const [
  MalformedJobPayload(),
  OfferNoLongerAvailable(),
  IncomingJobNetworkFailure(),
  IncomingJobServerFailure(),
  UnknownIncomingJobFailure(),
  JobAcceptBlockedByLockout(balancePkr: -495, owedPkr: 495),
];

/// Maps every failure to a short identifier via an exhaustive switch
/// expression. Compile-time exhaustiveness over the sealed parent is the
/// contract; the runtime assertion below is just a safety net.
String _identify(IncomingJobFailure f) => switch (f) {
  MalformedJobPayload() => 'malformed',
  OfferNoLongerAvailable() => 'gone',
  IncomingJobNetworkFailure() => 'offline',
  IncomingJobServerFailure() => 'server',
  UnknownIncomingJobFailure() => 'unknown',
  JobAcceptBlockedByLockout() => 'wallet_locked',
};

void main() {
  group('IncomingJobFailure — sealed hierarchy', () {
    test('every subtype is reachable through an exhaustive switch over the '
        'sealed parent', () {
      final identifiers = _allFailureCases().map(_identify).toSet();

      // Each identifier must be unique — otherwise two subtypes would map
      // to the same Snackbar in the UI and the technician would see
      // identical copy for distinct error states.
      expect(identifiers, {
        'malformed',
        'gone',
        'offline',
        'server',
        'unknown',
        'wallet_locked',
      });
    });

    test('every subtype carries a non-empty default message', () {
      for (final f in _allFailureCases()) {
        expect(
          f.message,
          isNotEmpty,
          reason:
              '${f.runtimeType} default message must be non-empty so '
              'the UI never surfaces a blank Snackbar',
        );
      }
    });

    test('every subtype implements Exception (throwable contract)', () {
      for (final f in _allFailureCases()) {
        expect(f, isA<Exception>());
      }
    });

    test('OfferNoLongerAvailable carries the user-facing copy the UI maps to '
        '— wire contract checkpoint with flag #20', () {
      // The string is part of the UX contract: "This job is no longer
      // available." reads as "the offer is gone, move on" — distinct from
      // UnknownIncomingJobFailure's retry-friendly copy.
      const failure = OfferNoLongerAvailable();
      expect(failure.message, 'This job is no longer available.');
    });

    test(
      'OfferNoLongerAvailable carries currentStatus when supplied — preserved '
      'from the 409 envelope for client-side debugging',
      () {
        const failure = OfferNoLongerAvailable(currentStatus: 'REJECTED');
        expect(failure.currentStatus, 'REJECTED');
      },
    );

    test('OfferNoLongerAvailable currentStatus defaults to null on the 404 '
        'collapse path (server can\'t leak missing-vs-wrong-owner)', () {
      const failure = OfferNoLongerAvailable();
      expect(failure.currentStatus, isNull);
    });
  });
}

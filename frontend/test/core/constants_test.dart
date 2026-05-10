// Audit S-8 (Batch D): pin the boot-time release-mode networking
// assertion's debug-mode behaviour. We can't easily flip
// `kReleaseMode` in a unit test, so this only verifies the
// debug-mode branch (it's a no-op even though baseUrl is `http://`
// for dev).

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/constants.dart';

void main() {
  group('AppConstants.assertReleaseSafeNetworking', () {
    test('is a no-op in debug mode (baseUrl is http://...)', () {
      // Tests run in debug mode → kReleaseMode == false → the
      // function early-returns and accepts the cleartext dev URLs.
      expect(AppConstants.assertReleaseSafeNetworking, returnsNormally);
    });

    test('current dev baseUrl is the expected cleartext localhost', () {
      // Sanity-pin: if someone flips baseUrl to https:// without
      // adjusting the dev backend setup, this test will catch it.
      // Conversely, if someone migrates baseUrl to https:// AND
      // wires the boot assertion through release-mode CI, both
      // tests need to be updated together.
      expect(AppConstants.baseUrl, startsWith('http://'));
      expect(AppConstants.baseWsUrl, startsWith('ws://'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/technician/wallet/presentation/format.dart';

void main() {
  group('formatRs', () {
    test('whole rupee drops the .00 suffix', () {
      expect(formatRs(100), 'Rs. 100');
      expect(formatRs(0), 'Rs. 0');
      expect(formatRs(5000), 'Rs. 5000');
    });

    test('paisa fraction renders 2dp', () {
      expect(formatRs(100.5), 'Rs. 100.50');
      expect(formatRs(100.99), 'Rs. 100.99');
      expect(formatRs(0.01), 'Rs. 0.01');
    });

    test('rounds to 2dp on sub-paisa input (defensive)', () {
      // The wire contract rejects sub-paisa, but tests + future
      // displays of computed values (e.g. running averages) might
      // hand us a longer decimal. Don't crash; round cleanly.
      expect(formatRs(100.999), 'Rs. 101');
      expect(formatRs(100.555), 'Rs. 100.56');
    });

    test('null / NaN degrade to Rs. 0 (never crashes)', () {
      expect(formatRs(null), 'Rs. 0');
      expect(formatRs(double.nan), 'Rs. 0');
    });

    test('negative balances render with sign preserved', () {
      // Used by the lockout banner copy elsewhere; the formatter
      // doesn't try to be opinionated about sign.
      expect(formatRs(-50), 'Rs. -50');
      expect(formatRs(-100.5), 'Rs. -100.50');
    });
  });
}

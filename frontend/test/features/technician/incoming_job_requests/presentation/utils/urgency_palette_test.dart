import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/technician/incoming_job_requests/presentation/utils/urgency_palette.dart';

void main() {
  // The palette is the single source of truth for the green/amber/red bands
  // consumed by the swipe-to-accept draining track. If these thresholds drift,
  // the visible time-pressure stops matching the actual SLA, which is the
  // failure mode these tests pin against.

  group('urgencyAccent', () {
    const sla = Duration(seconds: 100);

    test('> 50% of window remaining → green (AppColors.secondary)', () {
      // 60s remaining of a 100s window = 0.60, comfortably above 0.5.
      expect(
        urgencyAccent(const Duration(seconds: 60), sla),
        AppColors.secondary,
      );
    });

    test('exactly 50% remaining → amber (boundary, NOT green)', () {
      // The green threshold is `> 0.5` — an exact 0.5 belongs to amber so
      // the palette never reads "calm" when half the window is already gone.
      expect(
        urgencyAccent(const Duration(seconds: 50), sla),
        amberAccent,
      );
    });

    test('20–50% remaining → amber', () {
      expect(
        urgencyAccent(const Duration(seconds: 30), sla),
        amberAccent,
      );
    });

    test('exactly 20% remaining → amber (lower boundary inclusive)', () {
      expect(
        urgencyAccent(const Duration(seconds: 20), sla),
        amberAccent,
      );
    });

    test('< 20% remaining → red (AppColors.error)', () {
      expect(
        urgencyAccent(const Duration(seconds: 10), sla),
        AppColors.error,
      );
    });

    test('expired (negative duration) → red', () {
      expect(
        urgencyAccent(const Duration(seconds: -5), sla),
        AppColors.error,
      );
    });

    test('zero slaWindow → red (defensive: never silently degrade to green)',
        () {
      expect(
        urgencyAccent(const Duration(seconds: 30), Duration.zero),
        AppColors.error,
      );
    });
  });

  group('urgencyIsRed', () {
    const sla = Duration(seconds: 100);

    test('returns true for < 20% remaining', () {
      expect(urgencyIsRed(const Duration(seconds: 10), sla), isTrue);
    });

    test('returns false for amber band', () {
      expect(urgencyIsRed(const Duration(seconds: 30), sla), isFalse);
    });

    test('returns false for green band', () {
      expect(urgencyIsRed(const Duration(seconds: 80), sla), isFalse);
    });

    test('matches accent band 1:1 (red iff accent==error)', () {
      const sweep = [1, 5, 19, 20, 21, 49, 50, 51, 99];
      for (final s in sweep) {
        final remaining = Duration(seconds: s);
        final accent = urgencyAccent(remaining, sla);
        final isRed = urgencyIsRed(remaining, sla);
        expect(
          isRed,
          accent == AppColors.error,
          reason:
              'At ${s}s remaining, accent=$accent vs urgencyIsRed=$isRed — '
              'these must agree.',
        );
      }
    });
  });

  group('threshold constants', () {
    test('urgencyGreenAbove and urgencyAmberAbove are between 0 and 1', () {
      expect(urgencyGreenAbove, inExclusiveRange(0, 1));
      expect(urgencyAmberAbove, inExclusiveRange(0, 1));
    });

    test('green threshold strictly above amber threshold', () {
      expect(urgencyGreenAbove, greaterThan(urgencyAmberAbove));
    });
  });
}

Matcher inExclusiveRange(num low, num high) =>
    predicate<num>((v) => v > low && v < high, 'in exclusive ($low, $high)');

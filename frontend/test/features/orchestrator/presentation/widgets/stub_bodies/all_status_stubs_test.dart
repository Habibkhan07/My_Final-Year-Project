// Unit tests for `resolveLiveCallTarget` (audit H11 / W-8).
//
// The helper drives the call FAB on the live-tracking map. Customer-side
// must show a working FAB (deeplink to dialler) when support phone is
// configured; tech-side dials the customer; the FAB hides only when no
// number is reachable.
//
// `resolveLiveCallTarget` is `@visibleForTesting`; production callers
// in `all_status_stubs.dart` use the default `supportPhone` which reads
// from the compile-time `--dart-define=SUPPORT_PHONE_NUMBER`. Tests
// inject `supportPhone` directly to exercise both configured and
// unconfigured branches.

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/presentation/widgets/stub_bodies/all_status_stubs.dart';

import '../../../_helpers/booking_detail_fixture.dart';

BookingDetail _booking({required int currentUserId}) {
  final json = bookingDetailJson(
    id: 42,
    status: 'EN_ROUTE',
    customerId: 7,
    technicianId: 99,
  );
  return BookingDetailMapper.toDomain(
    BookingDetailModel.fromJson(json),
    currentUserId: currentUserId,
  );
}

void main() {
  group('resolveLiveCallTarget — tech viewer', () {
    test('returns customer.phoneNo + "Call customer" tooltip', () {
      final booking = _booking(currentUserId: 99); // tech
      final target = resolveLiveCallTarget(booking, supportPhone: '+92SUP');

      expect(target.phone, '+923001234567'); // fixture customer phone
      expect(target.tooltip, 'Call customer');
    });

    test('ignores supportPhone configuration (tech does not call support)', () {
      final booking = _booking(currentUserId: 99);
      final target = resolveLiveCallTarget(booking, supportPhone: '');

      expect(target.phone, '+923001234567');
      expect(target.tooltip, 'Call customer');
    });
  });

  group('resolveLiveCallTarget — customer viewer', () {
    test(
      'support configured → phone = support, tooltip = "Call support"',
      () {
        final booking = _booking(currentUserId: 7); // customer
        final target = resolveLiveCallTarget(
          booking,
          supportPhone: '+923000000111',
        );

        expect(target.phone, '+923000000111');
        expect(target.tooltip, 'Call support');
      },
    );

    test(
      'support unconfigured (empty) → phone null, FAB hidden',
      () {
        final booking = _booking(currentUserId: 7);
        final target = resolveLiveCallTarget(booking, supportPhone: '');

        // Null phone is the contract for "hide the FAB" — LiveTrackingMap
        // skips the FAB entirely when callPhoneNumber is null. Without
        // this branch, dev builds (no --dart-define passed) would crash
        // launchUrl with an empty tel: URI.
        expect(target.phone, isNull);
      },
    );
  });
}

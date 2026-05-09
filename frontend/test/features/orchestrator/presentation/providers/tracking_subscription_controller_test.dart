// Tests for `TrackingSubscriptionController`.
//
// Matrix coverage:
//   • viewerRole=customer + status ∈ {EN_ROUTE, ARRIVED} → subscribe sent
//   • viewerRole=customer + status ∉ window → no subscribe
//   • viewerRole=technician + any status → no subscribe (the tech
//     publishes via REST, not WS)
//   • Reconnect (WsConnected event while subscribed) → subscribe replayed
//   • Dispose → unsubscribe sent if currently subscribed
//
// (Restored in session 4 commit 3 — a cosmetic `sed` invocation in
// commit 2 emptied the file. Regenerated verbatim from the
// implementation pinned at session 4's plan.)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:frontend/features/orchestrator/data/mappers/booking_detail_mapper.dart';
import 'package:frontend/features/orchestrator/data/models/booking_detail_model.dart';
import 'package:frontend/features/orchestrator/domain/entities/booking_detail.dart';
import 'package:frontend/features/orchestrator/domain/repositories/booking_detail_repository.dart';
import 'package:frontend/features/orchestrator/presentation/providers/booking_detail_provider.dart';
import 'package:frontend/features/orchestrator/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/orchestrator/presentation/providers/tracking_subscription_controller.dart';

import '../../_helpers/booking_detail_fixture.dart';

class _FakeWsNotifier extends WsConnectionNotifier {
  final List<Map<String, dynamic>> sentMessages = [];
  final StreamController<WsConnectionEvent> events =
      StreamController.broadcast();

  @override
  WsConnectionStatus build() => WsConnectionStatus.connected;

  @override
  Stream<WsConnectionEvent> get connectionEvents => events.stream;

  @override
  void sendUpstream(Map<String, dynamic> message) {
    sentMessages.add(message);
  }

  void emitConnected() => events.add(WsConnected(DateTime.now()));
}

class _FixtureRepo implements IBookingDetailRepository {
  _FixtureRepo({
    required this.status,
    this.customerId = 7,
    this.technicianId = 99,
    this.currentUserId = 7,
  });

  final String status;
  final int customerId;
  final int technicianId;
  final int currentUserId;

  @override
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    final json = bookingDetailJson(
      id: bookingId,
      status: status,
      customerId: customerId,
      technicianId: technicianId,
    );
    return BookingDetailMapper.toDomain(
      BookingDetailModel.fromJson(json),
      currentUserId: currentUserId,
    );
  }
}

ProviderContainer _container({
  required _FixtureRepo repo,
  required _FakeWsNotifier ws,
}) {
  final c = ProviderContainer(
    overrides: [
      bookingDetailRepositoryProvider.overrideWithValue(repo),
      wsConnectionProvider.overrideWith(() => ws),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('TrackingSubscriptionController — status × role gate', () {
    test(
      'customer + EN_ROUTE → subscribe_tracking is sent on first detail load',
      () async {
        final ws = _FakeWsNotifier();
        addTearDown(() => ws.events.close());

        final container = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE'),
          ws: ws,
        );

        container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});

        await container.read(bookingDetailProvider(42).future);
        await Future<void>.microtask(() {});

        expect(ws.sentMessages, hasLength(1));
        expect(ws.sentMessages.first, {
          'action': 'subscribe_tracking',
          'booking_id': 42,
        });
      },
    );

    test('customer + ARRIVED → subscribe sent', () async {
      final ws = _FakeWsNotifier();
      addTearDown(() => ws.events.close());

      final container = _container(
        repo: _FixtureRepo(status: 'ARRIVED'),
        ws: ws,
      );
      container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});
      await container.read(bookingDetailProvider(42).future);
      await Future<void>.microtask(() {});

      expect(ws.sentMessages, hasLength(1));
      expect(ws.sentMessages.first['action'], 'subscribe_tracking');
    });

    test(
      'customer + CONFIRMED → no subscribe (status not in window)',
      () async {
        final ws = _FakeWsNotifier();
        addTearDown(() => ws.events.close());

        final container = _container(
          repo: _FixtureRepo(status: 'CONFIRMED'),
          ws: ws,
        );
        container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});
        await container.read(bookingDetailProvider(42).future);
        await Future<void>.microtask(() {});

        expect(ws.sentMessages, isEmpty);
      },
    );

    test(
      'technician viewer + EN_ROUTE → no subscribe (tech publishes via REST)',
      () async {
        final ws = _FakeWsNotifier();
        addTearDown(() => ws.events.close());

        final container = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE', currentUserId: 99),
          ws: ws,
        );
        container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});
        await container.read(bookingDetailProvider(42).future);
        await Future<void>.microtask(() {});

        expect(ws.sentMessages, isEmpty);
      },
    );
  });

  group('TrackingSubscriptionController — WS reconnect replay', () {
    test(
      'WsConnected event re-issues subscribe_tracking when subscribed',
      () async {
        final ws = _FakeWsNotifier();
        addTearDown(() => ws.events.close());

        final container = _container(
          repo: _FixtureRepo(status: 'EN_ROUTE'),
          ws: ws,
        );
        container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});
        await container.read(bookingDetailProvider(42).future);
        await Future<void>.microtask(() {});
        expect(ws.sentMessages, hasLength(1));

        ws.emitConnected();
        await Future<void>.microtask(() {});

        expect(ws.sentMessages, hasLength(2));
        expect(ws.sentMessages.last['action'], 'subscribe_tracking');
      },
    );

    test('WsConnected does NOT re-send when not currently subscribed '
        '(e.g. customer on CONFIRMED)', () async {
      final ws = _FakeWsNotifier();
      addTearDown(() => ws.events.close());

      final container = _container(
        repo: _FixtureRepo(status: 'CONFIRMED'),
        ws: ws,
      );
      container.listen(trackingSubscriptionControllerProvider(42), (_, _) {});
      await container.read(bookingDetailProvider(42).future);
      await Future<void>.microtask(() {});

      ws.emitConnected();
      await Future<void>.microtask(() {});

      expect(ws.sentMessages, isEmpty);
    });
  });

  group('TrackingSubscriptionController — dispose', () {
    test(
      'sends unsubscribe_tracking on dispose when currently subscribed',
      () async {
        final ws = _FakeWsNotifier();

        final container = ProviderContainer(
          overrides: [
            bookingDetailRepositoryProvider.overrideWithValue(
              _FixtureRepo(status: 'EN_ROUTE'),
            ),
            wsConnectionProvider.overrideWith(() => ws),
          ],
        );

        final sub = container.listen(
          trackingSubscriptionControllerProvider(42),
          (_, _) {},
        );
        await container.read(bookingDetailProvider(42).future);
        await Future<void>.microtask(() {});
        expect(ws.sentMessages, hasLength(1));

        sub.close();
        // container.dispose() unconditionally tears down all providers,
        // running each provider's `ref.onDispose` hooks. This is the
        // canonical way to verify dispose-time side effects in Riverpod
        // tests; relying on auto-dispose timing introduces flakiness.
        container.dispose();

        expect(ws.sentMessages, hasLength(2));
        expect(ws.sentMessages.last, {
          'action': 'unsubscribe_tracking',
          'booking_id': 42,
        });

        ws.events.close();
      },
    );
  });
}

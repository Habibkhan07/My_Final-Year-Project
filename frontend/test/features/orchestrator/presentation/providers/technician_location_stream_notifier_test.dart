// Tests for `TechnicianLocationStreamNotifier`.
//
// What we exercise:
//   • The notifier registers a handler with WsFrameDispatcher on build.
//   • An incoming `tech_gps` payload whose booking_id matches → state
//     becomes a TechGpsFrame.
//   • A payload whose booking_id does NOT match → state stays null.
//   • A malformed payload → state stays null (no exception escapes).
//   • The handler unregisters on dispose (no leak).
//
// The notifier defers state mutation via `Future.microtask` (audit
// P1-05), so tests pump pending microtasks via `await Future<void>.microtask(() {})`
// before asserting state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/services/ws_frame_dispatcher.dart';
import 'package:frontend/features/orchestrator/presentation/providers/technician_location_stream_notifier.dart';

void main() {
  group('TechnicianLocationStreamNotifier', () {
    late ProviderContainer container;
    late WsFrameDispatcher dispatcher;

    setUp(() {
      // Real dispatcher — the handler registry lives in plain Dart, no
      // need to mock. This also exercises the production register /
      // unregister API.
      container = ProviderContainer(
        overrides: [
          wsFrameDispatcherProvider.overrideWith((ref) {
            dispatcher = WsFrameDispatcher(ref);
            return dispatcher;
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Map<String, dynamic> envelope({
      required int bookingId,
      double lat = 31.5,
      double lng = 74.3,
    }) {
      return {
        'kind': 'stream',
        'streamType': 'tech_gps',
        'timestamp': '2026-05-10T14:30:00Z',
        'payload': {
          'lat': lat,
          'lng': lng,
          'accuracy_meters': 8.5,
          'heading': 145.0,
          'booking_id': bookingId,
        },
      };
    }

    test('starts with null state before any frame arrives', () {
      final state = container.read(technicianLocationStreamProvider(42));
      expect(state, isNull);
    });

    test('handler is registered after first read', () {
      // Reading the provider runs build(), which calls
      // dispatcher.register('tech_gps', handler).
      container.read(technicianLocationStreamProvider(42));
      expect(dispatcher.hasHandlerFor('tech_gps'), isTrue);
    });

    test('updates state on tech_gps frame matching jobId', () async {
      container.read(technicianLocationStreamProvider(42));
      dispatcher.dispatch(envelope(bookingId: 42, lat: 31.55, lng: 74.32));

      // Drain the deferred microtask the notifier uses for state mutation.
      await Future<void>.microtask(() {});

      final state = container.read(technicianLocationStreamProvider(42));
      expect(state, isNotNull);
      expect(state!.bookingId, 42);
      expect(state.latitude, 31.55);
      expect(state.longitude, 74.32);
      expect(state.accuracyMeters, 8.5);
      expect(state.heading, 145.0);
    });

    test('drops frames whose booking_id does not match family arg', () async {
      container.read(technicianLocationStreamProvider(42));
      dispatcher.dispatch(envelope(bookingId: 99));
      await Future<void>.microtask(() {});

      expect(container.read(technicianLocationStreamProvider(42)), isNull);
    });

    test('drops malformed payloads without crashing the listener', () async {
      container.read(technicianLocationStreamProvider(42));
      // Missing required `lat` and `lng` — fromJson must throw and the
      // handler must swallow.
      dispatcher.dispatch({
        'kind': 'stream',
        'streamType': 'tech_gps',
        'timestamp': '2026-05-10T14:30:00Z',
        'payload': {'booking_id': 42},
      });
      await Future<void>.microtask(() {});

      expect(container.read(technicianLocationStreamProvider(42)), isNull);

      // A subsequent valid frame still works — the handler wasn't
      // poisoned by the prior bad frame.
      dispatcher.dispatch(envelope(bookingId: 42, lat: 31.6, lng: 74.4));
      await Future<void>.microtask(() {});
      expect(
        container.read(technicianLocationStreamProvider(42))?.latitude,
        31.6,
      );
    });

    test('subsequent frames overwrite state with the latest', () async {
      container.read(technicianLocationStreamProvider(42));

      dispatcher.dispatch(envelope(bookingId: 42, lat: 31.0, lng: 74.0));
      await Future<void>.microtask(() {});
      dispatcher.dispatch(envelope(bookingId: 42, lat: 31.9, lng: 74.9));
      await Future<void>.microtask(() {});

      final latest = container.read(technicianLocationStreamProvider(42));
      expect(latest!.latitude, 31.9);
      expect(latest.longitude, 74.9);
    });

    test('unregisters dispatcher handler on dispose', () {
      container.read(technicianLocationStreamProvider(42));
      expect(dispatcher.hasHandlerFor('tech_gps'), isTrue);

      // Force the family-keyed provider to dispose by invalidating it.
      container.invalidate(technicianLocationStreamProvider(42));

      // Riverpod's auto-dispose runs on the next microtask after
      // invalidate; pump once.
      // (Explicit dispose verification — handler should be gone.)
      expect(dispatcher.hasHandlerFor('tech_gps'), isFalse);
    });
  });
}

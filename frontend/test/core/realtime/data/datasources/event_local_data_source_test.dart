import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/data/models/system_event_model.dart';

void main() {
  late EventLocalDataSource dataSource;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = EventLocalDataSource(prefs);
  });

  group('EventLocalDataSource', () {
    final sampleEvent = SystemEventModel(
      kind: 'event',
      id: '123',
      rawType: 'job_new_request',
      targetRole: 'technician',
      timestamp: '2023-01-01T12:00:00.000Z',
      payload: {'key': 'value'},
    );

    group('Event cache', () {
      test('L1 — cacheEventList -> getCachedEventList round-trip', () async {
        await dataSource.cacheEventList([sampleEvent]);
        final cached = dataSource.getCachedEventList();

        expect(cached, isNotNull);
        expect(cached!.length, 1);
        expect(cached.first.id, '123');
      });

      test('L2 — getCachedEventList returns null when key absent', () {
        final cached = dataSource.getCachedEventList();
        expect(cached, isNull);
      });

      test('L3 — getCachedEventList returns null on corrupt stored JSON', () async {
        await prefs.setString('event_sync_cached_events', '{ invalid json ]');
        final cached = dataSource.getCachedEventList();
        expect(cached, isNull);
      });

      test('L4 — cacheEventList with item that fails toJson leaves prior cache intact, never throws', () async {
        await dataSource.cacheEventList([sampleEvent]);
        
        // This will fail jsonEncode because Object() is not encodable.
        final badEvent = sampleEvent.copyWith(payload: {'bad': Object()});
        
        await expectLater(
          () => dataSource.cacheEventList([badEvent]),
          returnsNormally,
        );

        final cached = dataSource.getCachedEventList();
        expect(cached, isNotNull);
        expect(cached!.length, 1);
        expect(cached.first.id, '123');
      });
    });

    group('Sync timestamp', () {
      test('L5 — saveLastSyncTimestamp / getLastSyncTimestamp round-trip', () async {
        await dataSource.saveLastSyncTimestamp('2023-01-01T12:00:00.000Z');
        final timestamp = dataSource.getLastSyncTimestamp();
        expect(timestamp, '2023-01-01T12:00:00.000Z');
      });

      test('L6 — getLastSyncTimestamp returns null when absent', () {
        final timestamp = dataSource.getLastSyncTimestamp();
        expect(timestamp, isNull);
      });
    });

    group('Pending background events', () {
      test('L7 — savePendingBackgroundEvent appends to existing queue, preserves prior items + ordering', () async {
        await dataSource.savePendingBackgroundEvent({'id': '1'});
        await dataSource.savePendingBackgroundEvent({'id': '2'});

        final events = await dataSource.consumePendingBackgroundEvents();
        expect(events.length, 2);
        expect(events[0]['id'], '1');
        expect(events[1]['id'], '2');
      });

      test('L8 — savePendingBackgroundEvent on empty queue creates fresh list', () async {
        await dataSource.savePendingBackgroundEvent({'id': '1'});
        final events = await dataSource.consumePendingBackgroundEvents();
        expect(events.length, 1);
        expect(events[0]['id'], '1');
      });

      test('L9 — consumePendingBackgroundEvents returns and clears queue', () async {
        await dataSource.savePendingBackgroundEvent({'id': '1'});
        
        final events = await dataSource.consumePendingBackgroundEvents();
        expect(events.length, 1);

        final eventsAfter = await dataSource.consumePendingBackgroundEvents();
        expect(eventsAfter, isEmpty);
      });

      test('L10 — consumePendingBackgroundEvents returns [] on absent or corrupt data, never throws', () async {
        // Absent
        var events = await dataSource.consumePendingBackgroundEvents();
        expect(events, isEmpty);

        // Corrupt
        await prefs.setString('event_sync_pending_bg_events', '{ bad json ]');
        events = await dataSource.consumePendingBackgroundEvents();
        expect(events, isEmpty);
      });

      test('L11 — cross-isolate constant lock-in', () async {
        await dataSource.savePendingBackgroundEvent({'id': '1'});
        final raw = prefs.getString('event_sync_pending_bg_events');
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw!) as List<dynamic>;
        expect(decoded.length, 1);
        expect(decoded[0]['id'], '1');
      });

      test(
        'L11a — flag #19 family: pending-bg queue is FIFO-capped at 50; '
        'oldest entries drop when the cap is exceeded',
        () async {
          // Append 60 events. Cap is 50. After every save the queue is
          // truncated from the front, so the final state holds the 50
          // newest (ids 11..60).
          for (var i = 1; i <= 60; i++) {
            await dataSource.savePendingBackgroundEvent({'id': '$i'});
          }

          final events = await dataSource.consumePendingBackgroundEvents();
          expect(events.length, 50,
              reason: 'cap must hold even if save is called more than 50 '
                  'times — defends against a wedged FCM init in the main '
                  'isolate that never drains the queue');
          expect(events.first['id'], '11',
              reason: 'oldest 10 (ids 1..10) must be dropped');
          expect(events.last['id'], '60',
              reason: 'newest entry must be retained');
        },
      );
    });

    group('Pending ACKs', () {
      test('L12 — savePendingAcks merges with existing, dedupes', () async {
        await dataSource.savePendingAcks(['1', '2']);
        await dataSource.savePendingAcks(['2', '3']);

        final acks = dataSource.getPendingAcks();
        expect(acks.length, 3);
        expect(acks, containsAll(['1', '2', '3']));
      });

      test('L13 — getPendingAcks returns [] when absent', () {
        final acks = dataSource.getPendingAcks();
        expect(acks, isEmpty);
      });

      test('L14 — getPendingAcks returns [] on corrupt JSON, never throws', () async {
        await prefs.setString('event_sync_pending_acks', '{ bad json ]');
        final acks = dataSource.getPendingAcks();
        expect(acks, isEmpty);
      });

      test('L15 — clearPendingAcks removes the key', () async {
        await dataSource.savePendingAcks(['1']);
        expect(dataSource.getPendingAcks(), isNotEmpty);

        await dataSource.clearPendingAcks();
        expect(dataSource.getPendingAcks(), isEmpty);
      });
    });

    group('New clear methods', () {
      test('L16 — clearLastSyncTimestamp removes the key', () async {
        await dataSource.saveLastSyncTimestamp('2023-01-01T12:00:00.000Z');
        expect(dataSource.getLastSyncTimestamp(), isNotNull);

        await dataSource.clearLastSyncTimestamp();
        expect(dataSource.getLastSyncTimestamp(), isNull);
      });

      test('L17 — clearCachedEvents removes the key', () async {
        await dataSource.cacheEventList([sampleEvent]);
        expect(dataSource.getCachedEventList(), isNotNull);

        await dataSource.clearCachedEvents();
        expect(dataSource.getCachedEventList(), isNull);
      });
    });
  });
}

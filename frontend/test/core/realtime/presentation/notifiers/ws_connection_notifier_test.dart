import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/realtime/data/datasources/event_local_data_source.dart';
import 'package:frontend/core/realtime/data/repositories/event_repository.dart';
import 'package:frontend/core/realtime/domain/entities/system_event_entity.dart';
import 'package:frontend/core/realtime/presentation/notifiers/system_event_notifier.dart';
import 'package:frontend/core/realtime/presentation/notifiers/ws_connection_notifier.dart';
import 'package:frontend/core/realtime/presentation/providers/dependency_injection.dart';
import 'package:frontend/core/realtime/presentation/state/connection_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _MockRepo extends Mock implements EventRepository {}

class _MockLocal extends Mock implements EventLocalDataSource {}

// ─── Fake WebSocketChannel ────────────────────────────────────────────────

class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  final Completer<void> _readyCompleter = Completer<void>();
  final StreamController<dynamic> _streamController =
      StreamController<dynamic>();
  late final _FakeWebSocketSink _sink = _FakeWebSocketSink(this);
  final List<dynamic> sentItems = <dynamic>[];

  void completeReady() {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  void failReady(Object error) {
    if (!_readyCompleter.isCompleted) _readyCompleter.completeError(error);
  }

  void pushFrame(dynamic frame) => _streamController.add(frame);

  Future<void> closeStream() => _streamController.close();

  @override
  Future<void> get ready => _readyCompleter.future;

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink(this._channel);
  final _FakeWebSocketChannel _channel;
  final Completer<void> _doneCompleter = Completer<void>();

  @override
  void add(dynamic data) => _channel.sentItems.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<dynamic> close([int? closeCode, String? closeReason]) async {
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  @override
  Future<void> get done => _doneCompleter.future;
}

// ─── Container helper ─────────────────────────────────────────────────────

ProviderContainer _container({
  required EventRepository repo,
  required EventLocalDataSource local,
}) {
  final container = ProviderContainer(
    overrides: [
      eventRepositoryProvider.overrideWithValue(repo),
      eventLocalDataSourceProvider.overrideWithValue(local),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _MockRepo repo;
  late _MockLocal local;

  setUpAll(() {
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    repo = _MockRepo();
    local = _MockLocal();

    // Defaults so the post-connect cascade (syncMissedEvents → critical →
    // pending acks) never throws and doesn't trigger an outbound POST.
    when(() => local.getLastSyncTimestamp()).thenReturn(null);
    when(() => local.getPendingAcks()).thenReturn(const <String>[]);
    when(() => repo.syncMissedEvents(any()))
        .thenAnswer((_) async => <SystemEventEntity>[]);
    when(() => repo.fetchUnacknowledgedCritical())
        .thenAnswer((_) async => <SystemEventEntity>[]);
    when(() => repo.acknowledgeEvents(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    WsConnectionNotifier.channelFactoryForTesting = null;
  });

  // ─── Tier A — state machine ────────────────────────────────────────────

  group('Tier A — state machine', () {
    test('W1 — build() returns disconnected', () {
      final container = _container(repo: repo, local: local);

      final state = container.read(wsConnectionProvider);

      expect(state, WsConnectionStatus.disconnected);
    });

    test(
        'W2 — disconnect() with no live socket: state stays disconnected; no '
        'pending reconnect timer; no exception', () {
      fakeAsync((async) {
        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        notifier.disconnect();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.disconnected,
        );
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  // ─── Tier B — with injected factory ────────────────────────────────────

  group('Tier B — fake channel injection', () {
    test(
        'W3 — connect succeeds: connecting → connected; cascade triggers '
        'syncMissedEvents()', () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        final transitions = <WsConnectionStatus>[];
        container.listen<WsConnectionStatus>(
          wsConnectionProvider,
          (prev, next) => transitions.add(next),
        );

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.connected,
        );
        expect(
          transitions,
          containsAllInOrder(<WsConnectionStatus>[
            WsConnectionStatus.connecting,
            WsConnectionStatus.connected,
          ]),
        );
        verify(() => repo.syncMissedEvents(any())).called(1);
      });
    });

    test('W4 — handshake fails: state == reconnecting; reconnect scheduled', () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) {
          // Defer failReady so connect()'s `await ready` listener is attached
          // before the error lands — otherwise it surfaces as unhandled.
          scheduleMicrotask(() => fake.failReady(Exception('handshake')));
          return fake;
        };

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.reconnecting,
        );
        expect(async.pendingTimers, isNotEmpty);
      });
    });

    test(
        'W5 — backoff progression: 1s, 2s, 4s, 8s, 16s, 30s, 30s, 30s '
        '(doubling, capped at 30s)', () {
      fakeAsync((async) {
        WsConnectionNotifier.channelFactoryForTesting = (_) {
          final f = _FakeWebSocketChannel();
          scheduleMicrotask(() => f.failReady(Exception('handshake')));
          return f;
        };

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        const expected = <Duration>[
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
          Duration(seconds: 16),
          Duration(seconds: 30),
          Duration(seconds: 30),
          Duration(seconds: 30),
        ];

        for (final dur in expected) {
          final pending = async.pendingTimers.toList();
          expect(
            pending.length,
            1,
            reason: 'expected exactly one pending timer at $dur',
          );
          expect(pending.single.duration, dur);
          async.elapse(dur);
          async.flushMicrotasks();
        }
      });
    });

    test(
        'W6 — after 11 consecutive failures: state == failed; timer still '
        'scheduled at 30s cap; further failures keep state == failed', () {
      fakeAsync((async) {
        WsConnectionNotifier.channelFactoryForTesting = (_) {
          final f = _FakeWebSocketChannel();
          scheduleMicrotask(() => f.failReady(Exception('handshake')));
          return f;
        };

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();
        // After failure 1: state=reconnecting, 1 timer pending.

        // Drive failures 2..11. After failure 11, retryCount==11>10 → failed.
        for (var i = 0; i < 10; i++) {
          final dur = async.pendingTimers.single.duration;
          async.elapse(dur);
          async.flushMicrotasks();
        }

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.failed,
        );
        expect(
          async.pendingTimers.single.duration,
          const Duration(seconds: 30),
        );

        // One more failure (12th): still failed, still 30s.
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.failed,
        );
        expect(
          async.pendingTimers.single.duration,
          const Duration(seconds: 30),
        );
      });
    });

    test(
        'W7 — stream onDone WITHOUT manual disconnect → reconnect scheduled',
        () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();
        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.connected,
        );

        unawaited(fake.closeStream());
        async.flushMicrotasks();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.reconnecting,
        );
        expect(async.pendingTimers, isNotEmpty);
      });
    });

    test(
        'W8 — stream onDone WITH manual disconnect → no reconnect scheduled',
        () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        notifier.disconnect();
        // Even pushing a stream close after disconnect must not trigger a
        // reconnect — the subscription is cancelled and the manual flag is set.
        unawaited(fake.closeStream());
        async.flushMicrotasks();

        expect(
          container.read(wsConnectionProvider),
          WsConnectionStatus.disconnected,
        );
        expect(async.pendingTimers, isEmpty);
      });
    });

    test(
        'W9 — _onMessage with valid JSON frame → systemEventNotifier receives '
        'mapped entity', () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        final frame = jsonEncode(<String, dynamic>{
          'id': 'evt-w9',
          'rawType': 'job_dispatched',
          'targetRole': 'technician',
          'timestamp': '2026-04-25T12:00:00Z',
          'payload': <String, dynamic>{},
        });
        fake.pushFrame(frame);
        async.flushMicrotasks();

        expect(
          container.read(systemEventProvider).latestEvent?.id,
          'evt-w9',
        );
      });
    });

    test(
        'W10 — _onMessage with malformed JSON → caught, processEvent NOT called',
        () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        fake.pushFrame('not json {{{');
        async.flushMicrotasks();

        expect(
          container.read(systemEventProvider).latestEvent,
          isNull,
        );
      });
    });

    test(
        'W11 — _onMessage with frame whose toDomain() returns null (bad '
        'timestamp) → processEvent NOT called', () {
      fakeAsync((async) {
        final fake = _FakeWebSocketChannel();
        WsConnectionNotifier.channelFactoryForTesting = (_) => fake;
        fake.completeReady();

        final container = _container(repo: repo, local: local);
        final notifier = container.read(wsConnectionProvider.notifier);

        unawaited(notifier.connect('tok'));
        async.flushMicrotasks();

        final frame = jsonEncode(<String, dynamic>{
          'id': 'evt-w11',
          'rawType': 'job_dispatched',
          'targetRole': 'technician',
          'timestamp': 'not-a-valid-timestamp',
          'payload': <String, dynamic>{},
        });
        fake.pushFrame(frame);
        async.flushMicrotasks();

        expect(
          container.read(systemEventProvider).latestEvent,
          isNull,
        );
      });
    });
  });
}

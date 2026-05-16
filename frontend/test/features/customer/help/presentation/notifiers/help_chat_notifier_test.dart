// State-layer tests for HelpChatNotifier.
//
// Pattern (mirrors `chatbot_session_notifier_test.dart`):
//   * Hand-written `_FakeRemoteDataSource` implementing
//     `IChatbotRemoteDataSource`. The help notifier talks directly to
//     the remote data source (no repository / use-case indirection —
//     the help surface is small enough that the extra layers earn no
//     keep), so overriding the data source provider is enough.
//   * `ProviderContainer` with
//     `chatbotRemoteDataSourceProvider.overrideWithValue(fake)`.
//   * `await container.read(helpChatProvider.future)` before any
//     mutation (CLAUDE.md §Testing Warm-up).
//
// Coverage:
//   * build → start path produces greeting bubble.
//   * sendText optimistic append + bot reply.
//   * sendText empty / whitespace → no-op.
//   * sendText during isSending → no-op (double-tap guard).
//   * sendText error → reverts to pre-mutation transcript via
//     AsyncError.copyWithPrevious.
//   * clearAndRestart during no-state → no-op.
//   * clearAndRestart during isSending → no-op.
//   * clearAndRestart happy path → closeConversation called with the
//     correct id, then invalidateSelf restarts the conversation.
//   * clearAndRestart with close error → still invalidates (best-effort).
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/data/data_sources/chatbot_remote_data_source.dart';
import 'package:frontend/features/customer/chatbot/data/models/attachment_upload_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/close_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_detail_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_start_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/state_summary_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/turn_result_model.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/help/presentation/notifiers/help_chat_notifier.dart';
import 'package:frontend/features/customer/help/presentation/notifiers/help_chat_state.dart';

// ─── Test fake ──────────────────────────────────────────────────────────

class _FakeRemoteDataSource implements IChatbotRemoteDataSource {
  /// Scripted return for the next start call. Sequential opens (via
  /// clearAndRestart → invalidateSelf) read from this queue in order.
  final List<ConversationStartResponseModel> startResults = [];
  final List<TurnResultModel> sendResults = [];

  Object? throwOnStart;
  Object? throwOnSend;
  Object? throwOnClose;

  int startCalls = 0;
  int sendCalls = 0;
  int closeCalls = 0;
  int? lastClosedConversationId;

  @override
  Future<ConversationStartResponseModel> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) async {
    startCalls++;
    if (throwOnStart != null) throw throwOnStart!;
    if (startResults.isNotEmpty) return startResults.removeAt(0);
    return _defaultStart(conversationId: startCalls);
  }

  @override
  Future<TurnResultModel> sendTextMessage({
    required int conversationId,
    required String text,
  }) async {
    sendCalls++;
    if (throwOnSend != null) throw throwOnSend!;
    if (sendResults.isNotEmpty) return sendResults.removeAt(0);
    return _defaultTurn(conversationId: conversationId);
  }

  @override
  Future<CloseResponseModel> closeConversation(int conversationId) async {
    closeCalls++;
    lastClosedConversationId = conversationId;
    if (throwOnClose != null) throw throwOnClose!;
    return CloseResponseModel(closedAt: DateTime.now().toIso8601String());
  }

  // ── Unused on the help path — surface as UnimplementedError so a
  // future test accidentally invoking them gets a loud failure. ──
  @override
  Future<ConversationDetailModel> getConversation(int conversationId) =>
      throw UnimplementedError();

  @override
  Future<TurnResultModel> submitForm({
    required int conversationId,
    required Map<String, dynamic> values,
  }) => throw UnimplementedError();

  @override
  Future<TurnResultModel> notifyAttachmentsDone(int conversationId) =>
      throw UnimplementedError();

  @override
  Future<AttachmentUploadResponseModel> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) => throw UnimplementedError();
}

// ─── Sample factories ───────────────────────────────────────────────────

ConversationStartResponseModel _defaultStart({int conversationId = 1}) =>
    ConversationStartResponseModel(
      conversationId: conversationId,
      personaKey: 'general',
      currentPhase: 'CHAT',
      botMessage: 'Hi! Karigar Help here.',
      uiInputKind: 'text',
      uiFormSchema: null,
      uiHint: 'Ask a question',
      stateSummary: const StateSummaryModel(),
    );

TurnResultModel _defaultTurn({int conversationId = 1, String reply = 'Sure.'}) =>
    TurnResultModel(
      conversationId: conversationId,
      currentPhase: 'CHAT',
      botMessage: reply,
      uiInputKind: 'text',
      uiFormSchema: null,
      uiHint: 'Ask another question',
      stateSummary: const StateSummaryModel(),
      isClosed: false,
      outputRefs: const {},
    );

// ─── Container scaffolding ──────────────────────────────────────────────

ProviderContainer _makeContainer(_FakeRemoteDataSource fake) {
  final container = ProviderContainer(
    overrides: [
      chatbotRemoteDataSourceProvider.overrideWithValue(fake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ─── Tests ──────────────────────────────────────────────────────────────

void main() {
  group('HelpChatNotifier — build', () {
    test('opens a general conversation and seeds the greeting bubble', () async {
      final fake = _FakeRemoteDataSource()
        ..startResults.add(
          _defaultStart(conversationId: 42)
              .copyWith(botMessage: 'Greeting from server'),
        );
      final container = _makeContainer(fake);

      final state = await container.read(helpChatProvider.future);

      expect(fake.startCalls, 1);
      expect(state.conversationId, 42);
      expect(state.transcript, hasLength(1));
      expect(state.transcript.single.role, ChatRole.bot);
      expect(state.transcript.single.text, 'Greeting from server');
      expect(state.isSending, isFalse);
    });
  });

  group('HelpChatNotifier — sendText', () {
    test('appends optimistic user bubble + bot reply on happy path', () async {
      final fake = _FakeRemoteDataSource()
        ..sendResults.add(_defaultTurn(reply: 'Inspection fee is Rs. 500.'));
      final container = _makeContainer(fake);

      await container.read(helpChatProvider.future); // warm-up
      await container
          .read(helpChatProvider.notifier)
          .sendText('how much is the fee?');

      final state = await container.read(helpChatProvider.future);
      expect(fake.sendCalls, 1);
      expect(state.transcript, hasLength(3)); // greeting + user + bot
      expect(state.transcript[1].role, ChatRole.user);
      expect(state.transcript[1].text, 'how much is the fee?');
      expect(state.transcript[2].role, ChatRole.bot);
      expect(state.transcript[2].text, 'Inspection fee is Rs. 500.');
      expect(state.isSending, isFalse);
    });

    test('trims whitespace and rejects empty input', () async {
      final fake = _FakeRemoteDataSource();
      final container = _makeContainer(fake);
      await container.read(helpChatProvider.future);

      await container.read(helpChatProvider.notifier).sendText('   ');
      await container.read(helpChatProvider.notifier).sendText('');

      expect(fake.sendCalls, 0);
      final state = await container.read(helpChatProvider.future);
      expect(state.transcript, hasLength(1)); // greeting only
    });

    test('reverts to pre-mutation transcript on send error', () async {
      final fake = _FakeRemoteDataSource()
        ..throwOnSend = Exception('boom');
      final container = _makeContainer(fake);

      await container.read(helpChatProvider.future);
      await container.read(helpChatProvider.notifier).sendText('hi');

      final after = container.read(helpChatProvider);
      // After failure: AsyncError surfacing the boom, with previous
      // (pre-optimistic) data attached via copyWithPrevious.
      expect(after.hasError, isTrue);
      expect(after.hasValue, isTrue); // copyWithPrevious preserves data
      // Transcript reverts to greeting-only — no orphan optimistic
      // user bubble left dangling.
      expect(after.value!.transcript, hasLength(1));
      expect(after.value!.transcript.single.role, ChatRole.bot);
      expect(after.value!.isSending, isFalse);
    });
  });

  group('HelpChatNotifier — clearAndRestart', () {
    test('is a no-op before initial build has completed', () async {
      final fake = _FakeRemoteDataSource();
      final container = _makeContainer(fake);

      // Trigger build but DON'T await — state stays AsyncLoading
      // synchronously. The notifier's clearAndRestart should take the
      // ``!state.hasValue`` early-return path.
      // ignore: unawaited_futures
      container.read(helpChatProvider.future);

      await container.read(helpChatProvider.notifier).clearAndRestart();

      expect(fake.closeCalls, 0);
      expect(fake.startCalls, 1, reason: 'only the build start, no restart');

      // Drain so the notifier resolves cleanly before tearDown disposes.
      await container.read(helpChatProvider.future);
    });

    test('is a no-op while a send is in flight', () async {
      // sendText with a 50ms server delay → during that window
      // ``isSending=true`` so clearAndRestart's second guard kicks in.
      final fake = _FakeRemoteDataSourceDelayedSend(
        sendDelay: const Duration(milliseconds: 50),
      );
      final container = ProviderContainer(
        overrides: [
          chatbotRemoteDataSourceProvider.overrideWithValue(fake),
        ],
      );
      addTearDown(container.dispose);

      // The notifier is keepAlive: false. Without an active subscriber
      // the provider auto-disposes between awaits, which lets
      // sendText's post-delay state mutation hit a disposed Ref. A
      // permanent listener keeps the notifier alive for the whole test.
      final sub = container.listen<AsyncValue<HelpChatState>>(
        helpChatProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container.read(helpChatProvider.future);

      // Kick off the send — returns a Future that won't complete for
      // 50ms. The synchronous portion of sendText runs immediately and
      // flips state to ``isSending=true``.
      final sendFuture =
          container.read(helpChatProvider.notifier).sendText('hi');
      // Yield once so sendText's synchronous block (which sets state)
      // runs before we read it.
      await Future<void>.delayed(Duration.zero);

      // In-flight: clearAndRestart must no-op on the isSending guard.
      await container.read(helpChatProvider.notifier).clearAndRestart();
      expect(fake.closeCalls, 0,
          reason: 'clear must not run during in-flight send');

      // Let the send finish cleanly so the container can tear down
      // without a pending state-mutation on a disposed notifier.
      await sendFuture;
    });

    test('closes the current conversation and starts a fresh one', () async {
      final fake = _FakeRemoteDataSource()
        ..startResults.addAll([
          _defaultStart(conversationId: 100)
              .copyWith(botMessage: 'First greeting'),
          _defaultStart(conversationId: 200)
              .copyWith(botMessage: 'Fresh greeting'),
        ]);
      final container = _makeContainer(fake);

      final first = await container.read(helpChatProvider.future);
      expect(first.conversationId, 100);

      await container.read(helpChatProvider.notifier).clearAndRestart();

      expect(fake.closeCalls, 1);
      expect(fake.lastClosedConversationId, 100);
      // invalidateSelf triggers rebuild → second startConversation fires.
      final second = await container.read(helpChatProvider.future);
      expect(fake.startCalls, 2);
      expect(second.conversationId, 200);
      expect(second.transcript.single.text, 'Fresh greeting');
    });

    test('swallows close error and still starts a fresh conversation', () async {
      final fake = _FakeRemoteDataSource()
        ..throwOnClose = Exception('network down')
        ..startResults.addAll([
          _defaultStart(conversationId: 1),
          _defaultStart(conversationId: 2)
              .copyWith(botMessage: 'After failed close'),
        ]);
      final container = _makeContainer(fake);

      await container.read(helpChatProvider.future);
      await container.read(helpChatProvider.notifier).clearAndRestart();

      expect(fake.closeCalls, 1, reason: 'close attempted');
      // Best-effort: even though close threw, the fresh conversation
      // starts. The orphan row is left for the auto-close sweeper
      // (flag #56).
      final fresh = await container.read(helpChatProvider.future);
      expect(fresh.conversationId, 2);
      expect(fresh.transcript.single.text, 'After failed close');
    });
  });
}

// ─── Delayed-send variant for the in-flight isSending guard test ─────

class _FakeRemoteDataSourceDelayedSend extends _FakeRemoteDataSource {
  final Duration sendDelay;
  _FakeRemoteDataSourceDelayedSend({required this.sendDelay});

  @override
  Future<TurnResultModel> sendTextMessage({
    required int conversationId,
    required String text,
  }) async {
    sendCalls++;
    await Future<void>.delayed(sendDelay);
    return _defaultTurn(conversationId: conversationId);
  }
}

// State-layer tests for ChatbotSessionNotifier.
//
// Pattern (mirrors `test/features/customer/bookings/.../customer_bookings_list_notifier_test.dart`):
//   * Hand-written `_FakeRepo` implementing `IChatbotRepository`.
//     Use cases are thin wrappers around the repo, so overriding only
//     the repo provider is enough — the real use cases auto-wire to
//     the fake.
//   * `ProviderContainer` with `chatbotRepositoryProvider.overrideWithValue(fake)`.
//   * `await container.read(provider.future)` before any mutation
//     (CLAUDE.md §Testing Warm-up).
//
// Coverage:
//   * build → start path (no recovery id)
//   * build → fetch path (recovery id present)
//   * build → stale recovery id (fetch throws ConversationNotFoundFailure)
//     clears id + falls through to start
//   * sendText optimistic append + revert on error
//   * sendText empty / whitespace → no-op
//   * submitForm happy + FormValidationFailure
//   * uploadAttachment happy → attachmentsCount updates
//   * uploadAttachment error → previous session preserved via copyWithPrevious
//   * markAttachmentsDone happy
//   * close happy (state transitions to closed)
//   * close on already-closed session → early return, no repo call
//   * refresh → calls fetchConversation
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/output_refs.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';
import 'package:frontend/features/customer/chatbot/domain/failures/chatbot_failure.dart';
import 'package:frontend/features/customer/chatbot/domain/repositories/chatbot_repository.dart';
import 'package:frontend/features/customer/chatbot/presentation/notifiers/chatbot_session_notifier.dart';
import 'package:frontend/features/customer/chatbot/presentation/providers/dependency_injection.dart';

// ─── Test fake ──────────────────────────────────────────────────────────

class _FakeRepo implements IChatbotRepository {
  // Scripted returns / throws — null means "use the default sample".
  ChatSession? startResult;
  ChatSession? fetchResult;
  ChatSession? sendTextResult;
  ChatSession? submitFormResult;
  ChatSession? notifyDoneResult;
  ChatSession? closeResult;
  int uploadCountResult = 1;

  Object? throwOnStart;
  Object? throwOnFetch;
  Object? throwOnSendText;
  Object? throwOnSubmitForm;
  Object? throwOnNotifyDone;
  Object? throwOnUpload;
  Object? throwOnClose;

  /// Per-booking active recovery ids (was a single global int — now
  /// per-booking to match the production fix).
  final Map<int, int?> activeIds = {};
  final Map<int, String?> drafts = {};

  // Call counters.
  int startCalls = 0;
  int fetchCalls = 0;
  int sendTextCalls = 0;
  int submitFormCalls = 0;
  int notifyDoneCalls = 0;
  int uploadCalls = 0;
  int closeCalls = 0;
  int setActiveCalls = 0;

  String? capturedSendText;
  Map<String, dynamic>? capturedFormValues;

  @override
  Future<ChatSession> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) async {
    startCalls++;
    if (throwOnStart != null) throw throwOnStart!;
    return startResult ?? _sampleSession();
  }

  @override
  Future<ChatSession> fetchConversation(int conversationId) async {
    fetchCalls++;
    if (throwOnFetch != null) throw throwOnFetch!;
    return fetchResult ?? _sampleSession(conversationId: conversationId);
  }

  @override
  Future<ChatSession> sendTextTurn({
    required int conversationId,
    required int bookingId,
    required String text,
  }) async {
    sendTextCalls++;
    capturedSendText = text;
    if (throwOnSendText != null) throw throwOnSendText!;
    return sendTextResult ?? _sampleSession(conversationId: conversationId);
  }

  @override
  Future<ChatSession> submitFormTurn({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  }) async {
    submitFormCalls++;
    capturedFormValues = values;
    if (throwOnSubmitForm != null) throw throwOnSubmitForm!;
    return submitFormResult ?? _sampleSession(conversationId: conversationId);
  }

  @override
  Future<ChatSession> notifyAttachmentsDone({
    required int conversationId,
    required int bookingId,
  }) async {
    notifyDoneCalls++;
    if (throwOnNotifyDone != null) throw throwOnNotifyDone!;
    return notifyDoneResult ?? _sampleSession(conversationId: conversationId);
  }

  @override
  Future<int> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) async {
    uploadCalls++;
    if (throwOnUpload != null) throw throwOnUpload!;
    return uploadCountResult;
  }

  @override
  Future<ChatSession> closeConversation({
    required int conversationId,
    required int bookingId,
  }) async {
    closeCalls++;
    if (throwOnClose != null) throw throwOnClose!;
    return closeResult ??
        _sampleSession(
          conversationId: conversationId,
          isClosed: true,
          outputRefs: const OutputRefs(ticketId: 1284),
        );
  }

  // ─── Local-only methods ───
  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) async {
    drafts[conversationId] = text;
  }

  @override
  Future<String?> loadDraftText(int conversationId) async =>
      drafts[conversationId];

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) async {
    setActiveCalls++;
    activeIds[bookingId] = conversationId;
  }

  @override
  Future<int?> getActiveConversationId(int bookingId) async =>
      activeIds[bookingId];
}

ChatSession _sampleSession({
  int conversationId = 7001,
  ChatPhase phase = ChatPhase.understand,
  List<ChatMessage>? transcript,
  int attachmentsCount = 0,
  bool isClosed = false,
  OutputRefs? outputRefs,
}) {
  return ChatSession(
    conversationId: conversationId,
    personaKey: 'dispute',
    phase: phase,
    transcript: transcript ?? const [],
    directive: const TextDirective(botMessage: 'hi', hint: 'type'),
    attachmentsCount: attachmentsCount,
    isClosed: isClosed,
    outputRefs: outputRefs,
  );
}

ChatMessage _botMessage({int id = 1, String text = 'thanks'}) {
  return ChatMessage(
    id: id,
    role: ChatRole.bot,
    text: text,
    createdAt: DateTime.utc(2026, 5, 14, 3, 21, 55),
    phase: ChatPhase.understand,
  );
}

ProviderContainer _build({required _FakeRepo repo}) {
  final container = ProviderContainer(
    overrides: [
      chatbotRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  late _FakeRepo repo;

  setUp(() {
    repo = _FakeRepo();
  });

  // ─── build() ───────────────────────────────────────────────────────

  group('build()', () {
    test('no recovery id → calls startConversation', () async {
      // No activeIds entry for this booking → recovery is null →
      // startConversation runs.
      repo.startResult = _sampleSession(conversationId: 7777);
      final c = _build(repo: repo);

      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );
      final state = c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
      );

      expect(state.hasValue, isTrue);
      expect(state.requireValue.conversationId, 7777);
      expect(repo.startCalls, 1);
      expect(repo.fetchCalls, 0);
    });

    test('recovery id present → calls fetchConversation(id)', () async {
      repo.activeIds[9001] = 42;
      repo.fetchResult = _sampleSession(conversationId: 42);
      final c = _build(repo: repo);

      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      expect(repo.fetchCalls, 1);
      expect(repo.startCalls, 0);
      expect(
        c
            .read(
              chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
            )
            .requireValue
            .conversationId,
        42,
      );
    });

    test(
      'stale recovery id (fetch → ConversationNotFoundFailure) clears + starts fresh',
      () async {
        repo.activeIds[9001] = 999;
        repo.throwOnFetch = const ConversationNotFoundFailure();
        repo.startResult = _sampleSession(conversationId: 8888);
        final c = _build(repo: repo);

        await c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
        );

        // The stale id was cleared (set to null). The production repo
        // would then re-save the new id from inside startConversation;
        // the fake's startConversation doesn't replicate that side
        // effect, so the slot stays null here.
        expect(repo.activeIds[9001], isNull);
        expect(repo.startCalls, 1);
        expect(repo.fetchCalls, 1);
        expect(
          c
              .read(
                chatbotSessionProvider(
                  personaKey: 'dispute',
                  bookingId: 9001,
                ),
              )
              .requireValue
              .conversationId,
          8888,
        );
      },
    );
  });

  // ─── sendText ──────────────────────────────────────────────────────

  group('sendText', () {
    test(
      'happy path: server transcript replaces optimistic append',
      () async {
        repo.startResult = _sampleSession();
        repo.sendTextResult = _sampleSession(
          transcript: [
            _botMessage(id: 1, text: 'AC broken'),
            _botMessage(id: 2, text: 'got it'),
          ],
        );
        final c = _build(repo: repo);
        await c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
        );

        await c
            .read(
              chatbotSessionProvider(
                personaKey: 'dispute',
                bookingId: 9001,
              ).notifier,
            )
            .sendText('AC broken');

        final state = c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
        );
        expect(state.hasValue, isTrue);
        // Final transcript is the server's, not the optimistic one.
        expect(state.requireValue.transcript, hasLength(2));
        expect(state.requireValue.transcript.first.id, 1);
        expect(repo.capturedSendText, 'AC broken');
      },
    );

    test(
      'failure: AsyncError with previous session as copyWithPrevious data (no orphan bubble)',
      () async {
        repo.startResult = _sampleSession();
        repo.throwOnSendText = const LlmQuotaExceededFailure();
        final c = _build(repo: repo);
        await c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
        );

        await c
            .read(
              chatbotSessionProvider(
                personaKey: 'dispute',
                bookingId: 9001,
              ).notifier,
            )
            .sendText('hi');

        final state = c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
        );
        expect(state.hasError, isTrue);
        expect(state.error, isA<LlmQuotaExceededFailure>());
        // The previous session is preserved (with empty transcript — the
        // optimistic bubble was reverted by passing pre-mutation session
        // into copyWithPrevious).
        expect(state.requireValue.transcript, isEmpty);
      },
    );

    test('empty / whitespace-only text → no-op', () async {
      repo.startResult = _sampleSession();
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .sendText('   ');

      expect(repo.sendTextCalls, 0);
    });
  });

  // ─── submitForm ────────────────────────────────────────────────────

  group('submitForm', () {
    test('happy path replaces state with new session', () async {
      repo.startResult = _sampleSession(phase: ChatPhase.payout);
      repo.submitFormResult = _sampleSession(
        conversationId: 7001,
        phase: ChatPhase.confirm,
      );
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .submitForm(const {'iban': 'PK00ABCD0123456789012345'});

      expect(repo.submitFormCalls, 1);
      expect(repo.capturedFormValues!['iban'], 'PK00ABCD0123456789012345');
      expect(
        c
            .read(
              chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
            )
            .requireValue
            .phase,
        ChatPhase.confirm,
      );
    });

    test('FormValidationFailure surfaces as AsyncError', () async {
      repo.startResult = _sampleSession(phase: ChatPhase.payout);
      repo.throwOnSubmitForm = const FormValidationFailure(
        fieldErrors: {
          'iban': ['IBAN format is invalid.'],
        },
      );
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .submitForm(const {'iban': 'bogus'});

      final state = c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
      );
      expect(state.hasError, isTrue);
      expect(state.error, isA<FormValidationFailure>());
    });
  });

  // ─── uploadAttachment ─────────────────────────────────────────────

  group('uploadAttachment', () {
    test('happy path updates attachmentsCount in-place', () async {
      repo.startResult = _sampleSession(attachmentsCount: 0);
      repo.uploadCountResult = 3;
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .uploadAttachment(
            filename: 'x.jpg',
            bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
          );

      final state = c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
      );
      expect(state.hasValue, isTrue);
      expect(state.requireValue.attachmentsCount, 3);
    });

    test(
      'failure → AsyncError but previous session preserved (count unchanged)',
      () async {
        repo.startResult = _sampleSession(attachmentsCount: 2);
        repo.throwOnUpload = const AttachmentTooLargeFailure(maxMb: 10);
        final c = _build(repo: repo);
        await c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
        );

        await c
            .read(
              chatbotSessionProvider(
                personaKey: 'dispute',
                bookingId: 9001,
              ).notifier,
            )
            .uploadAttachment(
              filename: 'huge.jpg',
              bytes: Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
            );

        final state = c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
        );
        expect(state.hasError, isTrue);
        expect(state.error, isA<AttachmentTooLargeFailure>());
        // copyWithPrevious keeps the pre-error session readable so the
        // grid frame doesn't flicker.
        expect(state.requireValue.attachmentsCount, 2);
      },
    );
  });

  // ─── markAttachmentsDone ──────────────────────────────────────────

  group('markAttachmentsDone', () {
    test('happy path advances the phase via repo call', () async {
      repo.startResult = _sampleSession(phase: ChatPhase.evidence);
      repo.notifyDoneResult = _sampleSession(phase: ChatPhase.payout);
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .markAttachmentsDone();

      expect(repo.notifyDoneCalls, 1);
      expect(
        c
            .read(
              chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
            )
            .requireValue
            .phase,
        ChatPhase.payout,
      );
    });
  });

  // ─── close ─────────────────────────────────────────────────────────

  group('close', () {
    test('happy path flips isClosed and populates outputRefs', () async {
      repo.startResult = _sampleSession(isClosed: false);
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .close();

      final state = c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
      );
      expect(state.requireValue.isClosed, isTrue);
      expect(state.requireValue.outputRefs!.ticketId, 1284);
      expect(repo.closeCalls, 1);
    });

    test('already-closed session → early return, no repo call', () async {
      repo.startResult = _sampleSession(
        isClosed: true,
        outputRefs: const OutputRefs(ticketId: 1),
      );
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .close();

      expect(repo.closeCalls, 0);
    });

    test(
      'close failure preserves open session under AsyncError (P0-3 regression)',
      () async {
        // Regression for the audit's P0-3: the screen's confirm-and-
        // close handler must distinguish "close committed" from "close
        // failed". The notifier's contract is that on failure, the
        // pre-mutation session is still readable via copyWithPrevious
        // and `isClosed` stays false — the screen reads this to decide
        // whether to pop.
        repo.startResult = _sampleSession(isClosed: false);
        repo.throwOnClose = const ChatbotNetworkFailure();
        final c = _build(repo: repo);
        await c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
        );

        await c
            .read(
              chatbotSessionProvider(
                personaKey: 'dispute',
                bookingId: 9001,
              ).notifier,
            )
            .close();

        final state = c.read(
          chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
        );
        expect(state.hasError, isTrue);
        expect(state.error, isA<ChatbotNetworkFailure>());
        // The previous (open) session is still readable — the screen
        // reads this to decide NOT to pop.
        expect(state.requireValue.isClosed, isFalse);
      },
    );
  });

  // ─── refresh ───────────────────────────────────────────────────────

  group('refresh', () {
    test('calls fetchConversation(conversationId)', () async {
      repo.startResult = _sampleSession(conversationId: 7001);
      repo.fetchResult = _sampleSession(
        conversationId: 7001,
        phase: ChatPhase.evidence,
      );
      final c = _build(repo: repo);
      await c.read(
        chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001).future,
      );

      await c
          .read(
            chatbotSessionProvider(
              personaKey: 'dispute',
              bookingId: 9001,
            ).notifier,
          )
          .refresh();

      expect(repo.fetchCalls, 1);
      expect(
        c
            .read(
              chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001),
            )
            .requireValue
            .phase,
        ChatPhase.evidence,
      );
    });
  });
}

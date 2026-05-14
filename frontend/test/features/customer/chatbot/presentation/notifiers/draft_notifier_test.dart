// State-layer tests for DraftNotifier.
//
// Pattern:
//   * Hand-written `_FakeRepo` records every saveDraftText call with
//     the (conversationId, text) pair so we can assert what hit the
//     repo and what didn't.
//   * Real `Future.delayed` for the 500 ms debounce. (We tried
//     `fake_async` here first; the Timer callback's `async` body
//     didn't have its microtasks drained reliably by `elapse()`, and
//     the per-test wait cost is <1 s total so the determinism trade
//     is worth it.)
//
// Coverage:
//   * build() reads existing draft from repo and seeds state.
//   * setText(persistDraft: true) writes after the debounce window.
//   * setText(persistDraft: false) NEVER writes (PII discipline — PAYOUT).
//   * Two setText calls within the debounce window → single coalesced
//     write with the final value.
//   * Empty text → repo receives `null` (clear contract).
//   * clear() cancels pending debounce + writes `null` synchronously.
//   * Disposing mid-debounce cancels the pending Timer (no late writes).
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/repositories/chatbot_repository.dart';
import 'package:frontend/features/customer/chatbot/presentation/notifiers/draft_notifier.dart';
import 'package:frontend/features/customer/chatbot/presentation/providers/dependency_injection.dart';

// ─── Test fake ──────────────────────────────────────────────────────────

class _FakeRepo implements IChatbotRepository {
  /// Captured save calls: list of `(conversationId, text)` pairs.
  final List<({int conversationId, String? text})> saves = [];

  /// Pre-seeded draft to return from `loadDraftText`.
  String? loadedDraft;

  @override
  Future<void> saveDraftText({
    required int conversationId,
    required String? text,
  }) async {
    saves.add((conversationId: conversationId, text: text));
  }

  @override
  Future<String?> loadDraftText(int conversationId) async => loadedDraft;

  // ─── Unused remote methods (throw if accidentally invoked) ───
  @override
  Future<ChatSession> startConversation({
    required String personaKey,
    required Map<String, dynamic> context,
  }) => throw UnimplementedError();

  @override
  Future<ChatSession> fetchConversation(int conversationId) =>
      throw UnimplementedError();

  @override
  Future<ChatSession> sendTextTurn({
    required int conversationId,
    required int bookingId,
    required String text,
  }) => throw UnimplementedError();

  @override
  Future<ChatSession> submitFormTurn({
    required int conversationId,
    required int bookingId,
    required Map<String, dynamic> values,
  }) => throw UnimplementedError();

  @override
  Future<int> uploadAttachment({
    required int conversationId,
    required String filename,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<ChatSession> notifyAttachmentsDone({
    required int conversationId,
    required int bookingId,
  }) => throw UnimplementedError();

  @override
  Future<ChatSession> closeConversation({
    required int conversationId,
    required int bookingId,
  }) => throw UnimplementedError();

  @override
  Future<void> setActiveConversationId({
    required int bookingId,
    required int? conversationId,
  }) async {}

  @override
  Future<int?> getActiveConversationId(int bookingId) async => null;
}

ProviderContainer _build({required _FakeRepo repo}) {
  final container = ProviderContainer(
    overrides: [chatbotRepositoryProvider.overrideWithValue(repo)],
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
    test(
      'reads stored draft from repo and seeds state with that string',
      () async {
        repo.loadedDraft = 'half-written sentence';
        final c = _build(repo: repo);

        final value = await c.read(draftProvider(42).future);

        expect(value, 'half-written sentence');
      },
    );

    test('seeds empty string when no draft is stored', () async {
      repo.loadedDraft = null;
      final c = _build(repo: repo);
      final value = await c.read(draftProvider(42).future);
      expect(value, '');
    });
  });

  // ─── setText + debounce ───────────────────────────────────────────

  group('setText (debounced persistence)', () {
    // The debounce is 500 ms; we wait 700 ms to be safely past it.
    const wait = Duration(milliseconds: 700);

    // `draftProvider` is auto-dispose (`@riverpod` default). A `read()`
    // alone won't keep it alive across awaits, which means the Timer
    // scheduled in setText would be cancelled by `ref.onDispose` before
    // it ever fires. Holding a `listen()` subscription pins the
    // provider for the duration of the test.
    void pin(ProviderContainer c) =>
        c.listen(draftProvider(42), (_, _) {}, fireImmediately: true);

    test(
      'persistDraft=true: write fires after 500ms, contains final text',
      () async {
        final c = _build(repo: repo);
        pin(c);
        await c.read(draftProvider(42).future);

        c
            .read(draftProvider(42).notifier)
            .setText('hello', persistDraft: true);

        // Mid-window: nothing has hit the repo yet.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(repo.saves, isEmpty);

        // After the debounce.
        await Future<void>.delayed(wait);
        expect(repo.saves, hasLength(1));
        expect(repo.saves.single.text, 'hello');
        expect(repo.saves.single.conversationId, 42);
      },
    );

    test(
      'persistDraft=false: state still updates but repo never receives a save',
      () async {
        final c = _build(repo: repo);
        pin(c);
        await c.read(draftProvider(42).future);

        c
            .read(draftProvider(42).notifier)
            .setText('PK00ABCD0123456789012345', persistDraft: false);

        // In-memory value updates.
        expect(
          c.read(draftProvider(42)).requireValue,
          'PK00ABCD0123456789012345',
        );

        // But nothing reaches the repo even after the debounce window.
        await Future<void>.delayed(wait);
        expect(repo.saves, isEmpty);
      },
    );

    test(
      'two writes within window coalesce to one (last value wins)',
      () async {
        final c = _build(repo: repo);
        pin(c);
        await c.read(draftProvider(42).future);

        c.read(draftProvider(42).notifier).setText('a', persistDraft: true);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        c.read(draftProvider(42).notifier).setText('ab', persistDraft: true);

        await Future<void>.delayed(wait);
        expect(repo.saves, hasLength(1));
        expect(repo.saves.single.text, 'ab');
      },
    );

    test('empty text writes null (clears the persisted draft)', () async {
      final c = _build(repo: repo);
      pin(c);
      await c.read(draftProvider(42).future);

      c.read(draftProvider(42).notifier).setText('', persistDraft: true);
      await Future<void>.delayed(wait);

      expect(repo.saves, hasLength(1));
      expect(repo.saves.single.text, isNull);
    });
  });

  // ─── clear() ───────────────────────────────────────────────────────

  group('clear()', () {
    test(
      'cancels pending debounce, writes null synchronously, resets state',
      () async {
        repo.loadedDraft = 'in-progress';
        final c = _build(repo: repo);
        await c.read(draftProvider(42).future);

        // Stage a pending debounce.
        c
            .read(draftProvider(42).notifier)
            .setText('more typing', persistDraft: true);

        // Clear before the debounce fires.
        await c.read(draftProvider(42).notifier).clear();

        // Only the clear() write hit the repo.
        expect(repo.saves, hasLength(1));
        expect(repo.saves.single.text, isNull);
        expect(c.read(draftProvider(42)).requireValue, '');
      },
    );
  });

  // ─── disposal ─────────────────────────────────────────────────────

  group('disposal', () {
    test(
      'disposing mid-debounce cancels the pending Timer (no late write)',
      () async {
        final c = _build(repo: repo);
        await c.read(draftProvider(42).future);

        c
            .read(draftProvider(42).notifier)
            .setText('half-written', persistDraft: true);

        // Tear down the container before the debounce window elapses.
        c.dispose();

        // Even after a long wait, no write happened — the Timer was
        // cancelled by the `ref.onDispose` hook in `build()`.
        await Future<void>.delayed(const Duration(milliseconds: 700));
        expect(repo.saves, isEmpty);
      },
    );
  });
}

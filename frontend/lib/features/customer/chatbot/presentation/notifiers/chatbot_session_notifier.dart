// Session notifier for the chatbot screen.
//
// The chatbot screen mounts exactly one of these — keyed by the
// `(personaKey, bookingId)` family — and binds its build state to
// `AsyncValue<ChatSession>`. The notifier:
//
//   1. Hydrates the session on `build()` (recovery id → `fetch`,
//      else `start`).
//   2. Drives each turn through a single use case call; the
//      repository's POST + GET-detail flow returns the authoritative
//      next session and the notifier replaces state wholesale.
//   3. For free-text turns only, optimistically appends a local USER
//      bubble (negative sentinel id) so the user sees their own input
//      land before the server replies. On failure, the optimistic
//      bubble is reverted by restoring the pre-mutation session as
//      the `.copyWithPrevious` payload on the resulting `AsyncError`.
//
// **Riverpod discipline (CLAUDE.md §Frontend lines 78-84):**
//   - `state = await AsyncValue.guard(...)` for every mutation
//   - reads use `state.requireValue`, never `.value!`
//   - `@riverpod` code generation; default `keepAlive: false` (notifier
//     should dispose on screen pop — the repository above it is the
//     keepAlive layer)
//
// **Testing warm-up (CLAUDE.md):** any test that mutates state must
// first `await container.read(chatbotSessionNotifierProvider(
// personaKey: ..., bookingId: ...).future)` so the asynchronous
// `build()` settles before the assertion or mutation.
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_phase.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/failures/chatbot_failure.dart';
import '../providers/dependency_injection.dart';

part 'chatbot_session_notifier.g.dart';

@riverpod
class ChatbotSessionNotifier extends _$ChatbotSessionNotifier {
  /// Negative sentinel ids for optimistic local-only USER bubbles. The
  /// next server detail-fetch replaces the optimistic message with the
  /// authoritative server one (which has a positive id). Instance-
  /// scoped (was a module-level global before — that survived hot
  /// reloads + screen pops + test runs and broke isolation).
  int _optimisticIdCounter = -1;
  int _nextOptimisticId() => _optimisticIdCounter--;

  /// Build either rehydrates a previously-open session (Tier-3
  /// recovery, keyed per [bookingId] so a still-open dispute on a
  /// different booking never bleeds into this screen) or opens a new
  /// one. If the recovered id is stale — the server returns
  /// `conversation_not_found` because it was cleaned up or never
  /// existed — we clear the recovery key and fall through to `start`.
  @override
  Future<ChatSession> build({
    required String personaKey,
    required int bookingId,
  }) async {
    final repo = ref.watch(chatbotRepositoryProvider);
    final recoveredId = await repo.getActiveConversationId(bookingId);

    if (recoveredId != null) {
      try {
        return await ref.read(fetchConversationUseCaseProvider).call(
          recoveredId,
        );
      } on ConversationNotFoundFailure {
        // Stale id — clear and fall through to a fresh start.
        await repo.setActiveConversationId(
          bookingId: bookingId,
          conversationId: null,
        );
      }
    }

    return ref.read(startConversationUseCaseProvider).call(
      personaKey: personaKey,
      context: {'booking_id': bookingId},
    );
  }

  /// Pull-to-refresh / cold-boot retry. Re-fetches the conversation
  /// detail by id. No-op if state has no value yet.
  Future<void> refresh() async {
    if (!state.hasValue) return;
    final current = state.requireValue;
    // ignore: invalid_use_of_internal_member
    state = const AsyncLoading<ChatSession>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () =>
          ref.read(fetchConversationUseCaseProvider).call(current.conversationId),
    );
  }

  /// Free-text turn. Optimistically appends the user's bubble to the
  /// transcript before the round-trip; on failure the optimistic
  /// bubble is reverted and the error surfaces with the previous
  /// session as `copyWithPrevious` data.
  Future<void> sendText(String text) async {
    if (text.trim().isEmpty) return;
    if (!state.hasValue) return;
    final previous = state.requireValue;

    final optimistic = ChatMessage(
      id: _nextOptimisticId(),
      role: ChatRole.user,
      text: text,
      createdAt: DateTime.now().toUtc(),
      phase: previous.phase,
    );
    state = AsyncData(
      previous.copyWith(transcript: [...previous.transcript, optimistic]),
    );

    final next = await AsyncValue.guard(
      () => ref.read(sendTextTurnUseCaseProvider).call(
        conversationId: previous.conversationId,
        bookingId: bookingId,
        text: text,
      ),
    );
    state = next.hasError
        // Revert: surface the error but render against the
        // pre-optimistic transcript (so the orphan USER bubble
        // disappears alongside the error toast).
        ? AsyncError<ChatSession>(
            next.error!,
            next.stackTrace ?? StackTrace.current,
            // ignore: invalid_use_of_internal_member
          ).copyWithPrevious(AsyncData(previous))
        : next;
  }

  /// Submit the PAYOUT form (or any future dynamic-form phase).
  /// No optimistic bubble — the server-generated SYSTEM acknowledgement
  /// is what tells the user the submission succeeded.
  Future<void> submitForm(Map<String, dynamic> values) async {
    if (!state.hasValue) return;
    final previous = state.requireValue;
    state = await AsyncValue.guard(
      () => ref.read(submitFormTurnUseCaseProvider).call(
        conversationId: previous.conversationId,
        bookingId: bookingId,
        values: values,
      ),
    );
  }

  /// Advance past EVIDENCE phase. The persona handles the
  /// zero-attachment case — no client-side gating.
  Future<void> markAttachmentsDone() async {
    if (!state.hasValue) return;
    final previous = state.requireValue;
    state = await AsyncValue.guard(
      () => ref.read(notifyAttachmentsDoneUseCaseProvider).call(
        conversationId: previous.conversationId,
        bookingId: bookingId,
      ),
    );
  }

  /// Upload one image. Does NOT replace the whole session in state —
  /// we update `attachmentsCount` in-place so the composer's per-tile
  /// spinner UX (via [AttachmentUploadNotifier]) keeps its frame and
  /// the transcript doesn't flash through `AsyncLoading`. The
  /// authoritative count comes from the server's response.
  ///
  /// Throws nothing — failures are surfaced into `state` as the
  /// `error` payload of an [AsyncError] with `.copyWithPrevious` so
  /// the screen's `ref.listen` can switch on the [ChatbotFailure]
  /// subtype.
  Future<void> uploadAttachment({
    required String filename,
    required Uint8List bytes,
  }) async {
    if (!state.hasValue) return;
    final previous = state.requireValue;
    final result = await AsyncValue.guard(
      () => ref.read(uploadAttachmentUseCaseProvider).call(
        conversationId: previous.conversationId,
        filename: filename,
        bytes: bytes,
      ),
    );
    state = result.when(
      data: (newCount) =>
          AsyncData(previous.copyWith(attachmentsCount: newCount)),
      // On error, keep the previous session visible — the composer
      // reads `attachmentsCount` from the previous frame so the grid
      // stays consistent.
      error: (e, st) => AsyncError<ChatSession>(
        e,
        st,
        // ignore: invalid_use_of_internal_member
      ).copyWithPrevious(AsyncData(previous)),
      loading: () => state,
    );
  }

  /// Escape hatch / terminal close. Idempotent — calling on an
  /// already-closed conversation returns the existing terminal
  /// session (with `outputRefs` populated).
  Future<void> close() async {
    if (!state.hasValue) return;
    final previous = state.requireValue;
    if (previous.isClosed) return;
    state = await AsyncValue.guard(
      () => ref.read(closeConversationUseCaseProvider).call(
        conversationId: previous.conversationId,
        bookingId: bookingId,
      ),
    );
  }

  /// Convenience for the screen's `ref.listen` so it can read the
  /// current phase without unpacking the `AsyncValue`. Returns
  /// `ChatPhase.unknown` if the session hasn't loaded yet.
  ChatPhase get currentPhase =>
      state.hasValue ? state.requireValue.phase : ChatPhase.unknown;
}

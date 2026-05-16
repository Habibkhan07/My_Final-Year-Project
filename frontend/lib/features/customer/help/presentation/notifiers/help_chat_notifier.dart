// Help-tab chatbot notifier.
//
// Drives the customer Help tab. On `build()`, opens a fresh `general`
// persona conversation. Each `sendText` optimistically appends the
// user's bubble, POSTs the turn, and appends the bot's reply.
//
// **Why no recovery / no detail-GET.** The dispute notifier (1) caches
// `active_conversation_id` per booking for cold-boot recovery and (2)
// follows every turn POST with a detail GET to keep its transcript in
// sync with server ordering. Neither matters here: help conversations
// are ephemeral (fresh greeting on every tab open is fine UX), and the
// transcript only ever appends locally so we already know the order.
// Skipping the detail GET cuts the turn round-trip in half.
//
// **Riverpod discipline (CLAUDE.md §Frontend lines 78-84):**
//   - `state = await AsyncValue.guard(...)` for mutations
//   - reads use `state.requireValue`, never `.value!`
//   - `@riverpod` code generation
//   - `keepAlive: false` — disposes when the Help tab unmounts so a
//     re-open starts fresh with a new greeting
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../chatbot/domain/entities/chat_message.dart';
import '../../../chatbot/domain/entities/chat_phase.dart';
import '../../../chatbot/presentation/providers/dependency_injection.dart';
import 'help_chat_state.dart';

part 'help_chat_notifier.g.dart';

@riverpod
class HelpChatNotifier extends _$HelpChatNotifier {
  /// Negative sentinel ids for client-only bubbles (optimistic USER +
  /// locally-appended BOT). The server's persisted ids are positive
  /// integers; we never collide. Instance-scoped so a hot-reload or
  /// re-open doesn't share counter state across notifier instances.
  int _localIdCounter = -1;
  int _nextLocalId() => _localIdCounter--;

  @override
  Future<HelpChatState> build() async {
    final remote = ref.watch(chatbotRemoteDataSourceProvider);
    final response = await remote.startConversation(
      personaKey: 'general',
      context: const <String, dynamic>{},
    );

    // The opening greeting is in `bot_message` of the start response —
    // backend writes it as the conversation's first BOT row. We seed
    // the transcript with it so the user opens to a greeting instead
    // of an empty screen.
    final opening = ChatMessage(
      id: _nextLocalId(),
      role: ChatRole.bot,
      text: response.botMessage,
      createdAt: DateTime.now().toUtc(),
      // 'CHAT' is a help-persona phase the FE enum doesn't model;
      // ChatPhase.unknown is the documented fold-to default and is
      // harmless here (no widget branches on phase for help).
      phase: ChatPhase.unknown,
    );

    return HelpChatState(
      conversationId: response.conversationId,
      transcript: [opening],
    );
  }

  /// Send one free-text turn. No-op on empty / whitespace input.
  ///
  /// Optimistic flow: append the user's bubble immediately, mark
  /// isSending, then await the POST and append the bot's reply. On
  /// failure, revert the optimistic bubble and surface the error as
  /// `AsyncError` with the previous state as `copyWithPrevious` payload
  /// so the screen can show a snackbar without flashing through an
  /// empty transcript.
  Future<void> sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!state.hasValue) return;

    final previous = state.requireValue;
    if (previous.isSending) return; // prevent rapid double-tap

    final userBubble = ChatMessage(
      id: _nextLocalId(),
      role: ChatRole.user,
      text: trimmed,
      createdAt: DateTime.now().toUtc(),
      phase: ChatPhase.unknown,
    );

    // Optimistic: bubble in, lock send.
    state = AsyncData(
      previous.copyWith(
        transcript: [...previous.transcript, userBubble],
        isSending: true,
      ),
    );

    final remote = ref.read(chatbotRemoteDataSourceProvider);
    final next = await AsyncValue.guard<HelpChatState>(() async {
      final turn = await remote.sendTextMessage(
        conversationId: previous.conversationId,
        text: trimmed,
      );
      final botBubble = ChatMessage(
        id: _nextLocalId(),
        role: ChatRole.bot,
        text: turn.botMessage,
        createdAt: DateTime.now().toUtc(),
        phase: ChatPhase.unknown,
      );
      return state.requireValue.copyWith(
        transcript: [...state.requireValue.transcript, botBubble],
        isSending: false,
      );
    });

    state = next.hasError
        // Revert: surface error but render against the pre-optimistic
        // transcript so the orphan user bubble disappears with the
        // error toast (otherwise the user sees their question hanging
        // unanswered after a 5xx).
        ? AsyncError<HelpChatState>(
            next.error!,
            next.stackTrace ?? StackTrace.current,
            // ignore: invalid_use_of_internal_member
          ).copyWithPrevious(AsyncData(previous))
        : next;
  }

  /// Reset the help chat: close the current backend conversation and
  /// start a fresh one.
  ///
  /// Idempotent on the close (the backend's ``/close/`` endpoint is
  /// idempotent — second call returns the same closed_at). Best-effort
  /// on errors: if the close fails the user's intent to clear wins
  /// — we still invalidate the provider so a fresh conversation
  /// starts. The orphaned old conversation row remains in the DB for
  /// admin audit and will be swept by the planned auto-close task
  /// (see flag.md).
  ///
  /// During an in-flight send (``isSending=true``), this is a no-op:
  /// the screen disables the Clear button while sending, but we guard
  /// here too so a programmatic call can't race a turn.
  Future<void> clearAndRestart() async {
    if (!state.hasValue) return;
    final current = state.requireValue;
    if (current.isSending) return;

    // Mark loading immediately so the screen flashes the spinner
    // instead of leaving the old transcript visible while the close
    // round-trip happens. The ``ref.invalidateSelf`` below would do
    // this on its own, but only AFTER the close future resolves.
    state = const AsyncLoading<HelpChatState>();

    final remote = ref.read(chatbotRemoteDataSourceProvider);
    try {
      await remote.closeConversation(current.conversationId);
    } catch (_) {
      // Swallow — see docstring. The fresh conversation matters more
      // than the audit cleanup of the old one.
    }
    // Re-runs build() → fresh start_conversation → new greeting.
    ref.invalidateSelf();
  }
}

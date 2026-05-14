// Debounced free-text draft writer.
//
// Per-conversation family. The text composer calls [setText] on every
// keystroke; this notifier debounces the writes by 500 ms before
// hitting the repository's `saveDraftText` (which lands in
// SharedPreferences). On a successful turn-send the session notifier
// (or composer) calls [clear] to drop the persisted draft.
//
// **PII discipline:** the composer for the PAYOUT phase passes
// `persistDraft: false` (read from `FormDirective.persistDraft`). When
// that flag is false [setText] is a no-op — IBAN, account title and
// bank name never reach SharedPreferences. See CLAUDE.md §`Local
// Storage & Caching`.
//
// **State shape:** the notifier holds `AsyncValue<String>` — the
// initial `build` returns whatever string was already persisted
// (empty if none) so the composer can prefill its TextField.
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/dependency_injection.dart';

part 'draft_notifier.g.dart';

/// Debounce window for SharedPreferences writes. Long enough to skip
/// per-keystroke writes during normal typing, short enough to survive
/// a quick backgrounding.
const Duration _kDebounceWindow = Duration(milliseconds: 500);

@riverpod
class DraftNotifier extends _$DraftNotifier {
  Timer? _debounce;

  @override
  Future<String> build(int conversationId) async {
    // Cancel the debounce timer when the notifier is disposed so a
    // stale write doesn't fire after the screen pops.
    ref.onDispose(() => _debounce?.cancel());
    final stored = await ref
        .read(chatbotRepositoryProvider)
        .loadDraftText(conversationId);
    return stored ?? '';
  }

  /// Update the in-memory draft and schedule a debounced persistence.
  /// When [persistDraft] is `false` the in-memory value still updates
  /// (so the composer's controller stays consistent with notifier
  /// state) but no SharedPreferences write is queued.
  void setText(String text, {required bool persistDraft}) {
    state = AsyncData(text);
    if (!persistDraft) return;
    _debounce?.cancel();
    _debounce = Timer(_kDebounceWindow, () async {
      await ref.read(chatbotRepositoryProvider).saveDraftText(
        conversationId: conversationId,
        text: text.isEmpty ? null : text,
      );
    });
  }

  /// Drop the draft synchronously (cancel any pending debounced
  /// write, then persist `null`). Called by the composer after a
  /// successful `sendText` so a transcript replay doesn't show the
  /// already-submitted text still in the box.
  Future<void> clear() async {
    _debounce?.cancel();
    state = const AsyncData('');
    await ref.read(chatbotRepositoryProvider).saveDraftText(
      conversationId: conversationId,
      text: null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ui_directive.dart';
import '../notifiers/chatbot_session_notifier.dart';
import '../notifiers/draft_notifier.dart';
import '../utils/chatbot_palette.dart';

/// Free-text composer for [TextDirective] phases (UNDERSTAND is the
/// only one in dispute v1).
///
/// Owns a [TextEditingController]. On first build, prefills the field
/// from [DraftNotifier] (Tier-2 SharedPreferences cache) so a user who
/// backgrounded the app mid-typing returns to their half-written
/// sentence. Every keystroke calls `draftNotifier.setText` which
/// debounces the write 500ms — see `DraftNotifier`.
///
/// **Send button enabled** iff:
///   * text is non-empty after `trim()`, AND
///   * no send is currently in flight (local `_sending` flag).
///
/// On send: calls `sessionNotifier.sendText(text)` — the notifier's
/// optimistic-append pattern places the user's bubble in the
/// transcript immediately. After the call returns we clear the
/// controller + persisted draft regardless of success/failure (the
/// error toast and bubble revert are the session notifier's job).
///
/// **Why `bookingId` + `personaKey` instead of a [ChatSession]:** the
/// session-notifier family is keyed by `(personaKey, bookingId)` and
/// the [ChatSession] entity does not carry the booking id (it's part
/// of the persona's opaque entry context). The screen owns those
/// values via route params and passes them down here.
class TextComposer extends ConsumerStatefulWidget {
  final String personaKey;
  final int bookingId;
  final int conversationId;
  final TextDirective directive;

  const TextComposer({
    super.key,
    required this.personaKey,
    required this.bookingId,
    required this.conversationId,
    required this.directive,
  });

  @override
  ConsumerState<TextComposer> createState() => _TextComposerState();
}

class _TextComposerState extends ConsumerState<TextComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _prefilled = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// One-shot prefill from the draft notifier. Guarded by [_prefilled]
  /// so a later draft state change (e.g. after `clear`) doesn't
  /// re-overwrite the in-flight controller value.
  void _maybePrefill(String draft) {
    if (_prefilled) return;
    _prefilled = true;
    if (draft.isNotEmpty && _controller.text.isEmpty) {
      _controller.text = draft;
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);

    final sessionFamily = chatbotSessionProvider(
      personaKey: widget.personaKey,
      bookingId: widget.bookingId,
    );
    await ref.read(sessionFamily.notifier).sendText(text);

    if (!mounted) return;
    // Only clear on success. On failure (e.g. ChatbotNetworkFailure)
    // keep the user's typed text so they don't have to retype after
    // the toast — the optimistic bubble already reverted via
    // copyWithPrevious in the notifier.
    final after = ref.read(sessionFamily);
    if (!after.hasError) {
      _controller.clear();
      await ref
          .read(draftProvider(widget.conversationId).notifier)
          .clear();
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(
      draftProvider(widget.conversationId),
    );
    draftAsync.whenData(_maybePrefill);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: ChatbotPalette.composerSurface,
          boxShadow: ChatbotPalette.composerSoftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                enabled: !_sending,
                onChanged: (text) {
                  ref
                      .read(
                        draftProvider(widget.conversationId).notifier,
                      )
                      .setText(text, persistDraft: true);
                  // Re-render the send button enabled/disabled state.
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: widget.directive.hint.isNotEmpty
                      ? widget.directive.hint
                      : 'Type a message',
                  filled: true,
                  fillColor: ChatbotPalette.brandPrimaryTint06,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(
              enabled: _controller.text.trim().isNotEmpty && !_sending,
              loading: _sending,
              onTap: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? ChatbotPalette.brandPrimary
        : ChatbotPalette.brandPrimary.withValues(alpha: 0.4);
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}

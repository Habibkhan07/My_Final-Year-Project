// Customer Help tab — free-form AI chatbot powered by the backend
// `general` persona of the chatbot framework.
//
// Visual contract:
//   - App-bar style header (no back arrow — this is a bottom-nav tab,
//     not a pushed route).
//   - Scrollable transcript using the existing [ChatBubble] widget so
//     visual identity matches the dispute chat.
//   - Single text input + send button pinned to the bottom, KeyboardSafeArea
//     handled by the Scaffold's `resizeToAvoidBottomInset` default.
//
// Loading / error contract:
//   - Initial `AsyncLoading` → centred spinner (network start can take
//     a beat on cold open).
//   - `AsyncError` on initial build → centred retry card.
//   - `AsyncError` after a send → snackbar + transcript stays on the
//     previous (pre-optimistic) state via `copyWithPrevious` in the
//     notifier. The composer re-enables and the user can retry.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/common/errors/http_failure.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../chatbot/presentation/widgets/chat_bubble.dart';
import '../notifiers/help_chat_notifier.dart';
import '../notifiers/help_chat_state.dart';
import '../widgets/help_quota_exceeded_modal.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();
  // Guard against duplicate quota modals if the user retries while
  // the modal is already showing. Matches the pattern in
  // `chatbot_screen.dart::_modalLock`.
  bool _quotaModalLock = false;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoScrollToBottom() {
    // Defer to next frame so the new bubble's height is laid out
    // before we ask the scroll controller to jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(helpChatProvider);

    // Error-after-send surfaces as `AsyncError.copyWithPrevious(<data>)`:
    // we can keep rendering the previous transcript and react to the
    // specific failure code. Quota exhaustion gets a dedicated modal
    // (the user shouldn't be invited to retry — it'll fail again until
    // tomorrow); everything else gets a generic retry-able snackbar.
    ref.listen<AsyncValue<HelpChatState>>(helpChatProvider, (
      prev,
      next,
    ) {
      if (next is AsyncError && next.hasValue) {
        final err = next.error;
        if (err is HttpFailure && err.code == 'llm_quota_exceeded') {
          if (!_quotaModalLock) {
            _quotaModalLock = true;
            showHelpQuotaExceededModal(context)
                .whenComplete(() => _quotaModalLock = false);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Couldn't send your message. Please try again.",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      // New bubbles? scroll to bottom.
      if (next.hasValue &&
          (prev?.value?.transcript.length ?? 0) <
              next.value!.transcript.length) {
        _autoScrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: stateAsync.when(
                data: (state) => _Transcript(
                  scrollController: _scrollController,
                  state: state,
                ),
                error: (err, _) {
                  // If we already had data, surface the previous
                  // transcript (post-send failure path). The listener
                  // above raised the toast.
                  final prev = stateAsync.value;
                  if (prev != null) {
                    return _Transcript(
                      scrollController: _scrollController,
                      state: prev,
                    );
                  }
                  return _InitialErrorCard(
                    onRetry: () =>
                        ref.invalidate(helpChatProvider),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF0051AE),
                  ),
                ),
              ),
            ),
            _Composer(
              controller: _composerController,
              isSending: stateAsync.value?.isSending ?? false,
              enabled: stateAsync.hasValue,
              onSend: (text) async {
                _composerController.clear();
                await ref
                    .read(helpChatProvider.notifier)
                    .sendText(text);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — simple title strip, no back arrow (tab, not pushed route).
// Right-side action: "Clear chat" — closes the current backend
// conversation and starts a fresh one. Disabled while no session is
// loaded yet (initial AsyncLoading) and while a send is in flight.
// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(helpChatProvider);
    final clearEnabled =
        stateAsync.hasValue && !(stateAsync.value?.isSending ?? false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0051AE).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              color: Color(0xFF0051AE),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF151C24),
                  ),
                ),
                Text(
                  'Karigar AI assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Clear chat',
            icon: Icon(
              Icons.delete_sweep_outlined,
              color: clearEnabled ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            onPressed: clearEnabled
                ? () => ref.read(helpChatProvider.notifier).clearAndRestart()
                : null,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transcript
// ---------------------------------------------------------------------------

class _Transcript extends StatelessWidget {
  final ScrollController scrollController;
  final HelpChatState state;

  const _Transcript({
    required this.scrollController,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: state.transcript.length + (state.isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.transcript.length) {
          // Pending-reply indicator while the LLM is generating.
          return const _PendingBotBubble();
        }
        return ChatBubble(message: state.transcript[index]);
      },
    );
  }
}

class _PendingBotBubble extends StatelessWidget {
  const _PendingBotBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: const SizedBox(
            width: 32,
            height: 12,
            child: _TypingDots(),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_ctrl.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (phase - 0.5).abs() * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Composer
// ---------------------------------------------------------------------------

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool enabled;
  final Future<void> Function(String) onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && !isSending;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: controller,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Ask a question…',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: canSend ? (text) => onSend(text) : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(
            enabled: canSend,
            onTap: () => onSend(controller.text),
          ),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF0051AE) : Colors.grey.shade300;
    return InkResponse(
      onTap: enabled ? onTap : null,
      radius: 28,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Initial-load error card
// ---------------------------------------------------------------------------

class _InitialErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _InitialErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "We couldn't start the Help chat.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0051AE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

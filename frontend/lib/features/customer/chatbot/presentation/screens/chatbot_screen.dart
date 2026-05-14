import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/chat_session.dart';
import '../../domain/failures/chatbot_failure.dart';
import '../notifiers/chatbot_session_notifier.dart';
import '../utils/chatbot_palette.dart';
import '../widgets/chat_transcript.dart';
import '../widgets/input_renderer.dart';
import '../widgets/quota_exceeded_modal.dart';

/// Full-screen chatbot for a single booking's dispute.
///
/// **Lifecycle:** mounts a `chatbotSessionProvider(personaKey, bookingId)`
/// family. The notifier (a) tries Tier-3 recovery — if a previously
/// open conversation exists for this user it's rehydrated — else (b)
/// opens a fresh one. On screen pop the notifier disposes
/// (`keepAlive: false`), but the recovery id stays on disk until the
/// conversation closes, so re-entering this screen rehydrates the
/// transcript via `fetchConversation`.
///
/// **Error dispatch:** `ref.listen` on the session provider switches
/// on the [ChatbotFailure] subtype:
///   * [LlmQuotaExceededFailure] → [showQuotaExceededModal]
///   * [NotEligibleToStartFailure] / [ConversationNotFoundFailure] /
///     [ConversationClosedFailure] / [PersonaNotFoundFailure] →
///     AlertDialog → pop
///   * [FormValidationFailure] → no-op here (the form composer paints
///     field errors inline in D3b)
///   * [ChatbotNetworkFailure] → top inline banner
///   * other → neutral SnackBar
///
/// The `_modalLock` flag prevents duplicate-stack of modals when the
/// same error fires twice (e.g. retry → second 429).
class ChatbotScreen extends ConsumerStatefulWidget {
  final String personaKey;
  final int bookingId;

  const ChatbotScreen({
    super.key,
    required this.personaKey,
    required this.bookingId,
  });

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  bool _modalLock = false;

  void _dispatchFailure(BuildContext context, ChatbotFailure failure) {
    if (_modalLock) return;
    switch (failure) {
      case LlmQuotaExceededFailure _:
        _modalLock = true;
        showQuotaExceededModal(context).whenComplete(() => _modalLock = false);
      case NotEligibleToStartFailure _:
        _modalLock = true;
        _showTerminalDialog(
          context,
          title: 'Cannot file a dispute',
          body: failure.message,
        ).whenComplete(() => _modalLock = false);
      case ConversationNotFoundFailure _:
        _modalLock = true;
        _showTerminalDialog(
          context,
          title: 'Session expired',
          body: 'This dispute conversation no longer exists. '
              "Please open a new one from the booking screen.",
        ).whenComplete(() => _modalLock = false);
      case ConversationClosedFailure _:
        // The session's terminal directive (if cached) will render
        // the closing card; nothing to do here.
        break;
      case PersonaNotFoundFailure _:
        _showSnack(context, failure.message);
      case FormValidationFailure _:
        // Form composer paints field errors inline (D3b).
        break;
      case AttachmentTooLargeFailure _:
      case AttachmentCountExceededFailure _:
        // Attachment composer surfaces these inline (D3b).
        _showSnack(context, failure.message);
      case ChatbotNetworkFailure _:
        // Rendered as an inline banner in the transcript area —
        // no modal/snack.
        break;
      case UnsupportedMessageKindFailure _:
        assert(false, 'unsupported_message_kind — client/server drift');
        _showSnack(context, 'Something went wrong. Try again.');
      case UnknownChatbotFailure _:
        _showSnack(context, 'Something went wrong. Try again.');
    }
  }

  Future<void> _showTerminalDialog(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (context.mounted) context.pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: ChatbotPalette.brandPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmAndClose(
    BuildContext context,
    ChatbotSessionNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Close conversation?'),
          content: const Text(
            'Your typed message will be discarded. The dispute will '
            'not be filed. You can start again later from the booking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep going'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Close',
                style: TextStyle(color: ChatbotPalette.brandPrimary),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await notifier.close();
    if (!context.mounted) return;
    // Only pop when the close actually committed. On failure
    // (network outage, server bug, etc.) the notifier surfaces an
    // AsyncError through `ref.listen` → `_dispatchFailure`, which
    // handles its own dialog/snack. Popping here regardless would
    // leave the server with an open conversation while the user
    // believes they closed it.
    final after = ref.read(
      chatbotSessionProvider(
        personaKey: widget.personaKey,
        bookingId: widget.bookingId,
      ),
    );
    if (after.hasValue && after.requireValue.isClosed) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = chatbotSessionProvider(
      personaKey: widget.personaKey,
      bookingId: widget.bookingId,
    );

    ref.listen(family, (prev, next) {
      final error = next.error;
      if (error is ChatbotFailure) {
        _dispatchFailure(context, error);
      }
    });

    final sessionAsync = ref.watch(family);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        foregroundColor: const Color(0xFF0A2540),
        title: const Text(
          'Dispute Chat',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          sessionAsync.maybeWhen(
            data: (session) {
              if (session.isClosed) return const SizedBox.shrink();
              return PopupMenuButton<_AppbarAction>(
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  if (action == _AppbarAction.close) {
                    _confirmAndClose(context, ref.read(family.notifier));
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _AppbarAction.close,
                    child: Text('Close conversation'),
                  ),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: sessionAsync.when(
        data: (session) => _ChatBody(
          personaKey: widget.personaKey,
          bookingId: widget.bookingId,
          session: session,
          showNetworkBanner: sessionAsync.error is ChatbotNetworkFailure,
          onRetryNetwork: () => ref.read(family.notifier).refresh(),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(ChatbotPalette.brandPrimary),
          ),
        ),
        error: (error, _) {
          // If we have previous data, render against it (the
          // .copyWithPrevious-wrapped errors from the notifier's
          // mutation paths preserve `data` here). Otherwise show a
          // bare error state with retry.
          if (sessionAsync.hasValue) {
            return _ChatBody(
              personaKey: widget.personaKey,
              bookingId: widget.bookingId,
              session: sessionAsync.requireValue,
              showNetworkBanner: error is ChatbotNetworkFailure,
              onRetryNetwork: () => ref.read(family.notifier).refresh(),
            );
          }
          return _ColdBootError(
            failure: error,
            onRetry: () => ref.invalidate(family),
          );
        },
      ),
    );
  }
}

enum _AppbarAction { close }

class _ChatBody extends StatelessWidget {
  final String personaKey;
  final int bookingId;
  final ChatSession session;
  final bool showNetworkBanner;
  final VoidCallback onRetryNetwork;

  const _ChatBody({
    required this.personaKey,
    required this.bookingId,
    required this.session,
    required this.showNetworkBanner,
    required this.onRetryNetwork,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showNetworkBanner)
          _NetworkBanner(onRetry: onRetryNetwork),
        Expanded(child: ChatTranscript(messages: session.transcript)),
        InputRenderer(
          personaKey: personaKey,
          bookingId: bookingId,
          session: session,
        ),
      ],
    );
  }
}

class _NetworkBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _NetworkBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChatbotPalette.networkBannerSurface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 18,
                color: ChatbotPalette.networkBannerInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You're offline. Reconnect and try again.",
                  style: TextStyle(
                    fontSize: 13,
                    color: ChatbotPalette.networkBannerInk,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: TextStyle(color: ChatbotPalette.networkBannerInk),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColdBootError extends StatelessWidget {
  final Object failure;
  final VoidCallback onRetry;

  const _ColdBootError({required this.failure, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNetwork = failure is ChatbotNetworkFailure;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: ChatbotPalette.systemInk,
            ),
            const SizedBox(height: 12),
            Text(
              isNetwork
                  ? "You're offline. Reconnect and try again."
                  : 'Something went wrong. Try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: ChatbotPalette.systemInk, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatbotPalette.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

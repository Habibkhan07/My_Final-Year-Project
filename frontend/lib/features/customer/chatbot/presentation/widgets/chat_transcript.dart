import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import 'chat_bubble.dart';

/// Scrollable transcript of [ChatBubble]s.
///
/// Auto-scrolls to the bottom whenever [messages]' length grows, with
/// one exception: when the user has scrolled more than
/// [_kSuppressAutoScrollThreshold]px above the bottom we infer they are
/// reading history and suppress the auto-scroll so we don't yank them
/// back down mid-read.
///
/// The widget is stateful only because it owns the [ScrollController]
/// — the messages themselves are owned by the session notifier above.
class ChatTranscript extends StatefulWidget {
  final List<ChatMessage> messages;

  const ChatTranscript({super.key, required this.messages});

  @override
  State<ChatTranscript> createState() => _ChatTranscriptState();
}

/// Distance (px) above the bottom beyond which the user is considered
/// to be reading history. Picked empirically to be ~1 bubble-height —
/// any closer and the auto-scroll feels disruptive on a slow read.
const double _kSuppressAutoScrollThreshold = 100;

class _ChatTranscriptState extends State<ChatTranscript> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant ChatTranscript oldWidget) {
    // **Sample the user's scroll position BEFORE the new bubble lays
    // out.** Measuring after layout conflates "user is reading
    // history" with "user just sent a tall bubble whose height alone
    // exceeds the threshold" — the latter would self-suppress the
    // scroll the user actually wants. The decision is whether the
    // user *was* near the bottom when the new message arrived.
    final wasNearBottom = _wasNearBottomBeforeUpdate();
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length && wasNearBottom) {
      _scheduleScrollToBottom();
    }
  }

  /// True iff the controller is attached AND the viewport's current
  /// position is within [_kSuppressAutoScrollThreshold] of the bottom.
  /// True when the controller hasn't attached yet (initial mount) so
  /// the first round of messages auto-scrolls.
  bool _wasNearBottomBeforeUpdate() {
    if (!_controller.hasClients) return true;
    final position = _controller.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    return distanceFromBottom <= _kSuppressAutoScrollThreshold;
  }

  /// Schedules an auto-scroll for the next frame so the new bubble's
  /// extent is included in `maxScrollExtent` when we animate.
  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return ChatBubble(key: ValueKey(message.id), message: message);
      },
    );
  }
}

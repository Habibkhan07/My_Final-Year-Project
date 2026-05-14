import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';
import '../utils/chatbot_palette.dart';

/// One transcript bubble. Three visual variants by [ChatRole]:
///
/// * [ChatRole.user] → right-aligned, brand-blue background, white
///   text, asymmetric radius (4px on bottom-right).
/// * [ChatRole.bot] → left-aligned, cool-grey background, ink text,
///   asymmetric radius (4px on bottom-left).
/// * [ChatRole.system] → centered italic muted text, no bubble (the
///   persona injects exactly one of these — the closing "Ticket
///   #N — we'll review within 3 working days" line).
///
/// [ChatRole.unknown] renders as a SYSTEM bubble so a stray wire role
/// never crashes the screen — it surfaces visibly enough to debug
/// without disrupting the read experience.
///
/// **Sizing.** Max width is 75% of the parent's incoming constraint;
/// the parent (typically a `ListView` inside a `Scaffold`) provides
/// the viewport width. Long single-line messages wrap; very long
/// pasted blocks scroll the parent normally.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return switch (message.role) {
      ChatRole.user => _UserBubble(text: message.text),
      ChatRole.bot => _BotBubble(text: message.text),
      ChatRole.system || ChatRole.unknown => _SystemLine(text: message.text),
    };
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return _BubbleShell(
      alignment: Alignment.centerRight,
      background: ChatbotPalette.userBubble,
      foreground: ChatbotPalette.userBubbleInk,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(18),
        bottomRight: Radius.circular(4),
      ),
      text: text,
    );
  }
}

class _BotBubble extends StatelessWidget {
  final String text;
  const _BotBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return _BubbleShell(
      alignment: Alignment.centerLeft,
      background: ChatbotPalette.botBubble,
      foreground: ChatbotPalette.botBubbleInk,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomLeft: Radius.circular(4),
        bottomRight: Radius.circular(18),
      ),
      text: text,
    );
  }
}

class _SystemLine extends StatelessWidget {
  final String text;
  const _SystemLine({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: ChatbotPalette.systemInk,
          fontSize: 13,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BubbleShell extends StatelessWidget {
  final Alignment alignment;
  final Color background;
  final Color foreground;
  final BorderRadius borderRadius;
  final String text;

  const _BubbleShell({
    required this.alignment,
    required this.background,
    required this.foreground,
    required this.borderRadius,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width * 0.75),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: background,
              borderRadius: borderRadius,
            ),
            child: Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

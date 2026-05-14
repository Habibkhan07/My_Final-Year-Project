import 'package:flutter/material.dart';

import '../../domain/entities/chat_session.dart';
import '../../domain/entities/ui_directive.dart';
import 'attachment_composer.dart';
import 'closing_card.dart';
import 'form_composer.dart';
import 'text_composer.dart';

/// Polymorphic dispatch for the chatbot composer area.
///
/// **Single source of composer-mounting logic.** Dart's exhaustiveness
/// check on the [UiDirective] sealed root guarantees every subclass is
/// handled at compile time — adding a new directive subclass causes a
/// compile error here until a matching case is wired.
///
/// All four directive subclasses are wired:
///   * [TextDirective]       → [TextComposer]       (UNDERSTAND phase)
///   * [FormDirective]       → [FormComposer]       (PAYOUT phase)
///   * [AttachmentDirective] → [AttachmentComposer] (EVIDENCE phase)
///   * [TerminalDirective]   → [ClosingCard]        (terminal state)
class InputRenderer extends StatelessWidget {
  final String personaKey;
  final int bookingId;
  final ChatSession session;

  const InputRenderer({
    super.key,
    required this.personaKey,
    required this.bookingId,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return switch (session.directive) {
      final TextDirective d => TextComposer(
        personaKey: personaKey,
        bookingId: bookingId,
        conversationId: session.conversationId,
        directive: d,
      ),
      final FormDirective d => FormComposer(
        personaKey: personaKey,
        bookingId: bookingId,
        session: session,
        directive: d,
      ),
      final AttachmentDirective d => AttachmentComposer(
        personaKey: personaKey,
        bookingId: bookingId,
        session: session,
        directive: d,
      ),
      final TerminalDirective d => ClosingCard(refs: d.refs),
    };
  }
}

// Widget tests for InputRenderer's sealed-switch dispatch.
//
// The renderer's contract is: for each subclass of `UiDirective`, mount
// exactly one composer. Dart's exhaustiveness check guarantees a new
// subclass can't be added without a compile error here — this test
// just verifies the runtime dispatch matches at the type level.
//
// For composers that need Riverpod (TextComposer / FormComposer /
// AttachmentComposer), we wrap in `ProviderScope` with a stub
// repository override so the providers can resolve.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/form_schema.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/output_refs.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';
import 'package:frontend/features/customer/chatbot/domain/repositories/chatbot_repository.dart';
import 'package:frontend/features/customer/chatbot/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/attachment_composer.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/closing_card.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/form_composer.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/input_renderer.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/text_composer.dart';

import '../../_helpers/stub_repo.dart';

ChatSession _session({UiDirective? directive, bool isClosed = false}) {
  return ChatSession(
    conversationId: 7001,
    personaKey: 'dispute',
    phase: ChatPhase.understand,
    transcript: const <ChatMessage>[],
    directive: directive ??
        const TextDirective(botMessage: 'hi', hint: 'type'),
    attachmentsCount: 0,
    isClosed: isClosed,
  );
}

Widget _wrap({
  required ChatSession session,
  required IChatbotRepository repo,
}) {
  return ProviderScope(
    overrides: [chatbotRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Scaffold(
        body: InputRenderer(
          personaKey: 'dispute',
          bookingId: 9001,
          session: session,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('TextDirective → mounts TextComposer', (tester) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(
      _wrap(
        session: _session(
          directive: const TextDirective(
            botMessage: '',
            hint: 'tell me',
          ),
        ),
        repo: repo,
      ),
    );
    await tester.pump();

    expect(find.byType(TextComposer), findsOneWidget);
    expect(find.byType(FormComposer), findsNothing);
    expect(find.byType(AttachmentComposer), findsNothing);
    expect(find.byType(ClosingCard), findsNothing);
  });

  testWidgets('FormDirective → mounts FormComposer', (tester) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(
      _wrap(
        session: _session(
          directive: FormDirective(
            schema: const FormSchema(
              fields: [
                FormFieldSpec(
                  name: 'iban',
                  label: 'IBAN',
                  kind: FormFieldKind.text,
                ),
              ],
            ),
            persistDraft: false,
            botMessage: '',
            hint: '',
          ),
        ),
        repo: repo,
      ),
    );
    await tester.pump();

    expect(find.byType(FormComposer), findsOneWidget);
    expect(find.byType(TextComposer), findsNothing);
  });

  testWidgets('AttachmentDirective → mounts AttachmentComposer', (
    tester,
  ) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(
      _wrap(
        session: _session(
          directive: const AttachmentDirective(
            currentCount: 0,
            maxAllowed: 10,
            botMessage: '',
            hint: '',
          ),
        ),
        repo: repo,
      ),
    );
    await tester.pump();

    expect(find.byType(AttachmentComposer), findsOneWidget);
    expect(find.byType(TextComposer), findsNothing);
  });

  testWidgets('TerminalDirective → mounts ClosingCard', (tester) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(
      _wrap(
        session: _session(
          isClosed: true,
          directive: const TerminalDirective(
            refs: OutputRefs(ticketId: 1284),
          ),
        ),
        repo: repo,
      ),
    );
    await tester.pump();

    expect(find.byType(ClosingCard), findsOneWidget);
    expect(find.byType(TextComposer), findsNothing);
    expect(find.text('Dispute filed'), findsOneWidget);
    expect(find.text('Ticket #1284'), findsOneWidget);
  });
}

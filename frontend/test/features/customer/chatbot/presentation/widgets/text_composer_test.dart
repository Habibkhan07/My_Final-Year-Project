// Widget tests for TextComposer.
//
// The composer talks to:
//   * `chatbotSessionProvider` — call its `sendText` on tap.
//   * `draftProvider` — prefill on mount, debounce on keystroke,
//     clear after a successful send.
//
// We override `chatbotRepositoryProvider` with a stub repo so the
// providers can build. The provider graph for `chatbotSessionProvider`
// requires hydration (its `build()` calls `getActiveConversationId` →
// `startConversation`). To avoid mounting the full session-notifier
// surface in a widget test we test the composer **directly against
// the visual + draft contract** and assert the controller / button
// state — the `sendText` invocation is covered by the session
// notifier's unit tests.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';
import 'package:frontend/features/customer/chatbot/presentation/providers/dependency_injection.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/text_composer.dart';

import '../../_helpers/stub_repo.dart';

Widget _wrap({
  required TextDirective directive,
  required StubChatbotRepo repo,
}) {
  return ProviderScope(
    overrides: [chatbotRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Scaffold(
        body: TextComposer(
          personaKey: 'dispute',
          bookingId: 9001,
          conversationId: 7001,
          directive: directive,
        ),
      ),
    ),
  );
}

const _directive = TextDirective(botMessage: '', hint: 'Tell me what happened');

void main() {
  testWidgets('renders hint from directive when field is empty', (
    tester,
  ) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(_wrap(directive: _directive, repo: repo));
    await tester.pumpAndSettle();

    expect(find.text('Tell me what happened'), findsOneWidget);
  });

  testWidgets('prefills field from persisted draft', (tester) async {
    final repo = StubChatbotRepo()..drafts[7001] = 'half-written sentence';
    await tester.pumpWidget(_wrap(directive: _directive, repo: repo));
    // draftNotifier.build() is async; let it resolve and the prefill
    // run via `whenData`.
    await tester.pumpAndSettle();

    expect(find.text('half-written sentence'), findsOneWidget);
  });

  testWidgets(
    'send button is disabled until non-whitespace text is entered',
    (tester) async {
      final repo = StubChatbotRepo();
      await tester.pumpWidget(_wrap(directive: _directive, repo: repo));
      await tester.pumpAndSettle();

      // Initial: send button is in an InkWell whose onTap is null
      // (disabled). Verify by finding InkWell and reading onTap.
      InkWell sendWell() => tester.widget<InkWell>(
            find.descendant(
              of: find.byType(Material).last,
              matching: find.byType(InkWell),
            ),
          );

      expect(
        sendWell().onTap,
        isNull,
        reason: 'send disabled when field is empty',
      );

      // Type some text — button enables.
      await tester.enterText(find.byType(TextField), 'AC is broken');
      await tester.pump();
      expect(
        sendWell().onTap,
        isNotNull,
        reason: 'send enabled when field has text',
      );
    },
  );

  testWidgets('whitespace-only text leaves the send button disabled', (
    tester,
  ) async {
    final repo = StubChatbotRepo();
    await tester.pumpWidget(_wrap(directive: _directive, repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '    ');
    await tester.pump();

    final well = tester.widget<InkWell>(
      find.descendant(
        of: find.byType(Material).last,
        matching: find.byType(InkWell),
      ),
    );
    expect(well.onTap, isNull);
  });
}

// Widget tests for AttachmentComposer (EVIDENCE phase).
//
// **Picker note (per plan §10.5):** the camera/gallery `image_picker`
// platform call is hard to mock cleanly without `image_picker_platform_
// interface` plumbing — and even mocked, the assertion would just be
// "did we call the picker?" which adds no real signal. We instead
// test the visible contract:
//
//   * "X of Y" counter reflects directive.currentCount + maxAllowed.
//   * "+" tile is disabled when at the cap.
//   * Tapping "+" opens a bottom sheet with Camera + Gallery options.
//   * Tapping "Done" calls `sessionNotifier.markAttachmentsDone`.
//
// We override `chatbotSessionProvider` with a stub notifier so we can
// assert on `markAttachmentsDone` invocations without standing up the
// real repository graph.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';
import 'package:frontend/features/customer/chatbot/presentation/notifiers/chatbot_session_notifier.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/attachment_composer.dart';

// ─── Test session-notifier stub ─────────────────────────────────────

class _StubSessionNotifier extends ChatbotSessionNotifier {
  _StubSessionNotifier(this._initial);
  final ChatSession _initial;

  int markDoneCalls = 0;

  @override
  Future<ChatSession> build({
    required String personaKey,
    required int bookingId,
  }) async => _initial;

  @override
  Future<void> markAttachmentsDone() async {
    markDoneCalls++;
  }
}

// ─── Fixtures ───────────────────────────────────────────────────────

ChatSession _session({int attachmentsCount = 0}) {
  return ChatSession(
    conversationId: 7001,
    personaKey: 'dispute',
    phase: ChatPhase.evidence,
    transcript: const <ChatMessage>[],
    directive: AttachmentDirective(
      currentCount: attachmentsCount,
      maxAllowed: 10,
      botMessage: '',
      hint: 'Add photos as evidence',
    ),
    attachmentsCount: attachmentsCount,
    isClosed: false,
  );
}

Widget _wrap({
  required _StubSessionNotifier stub,
  required AttachmentDirective directive,
  required ChatSession session,
}) {
  return ProviderScope(
    overrides: [
      chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001)
          .overrideWith(() => stub),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AttachmentComposer(
          personaKey: 'dispute',
          bookingId: 9001,
          session: session,
          directive: directive,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('initial render shows "0 of 10" + Done button + add tile', (
    tester,
  ) async {
    final session = _session(attachmentsCount: 0);
    final directive = session.directive as AttachmentDirective;
    final stub = _StubSessionNotifier(session);
    await tester.pumpWidget(
      _wrap(stub: stub, directive: directive, session: session),
    );
    await tester.pump();

    expect(find.text('0 of 10'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    // The single "+" icon (the add tile).
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets(
    'directive.currentCount=3 → counter shows "3 of 10"',
    (tester) async {
      final session = _session(attachmentsCount: 3);
      final directive = session.directive as AttachmentDirective;
      final stub = _StubSessionNotifier(session);
      await tester.pumpWidget(
        _wrap(stub: stub, directive: directive, session: session),
      );
      await tester.pump();

      expect(find.text('3 of 10'), findsOneWidget);
    },
  );

  testWidgets(
    'at maxAllowed → "+" add tile is disabled (InkWell.onTap == null)',
    (tester) async {
      final session = _session(attachmentsCount: 10);
      final directive = session.directive as AttachmentDirective;
      final stub = _StubSessionNotifier(session);
      await tester.pumpWidget(
        _wrap(stub: stub, directive: directive, session: session),
      );
      await tester.pump();

      // The "+" tile is the InkWell whose icon is Icons.add.
      final addTileInk = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(InkWell),
      );
      final well = tester.widget<InkWell>(addTileInk);
      expect(well.onTap, isNull);
    },
  );

  testWidgets(
    'tapping the "+" tile opens a bottom sheet with Camera + Gallery',
    (tester) async {
      final session = _session(attachmentsCount: 0);
      final directive = session.directive as AttachmentDirective;
      final stub = _StubSessionNotifier(session);
      await tester.pumpWidget(
        _wrap(stub: stub, directive: directive, session: session),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Done invokes sessionNotifier.markAttachmentsDone',
    (tester) async {
      final session = _session(attachmentsCount: 2);
      final directive = session.directive as AttachmentDirective;
      final stub = _StubSessionNotifier(session);
      await tester.pumpWidget(
        _wrap(stub: stub, directive: directive, session: session),
      );
      await tester.pump();

      await tester.tap(find.text('Done'));
      await tester.pump();

      expect(stub.markDoneCalls, 1);
    },
  );
}

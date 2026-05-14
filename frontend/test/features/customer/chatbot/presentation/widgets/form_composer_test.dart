// ignore_for_file: invalid_use_of_internal_member
// Widget tests for FormComposer (PAYOUT phase).
//
// The composer:
//   1. Mounts one TextFormField per FormFieldSpec from the schema.
//   2. Runs client-side validators (advisory): non-empty + optional
//      regex match → "Required" / "Format looks off".
//   3. On a FormValidationFailure landing on the session notifier's
//      error frame, paints the server's per-field errors into the
//      matching TextFormField — server-error wins over advisory.
//   4. On Submit, calls `sessionNotifier.submitForm` with the trimmed
//      values map.
//
// We override the session provider with a controllable stub notifier
// so we can simulate both the success path and the
// FormValidationFailure error frame without spinning up the real
// repository graph.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_session.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/form_schema.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';
import 'package:frontend/features/customer/chatbot/domain/failures/chatbot_failure.dart';
import 'package:frontend/features/customer/chatbot/presentation/notifiers/chatbot_session_notifier.dart';
import 'package:frontend/features/customer/chatbot/presentation/widgets/form_composer.dart';

// ─── Test session-notifier stub ─────────────────────────────────────

class _StubSessionNotifier extends ChatbotSessionNotifier {
  _StubSessionNotifier(this._initial);
  final ChatSession _initial;

  /// Captures the values that were submitted (for assertions).
  Map<String, dynamic>? capturedValues;

  /// When set, `submitForm` simulates an error by writing this into
  /// `state` as the error payload (with the initial session as the
  /// previous value via copyWithPrevious).
  Object? submitErrorToInject;

  @override
  Future<ChatSession> build({
    required String personaKey,
    required int bookingId,
  }) async => _initial;

  @override
  Future<void> submitForm(Map<String, dynamic> values) async {
    capturedValues = values;
    if (submitErrorToInject != null) {
      state = AsyncError<ChatSession>(
        submitErrorToInject!,
        StackTrace.current,
      ).copyWithPrevious(AsyncData(_initial));
    }
  }
}

// ─── Fixtures ───────────────────────────────────────────────────────

const _bankSchema = FormSchema(
  fields: [
    FormFieldSpec(
      name: 'bank_name',
      label: 'Bank',
      kind: FormFieldKind.text,
      validationPattern: r'^[A-Za-z][A-Za-z .\-]{1,49}$',
    ),
    FormFieldSpec(
      name: 'account_title',
      label: 'Account title',
      kind: FormFieldKind.text,
    ),
    FormFieldSpec(
      name: 'iban',
      label: 'IBAN',
      kind: FormFieldKind.text,
      validationPattern: r'^PK\d{2}[A-Z]{4}\d{16}$',
    ),
  ],
);

final _directive = FormDirective(
  schema: _bankSchema,
  persistDraft: false,
  botMessage: 'Last step — your bank details.',
  hint: '',
);

ChatSession _session() {
  return ChatSession(
    conversationId: 7001,
    personaKey: 'dispute',
    phase: ChatPhase.payout,
    transcript: const <ChatMessage>[],
    directive: _directive,
    attachmentsCount: 0,
    isClosed: false,
  );
}

Widget _wrap({required _StubSessionNotifier stub}) {
  final session = _session();
  return ProviderScope(
    overrides: [
      chatbotSessionProvider(personaKey: 'dispute', bookingId: 9001)
          .overrideWith(() => stub),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: FormComposer(
          personaKey: 'dispute',
          bookingId: 9001,
          session: session,
          directive: _directive,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders one TextFormField per schema field, by label', (
    tester,
  ) async {
    final stub = _StubSessionNotifier(_session());
    await tester.pumpWidget(_wrap(stub: stub));
    await tester.pumpAndSettle();

    expect(find.text('Bank'), findsOneWidget);
    expect(find.text('Account title'), findsOneWidget);
    expect(find.text('IBAN'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets(
    'empty Submit → all fields paint "Required" (client-side advisory)',
    (tester) async {
      final stub = _StubSessionNotifier(_session());
      await tester.pumpWidget(_wrap(stub: stub));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsNWidgets(3));
      // submitForm should NOT have been called (client validation
      // failed before the network call).
      expect(stub.capturedValues, isNull);
    },
  );

  testWidgets(
    'IBAN regex mismatch → "Format looks off" advisory under IBAN field',
    (tester) async {
      final stub = _StubSessionNotifier(_session());
      await tester.pumpWidget(_wrap(stub: stub));
      await tester.pumpAndSettle();

      // Fill bank_name + account_title validly; IBAN with garbage.
      await tester.enterText(find.byType(TextFormField).at(0), 'HBL');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Hamayon Khan',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'NOPE');
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Format looks off'), findsOneWidget);
      expect(stub.capturedValues, isNull);
    },
  );

  testWidgets(
    'valid input → Submit invokes session notifier with trimmed values',
    (tester) async {
      final stub = _StubSessionNotifier(_session());
      await tester.pumpWidget(_wrap(stub: stub));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'HBL');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Hamayon Khan',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        // Valid IBAN-shaped string (PK + 2 digits + 4 letters + 16 digits).
        'PK00ABCD0123456789012345',
      );
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(stub.capturedValues, {
        'bank_name': 'HBL',
        'account_title': 'Hamayon Khan',
        'iban': 'PK00ABCD0123456789012345',
      });
    },
  );

  testWidgets(
    'FormValidationFailure paints server error under matching field '
    '(server wins over advisory)',
    (tester) async {
      final stub = _StubSessionNotifier(_session())
        ..submitErrorToInject = const FormValidationFailure(
          fieldErrors: {
            'iban': ['IBAN already used for another account.'],
          },
        );
      await tester.pumpWidget(_wrap(stub: stub));
      await tester.pumpAndSettle();

      // Pass client-side validation so we reach submitForm.
      await tester.enterText(find.byType(TextFormField).at(0), 'HBL');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Hamayon Khan',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'PK00ABCD0123456789012345',
      );

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Server error message now appears under the IBAN field, even
      // though the client-side regex was satisfied.
      expect(
        find.text('IBAN already used for another account.'),
        findsOneWidget,
      );
    },
  );
}

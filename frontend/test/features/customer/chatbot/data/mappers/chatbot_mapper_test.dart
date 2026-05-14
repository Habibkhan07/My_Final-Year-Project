// Pure-function tests for ChatbotMapper.
//
// No mocks. Build wire models via `fromJson` against the same JSON
// shapes the data source produces, then assert the resulting domain
// entities. This way the test exercises the wire→domain rail end to
// end the way prod does.
//
// Coverage map:
//   * sessionFromStart — every UiInputKind branch (text/form/attachment/
//     none/unknown), with and without form schema, and the is_closed
//     short-circuit + defensive ticketId fallback.
//   * Schema wire→domain: wire `key` becomes domain `name`; wire
//     `pattern` populates domain `validationPattern`; wire `type`
//     enum-folds to FormFieldKind (text vs unknown).
//   * ChatPhase / ChatRole — known values + unknown fallback.
//   * created_at ISO-8601 parsing into UTC DateTime.
//   * sessionFromDetail fallback directives by phase.
//   * Defensive defaults: malformed output_refs, missing
//     support_ticket_id → ticketId=0.
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/customer/chatbot/data/mappers/chatbot_mapper.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_detail_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/conversation_start_response_model.dart';
import 'package:frontend/features/customer/chatbot/data/models/turn_result_model.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_message.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/chat_phase.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/form_schema.dart';
import 'package:frontend/features/customer/chatbot/domain/entities/ui_directive.dart';

import '../../_fixtures/wire_payloads.dart' as fx;

void main() {
  // ─── sessionFromStart — directive dispatch ───────────────────────────

  group('sessionFromStart — directive dispatch', () {
    test('ui_input_kind=text → TextDirective', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(uiInputKind: 'text'),
      );
      final session = ChatbotMapper.sessionFromStart(m);
      expect(session.directive, isA<TextDirective>());
      expect(session.isClosed, isFalse);
    });

    test('ui_input_kind=form + schema → FormDirective with FormSchema', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'form',
          currentPhase: 'PAYOUT',
          uiFormSchema: fx.bankFormSchema(),
        ),
      );
      final session = ChatbotMapper.sessionFromStart(m);
      final directive = session.directive as FormDirective;
      expect(directive.schema.fields, hasLength(3));
      expect(directive.schema.fields.map((f) => f.name), [
        'bank_name',
        'account_title',
        'iban',
      ]);
      // PAYOUT must opt out of draft persistence (PII).
      expect(directive.persistDraft, isFalse);
    });

    test(
      'ui_input_kind=form on non-PAYOUT phase → FormDirective persistDraft=true',
      () {
        final m = ConversationStartResponseModel.fromJson(
          fx.startResponse(
            uiInputKind: 'form',
            currentPhase: 'UNDERSTAND',
            uiFormSchema: fx.bankFormSchema(),
          ),
        );
        final session = ChatbotMapper.sessionFromStart(m);
        final directive = session.directive as FormDirective;
        expect(directive.persistDraft, isTrue);
      },
    );

    test('ui_input_kind=form + null schema → falls back to TextDirective', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(uiInputKind: 'form'),
      );
      // No ui_form_schema in this payload — mapper should log and
      // mount a TextDirective instead of throwing.
      final session = ChatbotMapper.sessionFromStart(m);
      expect(session.directive, isA<TextDirective>());
    });

    test('ui_input_kind=attachment → AttachmentDirective(maxAllowed: 10)', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'attachment',
          currentPhase: 'EVIDENCE',
        ),
      );
      final session = ChatbotMapper.sessionFromStart(m);
      final directive = session.directive as AttachmentDirective;
      expect(directive.maxAllowed, 10);
      expect(directive.currentCount, 0);
    });

    test('ui_input_kind=none → TextDirective with synthetic hint', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(uiInputKind: 'none', uiHint: ''),
      );
      final session = ChatbotMapper.sessionFromStart(m);
      final directive = session.directive as TextDirective;
      // Empty hint folds to a sensible default so the composer
      // doesn't render a blank placeholder.
      expect(directive.hint, 'Please continue');
    });

    test('unknown ui_input_kind value → TextDirective (rollout drift)', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(uiInputKind: 'voice', uiHint: 'speak now'),
      );
      final session = ChatbotMapper.sessionFromStart(m);
      final directive = session.directive as TextDirective;
      // Non-empty hint passes through verbatim.
      expect(directive.hint, 'speak now');
    });

    test('seeds initial empty transcript + non-closed session', () {
      final m = ConversationStartResponseModel.fromJson(fx.startResponse());
      final session = ChatbotMapper.sessionFromStart(m);
      expect(session.transcript, isEmpty);
      expect(session.isClosed, isFalse);
      expect(session.outputRefs, isNull);
    });
  });

  // ─── sessionFromTurn — directive + transcript composition ────────────

  group('sessionFromTurn', () {
    test('appended messages are merged onto previous transcript', () {
      final start = ChatbotMapper.sessionFromStart(
        ConversationStartResponseModel.fromJson(fx.startResponse()),
      );
      final turn = TurnResultModel.fromJson(
        fx.turnResponse(botMessage: 'thanks'),
      );

      final next = ChatbotMapper.sessionFromTurn(
        previous: start,
        m: turn,
        appendedMessages: [
          ChatMessage(
            id: 1,
            role: ChatRole.user,
            text: 'AC broken',
            createdAt: DateTime.utc(2026, 5, 14, 3, 21, 55),
            phase: ChatPhase.understand,
          ),
        ],
      );
      expect(next.transcript, hasLength(1));
      expect(next.transcript.first.role, ChatRole.user);
    });

    test('isClosed turn populates outputRefs', () {
      final start = ChatbotMapper.sessionFromStart(
        ConversationStartResponseModel.fromJson(fx.startResponse()),
      );
      final turn = TurnResultModel.fromJson(
        fx.turnResponse(
          isClosed: true,
          currentPhase: 'CLOSED',
          outputRefs: const {'support_ticket_id': 1284},
        ),
      );
      final next = ChatbotMapper.sessionFromTurn(
        previous: start,
        m: turn,
        appendedMessages: const [],
      );
      expect(next.isClosed, isTrue);
      expect(next.outputRefs!.ticketId, 1284);
      expect(next.directive, isA<TerminalDirective>());
    });
  });

  // ─── Form schema wire → domain ───────────────────────────────────────

  group('FormFieldSpec wire → domain translation', () {
    test('wire `key` becomes domain `name`', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'form',
          currentPhase: 'PAYOUT',
          uiFormSchema: fx.bankFormSchema(),
        ),
      );
      final directive = ChatbotMapper.sessionFromStart(m).directive
          as FormDirective;
      expect(directive.schema.fields.map((f) => f.name).toList(), [
        'bank_name',
        'account_title',
        'iban',
      ]);
    });

    test('wire `pattern` populates validationPattern', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'form',
          currentPhase: 'PAYOUT',
          uiFormSchema: fx.bankFormSchema(),
        ),
      );
      final iban = (ChatbotMapper.sessionFromStart(m).directive
              as FormDirective)
          .schema
          .fields
          .firstWhere((f) => f.name == 'iban');
      expect(iban.validationPattern, r'^PK\d{2}[A-Z]{4}\d{16}$');
    });

    test('wire `type: text` → FormFieldKind.text', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'form',
          currentPhase: 'PAYOUT',
          uiFormSchema: fx.bankFormSchema(),
        ),
      );
      final fields = (ChatbotMapper.sessionFromStart(m).directive
              as FormDirective)
          .schema
          .fields;
      for (final f in fields) {
        expect(f.kind, FormFieldKind.text);
      }
    });

    test('unsupported wire `type` → FormFieldKind.unknown', () {
      final m = ConversationStartResponseModel.fromJson(
        fx.startResponse(
          uiInputKind: 'form',
          currentPhase: 'PAYOUT',
          uiFormSchema: {
            'fields': [
              {
                'key': 'preferred_call_time',
                'label': 'Best time to call',
                'type': 'time',
                'required': false,
              },
            ],
          },
        ),
      );
      final field = (ChatbotMapper.sessionFromStart(m).directive
              as FormDirective)
          .schema
          .fields
          .single;
      expect(field.kind, FormFieldKind.unknown);
    });
  });

  // ─── ChatPhase enum ──────────────────────────────────────────────────

  group('ChatPhase.fromWire', () {
    test('known values', () {
      expect(ChatPhase.fromWire('UNDERSTAND'), ChatPhase.understand);
      expect(ChatPhase.fromWire('EVIDENCE'), ChatPhase.evidence);
      expect(ChatPhase.fromWire('PAYOUT'), ChatPhase.payout);
      expect(ChatPhase.fromWire('CONFIRM'), ChatPhase.confirm);
      expect(ChatPhase.fromWire('CLOSED'), ChatPhase.closed);
    });

    test('unknown string folds to unknown', () {
      expect(ChatPhase.fromWire('FUTURE_PHASE'), ChatPhase.unknown);
      expect(ChatPhase.fromWire(null), ChatPhase.unknown);
    });
  });

  // ─── ChatRole enum ───────────────────────────────────────────────────

  group('ChatRole.fromWire', () {
    test('USER / BOT / SYSTEM', () {
      expect(ChatRole.fromWire('USER'), ChatRole.user);
      expect(ChatRole.fromWire('BOT'), ChatRole.bot);
      expect(ChatRole.fromWire('SYSTEM'), ChatRole.system);
    });

    test('unknown string folds to unknown', () {
      expect(ChatRole.fromWire('GHOST'), ChatRole.unknown);
      expect(ChatRole.fromWire(null), ChatRole.unknown);
    });
  });

  // ─── sessionFromDetail ───────────────────────────────────────────────

  group('sessionFromDetail', () {
    test('parses messages and converts createdAt to UTC DateTime', () {
      final m = ConversationDetailModel.fromJson(
        fx.conversationDetail(
          messages: [
            fx.message(
              id: 1,
              role: 'USER',
              text: 'AC broken',
              createdAt: '2026-05-14T03:21:55+00:00',
            ),
            fx.message(
              id: 2,
              role: 'BOT',
              text: 'Got it',
              createdAt: '2026-05-14T03:21:58+00:00',
            ),
          ],
        ),
      );
      final session = ChatbotMapper.sessionFromDetail(m);
      expect(session.transcript, hasLength(2));
      expect(session.transcript.first.role, ChatRole.user);
      expect(session.transcript.first.createdAt.isUtc, isTrue);
      expect(session.transcript.first.createdAt.hour, 3);
    });

    test('closed detail → TerminalDirective + outputRefs', () {
      final m = ConversationDetailModel.fromJson(
        fx.conversationDetail(
          isClosed: true,
          closedAt: '2026-05-14T12:00:00+00:00',
          outputRefs: const {'support_ticket_id': 4242},
        ),
      );
      final session = ChatbotMapper.sessionFromDetail(m);
      final directive = session.directive as TerminalDirective;
      expect(directive.refs.ticketId, 4242);
      expect(session.outputRefs!.ticketId, 4242);
      expect(session.closedAt!.isUtc, isTrue);
    });

    test(
      'closed detail with missing support_ticket_id → ticketId=0 fallback',
      () {
        // Server bug shape: closed=true but output_refs is `{}`.
        // Mapper logs and surfaces ticketId=0 so the screen doesn't
        // crash mid-render.
        final m = ConversationDetailModel.fromJson(
          fx.conversationDetail(
            isClosed: true,
            outputRefs: const {},
          ),
        );
        final session = ChatbotMapper.sessionFromDetail(m);
        expect(session.outputRefs!.ticketId, 0);
      },
    );

    test('open detail in EVIDENCE phase → fallback AttachmentDirective', () {
      final m = ConversationDetailModel.fromJson(
        fx.conversationDetail(currentPhase: 'EVIDENCE'),
      );
      final session = ChatbotMapper.sessionFromDetail(m);
      expect(session.directive, isA<AttachmentDirective>());
    });

    test('open detail in UNDERSTAND/PAYOUT/CONFIRM → fallback TextDirective', () {
      for (final phase in ['UNDERSTAND', 'PAYOUT', 'CONFIRM']) {
        final m = ConversationDetailModel.fromJson(
          fx.conversationDetail(currentPhase: phase),
        );
        final session = ChatbotMapper.sessionFromDetail(m);
        expect(
          session.directive,
          isA<TextDirective>(),
          reason: 'fallback for phase=$phase',
        );
      }
    });

    test('attachments count derived from list length', () {
      final m = ConversationDetailModel.fromJson(
        fx.conversationDetail(
          attachments: const [
            {
              'id': 1,
              'file': 'http://x/a.jpg',
              'mime_type': 'image/jpeg',
              'size_bytes': 1234,
            },
            {
              'id': 2,
              'file': 'http://x/b.jpg',
              'mime_type': 'image/jpeg',
              'size_bytes': 5678,
            },
          ],
        ),
      );
      final session = ChatbotMapper.sessionFromDetail(m);
      expect(session.attachmentsCount, 2);
    });
  });
}

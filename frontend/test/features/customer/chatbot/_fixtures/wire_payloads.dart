// Shared wire-shape fixtures for chatbot data-layer tests.
//
// Why a shared module: the wire payloads are reused across
// `chatbot_remote_data_source_test`, `chatbot_mapper_test`, and
// `chatbot_repository_impl_test`. Duplicating the JSON shape in each
// file is the easiest way to drift the test surface away from the
// real envelope. Centralising lets a backend contract change land in
// one place.
//
// Source of truth: `backend/chatbot/api/CHATBOT_API.md` and
// `backend/chatbot/views.py::_serialize_*`.
import 'dart:convert';

Map<String, dynamic> startResponse({
  int conversationId = 7001,
  String personaKey = 'dispute',
  String currentPhase = 'UNDERSTAND',
  String botMessage = 'Hi - tell me what went wrong with this booking.',
  String uiInputKind = 'text',
  String uiHint = 'Type a sentence or two',
  Map<String, dynamic>? uiFormSchema,
  Map<String, dynamic>? stateSummary,
}) {
  return {
    'conversation_id': conversationId,
    'persona_key': personaKey,
    'current_phase': currentPhase,
    'bot_message': botMessage,
    'ui_input_kind': uiInputKind,
    'ui_form_schema': ?uiFormSchema,
    'ui_hint': uiHint,
    'state_summary': stateSummary ?? stateSummaryBlock(phase: currentPhase),
  };
}

Map<String, dynamic> turnResponse({
  int conversationId = 7001,
  String currentPhase = 'UNDERSTAND',
  String botMessage = 'Got it, anything else?',
  String uiInputKind = 'text',
  String uiHint = '',
  Map<String, dynamic>? uiFormSchema,
  Map<String, dynamic>? stateSummary,
  bool isClosed = false,
  Map<String, dynamic>? outputRefs,
}) {
  return {
    'conversation_id': conversationId,
    'current_phase': currentPhase,
    'bot_message': botMessage,
    'ui_input_kind': uiInputKind,
    'ui_form_schema': ?uiFormSchema,
    'ui_hint': uiHint,
    'state_summary': stateSummary ?? stateSummaryBlock(phase: currentPhase),
    'is_closed': isClosed,
    'output_refs': outputRefs ?? const {},
  };
}

Map<String, dynamic> conversationDetail({
  int conversationId = 7001,
  String personaKey = 'dispute',
  String currentPhase = 'UNDERSTAND',
  bool isClosed = false,
  String? closedAt,
  List<Map<String, dynamic>>? messages,
  List<Map<String, dynamic>>? attachments,
  Map<String, dynamic>? outputRefs,
  Map<String, dynamic>? stateSummary,
}) {
  return {
    'conversation_id': conversationId,
    'persona_key': personaKey,
    'current_phase': currentPhase,
    'is_closed': isClosed,
    'closed_at': closedAt,
    'state_summary': stateSummary ?? stateSummaryBlock(phase: currentPhase),
    'messages': messages ?? const [],
    'attachments': attachments ?? const [],
    'output_refs': outputRefs ?? const {},
  };
}

Map<String, dynamic> closeResponse({
  String closedAt = '2026-05-14T12:00:00+00:00',
  Map<String, dynamic>? outputRefs,
}) {
  return {
    'closed_at': closedAt,
    'output_refs': outputRefs ?? const {'support_ticket_id': 1284},
  };
}

Map<String, dynamic> attachmentUploadResponse({
  int attachmentId = 42,
  int attachmentsCount = 1,
}) {
  return {
    'attachment_id': attachmentId,
    'attachments_count': attachmentsCount,
  };
}

Map<String, dynamic> stateSummaryBlock({
  String phase = 'UNDERSTAND',
  Map<String, dynamic>? capturedFields,
  int attachmentsCount = 0,
}) {
  return {
    'phase': phase,
    'captured_fields': capturedFields ?? const {},
    'attachments_count': attachmentsCount,
  };
}

Map<String, dynamic> message({
  required int id,
  String role = 'BOT',
  String text = 'hello',
  String phase = 'UNDERSTAND',
  String createdAt = '2026-05-14T03:21:55+00:00',
}) {
  return {
    'id': id,
    'role': role,
    'text': text,
    'phase': phase,
    'created_at': createdAt,
  };
}

/// The dispute persona's PAYOUT phase form schema. Shape mirrors
/// `backend/chatbot/personas/dispute/schemas.py::BANK_FORM_SCHEMA`.
Map<String, dynamic> bankFormSchema() {
  return {
    'fields': [
      {
        'key': 'bank_name',
        'label': 'Bank',
        'type': 'text',
        'required': true,
        'pattern': r'^[A-Za-z][A-Za-z .\-]{1,49}$',
      },
      {
        'key': 'account_title',
        'label': 'Account title',
        'type': 'text',
        'required': true,
        'pattern': r"^[A-Za-z][A-Za-z .'\-]{1,79}$",
      },
      {
        'key': 'iban',
        'label': 'IBAN',
        'type': 'text',
        'required': true,
        'pattern': r'^PK\d{2}[A-Z]{4}\d{16}$',
      },
    ],
  };
}

Map<String, dynamic> errorEnvelope({
  required int status,
  required String code,
  String message = 'Something went wrong.',
  Map<String, dynamic>? errors,
}) {
  return {
    'status': status,
    'code': code,
    'message': message,
    'errors': errors ?? const {},
  };
}

String encodeJson(Object? value) => jsonEncode(value);

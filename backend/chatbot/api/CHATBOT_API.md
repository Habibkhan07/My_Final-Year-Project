# CHATBOT_API.md — AI Chatbot Framework

> Pluggable LLM-driven chat framework. v1 ships a single persona (dispute resolution). New personas (general Q&A, tech onboarding, quote-helper) land as folder-adds under `chatbot/personas/<key>/` — no edits to the views, URLs, or core services.

---

## Architecture at a glance

```
┌─── HTTP ────────────────────────────────────────┐
│ POST /api/chat/<persona>/start/                 │  ← persona-agnostic surface
│ POST /api/chat/conversations/<id>/message/      │
│ POST /api/chat/conversations/<id>/attachments/  │
│ POST /api/chat/conversations/<id>/close/        │
│ GET  /api/chat/conversations/<id>/              │
└────────────────────┬────────────────────────────┘
                     │
              ┌──────▼──────────────┐
              │ chatbot/views.py    │ thin: parse → delegate
              └──────┬──────────────┘
                     │
       ┌─────────────▼─────────────────────────────┐
       │ chatbot/services/conversation.py          │  lifecycle, quota, persistence
       │   start_conversation                      │
       │   handle_message                          │
       │   close_conversation                      │
       └─────┬───────────────────────┬─────────────┘
             │                       │
   ┌─────────▼──────────┐    ┌───────▼─────────────┐
   │ chatbot/personas/  │    │ chatbot/adapters/   │  swappable LLM vendor
   │   dispute/         │    │   gemini.py         │  (LLM_ADAPTER setting)
   │   ...future        │    │   ...future         │
   └────────────────────┘    └─────────────────────┘
```

Two pluggable seams:

- **Persona** (`chatbot.services.ports.Persona`) — declares eligibility rules, initial state, flow engine, on-close side effects. Registered in `chatbot/personas/__init__.py` via `register(MyPersona())`, called from `ChatbotConfig.ready()`.
- **ConversationalAgent** (same module) — the LLM seam. Pick the adapter via `LLM_ADAPTER` setting. v1 ships `gemini`.

---

## Endpoints

All endpoints require token authentication (`Authorization: Token <token>`). All error responses use the project canonical envelope:

```json
{
  "status": 400,
  "code": "snake_case_stable_string",
  "message": "Human-readable string for UI toast",
  "errors": {"field": ["specific error"]}
}
```

### `POST /api/chat/<persona_key>/start/`

Open or resume a conversation with the given persona.

**Path params**
- `persona_key` — one of `dispute` (v1). Future: `general`, `onboarding`, …

**Request body**

```json
{
  "context": { "booking_id": 42 }
}
```

`context` is persona-specific:
- **dispute** — `{ "booking_id": int }` (required)

**Response — 201 Created**

```json
{
  "conversation_id": 17,
  "persona_key": "dispute",
  "current_phase": "UNDERSTAND",
  "bot_message": "Hi — sorry to hear that AC Repair on 2026-05-10 didn't go well. Could you tell me what happened?",
  "ui_input_kind": "text",
  "ui_form_schema": null,
  "ui_hint": "Tell me what happened",
  "state_summary": {
    "phase": "UNDERSTAND",
    "captured_fields": {},
    "attachments_count": 0
  }
}
```

If an open conversation already exists for the same `(user, booking)` pair, the existing one is returned (resume semantics — no duplicate row).

**Errors**
- `404 persona_not_found` — unknown persona_key
- `400 not_eligible_to_start` — persona rejected (wrong booking status, IDOR — same code in both cases, no info leak)
- `401` — unauthenticated

---

### `POST /api/chat/conversations/<id>/message/`

Process one user-driven turn.

**Request body**

```json
{ "kind": "text" | "form" | "attachment_done", "payload": <kind-specific> }
```

| kind | payload | Used in phase |
|---|---|---|
| `text` | non-empty string, ≤ 2000 chars | UNDERSTAND |
| `form` | `{bank_name, account_title, iban}` — IBAN regex `^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$` | PAYOUT (also closes the conversation in the same turn) |
| `attachment_done` | `null` (signal only) | EVIDENCE |

**Response — 200 OK**

```json
{
  "conversation_id": 17,
  "current_phase": "EVIDENCE",
  "bot_message": "Got it. Let's collect some photos next.",
  "ui_input_kind": "attachment",
  "ui_form_schema": null,
  "ui_hint": "Attach photos of the issue (optional, up to 10)",
  "state_summary": {
    "phase": "EVIDENCE",
    "captured_fields": {"issue_summary": "AC stopped working"},
    "attachments_count": 0
  },
  "is_closed": false,
  "output_refs": {}
}
```

The PAYOUT form-submit turn finalises the dispute inline — that turn's
response carries `is_closed=true` and `output_refs={"support_ticket_id": <id>}`.
A SYSTEM closing message is appended (visible via `GET /conversations/<id>/`)
confirming the ticket reference + SLA.

**Errors**
- `404 conversation_not_found` — no conversation with this id for this user (IDOR-safe — different user → same code)
- `409 conversation_closed` — conversation already closed
- `429 llm_quota_exceeded` — daily LLM call cap hit (50/day default, configurable via `CHATBOT_DAILY_CALL_LIMIT`)
- `400 unsupported_message_kind` — wrong `kind` for current phase (e.g. `form` during UNDERSTAND)
- `400 validation_error` — bad payload shape (kind serializer rejected it)

---

### `POST /api/chat/conversations/<id>/attachments/`

Upload one image to the conversation. Multipart.

**Form fields**
- `file` — image file (JPEG/PNG/HEIC). Server strips EXIF/GPS on save.

**Response — 201 Created**

```json
{ "attachment_id": 8, "attachments_count": 3 }
```

**Errors**
- `404 conversation_not_found`
- `409 conversation_closed`
- `400 attachment_count_exceeded` — per-conversation cap (default 10, via `CHATBOT_MAX_ATTACHMENTS`)
- `413 attachment_too_large` — per-file cap (default 5 MB, via `CHATBOT_MAX_ATTACHMENT_MB`)
- `400 validation_error` — non-image file

---

### `POST /api/chat/conversations/<id>/close/`

Explicit close. Usually unnecessary — terminal turns auto-close — but exposed for client-initiated abandons (e.g. user backs out of chat). **Idempotent**: re-calling on a closed conversation returns the existing `output_refs`.

**Response — 200 OK**

```json
{
  "closed_at": "2026-05-13T18:00:00Z",
  "output_refs": {"support_ticket_id": 42}
}
```

---

### `GET /api/chat/conversations/<id>/`

Full state + message history + attachments. Used by the Flutter app to resume after a tab swap, app restart, or crash.

**Response — 200 OK**

```json
{
  "conversation_id": 17,
  "persona_key": "dispute",
  "current_phase": "EVIDENCE",
  "is_closed": false,
  "closed_at": null,
  "state_summary": { "phase": "EVIDENCE", "captured_fields": {...}, "attachments_count": 1 },
  "messages": [
    { "id": 1, "role": "BOT",  "text": "Hi — sorry…", "phase": "UNDERSTAND", "created_at": "..." },
    { "id": 2, "role": "USER", "text": "AC stopped working", "phase": "UNDERSTAND", "created_at": "..." },
    { "id": 3, "role": "BOT",  "text": "Got it…", "phase": "UNDERSTAND", "created_at": "..." }
  ],
  "attachments": [
    { "id": 11, "file": "/media/chatbot/2026/05/photo.jpg", "mime_type": "image/jpeg", "size_bytes": 184320 }
  ],
  "output_refs": {}
}
```

---

## Dispute persona

### Eligibility

Mirrors `show_dispute_button` on the booking detail screen (see [[feedback_dispute_visibility]]):
- Booking must belong to the authenticated user (IDOR-safe via `select_for_update` on the booking row).
- Booking status must be `COMPLETED` or `COMPLETED_INSPECTION_ONLY`.

### Phase lifecycle

```
UNDERSTAND  ─►  EVIDENCE  ─►  PAYOUT  ─►  CLOSED
   ▲                            │           │
   │ (cap exceeded,             │           ▼
   │  required missing)         │  SupportTicket + RefundIntent
   └───► aborts → CLOSED        │           filed inline
         (no ticket)            │
                                ▼
                  (PAYOUT submit summarises + files in one turn)
```

| Phase | UI input | LLM call? | Required to advance |
|---|---|---|---|
| UNDERSTAND | text | yes (multi-turn) | `issue_summary` captured |
| EVIDENCE | attachment upload + done signal | no | (0 photos allowed) |
| PAYOUT | bank-form submit | yes (summarize, inline) | bank_name + account_title + valid IBAN; closes the conversation in the same turn |

CONFIRM was a separate turn pre-1.1 — it's been folded into the PAYOUT
submit so users don't get stuck having to type a sentinel message after
the form. The phase string `"CONFIRM"` may still appear in legacy
transcript logs.

**Cap-exceeded behavior** (`CHATBOT_UNDERSTAND_TURN_CAP`, default 8):
- Required fields captured → force-advance with `forced_advance=true` → resulting ticket carries `needs_review=true`.
- Required fields missing → abort: conversation closes, **no ticket filed**, customer redirected to Help.

**Outputs**
- `bookings.SupportTicket` with `dispute_intake_method='CHATBOT'`. The `chat_log` JSON carries:
  - `conversation_id`, `ai_summary`, `ai_summary_lang`, `captured_fields`
  - `needs_review` (true if summary validation tripped OR turn cap forced advance)
  - `needs_review_reason`
  - `messages` — full transcript snapshot
  - `attachments` — file paths
- `disputes.RefundIntent` — only created when PAYOUT phase reached. Bank PII restricted to `finance_admin` group in Django admin.

### Sample full transcript

```http
POST /api/chat/dispute/start/    { "context": { "booking_id": 42 } }
← 201 { conversation_id: 17, bot_message: "Hi — sorry to hear that AC Repair on 2026-05-10 didn't go well. What happened?", current_phase: "UNDERSTAND", ui_input_kind: "text", ... }

POST /api/chat/conversations/17/message/    { "kind": "text", "payload": "AC stopped working the day after." }
← 200 { bot_message: "I'm sorry. How much did you pay in total?", current_phase: "UNDERSTAND", ui_input_kind: "text", state_summary: { captured_fields: { issue_summary: "AC stopped working" } } }

POST /api/chat/conversations/17/message/    { "kind": "text", "payload": "Rs 3500. I called the technician but he didn't respond." }
← 200 { bot_message: "Got it. Let's collect some photos next.", current_phase: "EVIDENCE", ui_input_kind: "attachment", state_summary: { captured_fields: { issue_summary: "...", amount_paid: "3500", contacted_technician: "yes" } } }

POST /api/chat/conversations/17/attachments/  (multipart file=…)
← 201 { attachment_id: 8, attachments_count: 1 }

POST /api/chat/conversations/17/message/    { "kind": "attachment_done", "payload": null }
← 200 { bot_message: "If a refund is approved, where should we send it?", current_phase: "PAYOUT", ui_input_kind: "form", ui_form_schema: { fields: [...] } }

POST /api/chat/conversations/17/message/    { "kind": "form", "payload": { "bank_name": "HBL", "account_title": "Hamayon Khan", "iban": "PK36HABB0011223344556677" } }
← 200 { bot_message: "One moment — filing your dispute ticket now.", current_phase: "CLOSED", is_closed: true, output_refs: { support_ticket_id: 42 } }

GET /api/chat/conversations/17/
← 200 { ..., messages: [..., { role: "SYSTEM", text: "Thanks. Your dispute has been filed as ticket #42 — our team will review it within 3 working days. ..." }] }
```

---

## How to add a new persona (recipe)

Goal: add a `general` Q&A persona (or any other).

1. **Create the folder** `chatbot/personas/general/` with:
   ```
   __init__.py
   persona.py     ← class GeneralPersona implementing the Persona Protocol
   flow.py        ← class GeneralFlow implementing the FlowEngine Protocol
   prompts.py     ← system prompts
   outputs.py     ← on_close side effects (or no-op for a Q&A bot)
   ```

2. **Register in `ChatbotConfig.ready()`**:
   ```python
   from chatbot.personas import register
   from chatbot.personas.general.persona import GeneralPersona
   register(GeneralPersona())
   ```

3. **That's it.** No edits to `chatbot.views`, `chatbot.urls`, `chatbot.services`, or `chatbot.adapters`. The framework picks up the new key automatically.
   ```http
   POST /api/chat/general/start/  ← works immediately
   ```

**Checklist**

- [ ] Persona declares `key`, `display_name`, `flow_engine`, `tools=[]`, `system_prompt`, `response_schema`, `extra_output_validators`
- [ ] `is_eligible_to_start` is IDOR-safe (locks any relevant row with `select_for_update`)
- [ ] `find_existing_open` returns the right existing conversation (optional but recommended for resume UX)
- [ ] `initial_state` returns a dict the flow understands
- [ ] `on_close` is idempotent — replaying must not duplicate side effects
- [ ] Flow validates LLM output via `chatbot.services.content_safety.validate_output` with appropriate `kind`
- [ ] Persona-specific extra validators registered if you need them (e.g. forbidding certain phrases)
- [ ] Tests live under `tests/chatbot/personas/<key>/` mirroring the app structure

---

## Settings reference

| Setting | Default | Purpose |
|---|---|---|
| `LLM_ADAPTER` | `gemini` | Which adapter `get_default_agent()` returns |
| `GEMINI_API_KEY` | _required_ | Google AI Studio key (fail-loud at first use) |
| `GEMINI_MODEL` | `gemini-2.5-flash` | Model name |
| `CHATBOT_DAILY_CALL_LIMIT` | 50 | LLM calls per user per day (shared across personas) |
| `CHATBOT_UNDERSTAND_TURN_CAP` | 8 | Max UNDERSTAND-phase turns before force-advance/abort |
| `CHATBOT_MAX_ATTACHMENTS` | 10 | Per-conversation attachment cap |
| `CHATBOT_MAX_ATTACHMENT_MB` | 5 | Per-file size cap (MB) |
| `CHATBOT_MAX_SESSION_MB` | 50 | Per-conversation total size cap (MB) |
| `DISPUTE_SLA_STRING` | `within 3 working days` | Customer-facing SLA copy |
| `CHATBOT_SCRUB_FIELDS` | `user_message,narrative,bank_name,account_title,iban` | Fields scrubbed from logs / Sentry |

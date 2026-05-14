# Chatbot Feature — Customer Side

> Persona-agnostic chatbot framework for the Flutter app. v1 ships **one persona**: `dispute`, used by customers to file a service dispute on a completed booking.

---

## 1 · Overview

The chatbot is a **server-driven** turn-based conversation flow. Each turn the backend returns the bot's next message plus a `ui_input_kind` discriminator (`text` / `form` / `attachment` / `none`); the Flutter screen dispatches that to one of four composers via a polymorphic `UiDirective` sealed root. The frontend has **no knowledge** of phase transitions — adding a new phase or persona on the backend ships to the app with zero Flutter changes.

**Dispute persona flow:** `UNDERSTAND → EVIDENCE → PAYOUT → CONFIRM → CLOSED`. On close, the backend writes a `SupportTicket` and the dispute appears in the customer's booking detail with a `DISPUTED` status flip. (The status flip is driven by the booking feature's existing realtime listener — the chatbot itself does not broadcast.)

**Entry context (dispute persona):** `{booking_id: int}`. Pushed onto the route via `/customer/bookings/:bookingId/dispute-chat`.

---

## 2 · Architectural claims (the load-bearing decisions)

1. **State machine lives on the backend.** Frontend renders directives. New phase added on the backend ships with zero Flutter changes — the polymorphic `InputRenderer` dispatches on `UiDirective` subclass.
2. **Framework/persona split.** `features/customer/chatbot/` is persona-agnostic. The only persona-specific surface is the entry context. A second persona reuses the entire feature; only its entry point + context shape differ.
3. **Request/response only.** This feature does NOT subscribe to realtime — no `SystemEventType`, no entry in `realtimeBootHooksProvider`. The customer is the actor on every turn; the resulting `DISPUTE_OPENED` event is consumed by the booking feature.

---

## 3 · Domain entities

Location: `lib/features/customer/chatbot/domain/entities/`

| Entity | Fields | Fed by |
|---|---|---|
| `ChatSession` | `conversationId, personaKey, phase, transcript, directive, attachmentsCount, isClosed, closedAt?, outputRefs?` | `POST /api/chat/<persona>/start/` + `GET /api/chat/conversations/<id>/` + every turn write |
| `ChatMessage` | `id, role, text, createdAt (UTC DateTime), phase` | `messages[]` from detail GET; optimistic local instances for USER turns |
| `OutputRefs` | `ticketId` | `output_refs.support_ticket_id` from close response |
| `FormSchema` / `FormFieldSpec` | `fields[]` / `(name, label, kind, validationPattern?)` | `ui_form_schema` block on turn response. **Wire key→domain name** mapping applied by mapper. |
| `StateSummary` | `phase, attachmentsCount, capturedFields` | `state_summary` block (telemetry-only; UI doesn't read this today) |
| `UiDirective` (sealed) | see §6 below | Composed from turn-response quintuple by the mapper |

Enums: `ChatPhase {understand, evidence, payout, confirm, closed, unknown}`, `ChatRole {user, bot, system, unknown}`, `FormFieldKind {text, unknown}`. All have a forgiving `fromWire(String?)` that defaults to `unknown` on rollout drift.

---

## 4 · Sealed failure hierarchy

Location: `lib/features/customer/chatbot/domain/failures/chatbot_failure.dart`

Every wire-level error translates to one of these. The screen's `ref.listen` switches on the subclass to choose the UI affordance.

| Failure | HTTP / wire code | UI affordance |
|---|---|---|
| `ChatbotNetworkFailure` | `SocketException` | Inline network banner + retry. Turn was NOT committed server-side. |
| `NotEligibleToStartFailure` | 400 `not_eligible_to_start` | Modal → back to booking detail. |
| `ConversationNotFoundFailure` | 404 `conversation_not_found` | Modal → drop session, allow fresh start. |
| `ConversationClosedFailure` | 409 `conversation_closed` | Surface closing card (if `outputRefs` known) else navigate back. |
| `LlmQuotaExceededFailure` | 429 `llm_quota_exceeded` | Soft-worded `showQuotaExceededModal` — points at Help. |
| `UnsupportedMessageKindFailure` | 400 `unsupported_message_kind` | Neutral snackbar. Indicates client/state drift; `assert(false)` in debug. |
| `AttachmentTooLargeFailure(maxMb)` | 413 `attachment_too_large` | Inline error in attachment composer. `maxMb` read from envelope. |
| `AttachmentCountExceededFailure(maxCount)` | 400 `attachment_count_exceeded` | Inline error in attachment composer. `maxCount` read from envelope. |
| `FormValidationFailure(fieldErrors)` | 400 `validation_error` on form submit | Per-field paint under each `TextFormField`. **Server-error wins over client advisory regex.** |
| `PersonaNotFoundFailure` | 404 `persona_not_found` | Neutral snackbar. Client bug (unregistered persona key). |
| `UnknownChatbotFailure` | catch-all | Generic snackbar. |

---

## 5 · Repository interface contract

Location: `lib/features/customer/chatbot/domain/repositories/chatbot_repository.dart`

```dart
abstract class IChatbotRepository {
  // Remote (online-only — every call surfaces SocketException as ChatbotNetworkFailure).
  Future<ChatSession> startConversation({required String personaKey, required Map<String, dynamic> context});
  Future<ChatSession> fetchConversation(int conversationId);
  Future<ChatSession> sendTextTurn({required int conversationId, required int bookingId, required String text});
  Future<ChatSession> submitFormTurn({required int conversationId, required int bookingId, required Map<String, dynamic> values});
  // Bytes-based contract — XFile.path is a blob: URL on web; readAsBytes() is the cross-platform read.
  Future<int> uploadAttachment({required int conversationId, required String filename, required Uint8List bytes});
  Future<ChatSession> notifyAttachmentsDone({required int conversationId, required int bookingId});
  Future<ChatSession> closeConversation({required int conversationId, required int bookingId});   // idempotent

  // Local-only (Tier-2 + Tier-3). Recovery is per-booking (was a single
  // global before — caused cross-booking session bleed).
  Future<void> saveDraftText({required int conversationId, required String? text});
  Future<String?> loadDraftText(int conversationId);
  Future<void> setActiveConversationId({required int bookingId, required int? conversationId});
  Future<int?> getActiveConversationId(int bookingId);
}
```

`bookingId` flows through the turn-write methods so the repository can
clear the per-booking recovery key when the persona auto-closes
mid-turn — see plan §C and `chatbot_local_data_source.dart`.

Every remote method's dartdoc lists the `ChatbotFailure` subtypes it can throw. The contract is documented at the method level.

---

## 6 · `UiDirective` — polymorphic dispatch

Plain sealed class (no codegen). Location: `domain/entities/ui_directive.dart`.

```dart
sealed class UiDirective {
  final String botMessage;
  final String hint;
}

final class TextDirective       extends UiDirective {}                                // UNDERSTAND
final class FormDirective       extends UiDirective { final FormSchema schema;
                                                       final bool persistDraft; }    // PAYOUT
final class AttachmentDirective extends UiDirective { final int currentCount;
                                                       final int maxAllowed; }       // EVIDENCE
final class TerminalDirective   extends UiDirective { final OutputRefs refs; }       // CLOSED
```

`InputRenderer` dispatches on subclass — Dart's exhaustive switch ensures every subclass is handled at compile time. Adding a new directive type causes a compile error in `input_renderer.dart` until a matching composer is wired.

---

## 7 · Use cases

Location: `domain/use_cases/`. Seven single-method classes, each a thin wrapper around one repo method:

`StartConversationUseCase`, `FetchConversationUseCase`, `SendTextTurnUseCase`, `SubmitFormTurnUseCase`, `UploadAttachmentUseCase`, `NotifyAttachmentsDoneUseCase`, `CloseConversationUseCase`.

The notifier reads use cases (not the repo directly) for the four-step pipeline's symmetry with the rest of the codebase.

---

## 8 · Data models

Location: `lib/features/customer/chatbot/data/models/`. All `@freezed` with `fromJson` except `UiInputKind` (plain enum).

`ConversationStartResponseModel`, `TurnResultModel`, `ConversationDetailModel`, `CloseResponseModel`, `AttachmentUploadResponseModel`. Nested: `StateSummaryModel`, `MessageModel`, `AttachmentModel`, `FormSchemaModel` (+ `FormFieldModel`), `OutputRefsModel`.

**Wire-shape note.** The wire uses `key` for form fields; the mapper translates to domain `name`. The wire's `output_refs` is `Map<String, dynamic>`; the mapper parses it via `OutputRefsModel.fromJson` and falls back to `ticketId = 0` with a log if `support_ticket_id` is missing on a closed conversation (server bug surface — doesn't crash render).

---

## 9 · Data sources

### `ChatbotRemoteDataSource` (`data/data_sources/chatbot_remote_data_source.dart`)

Six methods over `http.Client`:

| Method | Endpoint | Notes |
|---|---|---|
| `startConversation` | `POST /api/chat/<persona>/start/` | Body: `{context: {...}}` |
| `getConversation` | `GET /api/chat/conversations/<id>/` | |
| `sendTextMessage` | `POST /api/chat/conversations/<id>/message/` | Body: `{kind: "text", payload: {text}}` |
| `submitForm` | `POST /api/chat/conversations/<id>/message/` | Body: `{kind: "form", payload: <values>}` |
| `notifyAttachmentsDone` | `POST /api/chat/conversations/<id>/message/` | Body: `{kind: "attachment_done", payload: {}}` |
| `uploadAttachment` | `POST /api/chat/conversations/<id>/attachments/` | `multipart/form-data` — field name `file`, mime sniffed by extension |
| `closeConversation` | `POST /api/chat/conversations/<id>/close/` | Empty body. **Idempotent server-side.** |

Auth: `Authorization: Token <secure_storage[auth_token]>`. Error envelope parsed via the same `HttpFailure.fromEnvelope` factory used across the codebase. Non-2xx → throws `HttpFailure(code, message, errors)`. `SocketException` propagates to the repository (NOT caught here).

### `ChatbotLocalDataSource` (`data/data_sources/chatbot_local_data_source.dart`)

`SharedPreferences`-backed. Two purposes only — see §11 PII Discipline:

| Key | Purpose |
|---|---|
| `CHATBOT_ACTIVE_CONVERSATION_ID_v1` (int) | Tier-3 session recovery target |
| `CHATBOT_DRAFT_TEXT_v1:<conversationId>` (string) | Tier-2 draft text (skipped for PAYOUT phase) |

Per-method `try/catch` logs and swallows — a draft-save failure must never bubble to the caller (the composer's keystroke listener is fire-and-forget).

`clear()` removes only chatbot-prefixed keys; unrelated SharedPreferences keys are preserved.

---

## 10 · Repository impl flow (online-only)

Location: `data/repositories/chatbot_repository_impl.dart`.

- **`startConversation`** — POST + map to session + `local.setActiveConversationId(session.conversationId)` for Tier-3 recovery.
- **Turn writes** (`sendTextTurn` / `submitFormTurn` / `notifyAttachmentsDone`) — go through a shared `_runTurn` helper: POST + GET-detail + map. The extra GET trades one round-trip per turn for "the persona may emit 0/1/2 bot messages per turn" composition simplicity. If the resulting session is `isClosed`, the repo clears the recovery id + drops the persisted draft.
- **`uploadAttachment`** — multipart POST, returns the wire's `attachments_count` (notifier updates the session's `attachmentsCount` in-place; no full session replacement).
- **`closeConversation`** — POST + GET-detail + map. **Idempotent contract**: a second `close` succeeds server-side; the detail GET picks up the existing closed state either way. After: clears recovery id + drops draft.

**No offline fallback.** Every `SocketException` surfaces as `ChatbotNetworkFailure` regardless of cache state. The local data source exists for draft persistence + cold-boot recovery only.

### Wire code → typed failure switch

Centralised in `_mapHttpFailure(HttpFailure)`. The 9 wire codes from §4 map 1:1 to their `ChatbotFailure` subclasses; `AttachmentTooLargeFailure.maxMb` / `AttachmentCountExceededFailure.maxCount` are read from the envelope's `errors` map via `_intFromErrors` (with documented defaults if absent). `FormValidationFailure.fieldErrors` is flattened from the envelope by `_fieldErrorsFromEnvelope`. Unknown codes fold to `UnknownChatbotFailure`.

---

## 11 · Error propagation pipeline (4 steps)

Per CLAUDE.md §Frontend Error Propagation:

1. **Data Source** — non-2xx → throws `HttpFailure(code, message, errors)`. `SocketException` propagates.
2. **Repository** — `_mapHttpFailure` translates `HttpFailure.code` → sealed `ChatbotFailure`. `SocketException` → `ChatbotNetworkFailure`. Untyped exceptions → `UnknownChatbotFailure`.
3. **Domain** — sealed `ChatbotFailure` hierarchy (§4).
4. **UI** — screen-level `ref.listen` on the session notifier; `switch` expression on the failure subtype → user-friendly Snackbar / modal / inline error.

The 4 steps are tested end-to-end: data-source tests assert the envelope→`HttpFailure` parse; repository tests assert every wire code → matching `ChatbotFailure` subtype.

---

## 12 · Presentation state

### Notifiers (`presentation/notifiers/`)

| Notifier | Family key | State | Role |
|---|---|---|---|
| `ChatbotSessionNotifier` | `(personaKey, bookingId)` | `AsyncValue<ChatSession>` | Owns the conversation. `build()` rehydrates via Tier-3 recovery (`fetchConversation`) or starts fresh (`startConversation`). Mutations: `sendText` (optimistic-append + revert), `submitForm`, `uploadAttachment` (in-place count update), `markAttachmentsDone`, `close`, `refresh`. |
| `DraftNotifier` | `conversationId` | `AsyncValue<String>` | Debounced 500ms per-conversation draft writer. PAYOUT calls `setText(persistDraft: false)` to suppress PII. |
| `AttachmentUploadNotifier` | `conversationId` | `Set<String>` | In-flight tracker — per-tile spinner state. Does NOT own the upload call (session notifier does). |

**Optimistic-append pattern** (`sendText` only): the notifier appends a USER bubble with a negative-sentinel id before the round-trip; on failure the previous session is restored via `AsyncError(...).copyWithPrevious(AsyncData(previous))` so the error toast appears AND the orphan bubble disappears.

**copyWithPrevious lint:** the chatbot notifier carries three `// ignore: invalid_use_of_internal_member` comments at the `.copyWithPrevious` sites. Same baseline as `bookings/customer_bookings_list_notifier.dart`; see flag #51.

### Widgets (`presentation/widgets/`)

```
ChatbotScreen
├─ AppBar (Close conversation popup menu, hidden when terminal)
├─ Network banner (when AsyncError == ChatbotNetworkFailure)
├─ ChatTranscript      ← scroll-aware (suppress auto-scroll when user is reading history >100px above bottom)
│   └─ ChatBubble × N   (USER right-aligned brand-blue / BOT left-aligned cool-grey / SYSTEM italic centered)
└─ InputRenderer       ← sealed switch on UiDirective
    ├─ TextComposer       ← TextDirective       (UNDERSTAND)
    ├─ FormComposer       ← FormDirective       (PAYOUT — server-driven schema)
    ├─ AttachmentComposer ← AttachmentDirective (EVIDENCE — image_picker + grid)
    └─ ClosingCard        ← TerminalDirective   (Ticket #N + Back to booking)
```

Modal: `showQuotaExceededModal` (soft-worded `LlmQuotaExceededFailure` surface) — see flag #50.

### Visual identity

Per `feedback_ui_target_foodpanda` memory: UX patterns from Foodpanda, visual identity is the project's brand-blue (#0051AE) `ElevatedButton` language from the booking flow. Tokens in `presentation/utils/chatbot_palette.dart` — parallel to `BookingsPalette`. Per `project_ui_cleanup_planned`, both palettes get folded into one shared token surface in the end-of-UI design-system sweep.

---

## 13 · DI wiring

Location: `presentation/providers/dependency_injection.dart`. Mirrors the bookings DI exactly — Infrastructure → Data Sources → Repository → Use Cases.

```
chatbotHttpClient ─┐
                   ├─→ chatbotRemoteDataSource ─┐
chatbotSecureStorage┘                            ├─→ chatbotRepository ─→ 7 × <op>UseCase
sharedPreferencesProvider* → chatbotLocalDataSource ┘

* re-uses the boot-time-overridden provider from technician/onboarding/.../dependency_injection.dart.
  main.dart's single ProviderScope override gives every customer feature the real SharedPreferences instance.
```

All DI providers are `keepAlive: true`. The session notifier itself is `keepAlive: false` (default `@riverpod`) — it owns per-screen state and disposes on screen pop.

---

## 14 · Server-driven state machine

The frontend's view of phase transitions is exclusively through `UiDirective`. Every turn response carries:

```
{
  current_phase:   "UNDERSTAND" | "EVIDENCE" | "PAYOUT" | "CLOSED" | <future>
  ui_input_kind:   "text" | "form" | "attachment" | "none" | "close" | <future>
  ui_form_schema:  <FormSchemaModel> | null
  ui_hint:         <string>
  bot_message:     <string>
  is_closed:       <bool>
  output_refs:     { support_ticket_id: <int> } | {}
}
```

CONFIRM is no longer a discrete user-visible phase — the PAYOUT form
submit finalises the ticket inline (single turn from PAYOUT → CLOSED).
Backwards-readable: legacy state strings may still contain `"CONFIRM"`
in transcript audit logs.

The mapper folds these into one of the four `UiDirective` subclasses (`is_closed: true` takes precedence over everything else — produces `TerminalDirective`). The widget tree never reads `current_phase` for branching. The phase enum is retained on `ChatMessage` only for transcript-audit purposes; it does not drive UI behaviour.

**Adding a new persona** = backend work + (optionally) a new entry-context shape passed to `startConversation`. Zero Flutter changes if the persona reuses `text` / `form` / `attachment` directives.

**Adding a new directive type** (e.g. future `VoiceDirective`) = adding a subclass + one composer + one case in `input_renderer.dart`'s switch. The compiler enforces exhaustiveness at the switch site.

---

## 15 · PII discipline

| Surface | Storage tier | PII handling |
|---|---|---|
| JWT auth token | Tier-1 (`flutter_secure_storage`) — key `auth_token` | Sent as `Authorization: Token <token>` header. Never logged. |
| Tier-3 recovery id (`active_conversation_id`) | Tier-2 (`SharedPreferences`) — int only | The id is not PII; cleared on `close`. |
| Draft text (UNDERSTAND phase) | Tier-2 (`SharedPreferences`) — per-conversation key | Customer's free-text narration. Drafts cleared on successful send + on close. |
| **Bank details (PAYOUT phase: IBAN, account_title, bank_name)** | **Memory only** — `TextEditingController` until POST submit | `FormDirective.persistDraft = false` for PAYOUT. `DraftNotifier.setText` is a no-op when `persistDraft: false`. **IBAN, account title and bank name never reach SharedPreferences.** |
| Image attachments | Local file path (managed by `image_picker`) until upload, then server-only | The file path is in-memory only during the EVIDENCE composer's lifetime. |

The PAYOUT no-persist contract is enforced at three layers:
1. **Mapper** sets `FormDirective.persistDraft = phase != ChatPhase.payout`.
2. **FormComposer** never calls `DraftNotifier.setText` (form fields live only in `TextEditingController` instances).
3. **DraftNotifier** treats `persistDraft: false` as a no-op even if called.

---

## 16 · Routing

Location: `core/routing/app_router.dart`. Route registered as a child of `/booking`-family paths:

```
/customer/bookings/:bookingId/dispute-chat
   → ChatbotScreen(personaKey: 'dispute', bookingId: <id>)
```

The route handler parses `:bookingId` defensively: malformed (non-int) ids route to a "booking not found" screen, mirroring the existing `/booking/:job_id` guard.

**Entry from booking detail** is **not yet wired** — see flag #49. The current dev path is direct deep-link (`/customer/bookings/<id>/dispute-chat`).

**Exit:** terminal `ClosingCard` calls `context.pop()` → returns to whatever pushed the route. The booking detail screen behind it picks up the `DISPUTED` status flip via its own realtime listener (the chatbot itself does not broadcast — see §2 claim 3).

---

## 17 · Testing

Test directory: `test/features/customer/chatbot/` (mirrors `lib/` exactly per CLAUDE.md).

| Layer | Tests | Pattern |
|---|---|---|
| Data sources | `chatbot_remote_data_source_test.dart` (20), `chatbot_local_data_source_test.dart` (10) | `MockClient` for HTTP; `SharedPreferences.setMockInitialValues` for prefs. |
| Mapper | `chatbot_mapper_test.dart` (24) | Pure functions; build wire models from `fromJson(fixture)`. |
| Repository | `chatbot_repository_impl_test.dart` (23) | Hand-written `_FakeRemote` + `_FakeLocal`. Every wire code → typed failure. |
| State | `chatbot_session_notifier_test.dart` (14), `draft_notifier_test.dart` (8), `attachment_upload_notifier_test.dart` (6) | `ProviderContainer` + override `chatbotRepositoryProvider` with a fake. `await container.read(provider.future)` before mutations (CLAUDE.md warm-up rule). |
| Widgets | `chat_bubble_test.dart` (6), `chat_transcript_test.dart` (3), `input_renderer_test.dart` (4), `text_composer_test.dart` (4), `form_composer_test.dart` (5), `attachment_composer_test.dart` (5), `closing_card_test.dart` (2), `quota_exceeded_modal_test.dart` (3) | `ProviderScope` + `MaterialApp` harness. Composer tests stub the session notifier directly (`chatbotSessionProvider.overrideWith(() => stub)`). |

Shared helpers:
- `_fixtures/wire_payloads.dart` — fixture factories for every wire shape.
- `_helpers/stub_repo.dart` — no-op `IChatbotRepository` for widget-test provider-graph satisfaction.

**Total: 137 tests, all green. Analyzer: `No issues found!` on `lib/` + `test/` chatbot scopes.**

### Notable test-discipline notes

- **Auto-dispose pin.** `draftProvider` is `@riverpod` default `keepAlive: false`. Tests that span an `await` then trigger a debounced timer must hold a `c.listen(provider, (_, _) {}, fireImmediately: true)` subscription — otherwise the provider auto-disposes between reads and `ref.onDispose` cancels the Timer before it fires.
- **Real `Future.delayed` for debounce.** We tried `fake_async` for the 500ms debounce; `elapse()` didn't reliably drain microtasks inside the Timer's async callback. Real-time delays add ~3s to the suite but are deterministic.
- **Auto-scroll suppression.** `ChatTranscript` suppresses auto-scroll when **post-update** distance-from-bottom > 100px. A single new bubble whose height exceeds the threshold itself triggers this — tests use short single-line fixtures.

---

## 18 · Open items / known shortcuts

These ship to `flag.md` at D4 wrap-up:

- **#49** — Booking detail "File a dispute" button is not wired. The route is registered; no UI entry pushes to it yet.
- **#50** — `/customer/help` route is a TODO stub in `QuotaExceededModal` ("Use Help" button closes the modal but does not navigate). Help feature ships post-viva.
- **#51** — Removing a successfully-uploaded attachment is not supported. No server-side delete endpoint exists. Re-pick is allowed within the count cap.
- **#52** — No logout-clear-feature-caches hook. `ChatbotLocalDataSource.clear()` exists; auth feature's logout doesn't call it. Acceptable v1 (keys are user-scoped via secure-storage `auth_token` boundary).
- **#53** — `copyWithPrevious` lint suppressions. Three `// ignore:` comments in `chatbot_session_notifier.dart`. Same un-suppressed warning exists in `bookings/.../customer_bookings_list_notifier.dart`. Future Riverpod upgrade may resolve.

---

## 19 · Reference

- Backend API: `backend/chatbot/api/CHATBOT_API.md`
- Auto-memory entries: `project_chatbot_scope`, `project_viva_sprint`, `feedback_ui_target_foodpanda`, `project_ui_cleanup_planned`, `feedback_dispute_visibility`
- Related flag entries: #43 (resolved — chatbot-filed dispute now emits `DISPUTE_OPENED`), #44–#48 (backend chatbot tech-debt)

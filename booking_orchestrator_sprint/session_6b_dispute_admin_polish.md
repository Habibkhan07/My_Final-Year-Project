# Session 6b — Dispute + Admin Resolve + Sprint Polish

> **Supersedes the second half of [`session_6_lifecycle_edges_and_polish.md`](./session_6_lifecycle_edges_and_polish.md).** Session 6 was split to keep human-in-the-loop decision density manageable. The parent spec is preserved as historical reference; [`session_6a_cancel_reschedule_noshow.md`](./session_6a_cancel_reschedule_noshow.md) is authoritative for what 6a ships, and this file is authoritative for what 6b ships.
>
> **6b scope (this file):** the customer-only dispute open flow (full-screen form with optional photo upload via multipart), tech-side read-only `DisputeStatusBanner`, Django Admin SupportTicket resolve polish, the final two stub bodies (`Disputed`, `Unknown`), folder rename `stub_bodies/` → `status_bodies/`, sprint-end CLAUDE.md amendments (3 patterns), `ORCHESTRATOR_FEATURE.md` final pass, flag.md closure of #26 + **update of existing flag #28 (chatbot)** + new flag `eventlog-retention-policy-tbd` (next available number), sprint-end 9 manual acceptance tests, tech-offline banner verification integration test.
>
> **6a scope (sibling, ships first):** cancellation, reschedule, no-show, SLA countdown, modal registry extension, AppBar overflow wiring, 5 polished stubs.

---

## §0 Sprint context

This is **session 6b of the post-split 8-session plan** (1, 2, 3, 4, 5a, 5b, 6a, 6b) — the **last** session of the Booking Orchestrator sprint. Cross-cutting decisions in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Sessions 1–6a invariants this sub-session relies on:

- All session 1–5 invariants from the parent spec §0.
- Backend `open_dispute`, `admin_resolve_dispute` endpoints (session 2 §4.4 / session 2 §4.11).
- 6a's modal registry extension (4 new keys); dispute is NAVIGATE so no further keys.
- 6a's polished stubs for `Awaiting`, `Confirmed`, `Cancelled`, `Rejected`, `NoShow`. After 6b: all 13 + `Unknown` (= 14) stubs are full bodies; the file's name "stub_bodies" becomes a misnomer — 6b does the rename `stub_bodies/` → `status_bodies/` and updates the import in `body_slot.dart` in the same edit.

What lands at sprint completion (after 6b):
- Full lifecycle end-to-end demoable on Android with OSM provider.
- All 14 transition endpoints wired to UI buttons or auto-flips.
- All 13 stub bodies + `Unknown` replaced with status-appropriate UI.
- Flag #26 closed.
- One new flag opened by 6a: `auto-no-show-detection-deferred` (#34 at spec-write time).
- One new flag opened by 6b: `eventlog-retention-policy-tbd` (#35 at spec-write time).
- Existing flag **#28 (`AI chatbot dispute intake`) updated** by 6b with sprint-end context — *not* re-opened. Re-audit caught the pre-existing entry at #28; opening a duplicate would corrupt the log.

What does NOT ship at sprint end: real money writes (finance sprint), AI chatbot intake (form-intake stub here; chatbot is its own sprint), auto-detected no-show via Celery (manual buttons only — covered by 6a's flag), reviews/ratings, iOS push (flag #10).

---

## §1 Decisions taken (subset of parent §1; numbers preserved)

Carried over from parent session 6 §1, scoped to 6b:

5. **Dispute open form is customer-only per §14 rule 5.** Tech viewers see a read-only `DisputeStatusBanner` ("Customer has reported an issue. Admin will contact you.") with no buttons. For customer viewers on disputable statuses (IN_PROGRESS, COMPLETED, COMPLETED_INSPECTION_ONLY) without an active OPEN ticket, server emits `open_dispute` in `secondary_actions`; tap NAVIGATEs to the form. (Parent §1.5.)
6. **`DisputeOpenForm` is full-screen route at `/booking/:job_id/dispute`**, not a modal. (Parent §1.6.)
7. **Photo upload uses `image_picker`** — single photo, optional, multipart POST. (Parent §1.7.)
8. **Admin resolve form is in Django Admin.** Session 2 scaffolded URL + view; this session polishes template + adds tests + wires success messages + bookings-page redirect. (Parent §1.8.)
11. **Polished terminal stubs (6b portion):** `Disputed` (with `DisputeStatusBanner` + role-aware copy), `Unknown` (defensive fallback for forward-compat). (Parent §1.11 — 6b portion.)
13. **Tech-offline banner verification**: integration test simulates network drop and asserts the banner appears, completing the live-tracking acceptance criteria from session 4. (Parent §1.13.)
14. **flag.md (6b portion):** ✅ Resolved (#26 with strikethrough + summary). **Update existing flag #28** (`AI chatbot dispute intake — schema seam present, module deferred`) with sprint-end context — orchestrator landed, FORM intake is now the live writer, chatbot adapter is what's still missing. **Do NOT open a new chatbot flag** — re-audit caught that #28 already covers it; the parent spec's "open #29 chatbot" was based on stale flag.md state. Open new flag `eventlog-retention-policy-tbd` at **#35** (audit P2-03; verify next-available with `tail flag.md`). (Parent §1.14 — 6b portion, with re-audit correction.)
15. **CLAUDE.md amendments**: 3 small additions placed under existing sections — modal endpoint registry pattern, stream consumer pattern, WS upstream subscribe contract. (Parent §1.15.)
16. **Sprint-end integration smoke**: 9 manual acceptance tests walking the full lifecycle through every edge — happy path, every cancellation phase, reschedule, no-show (both sides), dispute open + admin resolve, live-tracking edges, mid-job upsell. (Parent §1.16.)

17. **Audit-cycle-1 fixes (6b portion):**
    - **P0-03 / §24 transport**: `package:http` for dispute datasource. **Multipart pattern** uses `http.MultipartRequest` per §24 (Dio not in pubspec).
    - **flag.md eventlog-retention-policy-tbd** (audit P2-03): the realtime EventLog grows unbounded without a cleanup task; defer to ops sprint but log explicitly in flag.md so it doesn't get lost.
    - P1-09 modal registry — already done by 6a (no new keys for dispute since it's NAVIGATE).

Decisions already shipped by 6a: 1, 2, 3, 4, 9, 10, 12, the 6a portions of 11 and 14, and 17's modal-registry portion.

---

## §2 Files this session touches

### Dispute (frontend, 9 files; all from parent §2)

| File | Purpose |
|---|---|
| `data/datasources/dispute_remote_data_source.dart` | Multipart `POST /disputes/` via `http.MultipartRequest` (audit P0-03 §24 multipart pattern). |
| `data/models/dispute_open_request_model.dart` | DTO with `initial_reason` + optional `photo`. |
| `domain/failures/dispute_failure.dart` | Sealed: `DisputeNotDisputableStatus`, `DisputeNetworkFailure`, `DisputeServerFailure`, `UnknownDisputeFailure`. |
| `domain/repositories/dispute_repository.dart` | Interface (`openDispute`). |
| `data/repositories/dispute_repository_impl.dart` | Maps datasource exceptions to sealed failures. |
| `domain/use_cases/open_dispute_use_case.dart` | Wraps `repository.openDispute`. |
| `presentation/providers/dispute_notifier.dart` | Submit + async state. |
| `presentation/screens/dispute_open_form_screen.dart` | Full-screen form. |
| `presentation/widgets/dispute/dispute_status_banner.dart` | Read-only banner for tech viewer ("Customer has reported an issue. Admin will contact you."). |

### Stub bodies (modified, 2 of 7) + folder rename

| File | Status | Purpose |
|---|---|---|
| `presentation/widgets/stub_bodies/all_status_stubs.dart` | **modified** | Replace `DisputedBodyStub` and `UnknownBodyStub`. After this edit all 14 status bodies are full. |
| **Rename** `presentation/widgets/stub_bodies/all_status_stubs.dart` → `presentation/widgets/status_bodies/all_status_bodies.dart` | **renamed** | After replacing the last stub, the folder name is a misnomer. Same-commit rename + import update. |
| `presentation/widgets/body_slot.dart` | **modified** | Update import path. |

### Dispute routing

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/core/routing/app_router.dart` | **modified** | Add `GoRoute(path: '/booking/:job_id/dispute', ...)` for `DisputeOpenFormScreen`. |
| `frontend/pubspec.yaml` | **modified** (if needed) | Add `image_picker: ^x.y.z` if not already present. |
| `frontend/android/app/src/main/AndroidManifest.xml` | **modified** (if needed) | `READ_EXTERNAL_STORAGE` (or scoped storage permission for Android 13+) for the image picker. |

### Backend Admin polish

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/admin.py` | **modified** | Polish `SupportTicketAdmin.resolve_view`: validation (all-fields-required), success messages, redirect to JobBooking change page (not ticket changelist), already-resolved guard. |
| `backend/bookings/templates/admin/bookings/supportticket/resolve.html` | **modified** | Polished form template with confirmation step, evidence thumbnails, related-bookings hyperlinks. |

### Documentation

| File | Status | Purpose |
|---|---|---|
| `frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md` | **modified — final pass** | Complete coverage of all 14 transitions, all 13 statuses + `Unknown`, all event types, all modal endpoints, the SLA countdown widget, the dispute flow, the admin resolve flow. Mark sprint as DONE. |
| `CLAUDE.md` | **modified** | Three small additions (per parent §4.10), placed under existing sections (NOT appended at bottom): stream consumer pattern (under "Realtime"), WS upstream subscribe contract (under "Realtime"), modal endpoint registry (under "Frontend → Dumb UI Principle"). |
| `flag.md` | **modified** | ✅ Resolve #26 with strikethrough + ✅ + date + "What changed" block. **Update existing #28** (chatbot) with sprint-end context (don't re-open — pre-existing entry caught at re-audit). Open new flag `eventlog-retention-policy-tbd` at next-available number (**#35** at spec-write; verify with `tail flag.md`). |

### Tests (5 frontend + 1 backend)

| File | Status | Purpose |
|---|---|---|
| `test/features/orchestrator/data/repositories/dispute_repository_impl_test.dart` | **new** | Dispute open × failure branches (multipart edge cases — empty reason, photo not found, server 400, server 5xx). |
| `test/features/orchestrator/presentation/providers/dispute_notifier_test.dart` | **new** | Submit + async (with mocked photo). |
| `test/features/orchestrator/presentation/screens/dispute_open_form_screen_test.dart` | **new** | Form submit with + without photo. |
| `test/features/orchestrator/presentation/widgets/dispute/dispute_status_banner_test.dart` | **new** | Tech-viewer banner renders read-only; singular/plural copy by `openTicketsCount`; defensive guard for 0. |
| `test/features/orchestrator/presentation/widgets/stub_bodies/polished_stubs_test.dart` | **modified** | Extends 6a's coverage with `DisputedBodyStub` (customer + tech viewer paths; `openTicketsCount` singular/plural variants) and `UnknownBodyStub` (defensive forward-compat fixture). 6a created this file with its 5 stubs; 6b appends test cases — no rewrite. |
| `backend/tests/bookings/test_admin_resolve_dispute_polish.py` | **new** | End-to-end Django Admin form → orchestrator service → state mutation. Covers happy path, missing-field rejection, already-resolved rejection, redirect target. |

### Tech-offline integration test

| File | Status | Purpose |
|---|---|---|
| `test/integration/tech_offline_banner_test.dart` (or equivalent) | **new** | Simulates network drop on the customer side; asserts the live-tracking offline banner from session 4's `LiveTrackingMap` appears. Closes session 4's last acceptance gap. |

### Files NOT touched in 6b

- All session 1–5 + 6a work.
- iOS code (flag #10).
- Reviews / ratings (out of sprint).

---

## §3 Pre-flight

```bash
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# Confirm sessions 1–6a landed
ls frontend/lib/features/orchestrator/presentation/widgets/cancellation/customer_cancel_modal.dart
ls frontend/lib/core/widgets/timing/sla_countdown.dart
grep -n "auto-no-show-detection-deferred" flag.md

# Confirm session 2 admin scaffolding
grep -n "SupportTicketAdmin" backend/bookings/admin.py
ls backend/bookings/templates/admin/bookings/supportticket/resolve.html

# Backend baseline
cd backend && source venv/bin/activate
pytest -q
python manage.py check
cd ..

# Frontend baseline
cd frontend
flutter pub get
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs

# Confirm image_picker is in pubspec
grep -n "image_picker" pubspec.yaml || echo "Will add this session"

# Confirm flag.md schema (latest entry conventions)
tail -50 ../flag.md
```

---

## §4 Per-file detailed changes

For full code blocks, see the parent spec [`session_6_lifecycle_edges_and_polish.md`](./session_6_lifecycle_edges_and_polish.md). Sub-sections that apply to 6b:

- **Parent §4.5** — `DisputeOpenFormScreen` in full (text + optional photo via `image_picker`; submit length validation `>= 10` chars; multipart datasource sets `request.fields['initial_reason'] = reason` and optionally appends `await http.MultipartFile.fromPath('photo', photo.path)`; sends via `_client.send(request)`; converts to `http.Response.fromStream(...)` for the standard `_ensureOk` path; URL: `${AppConstants.baseUrl}/bookings/$bookingId/disputes/`). `DisputeStatusBanner` in full.
- **Parent §4.7** — polished stubs (6b portion): `DisputedBodyStub` (uses `DisputeStatusBanner`, role-aware copy), `UnknownBodyStub` (generic "Reload" prose + button — defensive fallback for forward-compat).
- **Parent §4.8** — GoRouter route for `/booking/:job_id/dispute`; folder rename `stub_bodies/` → `status_bodies/`; file rename `all_status_stubs.dart` → `all_status_bodies.dart`; import update in `body_slot.dart`.
- **Parent §4.9** — Backend Admin polish: `bookings/admin.py` `resolve_view` (validation, success messages, already-resolved guard, redirect to `/admin/bookings/jobbooking/<bid>/change/`); `resolve.html` template (evidence thumbnails, form layout, related-bookings hyperlinks).
- **Parent §4.10** — CLAUDE.md amendments (3 short paragraphs): stream consumer pattern under "Realtime → Events vs Streams"; WS upstream subscribe contract under "Realtime"; modal endpoint registry under "Frontend → Dumb UI Principle".
- **Parent §4.11** — flag.md updates (6b portion): `~~### Flag #26~~` strikethrough + `✅ Resolved (date)` + "What changed" block. **Update existing `## 28. AI chatbot dispute intake` entry** — append a "Sprint-end context (booking orchestrator)" block noting that the orchestrator landed, FORM intake is the live writer, and the chatbot adapter is the remaining gap. Do NOT open a new chatbot flag (re-audit caught the pre-existing #28; the parent spec's "open #29 chatbot" assumed an older flag.md state). Open `### Flag #35: EventLog retention policy TBD` (audit P2-03) with full schema — verify the number is next-available via `tail flag.md` at execution time.

### Order of operations note for the folder rename

The rename `stub_bodies/` → `status_bodies/` must happen in the SAME commit as the import update in `body_slot.dart`. Do both edits together. Search-and-replace the import + delete the old folder name from disk. Doing the rename in a separate commit creates an in-between state where `body_slot.dart` cannot resolve the import.

---

## §5 Gotchas (subset of parent §5)

Parent gotchas that apply to 6b (numbers preserved):

1. **Folder rename `stub_bodies/` → `status_bodies/`** breaks the import in `body_slot.dart`. Same-commit edit.
7. **`DisputeOpenFormScreen` requires `image_picker`** in pubspec. Add if not present and request the right permissions in AndroidManifest (`READ_EXTERNAL_STORAGE` or scoped storage on Android 13+).
8. **The dispute multipart POST** uses `http.MultipartRequest` per §24 (audit C2-P0-04). Endpoint URL: `${AppConstants.baseUrl}/bookings/$bookingId/disputes/` (no `/api/` prefix — audit C2-P0-01).
13. **Tech-side dispute banner is always read-only** per §14 rule 5. Don't render an open-dispute button for tech viewers.
14. **`UnknownBodyStub`** is a defensive fallback for unknown-status forward-compat. Renders prose + a refresh button.
15. **Django Admin resolve form** must validate `final_status` is one of the three allowed (COMPLETED / COMPLETED_INSPECTION_ONLY / CANCELLED). Backend's orchestrator validates too, but the form should pre-filter.
16. **Admin resolve success redirect** goes to the JobBooking change page (not the ticket changelist) — admin's mental model is "I resolved this booking's dispute, now show me the booking."
17. **CLAUDE.md amendments** appended in the right sections (not at the bottom). Read existing structure first.
18. **flag.md numbering**: at spec-write time `flag.md`'s latest entry is **#33** and **#28 is already `AI chatbot dispute intake`** (filed earlier). 6a opens **#34** (auto-no-show); 6b opens **#35** (eventlog retention) and *updates* the existing #28 with sprint-end context rather than opening a new chatbot flag. **Always verify by `tail flag.md` and `grep -n '^## 28' flag.md` at execution time** — the parent spec used stale numbers; if new flags landed since this re-audit, bump accordingly.
19. **Sprint-end CLAUDE.md amendments are not optional** — they document patterns introduced this sprint that future contributors will reference.
20. **`DisputeStatusBanner` count text** uses singular/plural based on `openTicketsCount`. Default 0 should not render the banner — defensive guard at the consumer.

---

## §6 Verification — sprint-end integration smoke

This is the **acceptance test for the entire booking orchestrator sprint**. Walks every transition end-to-end on a real device. (Parent §6 in full.)

### Setup

```bash
cd backend && source venv/bin/activate
python manage.py migrate
python manage.py runserver 0.0.0.0:8000 &

cd ../frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=MAP_PROVIDER=osm
```

Two physical Android devices (or one device + emulator) — one as customer, one as tech. Backend running. OTP `123456` (`DEBUG=True`).

### The 9 acceptance tests (parent §6.1–§6.9)

1. **Happy path** — book → accept → en-route → arrive → quote → approve → cash → COMPLETED.
2. **Bargain loop (3 revisions)** — bargain twice, then approve.
3. **Decline → COMPLETED_INSPECTION_ONLY** — customer declines after quote.
4. **Cancellation matrix** — customer cancels at each phase (AWAITING / CONFIRMED / EN_ROUTE / ARRIVED / INSPECTING / QUOTED) with correct fee surfacing; tech cancels via overflow → reliability event logged.
5. **Reschedule** — customer at CONFIRMED reschedules; original CANCELLED, child AWAITING; tech receives `job_new_request`.
6. **No-show (both sides)** — tech reports customer; customer reports tech; both arrive at NO_SHOW with correct `actor`.
7. **Dispute flow** — customer at COMPLETED reports issue with photo; both see `DisputedBodyStub`; admin opens Django Admin, resolves with outcome + final status; both receive `dispute_resolved`; booking ends in chosen final terminal status.
8. **Live-tracking edges** — tech moves out of network → 60s → "Technician offline" banner appears; reconnect → banner clears within next frame; tech kills foreground service → banner appears 60s later; reopen orchestrator → service restarts.
9. **Mid-job upsell** — tech taps "+ Add more work" in cash card; builder opens with `?upsell=true`; submit → QUOTED → customer approves → IN_PROGRESS with new total; tech taps "Cash Collected" → COMPLETED.

### Static / unit checks

```bash
cd frontend
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib/ test/
cd ../backend
pytest -q
python manage.py check
```

### Constraint final checks

```bash
# Single switch on BookingStatus across the entire frontend
grep -rn "switch (booking.status)" frontend/lib/features/orchestrator/   # 1 hit (body_slot.dart)

# No /api/ URL strings in widgets
grep -rn "/api/" frontend/lib/features/orchestrator/presentation/widgets/  # empty

# Orchestrator service is the only mutator of JobBooking.status
grep -rn "\\.status =" backend/bookings/   # orchestrator.py + instant_book_service.py + job_request_action.py + tasks.py only

# All 5 new event types present
grep -E "quoteRevisionRequested|quoteDeclined|bookingCancelled|bookingNoShow|bookingRescheduled" frontend/lib/core/realtime/domain/entities/system_event_type.dart

# Modal endpoint registry documented
grep -n "Modal endpoint registry" frontend/lib/features/orchestrator/ORCHESTRATOR_FEATURE.md

# Folder rename completed
ls frontend/lib/features/orchestrator/presentation/widgets/status_bodies/all_status_bodies.dart
```

### flag.md final state

```bash
grep -n "^## 26" flag.md                                    # ✅ Resolved (strikethrough + summary block)
grep -n "^## 28" flag.md                                    # still present, updated with sprint-end context (NOT a new entry)
grep -n "^## 34" flag.md                                    # auto-no-show-detection-deferred — opened by 6a
grep -n "eventlog-retention-policy" flag.md                 # present at next-available number (~#35)
grep -c "AI chatbot dispute intake" flag.md                 # 1 (only #28 — no duplicate)
```

---

## §7 What this session does NOT fix

- AI chatbot dispute intake — flag #29 future sprint.
- Auto no-show detection — flag #28 future sprint (opened by 6a).
- EventLog retention/cleanup — opened this session as a flag; deferred to ops sprint.
- Reviews / ratings — separate sprint.
- Real wallet writes — finance sprint.
- iOS foreground location service — flag #10.
- Per-tech / per-service geofence radius config — env-level only.
- Per-tech / per-service no-show threshold config — hardcoded 15min.
- Receipt PDF / share / export — out of v1.
- Polished animation transitions between status changes — micro-polish, not v1.
- Stitch design tokens applied to orchestrator — planned UI cleanup pass per memory.

---

## §8 Definition of done

### Code

- [ ] Dispute (9 files) created.
- [ ] `DisputedBodyStub` and `UnknownBodyStub` replace placeholders.
- [ ] Folder rename `stub_bodies/` → `status_bodies/`; file rename `all_status_stubs.dart` → `all_status_bodies.dart`; import in `body_slot.dart` updated. All in one commit.
- [ ] `app_router.dart` adds `/booking/:job_id/dispute` route.
- [ ] `image_picker` added to pubspec (if not present); AndroidManifest permissions updated.
- [ ] `bookings/admin.py` resolve view polished.
- [ ] `bookings/templates/admin/bookings/supportticket/resolve.html` polished.
- [ ] `dependency_injection.dart` registers dispute notifier + repository.

### Tests

- [ ] `flutter test` green on full suite.
- [ ] `pytest -q` (backend) green.
- [ ] All new dispute tests pass (repository, notifier, screen, banner).
- [ ] `polished_stubs_test.dart` extended (not rewritten) with `DisputedBodyStub` + `UnknownBodyStub` cases on top of 6a's 5-stub baseline. Final test file covers all 7 polished stubs.
- [ ] `test_admin_resolve_dispute_polish.py` covers happy path, missing-field rejection, already-resolved rejection, redirect target.
- [ ] Tech-offline banner integration test passes.

### Acceptance test (manual)

- [ ] All 9 acceptance tests in §6 pass on a physical Android device.

### Constraints (per CLAUDE.md + sprint meta)

- [ ] Single `switch (booking.status)` (in `body_slot.dart`).
- [ ] No `/api/` URL strings in widgets.
- [ ] Tech sees no dispute or reschedule buttons (per §14 rule 5).
- [ ] Tech-cancel only in overflow menu (per §14 rule 6).
- [ ] No-show is single-tap with single confirmation (per §14 rule 7).
- [ ] Server is authoritative on `available_transitions`; frontend doesn't pre-validate.

### Documentation

- [ ] `ORCHESTRATOR_FEATURE.md` final pass: complete coverage of all 14 transitions, all 14 statuses (13 + `Unknown`), all event types, all modal endpoints, the SLA countdown widget, the dispute flow, the admin resolve flow.
- [ ] CLAUDE.md amendments added in the right sections (stream consumer pattern, WS upstream subscribe contract, modal endpoint registry).

### flag.md

- [ ] Flag #26 resolved with strikethrough + ✅ + date + "What changed" block.
- [ ] Existing flag #28 (`AI chatbot dispute intake — schema seam present, module deferred`) **updated** with sprint-end "What changed" context — orchestrator landed, FORM intake is now the live writer, chatbot adapter remains the gap. **NOT re-opened as a new entry**.
- [ ] New flag `eventlog-retention-policy-tbd` opened at next-available number (**#35** at spec-write time; verify via `tail flag.md`).
- [ ] `grep -c "AI chatbot dispute intake" flag.md` returns exactly 1 (no duplicate).

### Sprint completion

- [ ] All 8 session files exist in `booking_orchestrator_sprint/` (`session_1`, `session_2`, `session_3`, `session_4`, `session_5a`, `session_5b`, `session_6a`, `session_6b`).
- [ ] `BOOKING_ORCHESTRATOR_SPRINT.md` reflects sprint completion (no outstanding `[TBD]` markers).
- [ ] `git status` clean.
- [ ] Final commit message: `feat(orchestrator): dispute + admin polish + sprint completion (sprint v1, session 6b)`.
- [ ] Sprint demo recorded (optional but recommended).

---

## §9 Sprint wrap-up note (this is the last session)

Eight sessions delivered the full booking orchestrator end-to-end (post-split):

- **Session 1**: backend foundations — status enum, models, finance ports, central orchestrator service.
- **Session 2**: backend HTTP + WS — every transition endpoint, `tech_gps` stream, dynamic subgroup subscription, admin resolve action.
- **Session 3**: frontend skeleton — one screen, slot architecture, per-event notifiers, stubs for every status.
- **Session 4**: live tracking — dual-provider maps, Android foreground GPS service, customer-side stream consumer, polyline + ETA, offline banner.
- **Session 5a**: tech-side quote authoring — chip-stack quote builder + sub-service catalog + `start_inspection` auto-flip + `InspectingBodyStub` + `QuotedBodyStub` tech-path.
- **Session 5b**: customer approval + cash + receipts — modal registry foundation, 3-action approval card, single-tap cash with offline hard-block, receipt cards, mid-job upsell, remaining stubs.
- **Session 6a**: cancel + reschedule + no-show + SLA countdown + tech-cancel overflow + 5 polished stubs.
- **Session 6b**: dispute + admin polish + sprint-end CLAUDE.md amendments + flag #26 closure + final 2 stubs + sprint demo + integration tests.

**What's next** (post-sprint):
- Finance sprint — `WalletTransaction`, `JobCommission`, JazzCash top-up, real adapter for the finance ports.
- AI chatbot adapter sprint — replaces dispute form intake; `dispute_intake_method='CHATBOT'` becomes live.
- iOS foreground location — flag #10 (requires Mac).
- Reviews / ratings — separate small sprint.
- Production hardening — self-hosted OSRM (or Mapbox), Google Maps API key provisioning, distributed `tech_location` throttling, EventLog retention task (the flag opened this session).

The architecture should support all of these as additive sessions — no orchestrator code needs to change.

---

*End of 6b. Sprint complete.*

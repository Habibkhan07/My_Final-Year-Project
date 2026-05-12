# Audit — Remaining Bugs (Medium + Low)

Snapshot of the 32 bugs left from the 57-item SQA audit, after the
critical + high tiers were fixed (25/57 done, 2026-05-12). None are
demo-blocking; the booking-detail / orchestrator / quote / cash flow
is correctness-clean for viva. These are polish, edge cases, and
architectural smells worth picking up post-viva.

**Status:** 904/904 backend tests + 1224/1224 frontend tests passing
as of last fix cycle. Any changes below should preserve that.

---

## 🟡 MEDIUM — 25 items

### Time / date formatting drift

#### #26 — Orchestrator hero subtitle uses device clock, no ticker
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/orchestrator_hero_header.dart:191-201`
- **What:** `_dynamicSubtitle()` calls `DateTime.now()` (device clock) AND is a pure function — the hero "Sent 3 min ago / Arrived 2 min ago" pill never re-renders on a ticker. Only refreshes when an event invalidates the detail provider.
- **Why:** Line 193 anchors on device wall clock; phone with wrong clock reads wrong "ago". Lines 196-200 compute once at build, no Timer drives a tick → tech who arrived 2 min ago will read "Arrived 2 min ago" twenty minutes later.
- **Fix:** Two parts. (1) Plumb `server_time` from the booking-detail response and anchor `ago()` on it. (2) Wrap `_StatusPill` (or the subtitle widget) in a 30s `Timer.periodic` that triggers `setState` — same pattern as `up_next_job_card.dart:49-51`.

#### #27 — AWAITING subtitle uses `scheduledStart` instead of `createdAt`
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/orchestrator_hero_header.dart:212`
- **What:** Pattern `ago(ts.acceptedAt ?? booking.scheduledStart)` falls through to a FUTURE time when AWAITING (acceptedAt is always null in that state). Subtitle always reads "Sent just now" even after 5 minutes.
- **Fix:** Use `booking.createdAt`. Requires plumbing `createdAt` into `BookingDetail` / `PhaseTimestamps`. The list-card entity already has it (`customer_booking.dart`).

#### #28 — `BookingSummaryCard._formatSlot` uses `DateTime.now()`
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/slots/booking_summary_card.dart:148-155`
- **What:** Today/Tomorrow decision anchored on device wall clock.
- **Fix:** Anchor on server-anchored now from the detail response (same plumbing as #26).

#### #29 — `timeline_slot.dart` hardcodes `DateFormat('h:mm a')`
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/slots/timeline_slot.dart:237`
- **What:** Ignores device locale (24h vs 12h, AM/PM-vs-Western). Hardcoded English format string.
- **Fix:** `DateFormat.jm()` — same locale-aware helper used elsewhere.

#### #30 — `customer_booking_mapper.dart` falls back to `DateTime.now()` on bad `server_time`
- **File:** `frontend/lib/features/customer/bookings/data/mappers/customer_booking_mapper.dart:95-105`
- **What:** Line 103 returns `DateTime.now().toUtc()` on a parse failure — silently swaps server anchor for device clock, defeating the no-DateTime.now invariant the formatter relies on.
- **Fix:** Surface a `CustomerBookingsServerFailure` on `server_time` parse failure (contract violation) or fall back to `DateTime.tryParse(items.first.scheduledStart)?.subtract(...)`. Anything anchored to server data, not device.

#### #31 — `booking_detail_mapper.dart` no try/catch on `DateTime.parse`
- **File:** `frontend/lib/features/orchestrator/data/mappers/booking_detail_mapper.dart:85-86`
- **What:** `DateTime.parse(model.scheduledStart)` throws on malformed string. One bad timestamp from server breaks entire detail screen with generic error.
- **Fix:** Mirror the list-mapper's `_parseIsoOrNow` helper. Log loudly on fallback.

#### #32 — `customer_bookings_local_data_source.dart` uses `DateTime.now()` for `cached_at`
- **File:** `frontend/lib/features/customer/bookings/data/data_sources/customer_bookings_local_data_source.dart:92`
- **What:** Device-clock skew → banner shows "yesterday" or "in 3 hours" wrong.
- **Fix:** Persist `cached_at = response.server_time` (already in the response payload).

#### #33 — Offline banner "last updated X ago" doesn't re-tick
- **File:** `frontend/lib/features/customer/bookings/presentation/widgets/bookings_offline_banner.dart:29-30, 83-93`
- **What:** `_ageLabel(minutes)` runs once per rebuild against frozen `serverNow`. Age string stuck at fetch-time.
- **Fix:** Once the list-card has the 30s ticker (already shipped in Fix #1), let the banner piggy-back on the same setState.

### Quote builder polish

#### #34 — Quote builder silent disable on out-of-band
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/sheets/quote_builder_sheet.dart:182-220`
- **What:** `_isLineValid` returns false on band violation; Submit greys with no error text, no red field border, no per-line indicator. Tech sees disabled button and doesn't know why.
- **Fix:** Add `errorText` on `TextField` decoration when `!_isLineValid(line) && priceController.text.isNotEmpty`. Use the band-hint string: "Must be Rs. 500 – Rs. 2,000".

#### #35 — `_maybeSeedFirstLine` mutates state in `build()`
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/sheets/quote_builder_sheet.dart:269-313`
- **What:** Inside `AsyncValue.when` data branch, writes to `line.priceController.text` and `_seeded`. State mutation during build — works today because `_seeded` blocks the second invocation, but a future setState-triggering edit here would loop.
- **Fix:** Defer: `WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSeedFirstLine(catalog))`.

#### #36 — `line.chosen!` force-unwrap inside `_submit`
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/sheets/quote_builder_sheet.dart:191`
- **What:** Safe today (`_canSubmit` guards null) but a state-change race during submit could expose it.
- **Fix:** `final chosen = line.chosen; if (chosen == null) return;` inside the loop.

#### #37 — `help_sheet` support branch uses post-pop context
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/sheets/help_sheet.dart:170-177`
- **What:** Captures `ScaffoldMessenger.of(context)` AFTER `Navigator.pop`. Context invalidated; SnackBar may not appear in newer Flutter releases.
- **Fix:** Capture messenger BEFORE pop (cancel branch at lines 134-138 already does this correctly — copy the pattern).

### Backend state-graph polish

#### #38 — `admin_resolve_dispute` can't resolve to NO_SHOW
- **File:** `backend/bookings/services/orchestrator.py:1452-1456`
- **What:** `_VALID_FINAL_STATUSES` is `{COMPLETED, COMPLETED_INSPECTION_ONLY, CANCELLED}` — no `NO_SHOW`. If a tech disputes a customer-filed no-show and admin reviews evidence and decides to uphold the no-show, they cannot.
- **Fix:** Add `JobBooking.STATUS_NO_SHOW` to `_VALID_FINAL_STATUSES`. Update `tests/bookings/services/test_orchestrator.py::TestAdminResolveDispute`.

#### #39 — `dev_panel._mirror_event` is redundant + double-fires
- **File:** `backend/bookings/management/commands/dev_panel.py:271, 274-301`
- **What:** Orchestrator now broadcasts to both sides via `_broadcast_both` (after Fix #10). The dev_panel mirror creates a SECOND envelope with a different UUID → FE dedup doesn't collapse it → `realtime_eventlog` table fills with duplicates. Practically harmless (Riverpod collapses) but noisy.
- **Fix:** Delete `_mirror_event` and `_ACTION_EVENT_TYPE` from `dev_panel.py`. Orchestrator does both sides now.

#### #40 — `_fallback` shows `show_dispute_button: True`
- **File:** `backend/bookings/selectors/orchestrator_ui.py:676`
- **What:** Defensive _fallback handler returns True for `show_dispute_button` — contradicts `feedback_dispute_visibility` memory (True only on COMPLETED / COMPLETED_INSPECTION_ONLY / NO_SHOW).
- **Fix:** Change line 676 to `False`. Orchestrator's `open_dispute` still 400s on disallowed states; the fallback shouldn't tempt the UI.

#### #41 — Tech-ARRIVED still emits `tech_cancel` inline
- **File:** `backend/bookings/selectors/orchestrator_ui.py:298-300`
- **What:** Tech-ARRIVED secondary_actions still includes the tech-cancel action. Per `feedback_cancel_vs_no_show` memory the frontend hides cancel behind Help and surfaces no-show as a cancel-reason. Inline cancel here violates that placement.
- **Fix:** Verify how FE renders secondary_actions. If inline, route tech_cancel through Help-menu fetched-list instead of base `secondary_actions`. Frontend-only fix is acceptable; backend can keep the action available so Help can render it.

#### #42 — Cash collection rejects legitimate Rs.0
- **File:** `backend/bookings/services/orchestrator.py:982-988`
- **What:** Rejects `cash_amount_d <= 0` but when quote total == `inspection_fee` exactly, `final_cash_to_collect` floors to 0 and the tech can't complete the booking (gets "Cash amount must be positive").
- **Fix:** Allow zero when server-computed expected is zero: `if cash_amount_d < 0 or (cash_amount_d == 0 and expected != 0)`. Or drop the positive guard since the strict-equality below already catches mismatches.

#### #43 — Redundant unlocked status pre-fetch
- **File:** `backend/bookings/api/tech_location/views.py:163-192` + `backend/bookings/services/auto_transition.py:60-67`
- **What:** `auto_transition.evaluate_on_location` re-reads `JobBooking` OUTSIDE the orchestrator's atomic block to check status, then calls `orchestrator.en_route/arrived`. Orchestrator re-locks and re-checks (safe), but the unlocked read is wasted.
- **Fix:** Inline the address coord lookup the orchestrator already does inside `_lock_booking()` and remove the auto_transition pre-fetch. Optional, perf-only.

### Frontend wiring polish

#### #44 — `later_today_list` empty `onTap` ripples for nothing
- **File:** `frontend/lib/features/technician/dashboard/presentation/widgets/later_today_list.dart:71`
- **What:** InkWell `onTap: () { /* TODO */ }` — splash ripple, no action. Looks broken.
- **Fix:** Wire to `/booking/$jobId` (one line: `GoRouter.of(context).push('/booking/${job.jobId}')`). Entity already has `jobId`.

#### #45 — Dashboard DI providers bare `@riverpod`
- **File:** `frontend/lib/features/technician/dashboard/presentation/providers/dependency_injection.dart:27, 37, 44`
- **What:** `technicianDashboardRemoteDataSource`, `LocalDataSource`, `Repository` are bare `@riverpod` (keepAlive: false). Inconsistent with orchestrator's `keepAlive: true` convention; full provider tree disposes between dashboard visits.
- **Fix:** Mark all three `@Riverpod(keepAlive: true)` for consistency. Costs nothing.

#### #46 — `quotableSubServicesNotifier` keepAlive without eviction
- **File:** `frontend/lib/features/orchestrator/presentation/providers/quotable_sub_services_notifier.dart:19`
- **What:** Per-serviceId cache grows unbounded. Tech servicing 20 service categories holds 20 cached lists until logout.
- **Fix:** Either `keepAlive: false` (re-fetch per sheet open) or add LRU eviction via `ref.cacheFor`.

#### #47 — `chatMessage` routes to /shared/chat but no chat feature
- **File:** `frontend/lib/core/realtime/presentation/router/event_urgency_router.dart` chatMessage entry
- **What:** Banner-tap route exists, placeholder screen now exists (Fix #7), but no chat thread state, no unread counter notifier. Banner is informational only.
- **Fix:** When the chat feature ships, replace the `_ComingSoonScreen` placeholder with a real thread list + unread notifier that listens to `chatMessage` events.

#### #48 — `onWalletBalanceEvent` / `onForcedOfflineEvent` are partially dead
- **File:** `frontend/lib/features/technician/dashboard/presentation/notifiers/technician_dashboard_notifier.dart:108-134`
- **What:** Mostly resolved by Fix #8 — the dashboard notifier now listens to `systemEventProvider` and calls `refresh()` on relevant events. But the *patch methods* (`onWalletBalanceEvent` reading the new balance from the payload, `onForcedOfflineEvent`) are still no-callers in production code. Currently the dashboard does a full refetch instead of patching the balance field.
- **Fix:** Either (a) delete the patch methods + their docstrings, or (b) wire them from the `ref.listen` switch when those events arrive — single-field patch avoids the full GET round-trip.

#### #49 — Orchestrator events notifier mount-window race
- **File:** `frontend/lib/features/orchestrator/presentation/providers/booking_orchestrator_events_notifier.dart:31`
- **What:** `keepAlive: false` notifier wakes only on screen mount. ~50ms window between `Navigator.push` and `initState` running `ref.watch(...)` — an event arriving in that gap is missed.
- **Fix:** Acceptable risk (GET hydrates fresh data, document in flag.md). Alternative: re-fetch once on first `WsConnected` event after mount, similar to tracking subscription's reconnect-replay.

#### #50 — Inline 403 envelope builders duplicate contract
- **File:** `backend/bookings/api/transitions/views.py:40` + `quotes/views.py:28` + `terminations/views.py:24` + `completion/views.py:29` + `tech_location/views.py:77`
- **What:** Multiple views build the 403 `not_a_technician_response` / `not_a_customer_response` envelope by hand instead of `raise PermissionDenied(detail=...)` and letting the DRF custom handler shape.
- **Fix:** Optional refactor — replace inline helpers with `raise PermissionDenied(detail=...)`. The handler at `core/common/failures/exception.py:57-60` already standardizes that path. Pragmatically the contract is correct today; collapse on the next backend cleanup pass.

---

## 🟢 LOW — 7 items

#### #51 — Const-correctness misses across orchestrator
- **File:** `up_next_job_card.dart` + `dashboard_metrics_row.dart` + others
- **What:** Several inner `Text` constructors omit `const` even though their arguments are all literals.
- **Fix:** Run `flutter analyze --no-fatal-infos | grep prefer_const` to enumerate; add `const` where suggested.

#### #52 — Test-detection via runtimeType string
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/orchestrator_hero_header.dart:357-360`
- **What:** `runtimeType.toString().contains('Test')` — brittle string heuristic.
- **Fix:** Use `shouldLoopAnimations()` from `core/animations/loop_mode.dart` (the canonical helper used by `meeting_countdown_button.dart` and `orchestrator_skeleton.dart`).

#### #53 — Cancel-sheet copy tautology
- **File:** `frontend/lib/features/orchestrator/presentation/widgets/sheets/cancel_reason_sheet.dart:165-167`
- **What:** `_isTechFlow ? 'Why are you cancelling?' : 'Why are you cancelling?'` — both branches identical; the ternary was clearly meant to differentiate.
- **Fix:** Tech branch: `'Why are you cancelling this job?'`. Trivial.

#### #54 — `tracking_subscription_controller.ref.onDispose` reads mutable field
- **File:** `frontend/lib/features/orchestrator/presentation/providers/tracking_subscription_controller.dart:104-127`
- **What:** Dispose hook reads `_subscribed` after stream-sub cancellation. Currently safe (Dart fields outlive ref disposal) but fragile pattern.
- **Fix:** Add a regression test that exercises dispose-after-unsubscribe and dispose-while-subscribed paths. No code change needed unless dispose semantics ever change.

#### #55 — Inner `Text` const omissions
- **File:** `up_next_job_card.dart`, `dashboard_metrics_row.dart`
- **What:** Duplicate of #51 — covered there.

#### #56 — Dev path is hidden non-negotiable
- **File:** `backend/bookings/management/commands/dev_panel.py` / README
- **What:** dev_panel `[4]` is now auto-started on depart (Fix #3) but the workflow is still not documented anywhere developers would find it without reading source.
- **Fix:** Add a one-paragraph note in `CLAUDE.md` or `README.md`: "For end-to-end demo on web, run `python manage.py dev_panel` and use [2]/[3]/[5]-[9] to walk a booking through all states. GPS sim auto-starts on [3] depart."

#### #57 — `wipe_bookings.py` PROTECT FK ordering is load-bearing
- **File:** `backend/bookings/management/commands/wipe_bookings.py`
- **What:** Currently safe (BookingItem deleted before JobBooking cascade — PROTECT on `BookingItem.sourced_quote`). Order is documented in code comments but a future refactor could re-order without realizing.
- **Fix:** Add an integration test that asserts wipe_bookings completes successfully against a fixture with BookingItem rows. Catches reordering regressions.

---

## Summary table

| Severity | Count | Effort to clear all |
|---|---|---|
| Medium | 25 | ~12-16 hr |
| Low | 7 | ~2-3 hr |
| **Total** | **32** | **~14-19 hr** |

Recommended order if picking up post-viva:

1. **Quick wins (~2h):** #29, #36, #37, #39, #40, #44, #45, #46, #53, #56
2. **Time/date polish pass (~3h):** #26, #27, #28, #30, #31, #32, #33 — most share the same root-cause (need server-anchored now plumbed through detail) and can be batched
3. **Backend state-graph (~1.5h):** #38, #41, #42, #43, #50
4. **Quote builder polish (~1h):** #34, #35
5. **Architecture (~2h):** #47 (chat feature), #48 (dashboard patches), #49 (mount race)
6. **Test additions (~1h):** #54, #57
7. **Lint cleanup (~30min):** #51, #52, #55

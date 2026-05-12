# Customer-Side Chrome Test Runbook

End-to-end verification of every `BookingOrchestratorScreen` state with the
customer client running in Chrome. No Android device or emulator required.

The "tech device" is faked two ways:

1. **Status transitions** — `manage.py drive_booking <id> <action>` calls the
   real orchestrator service functions, so events broadcast over the WebSocket
   exactly as a real tech app would.
2. **Live GPS during EN_ROUTE / ARRIVED** — `scripts/fake_tech_gps.py` POSTs
   to the same `/tech-location/` endpoint the Android foreground service uses.

---

## Phase 0 — One-time setup

```bash
# Terminal 1 — backend
cd backend
./venv/bin/python manage.py runserver 0.0.0.0:8000

# Terminal 2 — fixtures + first booking
cd backend
./venv/bin/python manage.py seed_test_fixtures --count 5
# Note printed: BOOKING_IDS, CUSTOMER_TOKEN, TECH_TOKEN

# Terminal 3 — customer client on Chrome
cd frontend
flutter run -d chrome --dart-define=MAP_PROVIDER=osm
```

**CORS check:** if Chrome console shows CORS errors against `localhost:8000`,
add the Flutter web port (printed by `flutter run`) to
`CORS_ALLOWED_ORIGINS` in `backend/core/settings.py`. Common ports: 5000,
8080, anything Flutter assigned.

**Login:** customer phone `+923002222222`, OTP `123456` (DEBUG mode — fixed,
no Twilio). Open the booking from the printed `BOOKING_IDS` list.

---

## Phase 1 — Walk every state

Run from a fourth terminal. Each row creates ONE state on the Chrome tab.
Substitute `<id>` with a booking id from the seeder output; substitute
`<tech_token>` with `TECH_TOKEN`.

| # | Status | Command | Verify on Chrome |
|---|---|---|---|
| 1 | AWAITING | (initial — set by seeder) | Schedule icon, "Awaiting tech accept" body |
| 2 | CONFIRMED | `python manage.py drive_booking <id> confirm` | Header pill flips to CONFIRMED, check_circle_outline icon |
| 3 | EN_ROUTE | `python manage.py drive_booking <id> depart` | LiveTrackingMap fills body, "Waiting for technician's location…" pill appears |
| 3a | + GPS frames | (separate terminal) `python scripts/fake_tech_gps.py --booking-id <id> --token <tech_token>` | Tech marker fades in, polyline draws, ETA pill shows "~N min · X.X km" |
| 3b | weak signal | switch the script to `--mode stop_60s` | At t=15s amber "Connection is weak…" banner; at t=60s orange "tech offline" banner |
| 3c | recovery | switch to `--mode drop_then_recover` | Banner clears within one frame after resume |
| 4 | ARRIVED | `python manage.py drive_booking <id> arrive` | Map shrinks to ~220px, walking-person marker, "Tech is at your door" copy |
| 5 | INSPECTING | `python manage.py drive_booking <id> start_inspection` | Search icon, "Inspection in progress" body |
| 6 | QUOTED | `python manage.py drive_booking <id> quote` | _QuoteCard with total + line items, footer Approve/Revise/Decline CTAs |
| 7a | back to INSPECTING (revise) | `python manage.py drive_booking <id> revise_quote` (or tap Revise on Chrome) | Returns to inspecting body; quote marked SUPERSEDED |
| 7b | IN_PROGRESS | `python manage.py drive_booking <id> approve_quote` (or tap Approve) | build_outlined icon, "Work in progress" body |
| 7c | upsell quote | `python manage.py drive_booking <id> quote --upsell --items "<sub_id>:800:1"` | New _QuoteCard appears while booking stays IN_PROGRESS |
| 7d | terminal: COMPLETED_INSPECTION_ONLY | (use a fresh booking up through QUOTED) `drive_booking <id2> decline_quote` | Receipt icon, "Inspection only" copy |
| 8 | COMPLETED | `python manage.py drive_booking <id> complete_cash` | check_circle, "Job complete" body, payment receipt |
| 9 | CANCELLED | (fresh booking) `drive_booking <id3> cancel --as customer` | event_busy icon, terminal |
| 10 | REJECTED | (fresh AWAITING) `drive_booking <id4> reject` | do_not_disturb icon, terminal |
| 11 | NO_SHOW | (fresh booking, drive to ARRIVED first) `drive_booking <id5> no_show --actor tech --force` | person_off icon, terminal |
| 12 | DISPUTED | (fresh booking, drive past AWAITING) `drive_booking <id6> dispute --reason "Quality"` | gavel icon, "Disputed" body, transitions locked |
| 13 | RESCHEDULED | (fresh AWAITING) `drive_booking <id7> reschedule --in-hours 3` | Original flips CANCELLED, new child booking surfaces |

**Sub-service id for `--items`:** read it from the seeder output printed in
Phase 0 (the `Freon Gas Top-up` row in `catalog.SubService`). The default
`drive_booking <id> quote` (no `--items`) auto-uses the booking's own
`sub_service` at its base price, which is what most rows above rely on.

---

## Phase 2 — Realtime guarantees

Sanity checks on the pipeline behind the UI.

### Reconnect re-subscribe

While EN_ROUTE with `fake_tech_gps` running:

1. Stop backend Terminal 1 (Ctrl+C).
2. Wait 5–10 seconds (Chrome's `WsConnectionNotifier` should show
   "reconnecting…" in dev tools).
3. Start backend again.
4. `TrackingSubscriptionController` re-issues `subscribe_tracking` on the
   `WsConnected` event — frames resume without restarting `fake_tech_gps`.

### Recipient filter

Open a second customer (different phone, e.g. `+923003333333` — sign up
fresh through the Chrome client). Seed a separate booking for them and
drive it to EN_ROUTE in another tab. The first customer's tab MUST NOT
receive frames for the second booking. (`SystemEventNotifier` filters by
`recipientUserId == currentAuthUserIdProvider`.)

### Throttle handshake

Run `fake_tech_gps --interval 2 ...` (faster than the backend's 4s
window). Expect `~ HTTP 429` markers in the script output every other
frame; the customer map should keep updating smoothly because the data
source treats 429 as silent drop. No error banner.

---

## Phase 3 — Cross-state edges

- **Cancel from each non-terminal state**: AWAITING, CONFIRMED, EN_ROUTE,
  ARRIVED, INSPECTING, QUOTED. Each should flip the body stub immediately
  via WS event; the EN_ROUTE/ARRIVED `tech_gps` subscription tears down on
  next status read.
- **Customer-cancel during IN_PROGRESS** is rejected by service. Verify the
  `drive_booking <id> cancel --as customer` invocation prints the canonical
  envelope code (`cancellation_not_allowed` or similar) — Chrome stays on
  IN_PROGRESS.
- **Open dispute from non-AWAITING/REJECTED states**: status flips to
  DISPUTED on the first ticket; subsequent `dispute` calls leave status
  alone but still create new tickets (visible in Django Admin).

---

## Phase 4 — Reset between runs

```bash
# Hand out a fresh batch of AWAITING bookings without re-logging-in:
./venv/bin/python manage.py seed_test_fixtures --count 5
```

The seeder is idempotent for users + catalog — only the bookings are new
each run. Chrome stays logged in.

To wipe everything (incl. terminal-state bookings cluttering the DB):

```bash
./venv/bin/python manage.py shell -c "from bookings.models import JobBooking; JobBooking.objects.all().delete()"
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Chrome stuck on "Waiting for technician's location…" | `fake_tech_gps` not running, or 4xx on first POST | Check the script's stdout — it prints HTTP status per frame |
| Banner says "tech offline" but script is running | Frame interval > 60s, or backend dropped the WS group | Set `--interval 5`; check Daphne logs for `tracking_job_<id>` group_send |
| `drive_booking` errors `not_assigned_to_you` | The booking's tech FK is wrong (you're using an old booking from a previous fixture set) | Re-seed: `seed_test_fixtures --count 1` |
| `drive_booking ... no_show` errors `no_show_too_early` | `--force` flag missing | Pass `--force` (script auto-builds a fake clock past the 15-min wait) |
| `drive_booking ... complete_cash` errors `invalid_input` | Booking has no approved quote → `final_cash_to_collect` is null | Run `quote` then `approve_quote` first, or pass `--amount 1500` |
| Chrome doesn't react to `drive_booking` calls | CORS / WS not connected | Open Chrome dev tools → Network → WS tab; should show `/ws/events/` open |

---

## Artifacts

- `backend/bookings/management/commands/seed_test_fixtures.py` — Phase 0 seeder
- `backend/bookings/management/commands/drive_booking.py` — state driver
- `backend/scripts/fake_tech_gps.py` — GPS frame generator
- `booking_orchestrator_sprint/customer_chrome_test_runbook.md` — this file

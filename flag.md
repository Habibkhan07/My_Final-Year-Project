# flag.md — Tech Debt Log

Living list of accepted shortcuts. Each entry has: **what's wrong**, **why we shipped it anyway**, **the proper fix**, and **where to look**. New flags go at the bottom; resolved flags get struck through with the commit/PR that closed them.

---

## 1. `JobBooking.accepted_at` — booking state encoded in a side field

**Where**
- Field: `backend/bookings/models.py` (`JobBooking.accepted_at`, nullable `DateTimeField`)
- Migration: `backend/bookings/migrations/0004_jobbooking_accepted_at.py`
- Consumer: `backend/bookings/tasks.py` (`expire_pending_job_booking`)
- Producer (future, not yet wired): the technician-acceptance endpoint that will set `accepted_at = timezone.now()`.

**What's wrong**
The "is this booking still awaiting technician acknowledgement?" signal is encoded as **two coupled fields**: `status == CONFIRMED` AND `accepted_at IS NULL`. That's two sources of truth for one piece of state. Future code that checks only `status` will miss the "awaiting accept" case; future code that checks only `accepted_at` will miss bookings cancelled by the customer before the tech responded. Every consumer has to remember to `AND` both.

**Why we shipped it**
The pre-existing API contract for `POST /api/bookings/instant-book/` says **"Creates a CONFIRMED JobBooking after passing four sequential defensive checks."** Changing the initial status to a new `AWAITING_TECH_ACCEPT` value would have rippled through:

- `BOOKINGS_API.md` (contract text)
- The slot-conflict overlap check in `instant_book_service.py` (currently filters `status__in=[PENDING, CONFIRMED]` — would need to add the new state)
- Frontend Active Job Screen logic (Tier 3 cache shape, status switch in the UI)
- Any analytics / dashboard selectors that key off status

That ripple was out of scope for the dispatch-event sprint. The additive `accepted_at` column gave us the SLA-task signal we needed without breaking the existing contract.

**The proper fix**
Introduce an explicit pre-acceptance state and collapse the two fields into one:

1. Add `STATUS_AWAITING_TECH_ACCEPT = 'AWAITING'` (or similar) to `JobBooking.STATUS_CHOICES`.
2. Change `instant_book_service.create_instant_booking` to create bookings in this state, not `CONFIRMED`.
3. The technician-acceptance endpoint flips `AWAITING → CONFIRMED`.
4. The SLA task flips `AWAITING → REJECTED` (or a new `EXPIRED` status if we want to distinguish "tech declined" from "tech timed out").
5. Drop `accepted_at`. If we want acceptance audit, replace it with a `BookingStatusHistory` table — proper modeling for a state machine.
6. Update the slot-overlap filter to include the new status.
7. Update `BOOKINGS_API.md` to describe the new lifecycle.

When picking this up, search the repo for `accepted_at` and `STATUS_CONFIRMED` together — those are the two patterns that need to migrate in lockstep.

---

## ~~2. `service_name = price_context` — wrong field, wrong reason~~ ✅ Resolved (2026-04-28)

Resolved by introducing real catalog FKs on `JobBooking` and a server-side resolver that classifies every booking into one of three `booking_type` values (`INSPECTION` / `FIXED_GIG` / `LABOR_GIG`).

**What changed**
- `JobBooking` now carries `service` (NOT NULL), `sub_service`, and `promotion` FKs — captures the customer's discovery intent at booking time.
- `POST /api/bookings/instant-book/` accepts `service_id` (required), `sub_service_id` / `promotion_id` (optional). Threaded from the same query params already on `/profile/{id}/` and `/availability/{id}/`. `price_context` dropped from ingress; server-derived now.
- New shared resolver `bookings.selectors.pricing_selector.resolve_booking_intent` — single source of truth for catalog-based pricing across reads and writes. Read paths (technician profile, home feed) refactored to consume it.
- Write-path validations: catalog consistency, promo firewall, price equality (or labor range), with field-level error envelopes.
- `job_new_request` event payload now carries `booking_type` + `payout_context` so the technician's job card can route to the correct on-site flow (Complete vs. Build Quote) and frame the headline payout correctly. Closes the reject-from-confusion failure mode on inspection bookings.
- `price_context` column kept on `JobBooking` as the customer-receipt label; it's now server-authoritative (one of `"Inspection Fee"` / `"Fixed Price"` / `"Labor Fee"`).

**Out of scope, deferred** — see flags 3, 4, 5 below. The originally proposed `JobBookingSubService` M2M was deferred to the quote-builder sprint where it earns its weight; at booking time the FK trio captures intent without it.

---

## ~~3. `TechnicianSkill.base_rate` / `max_rate` — labor pricing as a range~~ ✅ Resolved (2026-04-28)

Resolved by collapsing `TechnicianSkill` to a single `labor_rate` field. The booking write path now requires exact equality across all booking types (fixed, labor, inspection); the resolver's Scenario B branch shrinks to two cases (skill present vs. fallback).

**What changed**
- `TechnicianSkill.max_rate` removed; `base_rate` renamed to `labor_rate` (still nullable — null falls back to `sub_service.base_price`). Migration `technicians/0007_collapse_skill_rate_to_labor_rate.py` is `RemoveField(max_rate)` + `RenameField(base_rate → labor_rate)` — zero production data, no backfill.
- `bookings.selectors.pricing_selector.ResolvedIntent.primary_amount_max` removed; range formatting (`"Rs. 1,000 - 1,400"`) deleted.
- `bookings.services.instant_book_service._assert_price_in_bounds` is now a one-liner equality check across all booking types.
- `PriceMismatchError` simplified — single `expected` field, single error message form (`"Expected X, got Y"`).
- Onboarding ingress: `SkillInputSerializer` exposes `labor_rate` only (no `max_rate`); same on the Flutter `SkillInputModel` / `SkillSelectionEntity`.
- Frontend Step 5 onboarding screen now has a single labor-rate input. Notifier method `updateSkillRates` renamed to `updateSkillRate`.
- API docs updated: `BOOKINGS_API.md` price-validation row, `ONBOARDING_API.md` skill object detail.

**Unblocks** — flag #4 (server-derived `price_amount`). Now that labor pricing is deterministic from `service_id` / `sub_service_id` / `promotion_id` + the technician's skill row, the server can stop accepting `price_amount` on the wire.

---

## ~~4. Client-supplied `price_amount` — server should derive it~~ ✅ Resolved (2026-04-29)

Resolved by removing `price_amount` from the wire entirely. With flag #3's single-`labor_rate` collapse in place, the resolver's `intent.primary_amount` is a deterministic single value across all booking types, so the server can stamp it onto `JobBooking.price_amount` directly with no client input or re-validation step.

**What changed**
- `price_amount` dropped from `InstantBookSerializer` and from the `create_instant_booking` service signature.
- Booking creation now uses `price_amount=intent.primary_amount` — single source of truth lives in the pricing resolver.
- `_assert_price_in_bounds` and `PriceMismatchError` deleted; the view's `except PriceMismatchError` handler and the corresponding `400 — Price Mismatch` envelope are gone.
- `BOOKINGS_API.md` request-body table no longer lists `price_amount`; sample bodies for Scenarios A/C/D are slimmed down; the Defensive Check Pipeline shrinks from seven steps to six (Geofence → 5, Slot Race Lock → 6).
- §2.1 / §2.2 frontend contract sections updated — the field-keyed validation-error dictionary shrinks to two entries (`sub_service_id`, `promotion_id`).
- Flutter side: `priceAmount` removed from `InstantBookingRequestModel`, `IBookingRepository.createInstantBooking`, `CreateInstantBookingUseCase`, `InstantBookingNotifier.book`, and the `ReviewBookingSheet` call site. The `_resolveErrorPresentation` `price_amount` toast branch is deleted (the server can no longer return that error key).
- `TechnicianProfileEntity.primaryPrice` / `primaryPriceRaw` stay — they drive the review-sheet display, which the customer confirms before the server stamps the same figure.

---

## 5. Quote-phase `JobBookingSubService` M2M — deferred from flag #2

**Where (planned)**
- New model: `backend/bookings/models.py` (`JobBookingSubService` join table)
- Write path: a quote-builder service module (does not exist yet) populated from the technician's on-site Build Quote screen.

**What's wrong (today)**
A booking row knows the *initial* catalog reference (via the FK trio resolved in flag #2), but it has no record of the line items the technician actually performed during the visit. For inspection bookings the technician arrives, diagnoses, and quotes some set of sub-services; for fixed/labor gigs the technician may add line items if the customer agrees on-site. None of that is currently expressible in the schema.

**Why we shipped it that way**
Flag #2's scope was "stop using `price_context` as a service identifier." The M2M earns its weight only in the quote-building flow, and the quote builder is a sprint of its own (technician on-site UI, customer approval flow, commission accounting against per-line-item `priced_at`). Bundling that work into flag #2 would have multiplied the scope.

**The proper fix**
1. Add `JobBookingSubService` join table with fields `booking` (FK), `sub_service` (FK), `priced_at` (Decimal), `created_via` (enum: `INITIAL` | `QUOTE` | `ON_SITE_ADD`), `created_at`. The `created_via` discriminator preserves "what was pre-agreed" vs. "what the technician built on-site."
2. New service `bookings.services.quote_builder.build_quote(booking, line_items)` — populates the M2M for `INSPECTION` bookings.
3. New service `bookings.services.line_items.add_line_item(booking, sub_service, priced_at)` — `FIXED_GIG` / `LABOR_GIG` extension flow with customer approval gate.
4. Audit downstream events (`quote_generated`, `quote_approved`, `job_completed`) — surface sub-services on the wire.
5. Commission accounting moves from `JobBooking.price_amount × 0.80` to a per-line-item sum.

When picking this up, the technician's on-site UX is the design-heavy part — the data model is straightforward.

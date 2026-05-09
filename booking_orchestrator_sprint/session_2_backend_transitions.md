# Session 2 — Backend Transitions, Endpoints, and Realtime Wiring

> Second session of the Booking Orchestrator sprint. Wires the orchestrator service from session 1 to the HTTP and WebSocket layers. Ships every transition endpoint, the booking-detail read endpoint, the `tech_gps` stream, the WS consumer's dynamic tracking-subgroup mechanism, and the Django Admin "Resolve dispute" action.
>
> **Out of scope:** any Flutter work, real wallet operations, AI chatbot intake, iOS push, the orchestrator screen UI itself.

---

## §0 Sprint context

This is **session 2 of 6** in the booking orchestrator sprint. Cross-cutting decisions live in [`BOOKING_ORCHESTRATOR_SPRINT.md`](./BOOKING_ORCHESTRATOR_SPRINT.md). Session 1 (`session_1_backend_foundations.md`) shipped the data layer + service layer (orchestrator, finance ports, auto_transition, models, migrations, factories, service tests). This session is the HTTP and WS surface that calls into that service layer.

Session 1 invariants this session relies on:
- `bookings/services/orchestrator.py` exists with all 14 transition functions implemented and tested.
- `bookings/services/auto_transition.py::evaluate_on_location` exists.
- `bookings/services/finance_ports.py::FinancePort` Protocol + `bookings/adapters/null_finance.py::NullFinanceAdapter` wired via `get_default_finance_service()`.
- All 5 new event types declared in `realtime/constants/event_types.py` and registered in `EVENT_REGISTRY`.
- Models + migrations applied: `Quote`, `QuoteLineItem`, `BookingItem`, `SupportTicket`, `TicketEvidence`, `BookingAttachment`, `JobBooking` extended columns, `SubService.max_price`.

What sessions 3–6 will add on top of this session:
- **Session 3** — Frontend `BookingOrchestratorScreen` skeleton + per-event notifiers + booking-detail provider hydration consuming the `GET /api/bookings/<id>/` endpoint shipped here.
- **Session 4** — Dual-provider live tracking; tech-side foreground GPS service POSTing to the `tech_location` ingress endpoint shipped here; customer-side stream consumer subscribing via the WS subgroup mechanism shipped here.
- **Session 5** — Quote builder + customer approval + cash collection UIs calling the quote/completion endpoints shipped here.
- **Session 6** — Cancellation, no-show, dispute UIs calling the termination endpoints shipped here; closes flag #26.

This session touches **only** backend HTTP / WebSocket / admin / docs. No Flutter, no model/migration changes.

---

## §1 Decisions taken (session-local only)

Cross-sprint decisions are in sprint meta §4. Decisions specific to this session:

1. **Endpoint folder structure**: 6 feature-group subfolders under `bookings/api/`, mirroring the existing pattern (`instant_book/`, `job_actions/`, `customer_list/`):
   - `transitions/` — phase markers (start_inspection, en_route, arrived). Manual-override endpoints; the auto path is via `tech_location`.
   - `quotes/` — submit, approve, decline, request_revision.
   - `completion/` — confirm_cash_received (the combined "Mark Complete + Cash Collected" per §14 rule 2).
   - `terminations/` — customer_cancel, tech_cancel, no_show, open_dispute, reschedule.
   - `tech_location/` — GPS ingress; calls `auto_transition.evaluate_on_location` AND publishes the `tech_gps` stream.
   - `booking_detail/` — single-booking read with full UI hints.
2. **One view class per endpoint**, in `views.py` of the relevant folder. One serializer per endpoint, in `serializers.py` of the same folder. Matches existing pattern.
3. **Permission-check inline at the top of each view** (matches existing `job_actions/views.py`). Don't introduce DRF permission classes for one-off scope checks; the inline pattern keeps the view body readable.
4. **Booking-detail UI hint resolution lives in `bookings/selectors/orchestrator_ui.py`** (new) — pure function `resolve_orchestrator_ui(booking, viewer)` returning a dict that the serializer embeds verbatim under `ui`. Mirrors the existing `_resolve_ui_block` pattern in `customer_bookings_selector.py`.
5. **`available_transitions` is computed by `bookings/selectors/transition_validator.py`** (new) — pure function `available_transitions(booking, viewer) -> list[str]`. The orchestrator's transition functions remain authoritative for actually validating; this selector is a *projection* of the same rules for UI hints. Both must stay in sync (test-enforced).
6. **WS consumer accepts ONLY two upstream message types**: `subscribe_tracking` and `unsubscribe_tracking`. All other client messages still ignored (CLAUDE.md amendment per sprint meta §10).
7. **Subscribe authorization at the consumer**: subscriber must be the booking's customer or technician. Non-participants are silently dropped (no error frame to avoid leaking booking existence). Audit-log a warning.
8. **`tech_location` ingress is rate-limited at 4 seconds per tech-booking pair** to absorb 5s tick clock drift. Implemented as in-memory throttle (per CLAUDE.md, no Redis dependency for ratelimiting in v1).
9. **Geofence strictness** is env-controlled: `BOOKING_GEOFENCE_STRICT=False` (default) means the `arrived` manual endpoint warn-logs a mismatch but allows the transition; `BOOKING_GEOFENCE_STRICT=True` rejects with `400 not_at_customer_location`. Auto path (`auto_transition`) is unaffected — it never auto-flips on a mismatch.
10. **Admin "Resolve dispute" custom action** lives in `bookings/admin.py` as a Django Admin model action, not a REST endpoint. Form: outcome (radio), notes (textarea), final_status (select). Submit calls `orchestrator.admin_resolve_dispute`. No new URL.
11. **API docs are extended in this session**, not deferred. `BOOKINGS_API.md` gets all the new endpoints; new `STREAMS_TECH_GPS.md` documents the stream contract; existing `EVENT_DISPATCH_API.md` gets a one-line addition for each new event type.
12. **One test file per endpoint folder**, mirroring the source structure. Each test file covers: auth (401 for unauthenticated), authorization (403 for wrong role), happy path (200 + payload shape), error envelope per validation failure, idempotency where applicable.
13. **WS consumer tests use `channels.testing.WebsocketCommunicator`** (existing pattern in realtime test suite if present, otherwise introduce it).
14. **Booking-detail endpoint has NO HTTP cache** (audit P1-04). v0.9 added `@cache_control(private=True, max_age=5)`, but realtime-event-driven re-fetches would silently hit cached responses for up to 5s — defeating the realtime patching architecture. The mount-and-rare-refetch access pattern doesn't justify the cache. Drop the decorator.

15. **Audit-cycle-1 fixes shipped this session** (see [`AUDIT.md`](./AUDIT.md) and sprint meta §25): tech_profile related_name (P0-02), `core/settings.py` path (P0-06), customer phone via UserProfile (P1-01), tech profile_picture URL (P1-02), no cache_control (P1-04), in-memory throttle accepted with flag (P1-07), image upload size cap (P1-10), `_can_subscribe` rejects terminal-status bookings (P2-07), URL ordering shown explicitly (P1-13). Each is annotated inline with the audit ID.

---

## §2 Files this session touches

### Backend HTTP — endpoint folders (all new)

| Folder | New files | Purpose |
|---|---|---|
| `backend/bookings/api/transitions/` | `__init__.py`, `views.py`, `serializers.py` | start_inspection, en_route, arrived (3 endpoints). |
| `backend/bookings/api/quotes/` | `__init__.py`, `views.py`, `serializers.py` | submit_quote, approve_quote, decline_quote, request_revision (4 endpoints). |
| `backend/bookings/api/completion/` | `__init__.py`, `views.py`, `serializers.py` | confirm_cash_received (1 endpoint). |
| `backend/bookings/api/terminations/` | `__init__.py`, `views.py`, `serializers.py` | customer_cancel, tech_cancel, mark_no_show, open_dispute, reschedule (5 endpoints). |
| `backend/bookings/api/tech_location/` | `__init__.py`, `views.py`, `serializers.py` | tech_location GPS ingress (1 endpoint; calls auto_transition + publishes stream). |
| `backend/bookings/api/booking_detail/` | `__init__.py`, `views.py`, `serializers.py` | GET booking detail with UI hints (1 endpoint). |

### Backend HTTP — URL routing (modified)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/api/urls.py` | **modified** | Wire all 6 new feature-group URL families. |

### Backend selectors (new)

| File | Purpose |
|---|---|
| `backend/bookings/selectors/orchestrator_ui.py` | `resolve_orchestrator_ui(booking, viewer)` — produces the `ui` dict for the booking-detail response. |
| `backend/bookings/selectors/transition_validator.py` | `available_transitions(booking, viewer) -> list[str]` — projection of orchestrator validation for UI hints. |

### Backend WebSocket consumer (modified)

| File | Status | Purpose |
|---|---|---|
| `backend/realtime/events/consumers.py` | **modified** | Accept `subscribe_tracking` / `unsubscribe_tracking` upstream messages. Add per-booking authorization check. |

### Backend admin (modified)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/admin.py` | **modified** | "Resolve dispute" custom action on `SupportTicketAdmin`. |

### Backend settings (modified)

| File | Status | Purpose |
|---|---|---|
| `backend/core/settings.py` (or wherever the project settings live) | **modified** | `BOOKING_GEOFENCE_STRICT = env.bool('BOOKING_GEOFENCE_STRICT', default=False)`. |
| `backend/.env.example` | **modified** | Document the new env var. |

### Backend API docs (modified + new)

| File | Status | Purpose |
|---|---|---|
| `backend/bookings/api/BOOKINGS_API.md` | **modified** | Append §3–§13 covering all new endpoints. |
| `backend/realtime/api/STREAMS_TECH_GPS.md` | **new** | Stream contract for `tech_gps`. |
| `backend/realtime/api/EVENT_DISPATCH_API.md` | **modified** | One line per new event type in the registry table. |

### Backend tests (all new)

| File | Purpose |
|---|---|
| `backend/tests/bookings/test_api_transitions.py` | start_inspection, en_route, arrived endpoint tests. |
| `backend/tests/bookings/test_api_quotes.py` | submit, approve, decline, request_revision tests. |
| `backend/tests/bookings/test_api_completion.py` | confirm_cash_received tests. |
| `backend/tests/bookings/test_api_terminations.py` | customer_cancel, tech_cancel, no_show, open_dispute, reschedule tests. |
| `backend/tests/bookings/test_api_tech_location.py` | GPS ingress endpoint tests (auto-transition firing, stream publish, throttling). |
| `backend/tests/bookings/test_api_booking_detail.py` | GET endpoint tests (auth, UI hints, available_transitions, query count). |
| `backend/tests/bookings/test_selectors_orchestrator_ui.py` | UI hint resolution tests per status × viewer-role matrix. |
| `backend/tests/bookings/test_selectors_transition_validator.py` | Sync between transition validator and orchestrator (test-enforced). |
| `backend/tests/realtime/test_consumer_tracking_subscribe.py` | WS upstream message handling + authorization. |
| `backend/tests/bookings/test_admin_resolve_dispute.py` | Admin custom action wires correctly to orchestrator. |

### Files NOT touched

- `backend/bookings/services/*` — session 1 shipped these; this session calls them as-is.
- `backend/bookings/models.py`, all migrations — session 1; no schema changes here.
- `backend/realtime/events/services/event_dispatch_service.py`, `backend/realtime/streams/dispatch.py` — used as-is.
- All `backend/bookings/api/{instant_book,job_actions,customer_list}/*` — already shipped, untouched.
- All `frontend/` — sessions 3–6.

---

## §3 Pre-flight

```bash
# 1. Repo baseline
cd /home/hamayon-khan/Development/my_fyp_project
git status
git pull origin main

# 2. Confirm session 1 landed correctly
ls backend/bookings/services/orchestrator.py
ls backend/bookings/services/auto_transition.py
ls backend/bookings/services/finance_ports.py
ls backend/bookings/adapters/null_finance.py

# 3. Confirm session 1 migrations applied
cd backend
source venv/bin/activate
python manage.py showmigrations bookings | grep 0008    # should be (X)
python manage.py showmigrations catalog | grep 0009     # should be (X)

# 4. Confirm session 1 service-layer tests are green
pytest tests/bookings/test_services_orchestrator.py -q
pytest tests/bookings/test_services_auto_transition.py -q
pytest tests/bookings/test_finance_ports.py -q

# 5. Confirm full baseline still green (no regressions from session 1)
pytest -q

# 6. Confirm Daphne + WebSocket layer alive (we'll be modifying consumer)
python manage.py runserver &
sleep 2
# Existing WS endpoint should still respond
python manage.py shell -c "from realtime.events.consumers import SystemEventConsumer; print('consumer OK')"
kill %1

# 7. Confirm env machinery in place
grep -n "django-environ\|environ" backend/core/settings.py | head -3
```

If session 1's tests don't pass, do not proceed — fix session 1 first.

---

## §4 Per-file detailed changes

### §4.0 Canonical endpoint pattern

Every transition endpoint follows this exact shape. Departures must be justified in the file's leading docstring.

```python
# backend/bookings/api/<group>/views.py

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.services import orchestrator
from bookings.exceptions import BookingValidationError
from bookings.models import JobBooking
from .serializers import StartInspectionRequestSerializer, StartInspectionResponseSerializer


class StartInspectionView(APIView):
    """POST /api/bookings/<id>/start-inspection/

    Tech-only. Flips ARRIVED → INSPECTING. Triggered when the tech opens the
    quote builder UI (per §14 rule 1, the navigation IS the trigger), but the
    explicit endpoint exists for robustness — frontend may call it directly.

    Idempotent on already-INSPECTING.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, booking_id: int):
        # SECURITY: only the booking's assigned technician (validated inside orchestrator)
        # can transition. Inline early-out check for non-tech users to avoid leaking
        # booking existence via 404 vs 403 distinction.
        if not hasattr(request.user, 'tech_profile'):
            return Response(
                {'status': 403, 'code': 'not_a_technician', 'message': 'Tech-only action.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            booking = orchestrator.start_inspection(
                booking_id=booking_id,
                technician_user=request.user,
            )
        except JobBooking.DoesNotExist:
            return Response(
                {'status': 404, 'code': 'not_found', 'message': 'Booking not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except BookingValidationError as exc:
            # Standard envelope handler kicks in via DRF exception_handler;
            # raise to let it format. Only catch-and-format here if we need
            # to add endpoint-specific context.
            raise

        return Response(
            StartInspectionResponseSerializer(booking).data,
            status=status.HTTP_200_OK,
        )
```

```python
# backend/bookings/api/<group>/serializers.py

from rest_framework import serializers
from bookings.models import JobBooking


class StartInspectionRequestSerializer(serializers.Serializer):
    """No body fields. Endpoint takes booking_id from URL."""
    pass


class StartInspectionResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'inspection_started_at']
```

The pattern's invariants:

1. View body is ≤30 lines. All business logic lives in the orchestrator.
2. Permission check is inline at the top, returning 403 with the standard envelope.
3. Orchestrator call is wrapped in `try/except` for `DoesNotExist` (404) only. `BookingValidationError` propagates to the standard DRF handler.
4. Response serializer returns a minimal payload — `{id, status, <relevant_timestamps>}`. Full booking detail is fetched separately via `GET /api/bookings/<id>/`.
5. No business logic. No DB queries (other than what the orchestrator does internally). No realtime broadcasts (orchestrator handles those).

### §4.1 `bookings/api/transitions/`

#### `views.py` (canonical example covers `StartInspectionView`)

`StartInspectionView` — see §4.0.

`EnRouteView` — `POST /api/bookings/<id>/en-route/`. Manual override (auto path is via `tech_location`). Same shape as StartInspectionView; calls `orchestrator.en_route(..., source='manual')`.

`ArrivedView` — `POST /api/bookings/<id>/arrived/`. Manual override. Same shape; calls `orchestrator.arrived(..., source='manual')`. **Geofence check**: if `settings.BOOKING_GEOFENCE_STRICT` is True AND request body includes `current_lat, current_lng`, the view computes Haversine distance to the customer address and rejects with `400 not_at_customer_location` if >100m. Lenient (default) mode logs a warning but allows.

#### `serializers.py`

```python
class EnRouteRequestSerializer(serializers.Serializer):
    pass

class EnRouteResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'en_route_started_at']


class ArrivedRequestSerializer(serializers.Serializer):
    current_lat = serializers.FloatField(required=False)
    current_lng = serializers.FloatField(required=False)

class ArrivedResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'arrived_at']


class StartInspectionResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'inspection_started_at']
```

### §4.2 `bookings/api/quotes/`

Four views. All follow the canonical shape.

#### `SubmitQuoteView` — `POST /api/bookings/<id>/quotes/`

Tech-only. Body:
```json
{
  "is_upsell": false,
  "line_items": [
    {"sub_service_id": 17, "quantity": 1, "priced_at": "1500.00"}
  ]
}
```

Validates input shape via serializer; passes to `orchestrator.submit_quote`. Quote validation (band check, empty rejection) happens inside orchestrator and surfaces via `BookingValidationError`. Returns `{quote_id, revision_number, status, total_amount, line_items}`.

#### `ApproveQuoteView` — `POST /api/bookings/<id>/quotes/<quote_id>/approve/`

Customer-only. No body. Calls `orchestrator.approve_quote`. Returns `{booking_id, status: 'IN_PROGRESS', items: [...]}` (the snapshotted BookingItem rows).

#### `DeclineQuoteView` — `POST /api/bookings/<id>/quotes/<quote_id>/decline/`

Customer-only. Body: `{reason: "..."}` (optional). Calls `orchestrator.decline_quote`. Returns `{booking_id, status: 'COMPLETED_INSPECTION_ONLY', final_cash_to_collect}`.

#### `RequestRevisionView` — `POST /api/bookings/<id>/quotes/<quote_id>/request-revision/`

Customer-only. Body: `{reason: "..."}` (optional). Calls `orchestrator.request_revision`. Returns `{booking_id, status: 'INSPECTING', superseded_quote_id}`.

#### `serializers.py` for quotes

```python
class QuoteLineItemInputSerializer(serializers.Serializer):
    sub_service_id = serializers.IntegerField()
    quantity = serializers.IntegerField(min_value=1, default=1)
    priced_at = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0)


class SubmitQuoteRequestSerializer(serializers.Serializer):
    is_upsell = serializers.BooleanField(default=False)
    line_items = QuoteLineItemInputSerializer(many=True, allow_empty=False)


class QuoteLineItemResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    sub_service_id = serializers.IntegerField()
    sub_service_name = serializers.CharField(source='sub_service.name')
    quantity = serializers.IntegerField()
    priced_at = serializers.DecimalField(max_digits=10, decimal_places=2)
    line_total = serializers.DecimalField(max_digits=10, decimal_places=2)


class QuoteResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    booking_id = serializers.IntegerField()
    revision_number = serializers.IntegerField()
    status = serializers.CharField()
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    is_upsell = serializers.BooleanField()
    line_items = QuoteLineItemResponseSerializer(many=True)
    submitted_at = serializers.DateTimeField()


class DeclineQuoteRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, max_length=2000)


class RequestRevisionRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, max_length=2000)
```

### §4.3 `bookings/api/completion/`

Single view: `ConfirmCashReceivedView` — `POST /api/bookings/<id>/confirm-cash-received/`.

Tech-only. **Combined complete + cash collection per §14 rule 2** — there is no separate `mark_complete` endpoint. Body:
```json
{ "amount": "1500.00", "method": "cash" }
```

Validates `amount > 0`. Calls `orchestrator.mark_complete_with_cash`. Returns `{booking_id, status: 'COMPLETED', cash_collected_amount, cash_collected_at}`.

#### `serializers.py` for completion

```python
class ConfirmCashReceivedRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0.01)
    method = serializers.ChoiceField(choices=[('cash', 'Cash')], default='cash')

class ConfirmCashReceivedResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'cash_collected_amount', 'cash_collected_at', 'cash_collection_method', 'completed_at']
```

### §4.4 `bookings/api/terminations/`

Five views. All canonical shape.

#### `CustomerCancelView` — `POST /api/bookings/<id>/cancel/`

Customer-only (booking.customer == request.user). No body. Calls `orchestrator.cancel_by_customer`. Returns `{booking_id, status: 'CANCELLED', cancel_reason, final_cash_to_collect}`.

#### `TechCancelView` — `POST /api/bookings/<id>/tech-cancel/`

Tech-only. Body: `{reason: "..."}` (optional, for admin reliability log). Calls `orchestrator.cancel_by_tech`. Returns `{booking_id, status: 'CANCELLED', cancel_reason}`.

#### `MarkNoShowView` — `POST /api/bookings/<id>/no-show/`

Either tech or customer (validated against booking.customer / booking.technician.user). Body: `{actor_role: "tech"|"customer"}` — but the view ignores user-supplied role and derives it from the authenticated user's relationship to the booking (security: don't trust client). Calls `orchestrator.mark_no_show(actor_user, actor_role)`. Returns `{booking_id, status: 'NO_SHOW', no_show_actor}`.

**Time guard**: 
- If `actor_role='tech'`: reject with `400 no_show_too_early` unless `arrived_at + 15min` has passed (computed at view layer to avoid orchestrator coupling to wall-clock thresholds).
- If `actor_role='customer'`: reject with `400 no_show_too_early` unless `scheduled_start + 15min` has passed without `arrived_at` being set.

#### `OpenDisputeView` — `POST /api/bookings/<id>/disputes/`

Either tech or customer. Body multipart:
- `initial_reason` (string, required, ≤2000 chars)
- `photo` (file, optional)

Calls `orchestrator.open_dispute(opener_user, initial_reason, photo_file)`. Returns `{ticket_id, booking_id, booking_status: 'DISPUTED', dispute_intake_method: 'FORM'}`.

#### `RescheduleView` — `POST /api/bookings/<id>/reschedule/`

Customer-only. Body:
```json
{
  "new_scheduled_start": "2026-05-20T15:00:00+05:00",
  "new_scheduled_end": "2026-05-20T17:00:00+05:00"
}
```

Calls `orchestrator.reschedule`. Returns `{original_booking_id, original_status: 'CANCELLED', child_booking_id, child_status: 'AWAITING'}`.

#### `serializers.py` for terminations

```python
class CustomerCancelRequestSerializer(serializers.Serializer):
    pass

class CustomerCancelResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'cancel_reason', 'final_cash_to_collect']


class TechCancelRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(required=False, allow_blank=True, max_length=500)

class TechCancelResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'cancel_reason']


class MarkNoShowRequestSerializer(serializers.Serializer):
    pass  # actor_role derived from auth, not body

class MarkNoShowResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ['id', 'status', 'no_show_actor', 'no_show_at']


class OpenDisputeRequestSerializer(serializers.Serializer):
    initial_reason = serializers.CharField(min_length=10, max_length=2000)
    photo = serializers.ImageField(required=False, allow_null=True)

    # Audit P1-10: bound the upload size. DRF's ImageField does Pillow-validation
    # (rejects malformed images) but doesn't bound file size. 5 MB is generous
    # for a phone camera photo and cheap to enforce.
    MAX_PHOTO_BYTES = 5 * 1024 * 1024

    def validate_photo(self, photo):
        if photo and photo.size > self.MAX_PHOTO_BYTES:
            raise serializers.ValidationError(
                f'Photo must be under {self.MAX_PHOTO_BYTES // (1024 * 1024)} MB.'
            )
        return photo

class OpenDisputeResponseSerializer(serializers.Serializer):
    ticket_id = serializers.IntegerField()
    booking_id = serializers.IntegerField()
    booking_status = serializers.CharField()
    dispute_intake_method = serializers.CharField()


class RescheduleRequestSerializer(serializers.Serializer):
    new_scheduled_start = serializers.DateTimeField()
    new_scheduled_end = serializers.DateTimeField()

    def validate(self, attrs):
        if attrs['new_scheduled_end'] <= attrs['new_scheduled_start']:
            raise serializers.ValidationError({
                'new_scheduled_end': 'Must be after new_scheduled_start.'
            })
        return attrs

class RescheduleResponseSerializer(serializers.Serializer):
    original_booking_id = serializers.IntegerField()
    original_status = serializers.CharField()
    child_booking_id = serializers.IntegerField()
    child_status = serializers.CharField()
```

### §4.5 `bookings/api/tech_location/`

Single view: `TechLocationIngressView` — `POST /api/bookings/<id>/tech-location/`.

Tech-only (booking's assigned tech). Body:
```json
{ "lat": 31.5204, "lng": 74.3587, "accuracy_meters": 8.5, "heading": 145.0 }
```

Flow:
1. Permission check + booking fetch (no `select_for_update` — read-only path).
2. **Throttle**: in-memory cache keyed `(tech_id, booking_id)` with 4-second TTL. Reject second call within 4s with `429 too_many_requests` (no envelope; just plain 429).
3. Publish stream frame: `publish_stream(stream_type='tech_gps', group=f'tracking_job_{booking_id}', payload={lat, lng, accuracy_meters, heading, booking_id, timestamp})`.
4. Call `auto_transition.evaluate_on_location(booking_id=<id>, lat=lat, lng=lng, technician_user=request.user)`.
5. Return `{published: true, transition_fired: <new_status_or_null>}`.

**Booking status guard**: if booking is in a terminal status, view returns `200` but does NOT publish or auto-transition (silently no-ops, since the tech app might still be sending stale frames during the transition window).

#### `serializers.py` for tech_location

```python
class TechLocationRequestSerializer(serializers.Serializer):
    lat = serializers.FloatField(min_value=-90.0, max_value=90.0)
    lng = serializers.FloatField(min_value=-180.0, max_value=180.0)
    accuracy_meters = serializers.FloatField(required=False, min_value=0.0)
    heading = serializers.FloatField(required=False, min_value=0.0, max_value=360.0)


class TechLocationResponseSerializer(serializers.Serializer):
    published = serializers.BooleanField()
    transition_fired = serializers.CharField(allow_null=True)
```

#### Stream-publish helper (must extend existing `publish_stream` if needed)

The existing `realtime/streams/dispatch.py::publish_stream(...)` may currently only support user-scoped groups (`USER_GROUP_TEMPLATE.format(user_id=...)`). This session's first action is to **extend it to accept an explicit `group` argument**:

```python
# backend/realtime/streams/dispatch.py (extension)

def publish_stream(*, user=None, group=None, stream_type: str, payload: dict[str, Any]) -> None:
    """Publish a transient stream frame to a channel-layer group.

    Group resolution:
    - If `group` is provided, send to that group directly (e.g. 'tracking_job_42').
    - Else if `user` is provided, send to the user's group (USER_GROUP_TEMPLATE).
    - Else: ValueError.

    No DB write, no FCM, no ACK. Drop on disconnect.
    """
    if group is None and user is None:
        raise ValueError('Either group or user must be provided.')
    if group is None:
        group = USER_GROUP_TEMPLATE.format(user_id=user.id)

    envelope = {
        'kind': 'stream',
        'streamType': stream_type,
        'timestamp': timezone.now().isoformat() + 'Z',
        'payload': payload,
    }
    try:
        channel_layer = get_channel_layer()
        async_to_sync(channel_layer.group_send)(group, {
            'type': 'system.stream',
            'message': envelope,
        })
    except Exception as e:
        logger.warning('publish_stream failed group=%s: %s', group, e)
```

If the existing signature already supports `group=`, no change needed; document the existing contract.

### §4.6 `bookings/api/booking_detail/`

Single view: `BookingDetailView` — `GET /api/bookings/<id>/`.

Either tech (booking.technician.user) or customer (booking.customer) of the booking. Returns the full payload that the orchestrator screen needs.

#### View

```python
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from bookings.models import JobBooking
from bookings.selectors.orchestrator_ui import resolve_orchestrator_ui
from bookings.selectors.transition_validator import available_transitions
from bookings.selectors.quote_selector import get_active_quote, list_booking_items
from bookings.selectors.dispute_selector import list_open_tickets
from .serializers import BookingDetailResponseSerializer


class BookingDetailView(APIView):
    permission_classes = [IsAuthenticated]

    # Audit P1-04: no HTTP cache. Mount-and-event-refetch pattern means the cache
    # would silently return stale data right when an event needs the fresh state.
    def get(self, request, booking_id: int):
        try:
            booking = (
                JobBooking.objects
                # Audit P1-01: prefetch customer.userprofile for the phone field.
                # Audit P1-02: technician.profile_picture is read for URL building.
                .select_related(
                    'customer', 'customer__userprofile',
                    'technician__user',
                    'address',
                    'service', 'sub_service', 'parent_booking',
                )
                .prefetch_related('items__sub_service', 'tickets__evidence')
                .get(id=booking_id)
            )
        except JobBooking.DoesNotExist:
            return Response(
                {'status': 404, 'code': 'not_found', 'message': 'Booking not found.'},
                status=404,
            )

        # SECURITY: scope to participants only
        is_customer = booking.customer_id == request.user.id
        # Audit P0-02: TechnicianProfile.user uses related_name='tech_profile'.
        is_technician = (
            hasattr(request.user, 'tech_profile')
            and booking.technician_id == request.user.tech_profile.id
        )
        if not (is_customer or is_technician):
            return Response(
                {'status': 403, 'code': 'not_a_participant', 'message': 'You are not a participant on this booking.'},
                status=403,
            )

        viewer_role = 'customer' if is_customer else 'technician'

        payload = {
            'booking': booking,
            'active_quote': get_active_quote(booking),
            'booking_items': list_booking_items(booking),
            'open_tickets_count': len(list_open_tickets(booking)),
            'ui': resolve_orchestrator_ui(booking, viewer=request.user, role=viewer_role),
            'available_transitions': available_transitions(booking, viewer=request.user, role=viewer_role),
        }

        return Response(
            BookingDetailResponseSerializer(payload, context={'request': request}).data,
            status=200,
        )
```

#### Response shape (serializer)

```python
class _ServiceMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    icon_name = serializers.CharField()


class _SubServiceMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    is_fixed_price = serializers.BooleanField()
    base_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    max_price = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)


class _AddressMiniSerializer(serializers.Serializer):
    label = serializers.CharField()
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    address_text = serializers.CharField()


class _TechnicianMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    display_name = serializers.CharField()
    profile_picture_url = serializers.CharField(allow_null=True)


class _CustomerMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    full_name = serializers.CharField()
    phone_no = serializers.CharField()


class _PhaseTimestampsSerializer(serializers.Serializer):
    accepted_at = serializers.DateTimeField(allow_null=True)
    en_route_started_at = serializers.DateTimeField(allow_null=True)
    arrived_at = serializers.DateTimeField(allow_null=True)
    inspection_started_at = serializers.DateTimeField(allow_null=True)
    quote_first_submitted_at = serializers.DateTimeField(allow_null=True)
    work_started_at = serializers.DateTimeField(allow_null=True)
    completed_at = serializers.DateTimeField(allow_null=True)


class _PricingSerializer(serializers.Serializer):
    inspection_fee = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    base_services_total = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    discount_applied = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    final_cash_to_collect = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    promo_code_snapshot = serializers.CharField(allow_null=True)
    promo_discount_snapshot = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)


class _CashCollectionSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True, source='cash_collected_amount')
    at = serializers.DateTimeField(allow_null=True, source='cash_collected_at')
    method = serializers.CharField()  # source='cash_collection_method' is implicit


class _UiActionSerializer(serializers.Serializer):
    label = serializers.CharField()
    endpoint = serializers.CharField()
    method = serializers.CharField()
    style = serializers.ChoiceField(choices=['primary', 'destructive', 'neutral'], required=False)


class _UiBlockSerializer(serializers.Serializer):
    status_label = serializers.CharField()
    body_text = serializers.CharField()
    primary_action = _UiActionSerializer(allow_null=True)
    secondary_actions = _UiActionSerializer(many=True, default=list)
    show_tracking = serializers.BooleanField()
    show_quote_card = serializers.BooleanField()
    show_dispute_button = serializers.BooleanField()
    tone = serializers.ChoiceField(choices=['positive', 'warning', 'negative', 'neutral', 'info'])


class BookingDetailResponseSerializer(serializers.Serializer):
    """Top-level shape consumed by frontend orchestrator screen."""
    # Composed via `to_representation` to handle the nested `payload` dict shape.
    # See the BookingDetailView for context.

    def to_representation(self, payload: dict):
        booking = payload['booking']
        request = self.context.get('request')

        # Audit P1-02: TechnicianProfile.profile_picture is an ImageField, not a URL.
        # Build absolute URI via request (matches existing technicians/selectors/dashboard_selector.py).
        tech_profile_url = None
        if booking.technician.profile_picture:
            tech_profile_url = booking.technician.profile_picture.url
            if request is not None:
                tech_profile_url = request.build_absolute_uri(tech_profile_url)

        # Audit P1-01: User has no `phone_no` — phone lives on accounts.UserProfile.
        # Defensive: UserProfile is OneToOne with related_name 'userprofile' (default
        # accessor for OneToOne to AUTH_USER_MODEL); a User without UserProfile
        # (legacy/system accounts) falls back to empty string.
        customer_phone = ''
        try:
            customer_phone = booking.customer.userprofile.phone or ''
        except AttributeError:
            customer_phone = ''

        return {
            'id': booking.id,
            'status': booking.status,
            'service': _ServiceMiniSerializer(booking.service).data,
            'sub_service': _SubServiceMiniSerializer(booking.sub_service).data if booking.sub_service else None,
            'technician': _TechnicianMiniSerializer({
                'id': booking.technician.id,
                'display_name': booking.technician.user.get_full_name() or booking.technician.user.username,
                'profile_picture_url': tech_profile_url,
            }).data,
            'customer': _CustomerMiniSerializer({
                'id': booking.customer.id,
                'full_name': booking.customer.get_full_name() or booking.customer.username,
                'phone_no': customer_phone,
            }).data,
            'address': _AddressMiniSerializer(booking.address).data if booking.address else None,
            'address_snapshot': booking.actual_address_snapshot,
            'scheduled_start': booking.scheduled_start.isoformat(),
            'scheduled_end': booking.scheduled_end.isoformat(),
            'phase_timestamps': _PhaseTimestampsSerializer(booking).data,
            'pricing': _PricingSerializer(booking).data,
            'cash_collection': _CashCollectionSerializer(booking).data,
            'parent_booking_id': booking.parent_booking_id,
            'cancel_reason': booking.cancel_reason,
            'no_show_actor': booking.no_show_actor,
            'active_quote': QuoteResponseSerializer(payload['active_quote']).data if payload['active_quote'] else None,
            'booking_items': QuoteLineItemResponseSerializer(payload['booking_items'], many=True).data,
            'open_tickets_count': payload['open_tickets_count'],
            'ui': _UiBlockSerializer(payload['ui']).data,
            'available_transitions': payload['available_transitions'],
        }
```

(Reuse `QuoteResponseSerializer` and `QuoteLineItemResponseSerializer` from `bookings/api/quotes/serializers.py` — cross-import is acceptable since they're in the same app.)

### §4.7 `bookings/api/urls.py` (modified)

**Audit P1-13**: show the full ordered urls.py to prevent dispatch surprises. Django resolves URLs in declaration order; literal-prefix paths (`'counts/'`, `'instant-book/'`) must come BEFORE the typed `'<int:booking_id>/'` catch-all-int pattern. The `<int:>` converter rejects non-numeric segments so "counts" wouldn't match anyway, but explicit ordering avoids future regressions.

```python
from django.urls import path

# Existing imports (do not change)
from bookings.api.customer_list.views import (
    CustomerBookingsListView, CustomerBookingsCountsView,
)
from bookings.api.instant_book.views import InstantBookView
from bookings.api.job_actions.views import (
    AcceptJobBookingView, DeclineJobBookingView,
)

# Sprint v1 — new feature folders
from bookings.api.transitions.views import StartInspectionView, EnRouteView, ArrivedView
from bookings.api.quotes.views import (
    SubmitQuoteView, ApproveQuoteView, DeclineQuoteView, RequestRevisionView,
)
from bookings.api.completion.views import ConfirmCashReceivedView
from bookings.api.terminations.views import (
    CustomerCancelView, TechCancelView, MarkNoShowView, OpenDisputeView, RescheduleView,
)
from bookings.api.tech_location.views import TechLocationIngressView
from bookings.api.booking_detail.views import BookingDetailView


# Order matters. Literal-prefix paths first, typed-catch-all paths after.
urlpatterns = [
    # 1. Bare-root and bare-subpath literals (existing)
    path('', CustomerBookingsListView.as_view(), name='customer-bookings-list'),
    path('counts/', CustomerBookingsCountsView.as_view(), name='customer-bookings-counts'),
    path('instant-book/', InstantBookView.as_view(), name='instant-book'),

    # 2. Typed-int booking detail (sprint v1) — comes BEFORE other <int:>/ paths
    #    so it acts as the canonical detail GET; transition POSTs below use the
    #    same prefix but a longer trailing path (Django picks the most-specific match).
    path('<int:booking_id>/', BookingDetailView.as_view(), name='booking-detail'),

    # 3. Existing tech action endpoints (already shipped)
    path('<int:pk>/accept/', AcceptJobBookingView.as_view(), name='accept-job-booking'),
    path('<int:pk>/decline/', DeclineJobBookingView.as_view(), name='decline-job-booking'),

    # 4. Phase markers (sprint v1, manual override path)
    path('<int:booking_id>/start-inspection/', StartInspectionView.as_view(), name='start-inspection'),
    path('<int:booking_id>/en-route/', EnRouteView.as_view(), name='en-route'),
    path('<int:booking_id>/arrived/', ArrivedView.as_view(), name='arrived'),

    # Quotes
    path('<int:booking_id>/quotes/', SubmitQuoteView.as_view(), name='submit-quote'),
    path('<int:booking_id>/quotes/<int:quote_id>/approve/', ApproveQuoteView.as_view(), name='approve-quote'),
    path('<int:booking_id>/quotes/<int:quote_id>/decline/', DeclineQuoteView.as_view(), name='decline-quote'),
    path('<int:booking_id>/quotes/<int:quote_id>/request-revision/', RequestRevisionView.as_view(), name='request-revision'),

    # Completion
    path('<int:booking_id>/confirm-cash-received/', ConfirmCashReceivedView.as_view(), name='confirm-cash-received'),

    # Terminations
    path('<int:booking_id>/cancel/', CustomerCancelView.as_view(), name='customer-cancel'),
    path('<int:booking_id>/tech-cancel/', TechCancelView.as_view(), name='tech-cancel'),
    path('<int:booking_id>/no-show/', MarkNoShowView.as_view(), name='no-show'),
    path('<int:booking_id>/disputes/', OpenDisputeView.as_view(), name='open-dispute'),
    path('<int:booking_id>/reschedule/', RescheduleView.as_view(), name='reschedule'),

    # GPS ingress (calls auto_transition + publishes stream)
    path('<int:booking_id>/tech-location/', TechLocationIngressView.as_view(), name='tech-location'),
]
```

### §4.8 `bookings/selectors/orchestrator_ui.py` (new)

```python
"""Resolve UI hints for the booking-detail response per status × viewer-role.

The frontend's BookingOrchestratorScreen (session 3) reads `ui.*` fields verbatim
and never branches on raw status. All copy + button labels + slot visibility
flow from this selector.

Mirrors the existing pattern in customer_bookings_selector._resolve_ui_block.
"""

from typing import Literal
from bookings.models import JobBooking


def resolve_orchestrator_ui(booking: JobBooking, *, viewer, role: Literal['customer', 'technician']) -> dict:
    """Returns the dict that becomes the `ui` block in the booking-detail response."""

    handler = _HANDLERS.get((booking.status, role))
    if handler is None:
        # Fallback for unknown / edge case
        return {
            'status_label': booking.get_status_display(),
            'body_text': '',
            'primary_action': None,
            'secondary_actions': [],
            'show_tracking': False,
            'show_quote_card': False,
            'show_dispute_button': True,
            'tone': 'neutral',
        }
    return handler(booking, viewer)


# ---- Per (status, role) handlers ----

def _customer_awaiting(booking, viewer):
    return {
        'status_label': 'Awaiting tech',
        'body_text': f'Waiting for {booking.technician.user.get_full_name()} to confirm…',
        'primary_action': None,
        'secondary_actions': [
            {'label': 'Cancel booking', 'endpoint': f'/bookings/{booking.id}/cancel/', 'method': 'POST', 'style': 'destructive'},
        ],
        'show_tracking': False,
        'show_quote_card': False,
        'show_dispute_button': False,
        'tone': 'warning',
    }

def _customer_confirmed(booking, viewer):
    return {
        'status_label': 'Confirmed',
        'body_text': f'{booking.technician.user.get_full_name()} confirmed your booking.',
        'primary_action': None,
        'secondary_actions': [
            {'label': 'Cancel (Rs.500 fee may apply)', 'endpoint': f'/bookings/{booking.id}/cancel/', 'method': 'POST', 'style': 'destructive'},
        ],
        'show_tracking': False,
        'show_quote_card': False,
        'show_dispute_button': False,
        'tone': 'positive',
    }

def _customer_en_route(booking, viewer):
    return {
        'status_label': 'On the way',
        'body_text': f'{booking.technician.user.get_full_name()} is on the way.',
        'primary_action': None,
        'secondary_actions': [
            {'label': 'Cancel (Rs.500 fee)', 'endpoint': f'/bookings/{booking.id}/cancel/', 'method': 'POST', 'style': 'destructive'},
        ],
        'show_tracking': True,            # map slot mounts
        'show_quote_card': False,
        'show_dispute_button': False,
        'tone': 'info',
    }

def _customer_arrived(booking, viewer):
    return {
        'status_label': 'Arrived',
        'body_text': f'{booking.technician.user.get_full_name()} has arrived.',
        'primary_action': None,
        'secondary_actions': [
            {'label': 'Cancel (Rs.500 fee)', 'endpoint': f'/bookings/{booking.id}/cancel/', 'method': 'POST', 'style': 'destructive'},
            {'label': 'Tech didn\'t show', 'endpoint': f'/bookings/{booking.id}/no-show/', 'method': 'POST', 'style': 'neutral'},
        ],
        'show_tracking': True,
        'show_quote_card': False,
        'show_dispute_button': False,
        'tone': 'positive',
    }

# ... handlers for INSPECTING, QUOTED, IN_PROGRESS, COMPLETED, COMPLETED_INSPECTION_ONLY,
#     CANCELLED, REJECTED, NO_SHOW, DISPUTED — for both customer and technician role.
# 13 statuses × 2 roles = 26 handlers. Keep them simple, one function each, no nesting.

_HANDLERS: dict[tuple[str, str], callable] = {
    (JobBooking.STATUS_AWAITING_TECH_ACCEPT, 'customer'): _customer_awaiting,
    (JobBooking.STATUS_CONFIRMED, 'customer'): _customer_confirmed,
    (JobBooking.STATUS_EN_ROUTE, 'customer'): _customer_en_route,
    (JobBooking.STATUS_ARRIVED, 'customer'): _customer_arrived,
    # ... 22 more entries
}
```

The full handler set is 26 functions. Each is small; no shared logic to factor out.

### §4.9 `bookings/selectors/transition_validator.py` (new)

```python
"""Project the orchestrator's transition validity rules into a list of
strings (orchestrator function names) that the frontend can use as button
gates. Must stay in sync with orchestrator's actual validation; tested.
"""

from typing import Literal
from bookings.models import JobBooking


def available_transitions(booking: JobBooking, *, viewer, role: Literal['customer', 'technician']) -> list[str]:
    """Return the orchestrator function names valid from current state for current viewer."""

    out: list[str] = []
    s = booking.status

    if role == 'technician':
        # Phase markers (manual override; auto path also exists)
        if s == JobBooking.STATUS_CONFIRMED:
            out.append('en_route')
        elif s == JobBooking.STATUS_EN_ROUTE:
            out.append('arrived')
        elif s == JobBooking.STATUS_ARRIVED:
            out.append('start_inspection')

        # Quotes (tech submits; customer decides)
        if s in (JobBooking.STATUS_INSPECTING, JobBooking.STATUS_IN_PROGRESS):
            out.append('submit_quote')

        # Completion (combined complete + cash)
        if s == JobBooking.STATUS_IN_PROGRESS:
            out.append('mark_complete_with_cash')

        # Tech cancel (any non-terminal except IN_PROGRESS — IN_PROGRESS uses dispute)
        if s in {
            JobBooking.STATUS_CONFIRMED, JobBooking.STATUS_EN_ROUTE,
            JobBooking.STATUS_ARRIVED, JobBooking.STATUS_INSPECTING,
            JobBooking.STATUS_QUOTED,
        }:
            out.append('cancel_by_tech')

        # No-show (tech reports customer no-show)
        if s in {JobBooking.STATUS_ARRIVED, JobBooking.STATUS_INSPECTING, JobBooking.STATUS_QUOTED}:
            # Time guard enforced at view, not here
            out.append('mark_no_show')

    elif role == 'customer':
        # Quote decisions
        if s == JobBooking.STATUS_QUOTED:
            out.extend(['approve_quote', 'decline_quote', 'request_revision'])

        # Cancel (with phase-aware fee, computed orchestrator-side)
        if s in {
            JobBooking.STATUS_AWAITING_TECH_ACCEPT, JobBooking.STATUS_CONFIRMED,
            JobBooking.STATUS_EN_ROUTE, JobBooking.STATUS_ARRIVED,
            JobBooking.STATUS_INSPECTING, JobBooking.STATUS_QUOTED,
        }:
            out.append('cancel_by_customer')

        # Reschedule (only AWAITING and CONFIRMED)
        if s in {JobBooking.STATUS_AWAITING_TECH_ACCEPT, JobBooking.STATUS_CONFIRMED}:
            out.append('reschedule')

        # No-show (customer reports tech no-show)
        if s in {JobBooking.STATUS_CONFIRMED, JobBooking.STATUS_EN_ROUTE, JobBooking.STATUS_ARRIVED}:
            # Time guard enforced at view
            out.append('mark_no_show')

    # Both roles: dispute is always possible on completed/in-progress bookings
    if s in {
        JobBooking.STATUS_IN_PROGRESS,
        JobBooking.STATUS_COMPLETED,
        JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
    } and not booking.tickets.filter(status='OPEN').exists():
        out.append('open_dispute')

    return out
```

The test suite `test_selectors_transition_validator.py` enumerates every (status, role) and asserts that `available_transitions` matches what the orchestrator would actually allow (call orchestrator for each, expect `BookingValidationError` for absent transitions).

### §4.10 `realtime/events/consumers.py` (modified)

Existing `SystemEventConsumer` is one-way (downstream). Extend `receive` to handle two upstream message types: `subscribe_tracking` and `unsubscribe_tracking`.

```python
import json
import logging
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async

from bookings.models import JobBooking

logger = logging.getLogger(__name__)


class SystemEventConsumer(AsyncJsonWebsocketConsumer):
    # ... existing connect/disconnect/system_event/system_stream methods ...

    async def receive_json(self, content, **kwargs):
        """Accept upstream subscribe/unsubscribe for tracking subgroups."""
        action = content.get('action')

        if action == 'subscribe_tracking':
            booking_id = content.get('booking_id')
            if not isinstance(booking_id, int):
                return  # silent drop
            allowed = await self._can_subscribe(self.user_id, booking_id)
            if not allowed:
                logger.warning('subscribe_tracking denied: user=%s booking=%s', self.user_id, booking_id)
                return
            await self.channel_layer.group_add(
                f'tracking_job_{booking_id}',
                self.channel_name,
            )
            self._tracking_subscriptions.add(booking_id)

        elif action == 'unsubscribe_tracking':
            booking_id = content.get('booking_id')
            if not isinstance(booking_id, int):
                return
            await self.channel_layer.group_discard(
                f'tracking_job_{booking_id}',
                self.channel_name,
            )
            self._tracking_subscriptions.discard(booking_id)

        # All other upstream messages: ignored (one-way consumer for everything else).

    async def disconnect(self, code):
        # Clean up any tracking subgroups before existing user-group cleanup.
        for booking_id in self._tracking_subscriptions:
            await self.channel_layer.group_discard(
                f'tracking_job_{booking_id}',
                self.channel_name,
            )
        self._tracking_subscriptions.clear()
        # ... existing cleanup ...

    @database_sync_to_async
    def _can_subscribe(self, user_id: int, booking_id: int) -> bool:
        try:
            booking = JobBooking.objects.only(
                'id', 'status', 'customer_id', 'technician_id'
            ).select_related('technician__user').get(id=booking_id)
        except JobBooking.DoesNotExist:
            return False
        # Audit P2-07: defense-in-depth — refuse to subscribe to a terminal-status
        # booking. Tech's app should stop publishing on COMPLETED, but stale frames
        # from an unkillable foreground service shouldn't leak the tech's location
        # post-completion.
        if booking.status in JobBooking.TERMINAL_STATUSES:
            return False
        if booking.customer_id == user_id:
            return True
        if booking.technician.user_id == user_id:
            return True
        return False

    async def system_stream(self, event):
        """Channel-layer handler for stream frames sent to any group this consumer
        is subscribed to (user group OR tracking_job_N subgroup).
        """
        await self.send_json(event['message'])
```

In `connect`, add `self._tracking_subscriptions: set[int] = set()` after the user group is joined.

### §4.11 `bookings/admin.py` (modified)

Add the "Resolve dispute" custom action to `SupportTicketAdmin`.

```python
from django.contrib import admin, messages
from django.shortcuts import redirect, render
from django.urls import path
from django.utils.html import format_html

from bookings.services import orchestrator
from bookings.exceptions import BookingValidationError


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'opened_by', 'status', 'resolution_outcome', 'opened_at', 'resolve_link']
    list_filter = ['status', 'resolution_outcome', 'dispute_intake_method']
    readonly_fields = ['booking', 'opened_by', 'dispute_intake_method', 'initial_reason', 'chat_log', 'opened_at']
    inlines = [TicketEvidenceInline]

    def get_urls(self):
        urls = super().get_urls()
        return [
            path('<int:ticket_id>/resolve/', self.admin_site.admin_view(self.resolve_view), name='supportticket-resolve'),
        ] + urls

    def resolve_link(self, obj):
        if obj.status == SupportTicket.STATUS_OPEN:
            return format_html('<a href="./{}/resolve/">Resolve</a>', obj.id)
        return f'Resolved ({obj.resolution_outcome})'
    resolve_link.short_description = 'Resolve'

    def resolve_view(self, request, ticket_id: int):
        ticket = SupportTicket.objects.get(id=ticket_id)
        if request.method == 'POST':
            outcome = request.POST.get('outcome')
            notes = request.POST.get('notes', '')
            final_status = request.POST.get('final_status')
            try:
                orchestrator.admin_resolve_dispute(
                    ticket_id=ticket.id,
                    admin_user=request.user,
                    outcome=outcome,
                    notes=notes,
                    final_status=final_status,
                )
                self.message_user(request, f'Ticket #{ticket.id} resolved.', messages.SUCCESS)
            except BookingValidationError as exc:
                self.message_user(request, f'Failed: {exc.message}', messages.ERROR)
            return redirect(f'../../{ticket_id}/change/')
        return render(request, 'admin/bookings/supportticket/resolve.html', {
            'ticket': ticket,
            'outcomes': SupportTicket.OUTCOME_CHOICES,
            'final_statuses': [
                (JobBooking.STATUS_COMPLETED, 'Completed (full)'),
                (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, 'Completed (inspection only)'),
                (JobBooking.STATUS_CANCELLED, 'Cancelled'),
            ],
        })
```

Template `backend/bookings/templates/admin/bookings/supportticket/resolve.html`:

```html
{% extends "admin/base_site.html" %}
{% block content %}
<h1>Resolve dispute ticket #{{ ticket.id }}</h1>
<p><strong>Booking:</strong> {{ ticket.booking_id }}</p>
<p><strong>Opened by:</strong> {{ ticket.opened_by }}</p>
<p><strong>Initial reason:</strong> {{ ticket.initial_reason }}</p>

<form method="post">
  {% csrf_token %}
  <p>
    <label>Outcome:</label>
    <select name="outcome" required>
      {% for value, label in outcomes %}
        <option value="{{ value }}">{{ label }}</option>
      {% endfor %}
    </select>
  </p>
  <p>
    <label>Final booking status:</label>
    <select name="final_status" required>
      {% for value, label in final_statuses %}
        <option value="{{ value }}">{{ label }}</option>
      {% endfor %}
    </select>
  </p>
  <p>
    <label>Notes:</label><br>
    <textarea name="notes" rows="6" cols="80"></textarea>
  </p>
  <p><input type="submit" value="Resolve" class="default"></p>
</form>
{% endblock %}
```

### §4.12 `realtime/api/STREAMS_TECH_GPS.md` (new)

```markdown
# Stream contract: `tech_gps`

**Stream type**: `tech_gps`
**Channel-layer group**: `tracking_job_{booking_id}` (per-job, dynamic).
**Cadence**: 5-second tick from tech's foreground location service.
**Server-side rate limit**: 4-second per (tech, booking) at the ingress endpoint.
**Persistence**: none. No `EventLog` write. No FCM. No ACK.

## Wire envelope

```json
{
  "kind": "stream",
  "streamType": "tech_gps",
  "timestamp": "2026-05-08T10:23:45Z",
  "payload": {
    "lat": 31.5204,
    "lng": 74.3587,
    "accuracy_meters": 8.5,
    "heading": 145.0,
    "booking_id": 123
  }
}
```

## Subscription

Customer-side (and any future admin-watcher) subscribes via WS upstream message:

```json
{ "action": "subscribe_tracking", "booking_id": 123 }
```

Unsubscribe:

```json
{ "action": "unsubscribe_tracking", "booking_id": 123 }
```

Authorization: subscriber must be the booking's customer or assigned technician (the consumer validates, silently drops on denial).

## Ingress endpoint

`POST /api/bookings/<booking_id>/tech-location/` — tech-only.

Body:
```json
{ "lat": 31.5204, "lng": 74.3587, "accuracy_meters": 8.5, "heading": 145.0 }
```

Response:
```json
{ "published": true, "transition_fired": "ARRIVED" }
```

`transition_fired` is `null` if no auto-transition was triggered, or the new status string if `auto_transition.evaluate_on_location` flipped the booking.

## Client-side staleness

Customer's frontend should display a soft "Technician offline" banner if no frame has arrived in 60 seconds (sprint meta §10). Stream-staleness detection is purely a client concern — backend does not emit "stale" events.
```

### §4.13 `BOOKINGS_API.md` (modified)

Append §3 through §13 (one section per endpoint family). For each: URL + Method + body shape + response shape + error envelopes + "Dumb UI" field meanings. Sample sketch for §3 (transitions):

```markdown
## §3 Transitions (Tech)

### 3.1 POST /api/bookings/<booking_id>/start-inspection/

Tech-only. Flips ARRIVED → INSPECTING. Idempotent on already-INSPECTING.

**Body**: empty.

**Response 200**:
```json
{ "id": 123, "status": "INSPECTING", "inspection_started_at": "2026-05-08T10:23:45Z" }
```

**Errors**:
- `403 not_a_technician` — caller has no tech_profile.
- `403 not_assigned_to_you` — caller is not this booking's tech.
- `404 not_found` — booking missing.
- `400 invalid_transition` — booking not in ARRIVED state. `errors.current_status` echoes actual.
```

Repeat for every endpoint. ~40 endpoint specs across §3–§13. Tedious but necessary for frontend to consume.

### §4.14 Tests — coverage matrix

Each test file mirrors a source file. Coverage per endpoint:

- **Auth**: unauthenticated request returns 401.
- **Authorization**: wrong role (customer hitting tech endpoint, etc.) returns 403.
- **Happy path**: valid request returns 200 + correct payload shape.
- **State guards**: each invalid from-state returns `400 invalid_transition` with `current_status` echoed.
- **Idempotency** where applicable: same request twice returns 200 both times, no duplicate side effects.
- **Body validation**: missing/invalid fields return `400 validation_error` with field-keyed errors.
- **Database query count**: `django_assert_num_queries` on read endpoints (booking detail).
- **Realtime side effect**: events fire (mock `EventDispatchService.broadcast_event`, assert called with right kind + payload).
- **Finance port called**: assert null adapter received the call with right args (where applicable).

For `tech_location`:
- 2 calls within 4s: second returns 429.
- Auto-transition fires when geofence criteria met; doesn't fire otherwise.
- Stream publish happens (mock `publish_stream`, assert called with `group=tracking_job_<id>`).

For WS consumer tests (`test_consumer_tracking_subscribe.py`):
- Connect + subscribe_tracking → consumer joins `tracking_job_<id>` group.
- Subscribe with non-participant user → silently dropped, no group join.
- Disconnect → all tracking subgroups cleaned up.
- Use `channels.testing.WebsocketCommunicator`.

For admin custom action (`test_admin_resolve_dispute.py`):
- POST to `/admin/bookings/supportticket/<id>/resolve/` with valid form → calls `orchestrator.admin_resolve_dispute`, ticket marked RESOLVED, booking flipped to chosen final_status.
- Non-staff user gets redirected to login.

---

## §5 Gotchas

1. **Endpoint folder vs. existing pattern.** Existing folders are flat (`instant_book/`, not `actions/instant_book/`). Match that — every new folder lives directly under `bookings/api/`.
2. **`SubmitQuoteView` accepts decimal `priced_at` as string**, not float. The `DecimalField` serializer enforces this. Documented in BOOKINGS_API.md.
3. **`OpenDisputeView` is multipart** (photo upload). Set `parser_classes = [MultiPartParser, JSONParser]` on the view.
4. **`tech_location` ingress throttle is in-memory** (process-local). For multi-worker deployments, the throttle is per-worker — tech could send 1 request to each worker within 4s and get through twice. Accept this for v1; document. Real distributed throttling is a future concern.
5. **WS consumer's `_tracking_subscriptions` set is per-connection**. If a tech's app loses WS connection and reconnects, it must re-issue `subscribe_tracking` for any active booking it's watching. Frontend (session 4) handles this on `wsConnected` event.
6. **`_can_subscribe` uses `database_sync_to_async`** — required because consumers are async but ORM is sync. Don't accidentally call ORM directly from async code.
7. **`disconnect` cleanup order matters**. Discard tracking subgroups BEFORE the user group (existing) so the user-group cleanup doesn't race against any in-flight tracking frames. The set membership check makes this safe even on concurrent disconnects.
8. **`BookingDetailView` returns the active quote with full line items** (~100 bytes per line × ~5 lines = ~500 bytes). For a busy booking with 10 quote revisions, the `list_quote_history` selector exists but is NOT called from the detail endpoint — only the active quote. Quote history is admin-only via `bookings/selectors/quote_selector.py::list_quote_history`.
9. **`available_transitions` and orchestrator validation MUST stay in sync.** The test `test_selectors_transition_validator.py::test_validator_matches_orchestrator` enumerates every (status, role) tuple and verifies `available_transitions` returns exactly the orchestrator-allowed transitions. If you add a new transition, both files must update.
10. **`BookingDetailView` uses `cache_control(private=True, max_age=5)`** — clients (frontend) may cache up to 5s. Realtime events bypass this (they don't go through HTTP). If the frontend re-fetches detail in response to an event, it must `?nocache=<timestamp>` query-bust to avoid the cached response. Document in BOOKINGS_API.md.
11. **`MarkNoShowView` derives `actor_role` from auth, not body.** A tech sending `actor_role: 'customer'` doesn't get to flip a customer-side no-show. View resolves: if `request.user == booking.customer` → role='customer'; if `request.user == booking.technician.user` → role='technician'; else 403.
12. **`RescheduleView` for AWAITING booking with tech who hasn't accepted yet**: the original is CANCELLED with reason `customer_rescheduled`, the child gets a fresh `dispatch_job_new_request_event` (existing service). The child's SLA timer is fresh; do NOT inherit the original's remaining SLA.
13. **Geofence env toggle** is read at view-load time via `from django.conf import settings; settings.BOOKING_GEOFENCE_STRICT`. Don't cache it as a module-level constant — env may differ across deploys.
14. **Admin "Resolve" form** uses Django's CSRF protection automatically via `{% csrf_token %}`. No custom CSRF handling needed.
15. **`TicketEvidenceInline` allows admin to view photos** but not delete them once a ticket is resolved (audit trail). Override `has_delete_permission` to False if `obj.status == RESOLVED`.
16. **Don't add an `is_critical=True` flag to any new event type retroactively**. Sprint meta §15 lists which are critical. The orchestrator broadcasts use the registry's existing `is_critical`. Trying to flip an existing event's criticality breaks the ACK contract for any in-flight events.
17. **`_tracking_subscriptions` is a Python set** — duplicate subscribe calls are no-ops at the WS layer (idempotent group_add). Don't log a warning on duplicates; expect them on tab refocus.
18. **The `tech_location` ingress endpoint must NOT call `select_for_update`.** It's a high-frequency read path (one POST per 5s per active tech). Use a plain `JobBooking.objects.get(id=...)` in the throttle check, then orchestrator (which does `select_for_update` internally) handles the actual transition.

---

## §6 Verification

### Static checks

```bash
cd backend
python manage.py check
python manage.py shell -c "from bookings.api.transitions.views import StartInspectionView; print('OK')"
python manage.py shell -c "from bookings.api.tech_location.views import TechLocationIngressView; print('OK')"
python manage.py shell -c "from bookings.api.booking_detail.views import BookingDetailView; print('OK')"
```

### Unit / integration tests

```bash
cd backend
pytest tests/bookings/test_api_transitions.py -v
pytest tests/bookings/test_api_quotes.py -v
pytest tests/bookings/test_api_completion.py -v
pytest tests/bookings/test_api_terminations.py -v
pytest tests/bookings/test_api_tech_location.py -v
pytest tests/bookings/test_api_booking_detail.py -v
pytest tests/bookings/test_selectors_orchestrator_ui.py -v
pytest tests/bookings/test_selectors_transition_validator.py -v
pytest tests/realtime/test_consumer_tracking_subscribe.py -v
pytest tests/bookings/test_admin_resolve_dispute.py -v

# Full suite — no regressions on session 1 or shipped code
pytest -q
```

### Manual smoke (curl)

```bash
# 1. Get a token (existing OTP flow; DEBUG=True so OTP is 123456)
curl -X POST http://localhost:8000/api/accounts/otp/request/ -d '{"phone": "+923001234567"}' -H 'Content-Type: application/json'
curl -X POST http://localhost:8000/api/accounts/otp/verify/ -d '{"phone": "+923001234567", "otp": "123456"}' -H 'Content-Type: application/json'
# Returns {token: "..."}

TOKEN=...

# 2. Create a booking (existing endpoint)
curl -X POST http://localhost:8000/api/bookings/instant-book/ \
  -H "Authorization: Token $TOKEN" -H 'Content-Type: application/json' \
  -d '{...full instant-book payload...}'

# Note booking_id

# 3. Tech accepts (existing endpoint)
curl -X POST http://localhost:8000/api/bookings/<id>/accept/ -H "Authorization: Token $TECH_TOKEN"

# 4. Walk the lifecycle through new endpoints
curl -X POST http://localhost:8000/api/bookings/<id>/en-route/ -H "Authorization: Token $TECH_TOKEN"
curl -X POST http://localhost:8000/api/bookings/<id>/arrived/ -H "Authorization: Token $TECH_TOKEN"
curl -X POST http://localhost:8000/api/bookings/<id>/start-inspection/ -H "Authorization: Token $TECH_TOKEN"
curl -X POST http://localhost:8000/api/bookings/<id>/quotes/ \
  -H "Authorization: Token $TECH_TOKEN" -H 'Content-Type: application/json' \
  -d '{"line_items": [{"sub_service_id": 17, "quantity": 1, "priced_at": "1500.00"}]}'

QUOTE_ID=...

curl -X POST http://localhost:8000/api/bookings/<id>/quotes/$QUOTE_ID/approve/ -H "Authorization: Token $TOKEN"
curl -X POST http://localhost:8000/api/bookings/<id>/confirm-cash-received/ \
  -H "Authorization: Token $TECH_TOKEN" -H 'Content-Type: application/json' \
  -d '{"amount": "1500.00", "method": "cash"}'

# 5. Verify booking-detail response
curl http://localhost:8000/api/bookings/<id>/ -H "Authorization: Token $TOKEN" | jq .ui
```

### Manual smoke (WebSocket subscribe)

```bash
# Use websocat or wscat
websocat "ws://localhost:8000/ws/events/?token=$TECH_TOKEN"
# Once connected, send:
{"action":"subscribe_tracking","booking_id":123}
# Should silently succeed; subsequent stream frames will arrive.

# Test denial:
{"action":"subscribe_tracking","booking_id":999}   # not your booking
# Should silently drop (no error frame); check Django logs for warning.
```

### Migration / config checks

```bash
# Confirm new env var is wired
grep -n "BOOKING_GEOFENCE_STRICT" backend/core/settings.py
grep -n "BOOKING_GEOFENCE_STRICT" backend/.env.example

# No new migrations expected this session
python manage.py makemigrations --dry-run --check
```

### Constraint checks (per CLAUDE.md)

```bash
# Views must be thin — no business logic, no ORM beyond what permission needs
grep -rn "for .* in" backend/bookings/api/transitions/views.py     # no loops in views
grep -rn "filter\|exclude" backend/bookings/api/transitions/views.py  # no querysets in views (allowed only in selectors/services)

# All status mutations still go through orchestrator
grep -rn "\.status = " backend/bookings/api/                       # no direct status writes from views
```

---

## §7 What this session does NOT fix

- Frontend orchestrator screen — session 3.
- Per-event Flutter notifiers (BookingDetail re-fetch on event arrival) — session 3.
- Live tracking widget / dual-provider maps — session 4.
- Tech-side foreground location service that POSTs to `tech_location` — session 4.
- Quote builder UI / approval sheet UI / cash collection screen — session 5.
- Cancellation / no-show / dispute UIs — session 6.
- Real `WalletTransaction` and `JobCommission` writes — finance sprint.
- AI chatbot intake (the dispute flow ships form-only this session) — future sprint.
- Reviews / ratings — future sprint.
- iOS foreground location service — flag #10 deferred.
- Distributed (cross-worker) throttling for `tech_location` ingress — v2 polish.
- Per-tech / per-service geofence radius configuration — env-level toggle this session; per-entity later.
- Admin reliability-score surface — admin event audit only this session; user-facing later.
- Auto no-show detection (Celery-driven) — manual buttons this session; flag opens for future.
- WS consumer's `subscribe_tracking` retry on reconnect — frontend handles (session 4); backend just exposes the API.

---

## §8 Definition of done

Tick every item before pushing.

### Code

- [ ] All 16 endpoint views created across the 6 feature folders, matching the canonical shape.
- [ ] All 16 serializers (request + response pairs) created.
- [ ] `bookings/api/urls.py` extended with all new routes.
- [ ] `bookings/selectors/orchestrator_ui.py` shipped with all 26 (status, role) handlers.
- [ ] `bookings/selectors/transition_validator.py` shipped.
- [ ] `realtime/events/consumers.py` extended with `subscribe_tracking` / `unsubscribe_tracking` handling and per-booking authorization.
- [ ] `realtime/streams/dispatch.py` extended (or confirmed pre-existing) to accept explicit `group=` argument.
- [ ] `bookings/admin.py` extended with `SupportTicketAdmin.resolve_view` and the corresponding template.
- [ ] `BOOKING_GEOFENCE_STRICT` env var wired in settings + `.env.example`.

### Tests

- [ ] `pytest -q` green on the full suite.
- [ ] Each endpoint has tests for: auth (401), authorization (403), happy path (200), each invalid from-state (400), idempotency (where applicable), body validation, query count (where read-only), realtime broadcast asserted, finance port called (where applicable).
- [ ] `tech_location` tests verify: 4-second throttle (429), auto-transition firing, stream publish to correct group.
- [ ] WS consumer tests verify: subscribe joins group, non-participant denied (silent drop + warning log), unsubscribe leaves group, disconnect cleans up all subscriptions.
- [ ] `test_selectors_transition_validator.py::test_validator_matches_orchestrator` exhaustively enumerates (status, role) and asserts `available_transitions` matches orchestrator's actual validity.
- [ ] Admin custom action test: POST to resolve URL with valid form → orchestrator called → ticket RESOLVED + booking flipped.

### Constraints (per CLAUDE.md + sprint meta §22)

- [ ] No business logic in any new view (each view ≤30 lines, only HTTP concerns).
- [ ] No ORM in views beyond permission checks.
- [ ] No `from celery import` in any new file in `bookings/api/`.
- [ ] No direct event broadcasts from views (orchestrator owns broadcasts).
- [ ] All status mutations still go through orchestrator (grep confirms: only `bookings/services/{instant_book_service,job_request_action,orchestrator}.py` and `bookings/tasks.py` write `.status`).
- [ ] Standard error envelope used everywhere (`{status, code, message, errors}`).
- [ ] CLAUDE.md amendment for WS consumer's `subscribe_tracking` documented in CLAUDE.md (one-line addition under Realtime section).

### Documentation

- [ ] `BOOKINGS_API.md` extended with §3–§13 covering all new endpoints (sample requests, response shapes, error envelopes, "Dumb UI" field semantics for the booking-detail response).
- [ ] `STREAMS_TECH_GPS.md` created.
- [ ] `EVENT_DISPATCH_API.md` updated with one line per new event type in its registry table.
- [ ] CLAUDE.md updated: under Realtime section, add note "WS consumer accepts `subscribe_tracking` / `unsubscribe_tracking` upstream messages for booking-scoped tracking subgroups; otherwise still strictly downstream."

### flag.md

- [ ] flag.md updated per sprint meta §20:
  - [ ] Opens `geofence-strictness-config-tbd` (env-level only, per-entity config deferred).
  - [ ] Opens `wallet-commission-deferred-to-finance-sprint` (orchestrator's null adapter calls have correct shape; real implementation is finance sprint).
  - [ ] Opens `tech-location-rate-limit-not-distributed` (audit P1-07; in-memory throttle is per-process; multi-worker Daphne deployments allow N×4s rate. v1 tolerable; redis-backed token bucket is the proper fix; document acceptance criteria).

### Git

- [ ] Single commit (or small chain): `feat(bookings): orchestrator transition endpoints + tech_gps stream + dispute resolution (sprint v1, session 2)`.
- [ ] No `--no-verify`, no `--amend` of pushed commits.
- [ ] `git status` clean after commit.

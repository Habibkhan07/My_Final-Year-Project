"""Booking orchestrator — single transition gateway for every post-CONFIRMED
status mutation.

Every public function here follows the canonical 5-step shape (sprint meta
§9, CLAUDE.md "Async Tasks" + atomicity rules):

    1. Resolve the FinancePort adapter (lazy import via factory if not
       injected). Tests inject a fake; production gets the null adapter.
    2. ``with transaction.atomic():`` — open a single atomic block around
       the row lock + state-machine guard + mutation + finance call.
    3. Lock the booking row with ``select_for_update()`` and validate
       both authorization (IDOR scope) and from-state (state machine).
       On rejection, raise ``BookingValidationError`` with a stable
       ``code``; the canonical envelope is emitted by the DRF handler.
    4. Mutate ``JobBooking`` columns and create related rows
       (Quote / QuoteLineItem / BookingItem / SupportTicket / etc.).
    5. Register the realtime broadcast inside ``transaction.on_commit``
       so a rolled-back transaction never produces a phantom WS frame
       or FCM push. Inside the same atomic block, call the relevant
       FinancePort method — port failure rolls the whole transaction back.

Idempotency: every transition function returns silently when the booking is
already in the target state and the actor is unchanged. This protects
retries (network flakes, double-tap, FCM-driven repeat invocations) without
duplicating events or finance entries.

Scope of this sprint: no HTTP views consume these functions yet — that is
session 2. The orchestrator IS the contract; views will be thin pass-throughs.
"""

from __future__ import annotations

from decimal import Decimal
from typing import Any, Iterable

from django.db import transaction
from django.db.models import Sum as models_sum
from django.utils import timezone
from rest_framework import status as drf_status

from bookings.exceptions import (
    BookingValidationError,
    ERROR_BOOKING_NOT_FOUND,
    ERROR_CANCELLATION_NOT_ALLOWED,
    ERROR_DISPUTE_NOT_DISPUTABLE_STATUS,
    ERROR_INVALID_INPUT,
    ERROR_INVALID_QUOTE_EMPTY,
    ERROR_INVALID_TRANSITION,
    ERROR_NO_SHOW_TOO_EARLY,
    ERROR_NOT_ASSIGNED_TO_YOU,
    ERROR_QUOTE_BAND_VIOLATION,
    ERROR_QUOTE_NOT_FOUND,
    ERROR_QUOTE_SUPERSEDED,
    ERROR_RESCHEDULE_NOT_ALLOWED,
    ERROR_TICKET_NOT_FOUND,
)
from bookings.models import (
    BookingItem,
    JobBooking,
    Quote,
    QuoteLineItem,
    SupportTicket,
    TechReliabilityIncident,
    TicketEvidence,
)
from realtime.constants.event_types import EventType
from technicians.models import TechnicianProfile


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------


def _resolve_finance(finance):
    """Return the injected port or lazily resolve the production default.

    Lazy import keeps ``bookings.services.*`` modules free of finance code
    at module-load time — the adapters package is only touched when an
    orchestrator function actually executes (CLAUDE.md port-and-adapter rule).
    """
    if finance is not None:
        return finance
    from bookings.adapters import get_default_finance_service
    return get_default_finance_service()


def _broadcast(*, user, target_role: str, event_type: EventType, payload: dict) -> None:
    """Emit one realtime event.

    Imported lazily so module-load on ``bookings.services.orchestrator`` does
    not pull the realtime channel layer into scope (matches the existing
    ``job_request_action.py`` pattern, which imports at module top — but the
    orchestrator broadcasts in many places, so wrapping once keeps the call
    sites readable). ``expires_in_seconds=None`` because none of the
    orchestrator events are SLA-gated; the only SLA-bearing event in the
    bookings app is ``job_new_request`` (dispatched by ``job_request_dispatch``).
    """
    from realtime.events.services import EventDispatchService

    EventDispatchService.broadcast_event(
        user=user,
        target_role=target_role,
        event_type=event_type.value,
        payload=payload,
        expires_in_seconds=None,
    )


def _broadcast_both(*, booking: JobBooking, event_type: EventType, payload: dict) -> None:
    """Emit a transition event to BOTH the customer and the technician.

    The original asymmetric pattern (broadcast to counterparty only, actor
    refreshes locally via the action-button invalidate) is brittle:

      * **Auto-transitions** (``auto_transition.evaluate_on_location`` firing
        geofence flips) have no human actor on a device, so the "actor
        refreshes locally" leg never runs and one side's screen lies until
        the next event.
      * **Cross-device same-user** sessions (rare for v1, but possible —
        tech logged into both phone and tablet) only refresh on the device
        that issued the action.
      * **Dev tools** (``dev_panel``) play both sides at once; neither tab
        gets the local invalidate.

    Broadcasting to both roles is harmless on the actor side — the local
    invalidate has likely already fired by the time the WS frame lands, and
    a back-to-back ``ref.invalidate`` on Riverpod collapses to a single
    refetch. The realtime envelope is dedup'd by id at the frontend, so the
    cost is a redundant invalidate, not a redundant network call.
    """
    _broadcast(
        user=booking.customer,
        target_role='customer',
        event_type=event_type,
        payload=payload,
    )
    _broadcast(
        user=booking.technician.user,
        target_role='technician',
        event_type=event_type,
        payload=payload,
    )


def _payload_basics(booking: JobBooking) -> dict[str, Any]:
    """Common payload fields every orchestrator event ships."""
    return {
        "job_id": booking.id,
        "status": booking.status,
    }


def _lock_booking(booking_id: int) -> JobBooking:
    """Inside-atomic select_for_update fetch with the joins every transition needs.

    Nested catalog FKs ride along so payload composition (service/sub_service
    name) doesn't fire follow-up queries inside the lock window.

    Bad ``booking_id`` (no row, deleted, never existed) raises a 404
    envelope rather than a bare ``JobBooking.DoesNotExist`` so the future
    HTTP layer never has to translate. Every transition function inherits
    this behaviour by virtue of routing every booking fetch through here.
    """
    try:
        return (
            JobBooking.objects
            .select_for_update()
            .select_related(
                'technician__user',
                'customer',
                'service',
                'sub_service',
                'address',
            )
            .get(id=booking_id)
        )
    except JobBooking.DoesNotExist:
        raise BookingValidationError(
            code=ERROR_BOOKING_NOT_FOUND,
            message='Booking not found.',
            status=drf_status.HTTP_404_NOT_FOUND,
        )


def _get_booking_quote_locked(booking: JobBooking, quote_id: int) -> Quote:
    """Fetch a booking-scoped quote under select_for_update, raising the
    canonical envelope on a missing or cross-booking id.

    The booking-scope on the manager (``booking.quotes``) doubles as an
    IDOR guard: a quote_id from another booking returns DoesNotExist
    here, indistinguishable from "never existed."
    """
    try:
        return booking.quotes.select_for_update().get(id=quote_id)
    except Quote.DoesNotExist:
        raise BookingValidationError(
            code=ERROR_QUOTE_NOT_FOUND,
            message='Quote not found on this booking.',
            status=drf_status.HTTP_404_NOT_FOUND,
        )


def _quote_state_error_code(quote_status: str) -> str:
    """Pick the right error code when a Quote isn't in SUBMITTED state.

    SUPERSEDED → ``quote_superseded`` (a newer revision is now active,
    refresh-and-retry is the right response). Anything else (APPROVED,
    DECLINED, DRAFT) → generic ``invalid_transition``.

    The distinction matters because the FE auto-recovers from
    ``quote_superseded`` by invalidating the booking detail (which
    re-hydrates with the new quote_id) and surfacing a soft snack —
    instead of showing the user a hard "invalid transition" error
    on a perfectly legitimate concurrent edit by the technician.
    """
    if quote_status == Quote.STATUS_SUPERSEDED:
        return ERROR_QUOTE_SUPERSEDED
    return ERROR_INVALID_TRANSITION


def _require_assigned_tech(booking: JobBooking, technician_user) -> None:
    """IDOR guard for tech-driven transitions.

    Rejects with the canonical envelope code; the booking row was already
    fetched (we cannot collapse missing-vs-wrong-owner here without a
    pre-fetch that would defeat the point), so the message is honest about
    assignment rather than blanket-NotFound.
    """
    if booking.technician.user_id != technician_user.id:
        raise BookingValidationError(
            code=ERROR_NOT_ASSIGNED_TO_YOU,
            message='You are not the technician on this booking.',
        )


def _require_customer(booking: JobBooking, customer_user) -> None:
    """IDOR guard for customer-driven transitions."""
    if booking.customer_id != customer_user.id:
        raise BookingValidationError(
            code=ERROR_NOT_ASSIGNED_TO_YOU,
            message='You are not the customer on this booking.',
        )


def _reject_invalid_from_state(booking: JobBooking, message: str) -> None:
    raise BookingValidationError(
        code=ERROR_INVALID_TRANSITION,
        message=message,
        errors={'current_status': [booking.status]},
    )


# ---------------------------------------------------------------------------
# Geofence-driven transitions (called by auto_transition.py)
# ---------------------------------------------------------------------------


def en_route(
    *,
    booking_id: int,
    technician_user,
    source: str = 'manual',
    finance=None,
) -> JobBooking:
    """CONFIRMED → EN_ROUTE.

    ``source`` is informational: ``'auto'`` from ``auto_transition.py``
    (geofence trigger) and ``'manual'`` from a fallback override view in
    session 2. The mutation is identical either way.

    SECURITY: technician scope check; select_for_update serializes against
    the customer's cancellation flow.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if booking.status == JobBooking.STATUS_EN_ROUTE:
            return booking

        if booking.status != JobBooking.STATUS_CONFIRMED:
            _reject_invalid_from_state(booking, 'Booking is not in CONFIRMED state.')

        booking.status = JobBooking.STATUS_EN_ROUTE
        booking.en_route_started_at = timezone.now()
        booking.save(update_fields=['status', 'en_route_started_at'])

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.TECH_EN_ROUTE,
            payload={**_payload_basics(booking), 'source': source},
        ))

    return booking


def arrived(
    *,
    booking_id: int,
    technician_user,
    source: str = 'manual',
    finance=None,
) -> JobBooking:
    """EN_ROUTE → ARRIVED.

    Auto path fires when the GPS frame is within ARRIVED_THRESHOLD_METERS
    of the customer address; manual path is the fallback override.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if booking.status == JobBooking.STATUS_ARRIVED:
            return booking

        if booking.status != JobBooking.STATUS_EN_ROUTE:
            _reject_invalid_from_state(booking, 'Booking is not in EN_ROUTE state.')

        booking.status = JobBooking.STATUS_ARRIVED
        booking.arrived_at = timezone.now()
        booking.save(update_fields=['status', 'arrived_at'])

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.TECH_ARRIVED,
            payload={**_payload_basics(booking), 'source': source},
        ))

    return booking


def customer_arriving(*, booking_id: int, customer_user) -> JobBooking:
    """Customer taps "I'm coming out" — ACKs the tech's arrival AND
    auto-advances ARRIVED → INSPECTING.

    InDrive-style meeting flow plus a state-progression shortcut. The
    customer's tap signals two things at once: (1) they've seen the
    tech arrived and are walking out to find them; (2) the in-person
    meeting is starting, so the booking enters INSPECTING.

    Cutting the redundant tech tap matters: by the time the tech would
    otherwise press "Start inspection" themselves, they're standing at
    the door / opening the gate / shaking hands. We shouldn't make
    them stop to press a button for something that's physically
    happening on its own.

    Tech-side fallback: if the customer never opens the app, the tech
    can still drive ARRIVED → INSPECTING explicitly via the
    ``start_inspection`` service / endpoint. Both paths are idempotent
    and either can fire first.

    Idempotent: re-tapping after the booking already moved to INSPECTING
    (whether via this auto-advance or via the tech's explicit call) is
    a no-op return.
    """
    # SECURITY: customer-only IDOR guard via _require_customer below.
    # The status guard accepts ARRIVED (first tap → ack + advance) or
    # INSPECTING (re-tap → idempotent return). Any other state is
    # rejected, so a stray tap on a stale UI push cannot pollute later
    # phases or resurrect a completed booking.
    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        # Idempotent re-tap path. Booking is already INSPECTING — either
        # this customer already tapped (and we auto-advanced) or the
        # tech beat them to it via start_inspection. Either way the
        # transition has happened; nothing to do.
        if booking.status == JobBooking.STATUS_INSPECTING:
            return booking

        if booking.status != JobBooking.STATUS_ARRIVED:
            _reject_invalid_from_state(booking, 'Booking is not in ARRIVED state.')

        # First tap on ARRIVED. Stamp the ack, flip to INSPECTING, and
        # broadcast for the tech's UI. We inline the status flip rather
        # than calling start_inspection() because we already hold the
        # row lock and validated state==ARRIVED; calling the sibling
        # service would also require a technician_user we don't have
        # here, and would re-lock/re-validate redundantly.
        now = timezone.now()
        booking.customer_acknowledged_arrival_at = now
        booking.status = JobBooking.STATUS_INSPECTING
        booking.inspection_started_at = now
        booking.save(update_fields=[
            'customer_acknowledged_arrival_at',
            'status',
            'inspection_started_at',
        ])

        ack_ts = now
        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.CUSTOMER_ARRIVING,
            payload={
                **_payload_basics(booking),
                'acknowledged_at': ack_ts.isoformat(),
            },
        ))

    return booking


def start_inspection(*, booking_id: int, technician_user, finance=None) -> JobBooking:
    """ARRIVED → INSPECTING (tech-side fallback path).

    Two routes lead a booking to INSPECTING. The happy path is the
    customer tapping "I'm coming out" — ``customer_arriving`` flips the
    status inline and the customer's screen invalidates locally on its
    own POST response, so no event is required for that path.

    This function is the COLD-CUSTOMER FALLBACK: the customer never
    opened the app / didn't tap, and the tech advances the status from
    their own ARRIVED screen. The customer might still be on the
    orchestrator screen (just hadn't ACK'd yet); without an event their
    screen would sit on ARRIVED until manual refresh.

    Emits ``INSPECTION_STARTED`` to the customer. Silent on the frontend
    — no banner, no push — because the customer is physically next to
    the tech when this fires; a notification would be redundant. The
    event's only job is to trigger ``ref.invalidate(bookingDetailProvider)``
    on the customer's screen via ``BookingOrchestratorEventsNotifier``.

    Idempotent: re-call with status already INSPECTING returns the
    booking with no event re-broadcast.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if booking.status == JobBooking.STATUS_INSPECTING:
            return booking

        if booking.status != JobBooking.STATUS_ARRIVED:
            _reject_invalid_from_state(booking, 'Booking is not in ARRIVED state.')

        booking.status = JobBooking.STATUS_INSPECTING
        booking.inspection_started_at = timezone.now()
        booking.save(update_fields=['status', 'inspection_started_at'])

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.INSPECTION_STARTED,
            payload=_payload_basics(booking),
        ))

    return booking


# ---------------------------------------------------------------------------
# Quote flow
# ---------------------------------------------------------------------------


def _validate_line_items(line_items: list) -> None:
    """Schema and pricing-band check on submit_quote input.

    Empty list -> ERROR_INVALID_QUOTE_EMPTY.
    Each item must be a dict carrying ``sub_service_id`` and ``priced_at``;
    ``quantity`` defaults to 1.
    Per-line band:
        fixed-price: priced_at == base_price
        labor:       base_price <= priced_at <= max_price (max_price required)

    Defensive parsing: malformed items (non-dict, missing keys, unparsable
    Decimal) raise ``BookingValidationError`` with a field-level
    ``errors[f'line_items[{idx}].field']`` map. Session-2 serializers will
    catch most of this earlier, but the service is the canonical
    validator and must not crash on bad input.
    """
    if not line_items:
        raise BookingValidationError(
            code=ERROR_INVALID_QUOTE_EMPTY,
            message='A quote must contain at least one line item.',
        )

    from catalog.models import SubService

    # First pass: structural validation — every item must be a dict with
    # the required keys before we attempt the catalog fetch. Collecting
    # sub_service_ids cleanly here keeps the catalog query single-shot.
    sub_ids: list[int] = []
    for idx, li in enumerate(line_items):
        if not isinstance(li, dict):
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Line item must be an object.',
                errors={f'line_items[{idx}]': ['expected an object']},
            )
        if 'sub_service_id' not in li:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Line item missing sub_service_id.',
                errors={f'line_items[{idx}].sub_service_id': ['required']},
            )
        if 'priced_at' not in li:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Line item missing priced_at.',
                errors={f'line_items[{idx}].priced_at': ['required']},
            )
        sub_ids.append(li['sub_service_id'])

    sub_map = {s.id: s for s in SubService.objects.filter(id__in=sub_ids)}

    for idx, li in enumerate(line_items):
        sub_id = li['sub_service_id']
        quantity = li.get('quantity', 1)

        # Decimal parsing: priced_at can arrive as str / int / float /
        # Decimal / None. Wrap and surface a field-keyed envelope on
        # failure rather than letting decimal.InvalidOperation escape.
        try:
            priced_at = Decimal(str(li['priced_at']))
        except (TypeError, ValueError, ArithmeticError):
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='priced_at is not a valid decimal.',
                errors={f'line_items[{idx}].priced_at': [
                    f'invalid decimal: {li["priced_at"]!r}',
                ]},
            )

        # Quantity sanity. Accepts ints + numeric-looking strings; rejects
        # zero, negative, and unparsable.
        try:
            quantity = int(quantity)
        except (TypeError, ValueError):
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Quantity must be an integer.',
                errors={f'line_items[{idx}].quantity': [
                    f'invalid integer: {li.get("quantity")!r}',
                ]},
            )
        if quantity <= 0:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Quantity must be positive.',
                errors={f'line_items[{idx}].quantity': ['must be > 0']},
            )

        sub = sub_map.get(sub_id)
        if sub is None:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Unknown sub-service in quote.',
                errors={f'line_items[{idx}].sub_service_id': ['not found']},
            )

        if sub.is_fixed_price:
            if priced_at != sub.base_price:
                raise BookingValidationError(
                    code=ERROR_QUOTE_BAND_VIOLATION,
                    message='Fixed-price sub-service must be priced at base_price.',
                    errors={f'line_items[{idx}].priced_at': [
                        f'expected {sub.base_price}, got {priced_at}',
                    ]},
                )
        else:
            if sub.max_price is None:
                raise BookingValidationError(
                    code=ERROR_QUOTE_BAND_VIOLATION,
                    message='Labor sub-service is missing max_price; admin must set it.',
                    errors={f'line_items[{idx}].sub_service_id': ['max_price not configured']},
                )
            if priced_at < sub.base_price or priced_at > sub.max_price:
                raise BookingValidationError(
                    code=ERROR_QUOTE_BAND_VIOLATION,
                    message='Price is outside the allowed band for this sub-service.',
                    errors={f'line_items[{idx}].priced_at': [
                        f'must be between {sub.base_price} and {sub.max_price}',
                    ]},
                )


def submit_quote(
    *,
    booking_id: int,
    technician_user,
    line_items: Iterable[dict],
    is_upsell: bool = False,
    finance=None,
) -> Quote:
    """INSPECTING → QUOTED (or IN_PROGRESS → QUOTED if ``is_upsell=True``).

    Creates a fresh ``Quote`` with ``revision_number = max(prev) + 1`` and
    one ``QuoteLineItem`` per input dict. Recomputes ``Quote.total_amount``
    from the new line items. Stamps ``quote_first_submitted_at`` if this
    is the first revision.

    Upsell path (``is_upsell=True``): the from-state is IN_PROGRESS and the
    booking's ``status`` is NOT changed — the customer keeps seeing the
    same lifecycle, but a new approval card appears for the additional work.
    The non-upsell path flips INSPECTING → QUOTED.

    Returns the created ``Quote`` instance (with line items prefetched via
    the same select_related chain the orchestrator screen uses).
    """
    finance = _resolve_finance(finance)
    line_items_list = list(line_items)
    _validate_line_items(line_items_list)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if is_upsell:
            if booking.status != JobBooking.STATUS_IN_PROGRESS:
                _reject_invalid_from_state(
                    booking, 'Upsell quote requires booking in IN_PROGRESS state.',
                )
        else:
            if booking.status != JobBooking.STATUS_INSPECTING:
                _reject_invalid_from_state(
                    booking, 'Quote submission requires booking in INSPECTING state.',
                )

        # Mark any prior SUBMITTED quote of the SAME flavour as SUPERSEDED
        # before adding the new one. Customers can submit_quote ->
        # request_revision -> submit_quote -> ... and at any moment exactly
        # one quote per flavour (regular vs upsell) should be SUBMITTED.
        # The is_upsell filter is defensive — current flow makes regular
        # and upsell SUBMITTED quotes mutually exclusive (regular requires
        # status=QUOTED, upsell requires status=IN_PROGRESS), but the SQL
        # used to be loose; pinning it prevents future flow changes from
        # accidentally cross-superseding.
        booking.quotes.filter(
            status=Quote.STATUS_SUBMITTED,
            is_upsell=is_upsell,
        ).update(
            status=Quote.STATUS_SUPERSEDED,
            decided_at=timezone.now(),
        )

        previous_max = booking.quotes.order_by('-revision_number').values_list(
            'revision_number', flat=True,
        ).first() or 0
        next_revision = previous_max + 1

        now = timezone.now()
        quote = Quote.objects.create(
            booking=booking,
            revision_number=next_revision,
            status=Quote.STATUS_SUBMITTED,
            is_upsell=is_upsell,
            submitted_at=now,
            total_amount=Decimal('0'),
        )

        running_total = Decimal('0')
        for li in line_items_list:
            quantity = li.get('quantity', 1)
            priced_at = Decimal(str(li['priced_at']))
            line_total = (priced_at * quantity).quantize(Decimal('0.01'))
            QuoteLineItem.objects.create(
                quote=quote,
                sub_service_id=li['sub_service_id'],
                quantity=quantity,
                priced_at=priced_at,
                line_total=line_total,
            )
            running_total += line_total

        quote.total_amount = running_total
        quote.save(update_fields=['total_amount'])

        update_fields = []
        if not is_upsell and booking.status != JobBooking.STATUS_QUOTED:
            booking.status = JobBooking.STATUS_QUOTED
            update_fields.append('status')
        if booking.quote_first_submitted_at is None:
            booking.quote_first_submitted_at = now
            update_fields.append('quote_first_submitted_at')
        if update_fields:
            booking.save(update_fields=update_fields)

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.QUOTE_GENERATED,
            payload={
                **_payload_basics(booking),
                'quote_id': quote.id,
                'revision_number': quote.revision_number,
                'total_amount': str(quote.total_amount),
                'is_upsell': is_upsell,
            },
        ))

    return quote


def request_revision(
    *,
    booking_id: int,
    customer_user,
    quote_id: int,
    reason: str,
    finance=None,
) -> JobBooking:
    """QUOTED → INSPECTING (customer wants to bargain face-to-face).

    Marks the targeted Quote SUPERSEDED and returns the booking to
    INSPECTING so the tech can submit a revised quote. The whole quote
    history is preserved for audit; only the active SUBMITTED row flips.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        quote = _get_booking_quote_locked(booking, quote_id)

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=_quote_state_error_code(quote.status),
                message='Only a SUBMITTED quote can be revised.',
                errors={'quote_status': [quote.status]},
            )

        # Two valid from-states map to two outcomes:
        #   - QUOTED + non-upsell → flip booking back to INSPECTING so the
        #     tech can rebuild the initial quote.
        #   - IN_PROGRESS + upsell → keep booking IN_PROGRESS; the upsell
        #     quote becomes SUPERSEDED so the tech can submit a new upsell
        #     revision via submit_quote(is_upsell=True).
        if quote.is_upsell:
            if booking.status != JobBooking.STATUS_IN_PROGRESS:
                _reject_invalid_from_state(
                    booking, 'Upsell revision requires booking in IN_PROGRESS state.',
                )
        else:
            if booking.status != JobBooking.STATUS_QUOTED:
                _reject_invalid_from_state(
                    booking, 'Revision can only be requested on a QUOTED booking.',
                )

        now = timezone.now()
        quote.status = Quote.STATUS_SUPERSEDED
        quote.decision_reason = reason
        quote.decided_at = now
        quote.save(update_fields=['status', 'decision_reason', 'decided_at'])

        if not quote.is_upsell:
            booking.status = JobBooking.STATUS_INSPECTING
            booking.save(update_fields=['status'])

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.QUOTE_REVISION_REQUESTED,
            payload={
                **_payload_basics(booking),
                'quote_id': quote.id,
                'reason': reason,
            },
        ))

    return booking


def approve_quote(
    *,
    booking_id: int,
    customer_user,
    quote_id: int,
    finance=None,
) -> JobBooking:
    """QUOTED → IN_PROGRESS (or stays IN_PROGRESS for upsell approvals).

    Marks the Quote APPROVED. Snapshots its line items into ``BookingItem``
    rows — APPENDING for mid-job upsell, never deleting prior items.
    Recomputes ``booking.base_services_total`` from the BookingItem total.
    Stamps ``work_started_at`` on the first approval. Calls
    ``finance.apply_inspection_fee_decision(decision='accepted')``.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        # ``_get_booking_quote_locked`` raises the canonical 404 envelope
        # on miss / cross-booking id. We then re-fetch with
        # prefetch_related — and re-assert ``select_for_update()`` on
        # the second query so the FOR UPDATE lock on the Quote row is
        # preserved across the prefetch. Without the second
        # ``select_for_update()``, Postgres on READ COMMITTED would
        # drop the row-lock between the two SELECTs; the outer
        # booking-row lock from ``_lock_booking`` still serializes
        # concurrent approve calls in practice (every Quote mutation
        # passes through the same booking lock), but defending the
        # explicit invariant here is cheap.
        quote = _get_booking_quote_locked(booking, quote_id)
        quote = (
            booking.quotes
            .select_for_update()
            .prefetch_related('line_items')
            .get(id=quote.id)
        )

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=_quote_state_error_code(quote.status),
                message='Only a SUBMITTED quote can be approved.',
                errors={'quote_status': [quote.status]},
            )

        # Two valid from-states map to two outcomes:
        #   - QUOTED + non-upsell → flip booking to IN_PROGRESS, stamp start.
        #   - IN_PROGRESS + upsell → keep status, append items only.
        if quote.is_upsell:
            if booking.status != JobBooking.STATUS_IN_PROGRESS:
                _reject_invalid_from_state(
                    booking, 'Upsell quote can only be approved on an IN_PROGRESS booking.',
                )
        else:
            if booking.status != JobBooking.STATUS_QUOTED:
                _reject_invalid_from_state(
                    booking, 'Quote can only be approved on a QUOTED booking.',
                )

        now = timezone.now()
        quote.status = Quote.STATUS_APPROVED
        quote.decided_at = now
        quote.save(update_fields=['status', 'decided_at'])

        # Snapshot — APPEND, never replace. The finance sprint reads the
        # full set of BookingItem rows for reconciliation. bulk_create
        # collapses N inserts into one round trip; ordering is preserved
        # so callers iterating ``booking.items.order_by('id')`` see items
        # in the same order they appeared on the quote.
        BookingItem.objects.bulk_create([
            BookingItem(
                booking=booking,
                sub_service_id=li.sub_service_id,
                quantity=li.quantity,
                price_charged=li.priced_at,
                line_total=li.line_total,
                sourced_quote=quote,
            )
            for li in quote.line_items.all()
        ])

        # Recompute denormalized totals from the snapshot. Avoids floating
        # drift from ad-hoc additions to ``base_services_total``.
        running = booking.items.aggregate(
            total=models_sum('line_total'),
        )['total'] or Decimal('0')
        booking.base_services_total = running

        # Final cash button number (CLAUDE.md "Inspection Fee" rule:
        # accepted quote → Rs.500 deducted from final bill). Floor at 0
        # so a quote whose total is below the inspection fee doesn't
        # surface a negative number on the tech's button. inspection_fee
        # is null for FIXED_GIG / LABOR_GIG paths, in which case the
        # full base_services_total is owed.
        inspection_credit = booking.inspection_fee or Decimal('0')
        booking.final_cash_to_collect = max(
            Decimal('0'), running - inspection_credit,
        )

        update_fields = ['base_services_total', 'final_cash_to_collect']
        if not quote.is_upsell:
            booking.status = JobBooking.STATUS_IN_PROGRESS
            update_fields.append('status')
            if booking.work_started_at is None:
                booking.work_started_at = now
                update_fields.append('work_started_at')
        booking.save(update_fields=update_fields)

        # Single-shot inspection-fee finance hook — fires on the INITIAL
        # quote approval only. Upsell approvals append work to the bill
        # but the inspection-fee accounting was already settled by the
        # initial accept; firing again would double-bookkeep the credit
        # once the finance sprint replaces NullFinanceAdapter.
        if not quote.is_upsell:
            finance.apply_inspection_fee_decision(booking=booking, decision='accepted')

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.QUOTE_APPROVED,
            payload={
                **_payload_basics(booking),
                'quote_id': quote.id,
                'is_upsell': quote.is_upsell,
                # ``total_amount`` is THIS quote's total only (the upsell's
                # delta on the upsell path). ``final_cash_to_collect`` is
                # the cumulative number the tech's cash button needs and
                # spares the frontend a round-trip refetch.
                'total_amount': str(quote.total_amount),
                'final_cash_to_collect': str(booking.final_cash_to_collect),
            },
        ))

    return booking


def decline_quote(
    *,
    booking_id: int,
    customer_user,
    quote_id: int,
    reason: str,
    finance=None,
) -> JobBooking:
    """QUOTED → COMPLETED_INSPECTION_ONLY (terminal) for initial quotes,
    OR IN_PROGRESS → IN_PROGRESS (non-terminal) for upsell quotes.

    Initial quote decline: booking enters a terminal inspection-only
    state; ``final_cash_to_collect`` is set to the inspection fee
    (Rs.500 for INSPECTION-flow bookings; 0 for FIXED_GIG / LABOR_GIG
    since their flow doesn't carry an upfront inspection fee).

    Upsell decline: customer rejects the additional work the tech tried
    to add mid-job. The original work continues — booking stays
    IN_PROGRESS, the upsell quote is marked DECLINED but ``BookingItem``
    rows are unchanged (the upsell was never approved, so no items were
    appended), and the inspection-fee finance hook is NOT re-fired (it
    settled on the initial-approve path).
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        quote = _get_booking_quote_locked(booking, quote_id)

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=_quote_state_error_code(quote.status),
                message='Only a SUBMITTED quote can be declined.',
                errors={'quote_status': [quote.status]},
            )

        # Two valid from-states map to two outcomes:
        #   - QUOTED + non-upsell → flip booking to COMPLETED_INSPECTION_ONLY
        #     (terminal), settle inspection-fee credit as declined.
        #   - IN_PROGRESS + upsell → keep status, mark Quote DECLINED only.
        if quote.is_upsell:
            if booking.status != JobBooking.STATUS_IN_PROGRESS:
                _reject_invalid_from_state(
                    booking, 'Upsell decline requires booking in IN_PROGRESS state.',
                )
        else:
            if booking.status != JobBooking.STATUS_QUOTED:
                _reject_invalid_from_state(
                    booking, 'Decline only valid from QUOTED state.',
                )

        now = timezone.now()
        quote.status = Quote.STATUS_DECLINED
        quote.decision_reason = reason
        quote.decided_at = now
        quote.save(update_fields=['status', 'decision_reason', 'decided_at'])

        if not quote.is_upsell:
            booking.status = JobBooking.STATUS_COMPLETED_INSPECTION_ONLY
            booking.completed_at = now
            # Inspection-flow bookings (sub_service is None) carry the Rs.500
            # fee; pre-paid fixed/labor flows do not. The pre-existing
            # ``inspection_fee`` column is the source of truth — null implies 0.
            booking.final_cash_to_collect = booking.inspection_fee or Decimal('0')
            booking.save(update_fields=['status', 'completed_at', 'final_cash_to_collect'])

            # Inspection-fee finance settlement is a one-time event on
            # the initial decision. Upsell declines don't re-fire it.
            finance.apply_inspection_fee_decision(booking=booking, decision='declined')

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.QUOTE_DECLINED,
            payload={
                **_payload_basics(booking),
                'quote_id': quote.id,
                'reason': reason,
            },
        ))

    return booking


# ---------------------------------------------------------------------------
# Completion
# ---------------------------------------------------------------------------


# CLAUDE.md "Customer ↔ Technician = CASH ONLY". The ``method`` parameter
# exists on the API only so a future expansion (e.g. mobile-money receipt)
# can extend the set without a model change; until that ships, anything
# other than 'cash' is rejected at the service boundary.
_VALID_CASH_COLLECTION_METHODS = frozenset({'cash'})


def mark_complete_with_cash(
    *,
    booking_id: int,
    technician_user,
    cash_amount: Decimal,
    method: str = 'cash',
    finance=None,
) -> JobBooking:
    """IN_PROGRESS → COMPLETED.

    Sprint meta §14 rule 2 — the tech taps a single ``Cash Collected: Rs.X``
    button that both records the cash and completes the booking. Stamps
    completion + cash columns and broadcasts both ``payment_received`` and
    ``job_completed`` to the customer.
    """
    finance = _resolve_finance(finance)
    if method not in _VALID_CASH_COLLECTION_METHODS:
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message='Unsupported cash collection method.',
            errors={'method': [f'must be one of {sorted(_VALID_CASH_COLLECTION_METHODS)}']},
        )
    # Decimal coercion outside the atomic so the canonical envelope fires
    # before any DB work. Bad input (None, 'abc', etc.) becomes a clean
    # 400 instead of a decimal.InvalidOperation 500.
    try:
        cash_amount_d = Decimal(str(cash_amount))
    except (TypeError, ValueError, ArithmeticError):
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message='Cash amount is not a valid decimal.',
            errors={'cash_amount': [f'invalid decimal: {cash_amount!r}']},
        )

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        # Idempotent re-entry runs BEFORE the positive-cash guard so a
        # duplicate POST from a flaky client never re-validates an amount
        # that was accepted on the original call.
        if booking.status == JobBooking.STATUS_COMPLETED:
            return booking

        if booking.status != JobBooking.STATUS_IN_PROGRESS:
            _reject_invalid_from_state(booking, 'Completion only valid from IN_PROGRESS.')

        # Sanity floor: a negative amount can never be legitimate; the
        # strict equality check below catches positive mismatches. Zero
        # IS valid when the server-computed ``final_cash_to_collect``
        # is also zero (e.g. quote total equals the inspection fee
        # deduction exactly — edge case but reachable on cheap repairs).
        if cash_amount_d < Decimal('0'):
            raise BookingValidationError(
                code=ERROR_INVALID_INPUT,
                message='Cash amount must not be negative.',
                errors={'cash_amount': ['must be >= 0']},
            )

        # Audit P2 (Pass 2 / O2): the tech-side button surfaces the
        # server-derived ``final_cash_to_collect``; the SUBMITTED amount
        # MUST equal that figure. Without this check, a malicious or
        # buggy client can mark a Rs. 5000 job paid with Rs. 1, and the
        # platform would commission off the under-reported cash. Refuse
        # any mismatch with a clean envelope so finance never reconciles
        # against an attacker-controlled number.
        #
        # ``final_cash_to_collect`` may be None on the COMPLETED_INSPECTION_ONLY
        # path, which never reaches this function (that path runs through
        # decline_quote, not mark_complete_with_cash). For IN_PROGRESS we
        # assert it is set; absence is a server-side invariant break.
        expected = booking.final_cash_to_collect
        if expected is None:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Booking has no final_cash_to_collect set; cannot complete.',
                errors={'final_cash_to_collect': ['missing on booking']},
            )
        if cash_amount_d != expected:
            raise BookingValidationError(
                code=ERROR_INVALID_INPUT,
                message='Cash amount must match the server-computed final cash to collect.',
                errors={
                    'cash_amount': [
                        f'expected {expected}, got {cash_amount_d}',
                    ],
                },
            )

        now = timezone.now()
        booking.status = JobBooking.STATUS_COMPLETED
        booking.completed_at = now
        booking.cash_collected_amount = cash_amount_d
        booking.cash_collected_at = now
        booking.cash_collection_method = method
        booking.save(update_fields=[
            'status',
            'completed_at',
            'cash_collected_amount',
            'cash_collected_at',
            'cash_collection_method',
        ])

        finance.record_cash_collected(booking=booking, amount=cash_amount_d, method=method)
        finance.record_commission(booking=booking, amount=cash_amount_d)

        # Two events for both audiences. payment_received first
        # (informational cash receipt), job_completed second (lifecycle
        # close). Order matters only insofar as the customer's UI reacts
        # to the lifecycle close last.
        def _emit():
            _broadcast_both(
                booking=booking,
                event_type=EventType.PAYMENT_RECEIVED,
                payload={
                    **_payload_basics(booking),
                    'cash_collected_amount': str(cash_amount_d),
                    'cash_collection_method': method,
                },
            )
            _broadcast_both(
                booking=booking,
                event_type=EventType.JOB_COMPLETED,
                payload=_payload_basics(booking),
            )

        transaction.on_commit(_emit)

    return booking


# ---------------------------------------------------------------------------
# Cancellation
# ---------------------------------------------------------------------------


def _cancel_phase_for_status(status: str) -> str:
    """Map booking from-state to a cancellation phase string.

    Used both for the ``cancel_reason`` value and for the FinancePort hook.
    """
    if status == JobBooking.STATUS_AWAITING_TECH_ACCEPT:
        return 'pre_accept'
    if status in (JobBooking.STATUS_CONFIRMED, JobBooking.STATUS_EN_ROUTE):
        return 'pre_arrival'
    if status in (
        JobBooking.STATUS_ARRIVED,
        JobBooking.STATUS_INSPECTING,
        JobBooking.STATUS_QUOTED,
    ):
        return 'post_arrival'
    return 'post_arrival'  # defensive default for unexpected paths


_CUSTOMER_CANCELLABLE = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
})


def cancel_by_customer(
    *,
    booking_id: int,
    customer_user,
    finance=None,
) -> JobBooking:
    """Customer cancels — any non-IN_PROGRESS, non-terminal state.

    IN_PROGRESS is rejected because work has actually started; the customer's
    only out at that point is the dispute flow. Cancel reason maps to the
    phase string consumed by the receipt UI and the FinancePort hook.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        if booking.status not in _CUSTOMER_CANCELLABLE:
            raise BookingValidationError(
                code=ERROR_CANCELLATION_NOT_ALLOWED,
                message='Booking cannot be cancelled in its current state. Open a dispute instead.',
                errors={'current_status': [booking.status]},
            )

        phase = _cancel_phase_for_status(booking.status)
        reason_map = {
            'pre_accept': 'customer_cancelled_pre_accept',
            'pre_arrival': 'customer_cancelled_post_accept',
            'post_arrival': 'customer_cancelled_post_arrival',
        }

        now = timezone.now()
        booking.status = JobBooking.STATUS_CANCELLED
        booking.cancelled_at = now
        booking.cancelled_by = customer_user
        booking.cancel_reason = reason_map[phase]
        booking.save(update_fields=['status', 'cancelled_at', 'cancelled_by', 'cancel_reason'])

        finance.apply_cancellation_charge(booking=booking, actor='customer', phase=phase)

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.BOOKING_CANCELLED,
            payload={
                **_payload_basics(booking),
                'actor': 'customer',
                'phase': phase,
                'reason': booking.cancel_reason,
            },
        ))

    return booking


_TECH_CANCELLABLE = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
    JobBooking.STATUS_IN_PROGRESS,
})


def cancel_by_tech(
    *,
    booking_id: int,
    technician_user,
    finance=None,
) -> JobBooking:
    """Technician cancels — any non-terminal state.

    Writes a ``TechReliabilityIncident`` row (audit P0-08; admin reads via
    Django Admin since admin realtime is deferred) and broadcasts the
    cancellation to the customer. No customer-facing fee, but the
    reliability-incident row supports the future reliability-score sprint.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if booking.status in JobBooking.TERMINAL_STATUSES:
            raise BookingValidationError(
                code=ERROR_CANCELLATION_NOT_ALLOWED,
                message='Booking is already in a terminal state.',
                errors={'current_status': [booking.status]},
            )
        if booking.status not in _TECH_CANCELLABLE:
            raise BookingValidationError(
                code=ERROR_CANCELLATION_NOT_ALLOWED,
                message='Booking cannot be cancelled by tech in its current state.',
                errors={'current_status': [booking.status]},
            )

        phase = _cancel_phase_for_status(booking.status)
        now = timezone.now()
        booking.status = JobBooking.STATUS_CANCELLED
        booking.cancelled_at = now
        booking.cancelled_by = technician_user
        booking.cancel_reason = 'technician_cancelled'
        booking.save(update_fields=['status', 'cancelled_at', 'cancelled_by', 'cancel_reason'])

        TechReliabilityIncident.objects.create(
            technician=booking.technician,
            booking=booking,
            incident_type=TechReliabilityIncident.INCIDENT_TECH_CANCEL,
            phase=phase,
        )

        finance.apply_cancellation_charge(booking=booking, actor='tech', phase=phase)

        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.BOOKING_CANCELLED,
            payload={
                **_payload_basics(booking),
                'actor': 'tech',
                'phase': phase,
                'reason': booking.cancel_reason,
            },
        ))

    return booking


# ---------------------------------------------------------------------------
# No-show
# ---------------------------------------------------------------------------


_TECH_REPORT_NO_SHOW = frozenset({
    JobBooking.STATUS_ARRIVED,
    JobBooking.STATUS_INSPECTING,
    JobBooking.STATUS_QUOTED,
})

_CUSTOMER_REPORT_NO_SHOW = frozenset({
    JobBooking.STATUS_CONFIRMED,
    JobBooking.STATUS_EN_ROUTE,
    JobBooking.STATUS_ARRIVED,
})


# Spec: a no-show may only be filed once 15 minutes have elapsed since
# the relevant anchor (tech filing -> from arrival, customer filing ->
# from scheduled_start). Enforced at the service layer so non-view
# callers (cron, admin, future RPC) inherit the gate.
MIN_NO_SHOW_ELAPSED_SECONDS = 15 * 60


def mark_no_show(
    *,
    booking_id: int,
    actor_user,
    actor_role: str,  # 'tech' | 'customer'
    finance=None,
    _clock=None,
) -> JobBooking:
    """Mark booking as NO_SHOW.

    Tech path (``actor_role='tech'``): tech arrived but customer is missing.
    Allowed from {ARRIVED, INSPECTING, QUOTED}. Anchored on ``arrived_at``
    (the wait clock starts when the tech is at the door).

    Customer path (``actor_role='customer'``): tech never showed.
    Allowed from {CONFIRMED, EN_ROUTE, ARRIVED}; also writes a
    ``TechReliabilityIncident`` row. Anchored on ``scheduled_start``
    (the customer's perspective is "the booking time has come and the
    tech is not here").

    Both paths require ``MIN_NO_SHOW_ELAPSED_SECONDS`` (15 min) to have
    passed since the anchor. Filing too early raises
    ``ERROR_NO_SHOW_TOO_EARLY``.

    ``_clock`` is a test seam; production callers leave it None.
    """
    finance = _resolve_finance(finance)
    now = (_clock or timezone.now)()

    if actor_role not in ('tech', 'customer'):
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message="actor_role must be 'tech' or 'customer'.",
        )

    with transaction.atomic():
        booking = _lock_booking(booking_id)

        if actor_role == 'tech':
            _require_assigned_tech(booking, actor_user)
            allowed = _TECH_REPORT_NO_SHOW
            broadcast_user = booking.customer
            broadcast_role = 'customer'
            # Anchor: when did the tech arrive? Falls back to
            # scheduled_start if arrived_at is null (defensive — tech
            # paths require status >= ARRIVED, so arrived_at should be
            # set, but a manually-mutated row could still slip through).
            anchor = booking.arrived_at or booking.scheduled_start
        else:
            _require_customer(booking, actor_user)
            allowed = _CUSTOMER_REPORT_NO_SHOW
            broadcast_user = booking.technician.user
            broadcast_role = 'technician'
            anchor = booking.scheduled_start

        if booking.status not in allowed:
            _reject_invalid_from_state(
                booking, f'No-show by {actor_role} not allowed in current state.',
            )

        # Time-elapsed gate (sprint meta — 15 min). Service-level so any
        # caller pays the wait, not just the view layer.
        elapsed = (now - anchor).total_seconds()
        if elapsed < MIN_NO_SHOW_ELAPSED_SECONDS:
            remaining = int(MIN_NO_SHOW_ELAPSED_SECONDS - elapsed)
            raise BookingValidationError(
                code=ERROR_NO_SHOW_TOO_EARLY,
                message='No-show cannot be filed yet — wait at least 15 minutes.',
                errors={'wait_seconds': [str(max(0, remaining))]},
            )
        booking.status = JobBooking.STATUS_NO_SHOW
        booking.no_show_at = now
        booking.no_show_actor = actor_role
        booking.save(update_fields=['status', 'no_show_at', 'no_show_actor'])

        if actor_role == 'customer':
            # Customer reports tech as no-show — log a reliability incident.
            TechReliabilityIncident.objects.create(
                technician=booking.technician,
                booking=booking,
                incident_type=TechReliabilityIncident.INCIDENT_TECH_NO_SHOW,
            )

        # Broadcast to both audiences (reporter + reported-against) so a
        # cross-device / dev_panel session sees the terminal flip on
        # both sides. Previously only the counterparty got the event —
        # the actor refreshed locally — but that breaks for shared-user
        # sessions and the dev_panel.
        transaction.on_commit(lambda: _broadcast_both(
            booking=booking,
            event_type=EventType.BOOKING_NO_SHOW,
            payload={
                **_payload_basics(booking),
                'reported_by': actor_role,
            },
        ))

    return booking


# ---------------------------------------------------------------------------
# Dispute
# ---------------------------------------------------------------------------


# Disputes can be opened from any post-CONFIRMED state, including terminal
# completion / cancellation states (post-job dispute window). Pre-CONFIRMED
# (AWAITING / PENDING / TECH_DECLINED / TECH_NO_RESPONSE) are not disputable
# — the booking never became real work.
_DISPUTE_DISALLOWED = frozenset({
    JobBooking.STATUS_PENDING,
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_TECH_DECLINED,
    JobBooking.STATUS_TECH_NO_RESPONSE,
})


def apply_dispute_opened_side_effects(
    *,
    ticket: SupportTicket,
    booking: JobBooking,
    opener_role: str,
) -> None:
    """Stamp ``dispute_opened_at``, flip booking to DISPUTED if non-terminal,
    and broadcast ``DISPUTE_OPENED`` to both audiences.

    Shared between the form-intake path (``open_dispute``) and the
    chatbot-intake path
    (``disputes.services.ticket_creation.create_from_chatbot_session``)
    so both intake methods produce the same audit + realtime footprint.

    Caller contract:
      * already holds a ``select_for_update`` lock on ``booking``
      * already inside ``transaction.atomic``
      * ``opener_role`` ∈ {"customer", "technician"} — broadcast payload
        consumers branch on it.

    First-dispute semantics: ``dispute_opened_at`` is only stamped when
    previously null. Subsequent ticket creations on the same booking
    (multiple OPEN tickets are permitted) skip the timestamp. The status
    flip is one-shot via ``TERMINAL_STATUSES`` membership (``DISPUTED``
    is itself terminal, so the second-open path is also a no-op).
    """
    first_dispute = booking.dispute_opened_at is None
    update_fields: list[str] = []
    if first_dispute:
        booking.dispute_opened_at = timezone.now()
        update_fields.append('dispute_opened_at')
    # Preserve terminal status. CANCELLED / COMPLETED / etc. bookings
    # with a dispute filed against them stay queryable as such; the
    # dispute is captured by ``dispute_opened_at IS NOT NULL`` plus
    # the ticket row, not by erasing the prior terminal status. For
    # non-terminal bookings (IN_PROGRESS being the typical case) the
    # flip to DISPUTED is what locks out further transitions on the
    # booking until admin resolves, so it stays mandatory there.
    if booking.status not in JobBooking.TERMINAL_STATUSES:
        booking.status = JobBooking.STATUS_DISPUTED
        update_fields.append('status')
    if update_fields:
        booking.save(update_fields=update_fields)

    # Broadcast to both audiences so cross-device sessions and dev_panel
    # invalidate. The opener's own active session typically refreshes via
    # the local POST action button, but other sessions need the WS event.
    transaction.on_commit(lambda: _broadcast_both(
        booking=booking,
        event_type=EventType.DISPUTE_OPENED,
        payload={
            **_payload_basics(booking),
            'ticket_id': ticket.id,
            'opened_by_role': opener_role,
        },
    ))


def open_dispute(
    *,
    booking_id: int,
    opener_user,
    initial_reason: str,
    photo_file=None,
    finance=None,
) -> SupportTicket:
    """Open a dispute on the booking.

    Either party can open. Multiple OPEN tickets per booking are allowed —
    each captures a distinct grievance. The booking's ``status`` flip to
    DISPUTED is one-shot (only happens on the first open ticket); subsequent
    opens leave status alone but still create new tickets.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)

        # Either-party authorization — opener must be customer or assigned tech.
        is_customer = booking.customer_id == opener_user.id
        is_tech = booking.technician.user_id == opener_user.id
        if not (is_customer or is_tech):
            raise BookingValidationError(
                code=ERROR_NOT_ASSIGNED_TO_YOU,
                message='Only the booking customer or technician can open a dispute.',
            )

        if booking.status in _DISPUTE_DISALLOWED:
            raise BookingValidationError(
                code=ERROR_DISPUTE_NOT_DISPUTABLE_STATUS,
                message='Booking cannot be disputed in its current state.',
                errors={'current_status': [booking.status]},
            )

        ticket = SupportTicket.objects.create(
            booking=booking,
            opened_by=opener_user,
            dispute_intake_method=SupportTicket.INTAKE_FORM,
            initial_reason=initial_reason,
            status=SupportTicket.STATUS_OPEN,
        )

        if photo_file is not None:
            TicketEvidence.objects.create(
                ticket=ticket,
                uploaded_by=opener_user,
                image=photo_file,
            )

        apply_dispute_opened_side_effects(
            ticket=ticket,
            booking=booking,
            opener_role='customer' if is_customer else 'technician',
        )

    return ticket


_VALID_FINAL_STATUSES = frozenset({
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
    JobBooking.STATUS_CANCELLED,
})

# Binary outcome set used by the v2 admin dispute flow. The legacy
# three-way outcomes (REFUND_CUSTOMER / PENALIZE_TECH / DISMISS) are
# retained on the model for back-compat but are NEVER written by this
# orchestrator — admin_resolve_dispute rejects any value outside this
# set.
_VALID_OUTCOMES = frozenset({
    SupportTicket.OUTCOME_ACCEPT_REFUND,
    SupportTicket.OUTCOME_REJECT,
})


def _compute_refund_base(booking: JobBooking) -> Decimal:
    """Pick the canonical "what was the customer charged" amount for refund math.

    Preference order:
      1. ``final_cash_to_collect`` — orchestrator-stamped at quote
         approval, the exact number the tech presented to the customer.
      2. ``cash_collected_amount`` — set on cash collection; tightest
         match to what actually changed hands.
      3. ``price_amount`` — booking-creation price floor. Used only when
         the booking never reached the QUOTED state.

    Returns Decimal('0') for the degenerate case where every column is
    None — in practice impossible for a DISPUTED booking (dispute can
    only be opened from CONFIRMED+), but defensive math is cheap.
    """
    candidates = (
        booking.cash_collected_amount,
        booking.final_cash_to_collect,
        booking.price_amount,
    )
    for c in candidates:
        if c is not None:
            return Decimal(c)
    return Decimal('0')


def admin_resolve_dispute(
    *,
    ticket_id: int,
    admin_user,
    outcome: str,
    notes: str,
    final_status: str,
    tech_penalty_percentage: int = 0,
    external_refund_reference: str = '',
    customer_notification_message: str = '',
    finance=None,
) -> SupportTicket:
    """DISPUTED → admin-chosen terminal state. Binary outcome model.

    ``outcome`` is one of ``ACCEPT_REFUND`` / ``REJECT``.
    ``final_status`` is one of ``COMPLETED`` / ``COMPLETED_INSPECTION_ONLY`` /
    ``CANCELLED``. Both parties get a ``dispute_resolved`` broadcast.

    On ACCEPT_REFUND
    ----------------
    * ``external_refund_reference`` is mandatory (admin must have
      already sent the customer their money via JazzCash / bank wire
      out-of-band, and pastes the gateway txn id here).
    * ``tech_penalty_percentage`` (0–100) splits the cost: that
      percentage of the refund base amount is debited from the
      technician's wallet as a ``REFUND_DEBIT`` row. The remainder is
      absorbed by the platform.
    * The wallet ledger write goes through
      ``wallet.services.ledger.record_transaction`` which:
        - Re-fetches the tech under ``select_for_update``.
        - Computes ``balance_after`` atomically with the deduction.
        - Auto-flips ``is_online`` to False if the balance crosses
          into negative (lockout signal).
        - Schedules a WALLET_BALANCE_UPDATED broadcast on commit.
      Idempotency: keyed on ``dispute:<ticket_id>:refund`` so retry
      from the admin form (browser refresh on POST, click-spam) does
      not double-charge.

    On REJECT
    ---------
    * No wallet activity, no ledger row.
    * ``customer_notification_message`` is stored verbatim — it ships
      in the realtime payload so the customer sees *why* their dispute
      was denied rather than just a status flip.

    Both outcomes broadcast ``DISPUTE_RESOLVED`` to both parties.

    Authorization: this function trusts the caller's view layer to
    confirm admin role (Django Admin custom action). No IDOR scope
    here because the admin is acting across users by design.

    Idempotency: a re-call after the ticket is already RESOLVED is a
    no-op — the function returns the existing row without re-locking,
    re-charging, or re-broadcasting. Wallet idempotency is independently
    enforced by the ledger's transaction_reference_number constraint;
    the two layers compose safely.
    """
    finance = _resolve_finance(finance)

    if outcome not in _VALID_OUTCOMES:
        raise BookingValidationError(
            code=ERROR_INVALID_TRANSITION,
            message='Invalid dispute outcome.',
            errors={'outcome': [outcome]},
        )
    if final_status not in _VALID_FINAL_STATUSES:
        raise BookingValidationError(
            code=ERROR_INVALID_TRANSITION,
            message='Invalid final status for dispute resolution.',
            errors={'final_status': [final_status]},
        )

    # Coerce + range-check tech_penalty_percentage. Surface-level
    # validation lives in the admin form, but the orchestrator is the
    # ledger gate — never trust the caller.
    try:
        penalty_pct = int(tech_penalty_percentage)
    except (TypeError, ValueError):
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message='Tech penalty must be a whole number 0–100.',
            errors={'tech_penalty_percentage': [str(tech_penalty_percentage)]},
        )
    if not 0 <= penalty_pct <= 100:
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message='Tech penalty must be between 0 and 100.',
            errors={'tech_penalty_percentage': [penalty_pct]},
        )

    # External refund reference is mandatory on ACCEPT_REFUND. On
    # REJECT it must be empty (we don't want stale refs leaking onto
    # dismissed disputes).
    ext_ref = (external_refund_reference or '').strip()
    if outcome == SupportTicket.OUTCOME_ACCEPT_REFUND and not ext_ref:
        raise BookingValidationError(
            code=ERROR_INVALID_INPUT,
            message='External refund reference is required when accepting a refund.',
            errors={'external_refund_reference': ['required']},
        )
    if outcome == SupportTicket.OUTCOME_REJECT:
        ext_ref = ''
        penalty_pct = 0  # REJECT can never carry a wallet penalty.

    customer_msg = (customer_notification_message or '').strip()

    with transaction.atomic():
        # Lock-ordering: booking first, ticket second — matches every
        # user-facing transition (which only ever locks the booking),
        # so an admin resolving a dispute concurrent with a customer or
        # tech action can never deadlock-cycle.
        try:
            unlocked_ticket = SupportTicket.objects.only(
                'id', 'booking_id', 'status',
            ).get(id=ticket_id)
        except SupportTicket.DoesNotExist:
            raise BookingValidationError(
                code=ERROR_TICKET_NOT_FOUND,
                message='Dispute ticket not found.',
                status=drf_status.HTTP_404_NOT_FOUND,
            )
        if unlocked_ticket.status == SupportTicket.STATUS_RESOLVED:
            return unlocked_ticket  # idempotent — no lock needed

        booking = _lock_booking(unlocked_ticket.booking_id)
        ticket = (
            SupportTicket.objects
            .select_for_update()
            .select_related('booking__customer', 'booking__technician__user')
            .get(id=ticket_id)
        )
        # Re-check resolution under the lock — concurrent admin clicks
        # could both pass the unlocked check above; only one wins the
        # lock and the loser short-circuits.
        if ticket.status == SupportTicket.STATUS_RESOLVED:
            return ticket

        # --- Wallet writeback (ACCEPT_REFUND + penalty > 0 only) --------
        # Compute refund_base FIRST so the audit row reflects what the
        # admin saw when they decided the percentage, not whatever the
        # booking row drifts to afterwards. The ledger call lives inside
        # the same atomic block — if the wallet write raises, the entire
        # resolution rolls back (ticket stays OPEN, booking stays
        # DISPUTED). Defensive maximalism per CLAUDE.md financial-code rule.
        refund_base = _compute_refund_base(booking)
        tech_deduction = Decimal('0')
        if (
            outcome == SupportTicket.OUTCOME_ACCEPT_REFUND
            and penalty_pct > 0
            and refund_base > Decimal('0')
        ):
            # Whole-rupee floor — paisa would silently break the wallet
            # display formatter and the JazzCash withdrawal path. Use
            # integer division by 100 to stay in Decimal land.
            tech_deduction = (refund_base * Decimal(penalty_pct)) // Decimal(100)
            if tech_deduction > Decimal('0'):
                from wallet.models import RefundDeduction, TransactionType
                from wallet.services.ledger import record_transaction

                wt = record_transaction(
                    technician=booking.technician,
                    transaction_type=TransactionType.REFUND_DEBIT,
                    amount=-tech_deduction,  # signed: debit
                    transaction_reference_number=f'dispute:{ticket.id}:refund',
                    memo=(
                        f'Refund for booking #{booking.id} '
                        f'({penalty_pct}% of Rs.{refund_base})'
                    ),
                )
                # Attach the subtype row. OneToOne on wallet_transaction
                # makes this idempotent against the ledger's own
                # idempotency key — get_or_create avoids the duplicate-
                # insert race on browser-refresh-during-POST.
                RefundDeduction.objects.get_or_create(
                    wallet_transaction=wt,
                    defaults={
                        'penalty_reason': (
                            f'Dispute ticket #{ticket.id} accepted by '
                            f'{getattr(admin_user, "username", "admin")} '
                            f'(refund base Rs.{refund_base}, '
                            f'tech share {penalty_pct}%)'
                        ),
                    },
                )

        # --- Stamp the ticket ------------------------------------------
        now = timezone.now()
        ticket.status = SupportTicket.STATUS_RESOLVED
        ticket.resolution_outcome = outcome
        ticket.resolution_notes = notes
        ticket.resolved_at = now
        ticket.resolved_by = admin_user
        ticket.tech_penalty_percentage = penalty_pct
        ticket.external_refund_reference = ext_ref
        ticket.customer_notification_message = customer_msg
        ticket.save(update_fields=[
            'status', 'resolution_outcome', 'resolution_notes',
            'resolved_at', 'resolved_by',
            'tech_penalty_percentage', 'external_refund_reference',
            'customer_notification_message',
        ])

        # --- Stamp the booking's terminal-state audit columns ----------
        # Mirrors what cancel_by_* / mark_complete_with_cash write so
        # admin-resolved dispositions don't drop out of analytics
        # filtering on the timestamps.
        booking.status = final_status
        booking_update_fields = ['status']
        if final_status == JobBooking.STATUS_CANCELLED:
            booking.cancelled_at = now
            booking.cancelled_by = admin_user
            booking.cancel_reason = 'admin_resolved_dispute'
            booking_update_fields += [
                'cancelled_at', 'cancelled_by', 'cancel_reason',
            ]
        elif final_status in (
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
        ):
            if booking.completed_at is None:
                booking.completed_at = now
                booking_update_fields.append('completed_at')
        booking.save(update_fields=booking_update_fields)

        # --- Realtime broadcast ----------------------------------------
        admin_username = (
            getattr(admin_user, 'username', None)
            or getattr(admin_user, 'email', None)
            or 'admin'
        )
        # Snapshot Decimals as strings for the wire — JSON serialization
        # of Decimal is implementation-dependent and the Flutter mapper
        # parses wire-strings.
        deduction_str = str(tech_deduction)
        refund_base_str = str(refund_base)

        def _emit_to_both():
            for u, role in (
                (booking.customer, 'customer'),
                (booking.technician.user, 'technician'),
            ):
                _broadcast(
                    user=u,
                    target_role=role,
                    event_type=EventType.DISPUTE_RESOLVED,
                    payload={
                        **_payload_basics(booking),
                        'ticket_id': ticket.id,
                        'outcome': outcome,
                        'final_status': final_status,
                        'resolved_by_admin': admin_username,
                        'customer_message': customer_msg,
                        'tech_penalty_percentage': penalty_pct,
                        'tech_wallet_deduction': deduction_str,
                        'refund_base_amount': refund_base_str,
                        'external_refund_reference': ext_ref,
                    },
                )

        transaction.on_commit(_emit_to_both)

    return ticket


# ---------------------------------------------------------------------------
# Reschedule
# ---------------------------------------------------------------------------


_RESCHEDULE_FROM = frozenset({
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_CONFIRMED,
})


def reschedule(
    *,
    original_booking_id: int,
    customer_user,
    new_scheduled_start,
    new_scheduled_end,
    finance=None,
) -> JobBooking:
    """Reschedule {AWAITING, CONFIRMED} → cancel original + create child booking.

    The original is CANCELLED with ``cancel_reason='customer_rescheduled'``
    (fee-exempt). A new child JobBooking is created with the same
    technician, address, service, sub_service, promo snapshots, and pricing
    — only the schedule changes. The child is dispatched via the existing
    ``dispatch_job_new_request_event`` so the tech sees a fresh offer card.

    EN_ROUTE and later are not reschedulable — the tech is already in motion
    or working. Use cancel + book-fresh for those edge cases.
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        original = _lock_booking(original_booking_id)
        _require_customer(original, customer_user)

        if original.status not in _RESCHEDULE_FROM:
            raise BookingValidationError(
                code=ERROR_RESCHEDULE_NOT_ALLOWED,
                message='Booking cannot be rescheduled in its current state.',
                errors={'current_status': [original.status]},
            )

        # Lock the technician row + re-check the new window for an overlap.
        # Mirrors instant_book_service: without this lock, a concurrent
        # instant-book and a reschedule INTO the same target slot can both
        # pass their respective checks under READ_COMMITTED and double-book
        # the technician. Lock ordering (booking → tech profile) is safe:
        # instant_book_service only locks the tech profile, never a booking
        # row, so no deadlock cycle is reachable.
        # ``.exclude(id=original.id)`` is required because the original is
        # still in AWAITING/CONFIRMED at this moment (the cancellation
        # mutation runs below); without the exclude, shortening the
        # original's window in-place would self-overlap.
        TechnicianProfile.objects.select_for_update().get(pk=original.technician_id)
        overlap_exists = JobBooking.objects.filter(
            technician=original.technician,
            status__in=[
                JobBooking.STATUS_PENDING,
                JobBooking.STATUS_AWAITING_TECH_ACCEPT,
                JobBooking.STATUS_CONFIRMED,
            ],
            scheduled_start__lt=new_scheduled_end,
            scheduled_end__gt=new_scheduled_start,
        ).exclude(id=original.id).exists()
        if overlap_exists:
            raise BookingValidationError(
                code=ERROR_RESCHEDULE_NOT_ALLOWED,
                message='New time slot conflicts with another booking.',
                errors={'new_scheduled_start': ['slot unavailable']},
            )

        now = timezone.now()
        original.status = JobBooking.STATUS_CANCELLED
        original.cancelled_at = now
        original.cancelled_by = customer_user
        original.cancel_reason = 'customer_rescheduled'
        original.save(update_fields=[
            'status', 'cancelled_at', 'cancelled_by', 'cancel_reason',
        ])

        child = JobBooking.objects.create(
            technician=original.technician,
            customer=original.customer,
            address=original.address,
            service=original.service,
            sub_service=original.sub_service,
            promotion=original.promotion,
            scheduled_start=new_scheduled_start,
            scheduled_end=new_scheduled_end,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            price_amount=original.price_amount,
            price_context=original.price_context,
            inspection_fee=original.inspection_fee,
            # Carry the cash-button value so a FIXED_GIG / LABOR_GIG child
            # has the same final_cash_to_collect the original surfaced
            # before the reschedule. INSPECTION-flow originals have None
            # here (cash isn't computed until quote-decision), so the
            # carry is a no-op for that path.
            final_cash_to_collect=original.final_cash_to_collect,
            promo_code_snapshot=original.promo_code_snapshot,
            promo_discount_snapshot=original.promo_discount_snapshot,
            actual_address_snapshot=original.actual_address_snapshot,
            parent_booking=original,
        )

        # Broadcast to BOTH the customer (who initiated) and the tech
        # (who lost the assignment). The customer's own session
        # typically refreshes via the local action POST, but other
        # devices / dev_panel as actor still need the WS event to
        # invalidate the original booking and route to the child.
        transaction.on_commit(lambda: _broadcast_both(
            booking=original,
            event_type=EventType.BOOKING_RESCHEDULED,
            payload={
                **_payload_basics(original),
                'new_booking_id': child.id,
                'new_scheduled_start': child.scheduled_start.isoformat(),
            },
        ))

        # Then dispatch the child as a fresh job request. Lazy import keeps
        # the orchestrator decoupled from the dispatch service at module load.
        def _dispatch_child():
            from bookings.services.job_request_dispatch import dispatch_job_new_request_event
            dispatch_job_new_request_event(child)

        transaction.on_commit(_dispatch_child)

    return child

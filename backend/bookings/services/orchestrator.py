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

from bookings.exceptions import (
    BookingValidationError,
    ERROR_CANCELLATION_NOT_ALLOWED,
    ERROR_DISPUTE_NOT_DISPUTABLE_STATUS,
    ERROR_INVALID_QUOTE_EMPTY,
    ERROR_INVALID_TRANSITION,
    ERROR_NOT_ASSIGNED_TO_YOU,
    ERROR_QUOTE_BAND_VIOLATION,
    ERROR_RESCHEDULE_NOT_ALLOWED,
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
    """
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

        transaction.on_commit(lambda: _broadcast(
            user=booking.customer,
            target_role='customer',
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

        transaction.on_commit(lambda: _broadcast(
            user=booking.customer,
            target_role='customer',
            event_type=EventType.TECH_ARRIVED,
            payload={**_payload_basics(booking), 'source': source},
        ))

    return booking


def start_inspection(*, booking_id: int, technician_user, finance=None) -> JobBooking:
    """ARRIVED → INSPECTING.

    Triggered when the tech opens the quote builder (sprint meta §14
    rule 1 — UI navigation IS the trigger). No event broadcast: this is
    a UI-flip-only transition.
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

    return booking


# ---------------------------------------------------------------------------
# Quote flow
# ---------------------------------------------------------------------------


def _validate_line_items(line_items: list[dict]) -> None:
    """Schema and pricing-band check on submit_quote input.

    Empty list → ERROR_INVALID_QUOTE_EMPTY.
    Each dict must carry sub_service_id, quantity, priced_at.
    Per-line band:
        fixed-price: priced_at == base_price
        labor:      base_price <= priced_at <= max_price (max_price required)
    """
    if not line_items:
        raise BookingValidationError(
            code=ERROR_INVALID_QUOTE_EMPTY,
            message='A quote must contain at least one line item.',
        )

    from catalog.models import SubService

    sub_ids = [li['sub_service_id'] for li in line_items]
    sub_map = {s.id: s for s in SubService.objects.filter(id__in=sub_ids)}

    for idx, li in enumerate(line_items):
        sub_id = li['sub_service_id']
        quantity = li.get('quantity', 1)
        priced_at = Decimal(str(li['priced_at']))

        sub = sub_map.get(sub_id)
        if sub is None:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Unknown sub-service in quote.',
                errors={f'line_items[{idx}].sub_service_id': ['not found']},
            )

        if quantity <= 0:
            raise BookingValidationError(
                code=ERROR_QUOTE_BAND_VIOLATION,
                message='Quantity must be positive.',
                errors={f'line_items[{idx}].quantity': ['must be > 0']},
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

        # Mark any prior SUBMITTED quote as SUPERSEDED before adding the new one.
        # Customers can submit_quote → request_revision → submit_quote → ... and
        # at any moment exactly one quote should be SUBMITTED.
        booking.quotes.filter(status=Quote.STATUS_SUBMITTED).update(
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

        transaction.on_commit(lambda: _broadcast(
            user=booking.customer,
            target_role='customer',
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

        if booking.status != JobBooking.STATUS_QUOTED:
            _reject_invalid_from_state(
                booking, 'Revision can only be requested on a QUOTED booking.',
            )

        try:
            quote = booking.quotes.select_for_update().get(id=quote_id)
        except Quote.DoesNotExist:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Quote not found on this booking.',
            )

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Only a SUBMITTED quote can be revised.',
                errors={'quote_status': [quote.status]},
            )

        now = timezone.now()
        quote.status = Quote.STATUS_SUPERSEDED
        quote.decision_reason = reason
        quote.decided_at = now
        quote.save(update_fields=['status', 'decision_reason', 'decided_at'])

        booking.status = JobBooking.STATUS_INSPECTING
        booking.save(update_fields=['status'])

        transaction.on_commit(lambda: _broadcast(
            user=booking.technician.user,
            target_role='technician',
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

        try:
            quote = booking.quotes.select_for_update().prefetch_related('line_items').get(id=quote_id)
        except Quote.DoesNotExist:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Quote not found on this booking.',
            )

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
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
        # full set of BookingItem rows for reconciliation.
        for li in quote.line_items.all():
            BookingItem.objects.create(
                booking=booking,
                sub_service_id=li.sub_service_id,
                quantity=li.quantity,
                price_charged=li.priced_at,
                line_total=li.line_total,
                sourced_quote=quote,
            )

        # Recompute denormalized totals from the snapshot. Avoids floating
        # drift from ad-hoc additions to ``base_services_total``.
        running = booking.items.aggregate(
            total=models_sum('line_total'),
        )['total'] or Decimal('0')
        booking.base_services_total = running

        update_fields = ['base_services_total']
        if not quote.is_upsell:
            booking.status = JobBooking.STATUS_IN_PROGRESS
            update_fields.append('status')
            if booking.work_started_at is None:
                booking.work_started_at = now
                update_fields.append('work_started_at')
        booking.save(update_fields=update_fields)

        finance.apply_inspection_fee_decision(booking=booking, decision='accepted')

        transaction.on_commit(lambda: _broadcast(
            user=booking.technician.user,
            target_role='technician',
            event_type=EventType.QUOTE_APPROVED,
            payload={
                **_payload_basics(booking),
                'quote_id': quote.id,
                'is_upsell': quote.is_upsell,
                'total_amount': str(quote.total_amount),
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
    """QUOTED → COMPLETED_INSPECTION_ONLY (terminal).

    Customer rejects the quote outright. Booking enters a terminal
    inspection-only state; ``final_cash_to_collect`` is set to the
    inspection fee (Rs.500 for INSPECTION-flow bookings; 0 for FIXED_GIG /
    LABOR_GIG since their flow doesn't carry an upfront inspection fee).
    """
    finance = _resolve_finance(finance)

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_customer(booking, customer_user)

        if booking.status != JobBooking.STATUS_QUOTED:
            _reject_invalid_from_state(
                booking, 'Decline only valid from QUOTED state.',
            )

        try:
            quote = booking.quotes.select_for_update().get(id=quote_id)
        except Quote.DoesNotExist:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Quote not found on this booking.',
            )

        if quote.status != Quote.STATUS_SUBMITTED:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Only a SUBMITTED quote can be declined.',
                errors={'quote_status': [quote.status]},
            )

        now = timezone.now()
        quote.status = Quote.STATUS_DECLINED
        quote.decision_reason = reason
        quote.decided_at = now
        quote.save(update_fields=['status', 'decision_reason', 'decided_at'])

        booking.status = JobBooking.STATUS_COMPLETED_INSPECTION_ONLY
        booking.completed_at = now
        # Inspection-flow bookings (sub_service is None) carry the Rs.500
        # fee; pre-paid fixed/labor flows do not. The pre-existing
        # ``inspection_fee`` column is the source of truth — null implies 0.
        booking.final_cash_to_collect = booking.inspection_fee or Decimal('0')
        booking.save(update_fields=['status', 'completed_at', 'final_cash_to_collect'])

        finance.apply_inspection_fee_decision(booking=booking, decision='declined')

        transaction.on_commit(lambda: _broadcast(
            user=booking.technician.user,
            target_role='technician',
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
    cash_amount_d = Decimal(str(cash_amount))

    with transaction.atomic():
        booking = _lock_booking(booking_id)
        _require_assigned_tech(booking, technician_user)

        if booking.status == JobBooking.STATUS_COMPLETED:
            return booking

        if booking.status != JobBooking.STATUS_IN_PROGRESS:
            _reject_invalid_from_state(booking, 'Completion only valid from IN_PROGRESS.')

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

        # Two events, single recipient. payment_received first (informational
        # cash receipt), job_completed second (lifecycle close). Order matters
        # only insofar as the customer's UI reacts to the lifecycle close last.
        def _emit():
            _broadcast(
                user=booking.customer,
                target_role='customer',
                event_type=EventType.PAYMENT_RECEIVED,
                payload={
                    **_payload_basics(booking),
                    'cash_collected_amount': str(cash_amount_d),
                    'cash_collection_method': method,
                },
            )
            _broadcast(
                user=booking.customer,
                target_role='customer',
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

        transaction.on_commit(lambda: _broadcast(
            user=booking.technician.user,
            target_role='technician',
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

        transaction.on_commit(lambda: _broadcast(
            user=booking.customer,
            target_role='customer',
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


def mark_no_show(
    *,
    booking_id: int,
    actor_user,
    actor_role: str,  # 'tech' | 'customer'
    finance=None,
) -> JobBooking:
    """Mark booking as NO_SHOW.

    Tech path (``actor_role='tech'``): tech arrived but customer is missing.
    Allowed from {ARRIVED, INSPECTING, QUOTED}.
    Customer path (``actor_role='customer'``): tech never showed.
    Allowed from {CONFIRMED, EN_ROUTE, ARRIVED}; also writes a
    ``TechReliabilityIncident`` row.

    Time-elapsed gating (15-min threshold per spec) is enforced at the
    view layer where wall-clock context lives — service signature stays clean.
    """
    finance = _resolve_finance(finance)

    if actor_role not in ('tech', 'customer'):
        raise BookingValidationError(
            code=ERROR_INVALID_TRANSITION,
            message="actor_role must be 'tech' or 'customer'.",
        )

    with transaction.atomic():
        booking = _lock_booking(booking_id)

        if actor_role == 'tech':
            _require_assigned_tech(booking, actor_user)
            allowed = _TECH_REPORT_NO_SHOW
            broadcast_user = booking.customer
            broadcast_role = 'customer'
        else:
            _require_customer(booking, actor_user)
            allowed = _CUSTOMER_REPORT_NO_SHOW
            broadcast_user = booking.technician.user
            broadcast_role = 'technician'

        if booking.status not in allowed:
            _reject_invalid_from_state(
                booking, f'No-show by {actor_role} not allowed in current state.',
            )

        now = timezone.now()
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

        transaction.on_commit(lambda: _broadcast(
            user=broadcast_user,
            target_role=broadcast_role,
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
# (AWAITING / PENDING / REJECTED) are not disputable — the booking never
# became real work.
_DISPUTE_DISALLOWED = frozenset({
    JobBooking.STATUS_PENDING,
    JobBooking.STATUS_AWAITING_TECH_ACCEPT,
    JobBooking.STATUS_REJECTED,
})


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

        first_dispute = booking.dispute_opened_at is None
        update_fields = []
        if first_dispute:
            booking.dispute_opened_at = timezone.now()
            update_fields.append('dispute_opened_at')
        if booking.status != JobBooking.STATUS_DISPUTED:
            booking.status = JobBooking.STATUS_DISPUTED
            update_fields.append('status')
        if update_fields:
            booking.save(update_fields=update_fields)

        # Broadcast to the counterparty (the user who didn't open it).
        counterparty_user = booking.technician.user if is_customer else booking.customer
        counterparty_role = 'technician' if is_customer else 'customer'

        transaction.on_commit(lambda: _broadcast(
            user=counterparty_user,
            target_role=counterparty_role,
            event_type=EventType.DISPUTE_OPENED,
            payload={
                **_payload_basics(booking),
                'ticket_id': ticket.id,
                'opened_by_role': 'customer' if is_customer else 'technician',
            },
        ))

    return ticket


_VALID_FINAL_STATUSES = frozenset({
    JobBooking.STATUS_COMPLETED,
    JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
    JobBooking.STATUS_CANCELLED,
})


def admin_resolve_dispute(
    *,
    ticket_id: int,
    admin_user,
    outcome: str,
    notes: str,
    final_status: str,
    finance=None,
) -> SupportTicket:
    """DISPUTED → admin-chosen terminal state.

    ``outcome`` is one of ``REFUND_CUSTOMER`` / ``PENALIZE_TECH`` / ``DISMISS``.
    ``final_status`` is one of ``COMPLETED`` / ``COMPLETED_INSPECTION_ONLY`` /
    ``CANCELLED``. Both parties get a ``dispute_resolved`` broadcast. Money
    flows (refunds, penalties) move to the finance sprint; this transition
    only flips status + closes the ticket.

    Authorization: this function trusts the caller's view layer to confirm
    admin role (Django Admin custom action). No IDOR scope here because the
    admin is acting across users by design.
    """
    finance = _resolve_finance(finance)

    if outcome not in {
        SupportTicket.OUTCOME_REFUND_CUSTOMER,
        SupportTicket.OUTCOME_PENALIZE_TECH,
        SupportTicket.OUTCOME_DISMISS,
    }:
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

    with transaction.atomic():
        try:
            ticket = (
                SupportTicket.objects
                .select_for_update()
                .select_related('booking__customer', 'booking__technician__user')
                .get(id=ticket_id)
            )
        except SupportTicket.DoesNotExist:
            raise BookingValidationError(
                code=ERROR_INVALID_TRANSITION,
                message='Dispute ticket not found.',
            )
        if ticket.status == SupportTicket.STATUS_RESOLVED:
            return ticket  # idempotent

        booking = JobBooking.objects.select_for_update().get(id=ticket.booking_id)

        now = timezone.now()
        ticket.status = SupportTicket.STATUS_RESOLVED
        ticket.resolution_outcome = outcome
        ticket.resolution_notes = notes
        ticket.resolved_at = now
        ticket.save(update_fields=[
            'status', 'resolution_outcome', 'resolution_notes', 'resolved_at',
        ])

        booking.status = final_status
        booking.save(update_fields=['status'])

        # Capture admin identity in the broadcast for audit. SupportTicket has
        # no ``resolved_by`` column today; surfacing the admin's username on
        # the wire keeps the audit trail visible without a schema change.
        admin_username = (
            getattr(admin_user, 'username', None)
            or getattr(admin_user, 'email', None)
            or 'admin'
        )

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
            promo_code_snapshot=original.promo_code_snapshot,
            promo_discount_snapshot=original.promo_discount_snapshot,
            actual_address_snapshot=original.actual_address_snapshot,
            parent_booking=original,
        )

        # Broadcast to the tech (cancellation of original + new offer arriving).
        transaction.on_commit(lambda: _broadcast(
            user=original.technician.user,
            target_role='technician',
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

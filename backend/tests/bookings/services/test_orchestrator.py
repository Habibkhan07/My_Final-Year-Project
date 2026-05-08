"""Unit tests for ``bookings.services.orchestrator``.

For each transition function the suite covers:
    1. happy path (mutation lands; broadcast registered; finance port called)
    2. wrong from-state (BookingValidationError(code='invalid_transition'))
    3. idempotent retry (no double-mutation; no double-broadcast)
    4. unauthorized actor (BookingValidationError(code='not_assigned_to_you'))

Plus targeted tests for behaviors that ARE the contract:
    - submit_quote: empty list, labor band, fixed-price band, revision counting,
      prior SUBMITTED quotes superseded
    - approve_quote: BookingItem snapshot; mid-job upsell appends, never replaces
    - decline_quote: final_cash_to_collect set from inspection_fee
    - cancel_by_customer: phase mapping (pre_accept / pre_arrival / post_arrival)
    - cancel_by_tech: TechReliabilityIncident written
    - mark_no_show: actor_role discrimination + reliability incident on
      customer-reports-tech
    - open_dispute: multiple OPEN tickets allowed; status flip is one-shot
    - reschedule: child booking + parent_booking link + dispatch on commit

Broadcast and dispatch side-effects are captured via mocking the lazy
imports inside ``_broadcast`` and the reschedule child-dispatch closure.
"""

from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from django.db import transaction
from django.utils import timezone

from bookings.exceptions import BookingValidationError
from bookings.models import (
    BookingItem,
    JobBooking,
    Quote,
    QuoteLineItem,
    SupportTicket,
    TechReliabilityIncident,
    TicketEvidence,
)
from bookings.services import orchestrator
from realtime.constants.event_types import EventType
from tests.factories.bookings import (
    JobBookingArrivedFactory,
    JobBookingConfirmedFactory,
    JobBookingEnRouteFactory,
    JobBookingFactory,
    JobBookingInProgressFactory,
    JobBookingInspectingFactory,
    JobBookingQuotedFactory,
    QuoteFactory,
    QuoteLineItemFactory,
)
from tests.factories.catalog import (
    FixedPriceSubServiceFactory,
    LaborSubServiceFactory,
)
from tests.factories.accounts import UserFactory


pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# Test infrastructure
# ---------------------------------------------------------------------------


@pytest.fixture
def fake_finance():
    """A MagicMock standing in for FinancePort.

    Each test asserts on ``mock_calls`` to verify port methods fire with
    the right kwargs. ``can_accept_job`` returns ``(True, None)`` by default
    to mirror the null adapter; tests override when exercising lockout paths.
    """
    m = MagicMock()
    m.can_accept_job.return_value = (True, None)
    m.record_commission.return_value = None
    m.apply_inspection_fee_decision.return_value = None
    m.apply_cancellation_charge.return_value = None
    m.record_cash_collected.return_value = None
    return m


@pytest.fixture
def captured_broadcasts():
    """Patches ``_broadcast`` to capture every emit AND forces
    ``transaction.on_commit`` callbacks to fire inline.

    Pytest-django wraps each test in a transaction that rolls back at
    teardown; by default that means ``on_commit`` callbacks never run.
    Marking every happy-path test ``transaction=True`` works but is slow
    (no savepoint reuse). Instead we hijack ``transaction.on_commit`` so
    its callbacks execute as soon as the orchestrator's atomic block
    closes — verifying the side-effect contract without paying the
    transaction-mode cost. Tests that explicitly need rollback semantics
    (the orchestrator's atomicity guarantee on finance-port failure) opt
    into ``@pytest.mark.django_db(transaction=True)`` separately.
    """
    calls = []

    def _capture(*, user, target_role, event_type, payload):
        calls.append({
            'user': user,
            'target_role': target_role,
            'event_type': event_type,
            'payload': payload,
        })

    def _immediate_on_commit(func, using=None):
        # Real on_commit fires only on commit; the test's outer transaction
        # rolls back at teardown, so we run callbacks immediately and let
        # the regular atomicity-failure tests cover the rollback path.
        func()

    with patch.object(orchestrator, '_broadcast', side_effect=_capture), \
         patch('bookings.services.orchestrator.transaction.on_commit', side_effect=_immediate_on_commit):
        yield calls


# ---------------------------------------------------------------------------
# en_route
# ---------------------------------------------------------------------------


class TestEnRoute:
    def test_happy_path_flips_status_and_stamps_timestamp(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        result = orchestrator.en_route(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_EN_ROUTE
        assert result.en_route_started_at is not None
        # One TECH_EN_ROUTE event broadcast to the customer.
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.TECH_EN_ROUTE]
        assert len(events) == 1
        assert events[0]['user'] == booking.customer
        assert events[0]['target_role'] == 'customer'
        assert events[0]['payload']['source'] == 'manual'

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingInspectingFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.en_route(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'invalid_transition'

    def test_idempotent_already_en_route(self, fake_finance, captured_broadcasts):
        booking = JobBookingEnRouteFactory()
        original_ts = booking.en_route_started_at
        result = orchestrator.en_route(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_EN_ROUTE
        assert result.en_route_started_at == original_ts  # not re-stamped
        assert captured_broadcasts == []  # no duplicate event

    def test_unauthorized_other_tech(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        other = UserFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.en_route(
                booking_id=booking.id,
                technician_user=other,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'not_assigned_to_you'

    def test_source_auto_propagates_into_payload(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        orchestrator.en_route(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            source='auto',
            finance=fake_finance,
        )
        assert captured_broadcasts[0]['payload']['source'] == 'auto'


# ---------------------------------------------------------------------------
# arrived
# ---------------------------------------------------------------------------


class TestArrived:
    def test_happy_path(self, fake_finance, captured_broadcasts):
        booking = JobBookingEnRouteFactory()
        result = orchestrator.arrived(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_ARRIVED
        assert result.arrived_at is not None
        assert any(c['event_type'] == EventType.TECH_ARRIVED for c in captured_broadcasts)

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.arrived(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            )

    def test_idempotent(self, fake_finance, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        orchestrator.arrived(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert captured_broadcasts == []


# ---------------------------------------------------------------------------
# start_inspection
# ---------------------------------------------------------------------------


class TestStartInspection:
    def test_happy_path_no_event(self, fake_finance, captured_broadcasts):
        # UI-flip-only transition — no event, no finance port call.
        booking = JobBookingArrivedFactory()
        result = orchestrator.start_inspection(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_INSPECTING
        assert result.inspection_started_at is not None
        assert captured_broadcasts == []
        fake_finance.assert_not_called()

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.start_inspection(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            )

    def test_idempotent(self, fake_finance):
        booking = JobBookingInspectingFactory()
        original_ts = booking.inspection_started_at
        result = orchestrator.start_inspection(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        assert result.inspection_started_at == original_ts


# ---------------------------------------------------------------------------
# submit_quote
# ---------------------------------------------------------------------------


class TestSubmitQuote:
    def test_happy_path_creates_quote_and_line_items(self, fake_finance, captured_broadcasts):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        quote = orchestrator.submit_quote(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            line_items=[
                {'sub_service_id': sub.id, 'quantity': 2, 'priced_at': '750.00'},
            ],
            finance=fake_finance,
        )
        assert quote.status == Quote.STATUS_SUBMITTED
        assert quote.revision_number == 1
        assert quote.total_amount == Decimal('1500.00')
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_QUOTED
        assert booking.quote_first_submitted_at is not None
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.QUOTE_GENERATED]
        assert len(events) == 1
        assert events[0]['payload']['is_upsell'] is False

    def test_empty_line_items_rejected(self, fake_finance):
        booking = JobBookingInspectingFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                line_items=[],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'invalid_quote_empty'

    def test_labor_band_lower_violation(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                line_items=[
                    {'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '300.00'},
                ],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'quote_band_violation'

    def test_labor_band_upper_violation(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                line_items=[
                    {'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '5000.00'},
                ],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'quote_band_violation'

    def test_fixed_price_must_equal_base_price(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = FixedPriceSubServiceFactory(base_price=Decimal('1500'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                line_items=[
                    {'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '1499.00'},
                ],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'quote_band_violation'

    def test_fixed_price_at_base_price_accepted(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = FixedPriceSubServiceFactory(base_price=Decimal('1500'))
        quote = orchestrator.submit_quote(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            line_items=[
                {'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '1500.00'},
            ],
            finance=fake_finance,
        )
        assert quote.total_amount == Decimal('1500.00')

    def test_resubmission_supersedes_prior_and_increments_revision(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        # First submit — booking goes to QUOTED.
        q1 = orchestrator.submit_quote(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            line_items=[{'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '500.00'}],
            finance=fake_finance,
        )
        # Customer asks for revision (back to INSPECTING).
        booking.refresh_from_db()
        booking.status = JobBooking.STATUS_INSPECTING
        booking.save(update_fields=['status'])
        # Tech resubmits.
        q2 = orchestrator.submit_quote(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            line_items=[{'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '700.00'}],
            finance=fake_finance,
        )
        q1.refresh_from_db()
        assert q1.status == Quote.STATUS_SUPERSEDED
        assert q2.revision_number == 2
        assert q2.status == Quote.STATUS_SUBMITTED

    def test_upsell_keeps_status_in_progress(self, fake_finance):
        booking = JobBookingInProgressFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        quote = orchestrator.submit_quote(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            line_items=[{'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '600.00'}],
            is_upsell=True,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_IN_PROGRESS
        assert quote.is_upsell is True

    def test_unauthorized_other_tech(self, fake_finance):
        booking = JobBookingInspectingFactory()
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=booking.id,
                technician_user=UserFactory(),
                line_items=[{'sub_service_id': sub.id, 'quantity': 1, 'priced_at': '500'}],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'not_assigned_to_you'


# ---------------------------------------------------------------------------
# request_revision
# ---------------------------------------------------------------------------


class TestRequestRevision:
    def test_happy_path(self, fake_finance, captured_broadcasts):
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED, revision_number=1)
        result = orchestrator.request_revision(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            reason='too high',
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_INSPECTING
        quote.refresh_from_db()
        assert quote.status == Quote.STATUS_SUPERSEDED
        assert quote.decision_reason == 'too high'
        assert any(c['event_type'] == EventType.QUOTE_REVISION_REQUESTED for c in captured_broadcasts)

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingInspectingFactory()  # not QUOTED
        quote = QuoteFactory(booking=booking)
        with pytest.raises(BookingValidationError):
            orchestrator.request_revision(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=quote.id,
                reason='x',
                finance=fake_finance,
            )

    def test_unauthorized_other_customer(self, fake_finance):
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking)
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.request_revision(
                booking_id=booking.id,
                customer_user=UserFactory(),
                quote_id=quote.id,
                reason='x',
                finance=fake_finance,
            )
        assert exc_info.value.code == 'not_assigned_to_you'


# ---------------------------------------------------------------------------
# approve_quote
# ---------------------------------------------------------------------------


class TestApproveQuote:
    def test_happy_path_snapshots_booking_items(self, fake_finance, captured_broadcasts):
        # Inspection-flow booking with the standard Rs.500 fee — accepting
        # the quote credits the fee, so final_cash = 1000 - 500 = 500.
        booking = JobBookingQuotedFactory(inspection_fee=Decimal('500.00'))
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED, total_amount=Decimal('1000.00'))
        QuoteLineItemFactory(
            quote=quote, sub_service=sub, quantity=2,
            priced_at=Decimal('500.00'), line_total=Decimal('1000.00'),
        )
        result = orchestrator.approve_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_IN_PROGRESS
        assert result.work_started_at is not None
        assert result.base_services_total == Decimal('1000.00')
        # final_cash = base_services_total - inspection_fee, floored at 0.
        assert result.final_cash_to_collect == Decimal('500.00')
        # BookingItem snapshot exists.
        items = list(booking.items.all())
        assert len(items) == 1
        assert items[0].price_charged == Decimal('500.00')
        assert items[0].quantity == 2
        assert items[0].sourced_quote == quote
        # Quote moved to APPROVED.
        quote.refresh_from_db()
        assert quote.status == Quote.STATUS_APPROVED
        # Broadcast sent — payload carries the cumulative
        # final_cash_to_collect so the tech's cash button updates without
        # a follow-up fetch (matters most on upsell approvals where
        # ``total_amount`` is the upsell delta only, not the cumulative).
        approved_events = [c for c in captured_broadcasts if c['event_type'] == EventType.QUOTE_APPROVED]
        assert len(approved_events) == 1
        assert approved_events[0]['payload']['final_cash_to_collect'] == '500.00'
        # Finance port hooked.
        fake_finance.apply_inspection_fee_decision.assert_called_once()
        kwargs = fake_finance.apply_inspection_fee_decision.call_args.kwargs
        assert kwargs['decision'] == 'accepted'

    def test_final_cash_clamped_to_zero_when_quote_below_inspection_fee(self, fake_finance):
        # Quote total Rs.300, inspection fee Rs.500 → 300 - 500 = -200 →
        # clamped to 0 so the cash button never shows a negative number.
        booking = JobBookingQuotedFactory(inspection_fee=Decimal('500.00'))
        sub = LaborSubServiceFactory(base_price=Decimal('300'), max_price=Decimal('1000'))
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED, total_amount=Decimal('300.00'))
        QuoteLineItemFactory(
            quote=quote, sub_service=sub, quantity=1,
            priced_at=Decimal('300.00'), line_total=Decimal('300.00'),
        )
        result = orchestrator.approve_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            finance=fake_finance,
        )
        assert result.final_cash_to_collect == Decimal('0')

    def test_final_cash_no_inspection_credit_when_fee_null(self, fake_finance):
        # FIXED_GIG / LABOR_GIG paths arrive at approve_quote without an
        # inspection fee on the booking row. Defensive fallback: full
        # base_services_total is owed, no credit applied.
        booking = JobBookingQuotedFactory(inspection_fee=None)
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED, total_amount=Decimal('1200.00'))
        QuoteLineItemFactory(
            quote=quote, sub_service=sub, quantity=1,
            priced_at=Decimal('1200.00'), line_total=Decimal('1200.00'),
        )
        result = orchestrator.approve_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            finance=fake_finance,
        )
        assert result.final_cash_to_collect == Decimal('1200.00')

    def test_upsell_recomputes_final_cash_on_total_growth(self, fake_finance):
        # Existing approved quote with one item (Rs.1000) already in the
        # snapshot. An upsell quote adds Rs.1500 → base_total = 2500,
        # final_cash = 2500 - 500 (fee) = 2000.
        booking = JobBookingInProgressFactory(
            inspection_fee=Decimal('500.00'),
            base_services_total=Decimal('1000.00'),
            final_cash_to_collect=Decimal('500.00'),
        )
        sub_a = LaborSubServiceFactory(base_price=Decimal('1000'), max_price=Decimal('2000'))
        sub_b = LaborSubServiceFactory(base_price=Decimal('1500'), max_price=Decimal('2000'))
        prior_quote = QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_APPROVED)
        BookingItem.objects.create(
            booking=booking, sub_service=sub_a, quantity=1,
            price_charged=Decimal('1000.00'), line_total=Decimal('1000.00'),
            sourced_quote=prior_quote,
        )

        upsell = QuoteFactory(
            booking=booking, revision_number=2,
            status=Quote.STATUS_SUBMITTED, is_upsell=True,
            total_amount=Decimal('1500.00'),
        )
        QuoteLineItemFactory(
            quote=upsell, sub_service=sub_b, quantity=1,
            priced_at=Decimal('1500.00'), line_total=Decimal('1500.00'),
        )
        result = orchestrator.approve_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=upsell.id,
            finance=fake_finance,
        )
        assert result.base_services_total == Decimal('2500.00')
        assert result.final_cash_to_collect == Decimal('2000.00')

    def test_upsell_appends_booking_items_does_not_replace(self, fake_finance):
        # Set up a booking that's already IN_PROGRESS with one BookingItem
        # snapshot from a prior approved quote.
        booking = JobBookingInProgressFactory()
        sub_a = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('2000'))
        sub_b = LaborSubServiceFactory(base_price=Decimal('800'), max_price=Decimal('2000'))
        prior_quote = QuoteFactory(booking=booking, revision_number=1, status=Quote.STATUS_APPROVED)
        BookingItem.objects.create(
            booking=booking, sub_service=sub_a, quantity=1,
            price_charged=Decimal('500.00'), line_total=Decimal('500.00'),
            sourced_quote=prior_quote,
        )

        # Now an upsell quote.
        upsell = QuoteFactory(
            booking=booking, revision_number=2,
            status=Quote.STATUS_SUBMITTED, is_upsell=True,
            total_amount=Decimal('1600.00'),
        )
        QuoteLineItemFactory(
            quote=upsell, sub_service=sub_b, quantity=2,
            priced_at=Decimal('800.00'), line_total=Decimal('1600.00'),
        )
        result = orchestrator.approve_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=upsell.id,
            finance=fake_finance,
        )
        # Status stays IN_PROGRESS for upsell.
        assert result.status == JobBooking.STATUS_IN_PROGRESS
        # Both BookingItem rows exist (append, never replace).
        items = list(booking.items.order_by('id'))
        assert len(items) == 2
        assert items[0].sub_service == sub_a
        assert items[1].sub_service == sub_b
        # base_services_total reflects sum of all items.
        assert result.base_services_total == Decimal('2100.00')

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingInspectingFactory()
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
        with pytest.raises(BookingValidationError):
            orchestrator.approve_quote(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=quote.id,
                finance=fake_finance,
            )

    def test_quote_not_submitted_rejected(self, fake_finance):
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUPERSEDED)
        with pytest.raises(BookingValidationError):
            orchestrator.approve_quote(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=quote.id,
                finance=fake_finance,
            )

    def test_unauthorized_other_customer(self, fake_finance):
        booking = JobBookingQuotedFactory()
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.approve_quote(
                booking_id=booking.id,
                customer_user=UserFactory(),
                quote_id=quote.id,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'not_assigned_to_you'


# ---------------------------------------------------------------------------
# decline_quote
# ---------------------------------------------------------------------------


class TestDeclineQuote:
    def test_happy_path_terminal_inspection_only(self, fake_finance, captured_broadcasts):
        booking = JobBookingQuotedFactory(inspection_fee=Decimal('500.00'))
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
        result = orchestrator.decline_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            reason='too high',
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_COMPLETED_INSPECTION_ONLY
        assert result.completed_at is not None
        assert result.final_cash_to_collect == Decimal('500.00')
        quote.refresh_from_db()
        assert quote.status == Quote.STATUS_DECLINED
        assert quote.decision_reason == 'too high'
        fake_finance.apply_inspection_fee_decision.assert_called_once()
        kwargs = fake_finance.apply_inspection_fee_decision.call_args.kwargs
        assert kwargs['decision'] == 'declined'
        assert any(c['event_type'] == EventType.QUOTE_DECLINED for c in captured_broadcasts)

    def test_decline_with_null_inspection_fee_defensive_fallback_zero(self, fake_finance):
        # Defensive fallback path. INSPECTION-flow bookings created via
        # ``create_instant_booking`` always populate ``inspection_fee``,
        # so reaching ``decline_quote`` with a null fee implies a legacy
        # row or a hand-built test fixture. The orchestrator floors to 0
        # rather than crashing or surfacing a phantom number — but this
        # is NOT the inspection-flow contract; that's covered by the
        # ``test_happy_path_terminal_inspection_only`` case above which
        # asserts a Rs.500 cash owed.
        booking = JobBookingQuotedFactory(inspection_fee=None)
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
        result = orchestrator.decline_quote(
            booking_id=booking.id,
            customer_user=booking.customer,
            quote_id=quote.id,
            reason='no thanks',
            finance=fake_finance,
        )
        assert result.final_cash_to_collect == Decimal('0')

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingInspectingFactory()
        quote = QuoteFactory(booking=booking, status=Quote.STATUS_SUBMITTED)
        with pytest.raises(BookingValidationError):
            orchestrator.decline_quote(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=quote.id,
                reason='x',
                finance=fake_finance,
            )


# ---------------------------------------------------------------------------
# mark_complete_with_cash
# ---------------------------------------------------------------------------


class TestMarkCompleteWithCash:
    def test_happy_path(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        result = orchestrator.mark_complete_with_cash(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            cash_amount=Decimal('1500.00'),
            method='cash',
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_COMPLETED
        assert result.cash_collected_amount == Decimal('1500.00')
        assert result.cash_collected_at is not None
        assert result.cash_collection_method == 'cash'
        # Both events fired.
        types = [c['event_type'] for c in captured_broadcasts]
        assert EventType.PAYMENT_RECEIVED in types
        assert EventType.JOB_COMPLETED in types
        fake_finance.record_cash_collected.assert_called_once()
        fake_finance.record_commission.assert_called_once()

    def test_wrong_from_state(self, fake_finance):
        booking = JobBookingArrivedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('1000'),
                finance=fake_finance,
            )

    def test_idempotent_already_completed(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory(
            status=JobBooking.STATUS_COMPLETED,
            cash_collected_amount=Decimal('1500.00'),
            completed_at=timezone.now(),
        )
        orchestrator.mark_complete_with_cash(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            cash_amount=Decimal('1500'),
            finance=fake_finance,
        )
        assert captured_broadcasts == []
        fake_finance.record_cash_collected.assert_not_called()


# ---------------------------------------------------------------------------
# cancel_by_customer — phase mapping
# ---------------------------------------------------------------------------


class TestCancelByCustomer:
    @pytest.mark.parametrize('factory_cls,expected_phase,expected_reason', [
        (JobBookingFactory, 'pre_accept', 'customer_cancelled_pre_accept'),
        (JobBookingConfirmedFactory, 'pre_arrival', 'customer_cancelled_post_accept'),
        (JobBookingEnRouteFactory, 'pre_arrival', 'customer_cancelled_post_accept'),
        (JobBookingArrivedFactory, 'post_arrival', 'customer_cancelled_post_arrival'),
        (JobBookingInspectingFactory, 'post_arrival', 'customer_cancelled_post_arrival'),
        (JobBookingQuotedFactory, 'post_arrival', 'customer_cancelled_post_arrival'),
    ])
    def test_phase_mapping(
        self, fake_finance, captured_broadcasts,
        factory_cls, expected_phase, expected_reason,
    ):
        # Override default factory status to AWAITING for the bare
        # JobBookingFactory case (factory default is CONFIRMED).
        kwargs = {}
        if factory_cls is JobBookingFactory:
            kwargs['status'] = JobBooking.STATUS_AWAITING_TECH_ACCEPT
        booking = factory_cls(**kwargs)
        orchestrator.cancel_by_customer(
            booking_id=booking.id,
            customer_user=booking.customer,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        assert booking.cancel_reason == expected_reason
        kwargs = fake_finance.apply_cancellation_charge.call_args.kwargs
        assert kwargs['actor'] == 'customer'
        assert kwargs['phase'] == expected_phase

    def test_in_progress_rejected(self, fake_finance):
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.cancel_by_customer(
                booking_id=booking.id,
                customer_user=booking.customer,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'cancellation_not_allowed'

    def test_unauthorized_other_customer(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.cancel_by_customer(
                booking_id=booking.id,
                customer_user=UserFactory(),
                finance=fake_finance,
            )


# ---------------------------------------------------------------------------
# cancel_by_tech
# ---------------------------------------------------------------------------


class TestCancelByTech:
    def test_happy_path_writes_reliability_incident(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        orchestrator.cancel_by_tech(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        assert booking.cancel_reason == 'technician_cancelled'
        # TechReliabilityIncident row written.
        incidents = TechReliabilityIncident.objects.filter(booking=booking)
        assert incidents.count() == 1
        inc = incidents.get()
        assert inc.incident_type == TechReliabilityIncident.INCIDENT_TECH_CANCEL
        assert inc.phase == 'pre_arrival'
        assert inc.technician == booking.technician
        # Customer broadcast.
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.BOOKING_CANCELLED]
        assert len(events) == 1
        assert events[0]['target_role'] == 'customer'

    def test_terminal_state_rejected(self, fake_finance):
        booking = JobBookingFactory(status=JobBooking.STATUS_COMPLETED)
        with pytest.raises(BookingValidationError):
            orchestrator.cancel_by_tech(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                finance=fake_finance,
            )

    def test_unauthorized_other_tech(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.cancel_by_tech(
                booking_id=booking.id,
                technician_user=UserFactory(),
                finance=fake_finance,
            )


# ---------------------------------------------------------------------------
# mark_no_show
# ---------------------------------------------------------------------------


class TestMarkNoShow:
    """The 15-minute gate is enforced at the service level. Tests pass
    ``_clock=lambda: <future>`` to simulate the elapsed wait without
    sleeping. The gate's anchor differs by actor:
        tech filing     → from booking.arrived_at
        customer filing → from booking.scheduled_start
    """

    @staticmethod
    def _twenty_min_later():
        # Helper: returns a clock fn that's 20 minutes ahead of "now"
        # at fixture-build time, comfortably past the 15-min gate.
        future = timezone.now() + timezone.timedelta(minutes=20)
        return lambda: future

    def test_tech_path_after_15_min_wait(self, fake_finance, captured_broadcasts):
        booking = JobBookingArrivedFactory()
        orchestrator.mark_no_show(
            booking_id=booking.id,
            actor_user=booking.technician.user,
            actor_role='tech',
            finance=fake_finance,
            _clock=self._twenty_min_later(),
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_NO_SHOW
        assert booking.no_show_actor == 'tech'
        # No reliability incident on tech-reports-customer.
        assert TechReliabilityIncident.objects.filter(booking=booking).count() == 0
        # Customer is the broadcast recipient.
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.BOOKING_NO_SHOW]
        assert events[0]['target_role'] == 'customer'

    def test_customer_path_writes_reliability_incident(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        orchestrator.mark_no_show(
            booking_id=booking.id,
            actor_user=booking.customer,
            actor_role='customer',
            finance=fake_finance,
            _clock=self._twenty_min_later(),
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_NO_SHOW
        assert booking.no_show_actor == 'customer'
        incidents = TechReliabilityIncident.objects.filter(booking=booking)
        assert incidents.count() == 1
        assert incidents.get().incident_type == TechReliabilityIncident.INCIDENT_TECH_NO_SHOW
        # Tech is the broadcast recipient.
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.BOOKING_NO_SHOW]
        assert events[0]['target_role'] == 'technician'

    def test_invalid_actor_role(self, fake_finance):
        booking = JobBookingArrivedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=booking.customer,
                actor_role='admin',
                finance=fake_finance,
            )

    def test_tech_path_wrong_from_state(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=booking.technician.user,
                actor_role='tech',
                finance=fake_finance,
                _clock=self._twenty_min_later(),
            )

    def test_tech_path_too_early_rejected(self, fake_finance):
        # Tech files immediately after marking arrived → < 15 min elapsed.
        booking = JobBookingArrivedFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=booking.technician.user,
                actor_role='tech',
                finance=fake_finance,
                # No _clock → uses timezone.now(), which is essentially
                # the same instant as the factory's LazyFunction-built
                # arrived_at.
            )
        assert exc_info.value.code == 'no_show_too_early'
        assert 'wait_seconds' in exc_info.value.errors

    def test_customer_path_too_early_rejected(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=booking.customer,
                actor_role='customer',
                finance=fake_finance,
            )
        assert exc_info.value.code == 'no_show_too_early'

    def test_tech_path_anchors_on_arrived_at_not_scheduled_start(self, fake_finance, captured_broadcasts):
        # Anchor distinction matters: a booking whose scheduled_start is
        # ancient but whose arrived_at is recent must REJECT (tech only
        # just arrived; the wait starts then). Pin the contract.
        booking = JobBookingArrivedFactory(
            scheduled_start=timezone.now() - timezone.timedelta(hours=2),
            arrived_at=timezone.now() - timezone.timedelta(minutes=5),
        )
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_no_show(
                booking_id=booking.id,
                actor_user=booking.technician.user,
                actor_role='tech',
                finance=fake_finance,
            )
        assert exc_info.value.code == 'no_show_too_early'

    def test_tech_path_arrived_at_null_falls_back_to_scheduled_start(self, fake_finance, captured_broadcasts):
        # Defensive fallback: a manually-mutated row could have ARRIVED
        # status without arrived_at populated. Use scheduled_start.
        booking = JobBookingArrivedFactory(
            scheduled_start=timezone.now() - timezone.timedelta(minutes=20),
            arrived_at=None,
        )
        orchestrator.mark_no_show(
            booking_id=booking.id,
            actor_user=booking.technician.user,
            actor_role='tech',
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_NO_SHOW


# ---------------------------------------------------------------------------
# open_dispute
# ---------------------------------------------------------------------------


class TestOpenDispute:
    def test_customer_opens_first_ticket(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        ticket = orchestrator.open_dispute(
            booking_id=booking.id,
            opener_user=booking.customer,
            initial_reason='leaking still',
            finance=fake_finance,
        )
        assert ticket.status == SupportTicket.STATUS_OPEN
        assert ticket.opened_by == booking.customer
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_DISPUTED
        assert booking.dispute_opened_at is not None
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.DISPUTE_OPENED]
        assert events[0]['target_role'] == 'technician'

    def test_tech_opens_dispute(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        ticket = orchestrator.open_dispute(
            booking_id=booking.id,
            opener_user=booking.technician.user,
            initial_reason='customer assaulted me',
            finance=fake_finance,
        )
        assert ticket.opened_by == booking.technician.user
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.DISPUTE_OPENED]
        assert events[0]['target_role'] == 'customer'

    def test_multiple_open_tickets_allowed_status_flip_one_shot(self, fake_finance, captured_broadcasts):
        booking = JobBookingInProgressFactory()
        t1 = orchestrator.open_dispute(
            booking_id=booking.id, opener_user=booking.customer,
            initial_reason='one', finance=fake_finance,
        )
        booking.refresh_from_db()
        first_dispute_at = booking.dispute_opened_at
        t2 = orchestrator.open_dispute(
            booking_id=booking.id, opener_user=booking.technician.user,
            initial_reason='two', finance=fake_finance,
        )
        booking.refresh_from_db()
        # Second open creates a new ticket but does not re-stamp dispute_opened_at.
        assert SupportTicket.objects.filter(booking=booking).count() == 2
        assert booking.dispute_opened_at == first_dispute_at

    def test_unauthorized_third_party(self, fake_finance):
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.open_dispute(
                booking_id=booking.id,
                opener_user=UserFactory(),
                initial_reason='not my booking',
                finance=fake_finance,
            )

    def test_pre_confirmed_state_rejected(self, fake_finance):
        booking = JobBookingFactory(status=JobBooking.STATUS_AWAITING_TECH_ACCEPT)
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.open_dispute(
                booking_id=booking.id,
                opener_user=booking.customer,
                initial_reason='prematurely angry',
                finance=fake_finance,
            )
        assert exc_info.value.code == 'dispute_not_disputable_status'

    def test_dispute_on_completed_preserves_terminal_status(self, fake_finance, captured_broadcasts):
        # Post-job dispute window: customer disputes a COMPLETED booking.
        # Status MUST stay COMPLETED so list-views filtering by terminal
        # state still surface the booking; the dispute is captured by
        # ``dispute_opened_at IS NOT NULL`` plus the ticket row.
        booking = JobBookingFactory(
            status=JobBooking.STATUS_COMPLETED,
            completed_at=timezone.now(),
        )
        ticket = orchestrator.open_dispute(
            booking_id=booking.id,
            opener_user=booking.customer,
            initial_reason='leak came back',
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_COMPLETED  # NOT DISPUTED
        assert booking.dispute_opened_at is not None
        assert ticket.status == SupportTicket.STATUS_OPEN

    def test_dispute_on_cancelled_preserves_terminal_status(self, fake_finance):
        # Same contract for CANCELLED bookings — customer disputes that
        # the cancellation was unjustified. Booking stays CANCELLED;
        # admin can override final_status when resolving.
        booking = JobBookingFactory(
            status=JobBooking.STATUS_CANCELLED,
            cancelled_at=timezone.now(),
            cancel_reason='technician_cancelled',
        )
        orchestrator.open_dispute(
            booking_id=booking.id,
            opener_user=booking.customer,
            initial_reason='this cancel was bogus',
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        assert booking.dispute_opened_at is not None

    def test_dispute_on_in_progress_flips_to_disputed(self, fake_finance):
        # Non-terminal contract: IN_PROGRESS still flips to DISPUTED so
        # mark_complete_with_cash and other transitions can't fire while
        # the dispute is open.
        booking = JobBookingInProgressFactory()
        orchestrator.open_dispute(
            booking_id=booking.id,
            opener_user=booking.customer,
            initial_reason='something is wrong',
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_DISPUTED


# ---------------------------------------------------------------------------
# admin_resolve_dispute
# ---------------------------------------------------------------------------


class TestAdminResolveDispute:
    def test_happy_path_completes_booking(self, fake_finance, captured_broadcasts):
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='broken', status=SupportTicket.STATUS_OPEN,
        )
        admin = UserFactory(username='+923009999999')
        result = orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id,
            admin_user=admin,
            outcome=SupportTicket.OUTCOME_REFUND_CUSTOMER,
            notes='valid claim',
            final_status=JobBooking.STATUS_CANCELLED,
            finance=fake_finance,
        )
        assert result.status == SupportTicket.STATUS_RESOLVED
        assert result.resolution_outcome == SupportTicket.OUTCOME_REFUND_CUSTOMER
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        # Both parties got DISPUTE_RESOLVED.
        roles = [c['target_role'] for c in captured_broadcasts if c['event_type'] == EventType.DISPUTE_RESOLVED]
        assert sorted(roles) == ['customer', 'technician']
        # Admin identity in payload.
        payloads = [c['payload'] for c in captured_broadcasts if c['event_type'] == EventType.DISPUTE_RESOLVED]
        assert all(p['resolved_by_admin'] == admin.username for p in payloads)

    def test_idempotent_already_resolved(self, fake_finance, captured_broadcasts):
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_RESOLVED,
            resolution_outcome=SupportTicket.OUTCOME_DISMISS,
            resolved_at=timezone.now(),
        )
        result = orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id, admin_user=UserFactory(),
            outcome=SupportTicket.OUTCOME_DISMISS, notes='retry',
            final_status=JobBooking.STATUS_CANCELLED,
            finance=fake_finance,
        )
        assert result.status == SupportTicket.STATUS_RESOLVED
        assert captured_broadcasts == []

    def test_invalid_outcome_rejected(self, fake_finance):
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        with pytest.raises(BookingValidationError):
            orchestrator.admin_resolve_dispute(
                ticket_id=ticket.id, admin_user=UserFactory(),
                outcome='LET_THEM_FIGHT', notes='',
                final_status=JobBooking.STATUS_CANCELLED,
                finance=fake_finance,
            )

    def test_invalid_final_status_rejected(self, fake_finance):
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        with pytest.raises(BookingValidationError):
            orchestrator.admin_resolve_dispute(
                ticket_id=ticket.id, admin_user=UserFactory(),
                outcome=SupportTicket.OUTCOME_DISMISS, notes='',
                final_status=JobBooking.STATUS_DISPUTED,  # not a valid terminal
                finance=fake_finance,
            )

    def test_resolution_to_cancelled_stamps_audit_columns(self, fake_finance, captured_broadcasts):
        # Reports that filter on cancelled_at / cancelled_by must see
        # admin-resolved cancellations. Without the stamp, those
        # bookings have status=CANCELLED but null audit columns.
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        admin = UserFactory(username='+923009999999')
        orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id, admin_user=admin,
            outcome=SupportTicket.OUTCOME_REFUND_CUSTOMER,
            notes='valid claim',
            final_status=JobBooking.STATUS_CANCELLED,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        assert booking.cancelled_at is not None
        assert booking.cancelled_by_id == admin.id
        assert booking.cancel_reason == 'admin_resolved_dispute'

    def test_resolution_to_completed_stamps_completed_at(self, fake_finance, captured_broadcasts):
        # Admin upholds completion on a disputed booking that never
        # reached COMPLETED on its own (dispute opened mid-flow). The
        # completed_at column must be stamped so the booking shows up
        # in completion analytics.
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        assert booking.completed_at is None  # precondition
        orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id, admin_user=UserFactory(),
            outcome=SupportTicket.OUTCOME_DISMISS,
            notes='customer claim unsupported',
            final_status=JobBooking.STATUS_COMPLETED,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_COMPLETED
        assert booking.completed_at is not None

    def test_resolution_to_completed_preserves_existing_completed_at(self, fake_finance, captured_broadcasts):
        # Dispute opened on a booking that was ALREADY completed before
        # the dispute was filed. Admin upholds the completion. The
        # original completed_at must be preserved — overwriting it to
        # ``now`` would falsify the historical record of when work
        # actually finished.
        original_completion = timezone.now() - timezone.timedelta(days=3)
        booking = JobBookingFactory(
            status=JobBooking.STATUS_DISPUTED,
            completed_at=original_completion,
        )
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id, admin_user=UserFactory(),
            outcome=SupportTicket.OUTCOME_DISMISS, notes='',
            final_status=JobBooking.STATUS_COMPLETED,
            finance=fake_finance,
        )
        booking.refresh_from_db()
        # Use isoformat to dodge timezone-aware-vs-naive comparison
        # quirks if the factory stored a different tzinfo than
        # timezone.now() returns.
        assert booking.completed_at == original_completion

    def test_resolved_by_recorded_on_ticket(self, fake_finance, captured_broadcasts):
        # Permanent audit trail for the dispute resolution. The WS
        # broadcast captures the admin username for ephemeral display,
        # but the DB row must hold the FK so a future audit query can
        # answer "which admin resolved ticket #N" without reading WS
        # logs.
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_OPEN,
        )
        admin = UserFactory(username='+923001112222')
        orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id, admin_user=admin,
            outcome=SupportTicket.OUTCOME_DISMISS, notes='',
            final_status=JobBooking.STATUS_CANCELLED,
            finance=fake_finance,
        )
        ticket.refresh_from_db()
        assert ticket.resolved_by_id == admin.id


# ---------------------------------------------------------------------------
# reschedule
# ---------------------------------------------------------------------------


class TestReschedule:
    def test_happy_path_creates_child_with_lineage(self, fake_finance, captured_broadcasts):
        booking = JobBookingConfirmedFactory()
        new_start = booking.scheduled_start + timezone.timedelta(days=2)
        new_end = new_start + timezone.timedelta(hours=1)
        with patch('bookings.services.job_request_dispatch.dispatch_job_new_request_event') as mock_dispatch:
            child = orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_end,
                finance=fake_finance,
            )

        assert child.parent_booking == booking
        assert child.status == JobBooking.STATUS_AWAITING_TECH_ACCEPT
        assert child.technician == booking.technician
        assert child.customer == booking.customer
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED
        assert booking.cancel_reason == 'customer_rescheduled'
        # BOOKING_RESCHEDULED broadcast to tech.
        events = [c for c in captured_broadcasts if c['event_type'] == EventType.BOOKING_RESCHEDULED]
        assert events[0]['target_role'] == 'technician'
        assert events[0]['payload']['new_booking_id'] == child.id
        # Child dispatched.
        mock_dispatch.assert_called_once()
        dispatched = mock_dispatch.call_args.args[0]
        assert dispatched.id == child.id

    def test_blocked_from_en_route_onwards(self, fake_finance):
        booking = JobBookingEnRouteFactory()
        new_start = booking.scheduled_start + timezone.timedelta(days=1)
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_start + timezone.timedelta(hours=1),
                finance=fake_finance,
            )
        assert exc_info.value.code == 'reschedule_not_allowed'

    def test_unauthorized_other_customer(self, fake_finance):
        booking = JobBookingConfirmedFactory()
        new_start = booking.scheduled_start + timezone.timedelta(days=1)
        with pytest.raises(BookingValidationError):
            orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=UserFactory(),
                new_scheduled_start=new_start,
                new_scheduled_end=new_start + timezone.timedelta(hours=1),
                finance=fake_finance,
            )

    def test_promo_snapshots_carried_to_child(self, fake_finance):
        booking = JobBookingConfirmedFactory(
            promo_code_snapshot='WINTER25',
            promo_discount_snapshot=Decimal('250.00'),
        )
        new_start = booking.scheduled_start + timezone.timedelta(days=1)
        with patch('bookings.services.job_request_dispatch.dispatch_job_new_request_event'):
            child = orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_start + timezone.timedelta(hours=1),
                finance=fake_finance,
            )
        assert child.promo_code_snapshot == 'WINTER25'
        assert child.promo_discount_snapshot == Decimal('250.00')

    def test_final_cash_to_collect_carried_to_child(self, fake_finance):
        # Phase 1 invariant: every newly-created booking has the cash
        # columns populated for its booking type. FIXED_GIG / LABOR_GIG
        # bookings carry final_cash_to_collect from creation; the
        # reschedule child must mirror that value or the cash button on
        # the rescheduled booking renders empty until quote-approve
        # re-derives it.
        booking = JobBookingConfirmedFactory(
            final_cash_to_collect=Decimal('1000.00'),
        )
        new_start = booking.scheduled_start + timezone.timedelta(days=1)
        with patch('bookings.services.job_request_dispatch.dispatch_job_new_request_event'):
            child = orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_start + timezone.timedelta(hours=1),
                finance=fake_finance,
            )
        assert child.final_cash_to_collect == Decimal('1000.00')

    def test_new_slot_overlap_with_other_booking_rejected(self, fake_finance):
        # Without the new tech-profile lock + overlap re-check, a customer
        # could reschedule INTO a window already claimed by another
        # AWAITING/CONFIRMED booking on the same technician — silently
        # double-booking the tech. This test pins the rejection.
        booking = JobBookingConfirmedFactory()
        new_start = booking.scheduled_start + timezone.timedelta(days=1)
        new_end = new_start + timezone.timedelta(hours=1)
        # A second booking already owns the target slot.
        JobBookingConfirmedFactory(
            technician=booking.technician,
            scheduled_start=new_start,
            scheduled_end=new_end,
        )
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_end,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'reschedule_not_allowed'
        assert 'new_scheduled_start' in exc_info.value.errors

    def test_overlap_query_excludes_original_being_rescheduled(self, fake_finance):
        # The customer reschedules into a window that overlaps the
        # original's own current window (e.g. shortening duration without
        # changing start time). The overlap query must exclude the
        # original itself — it's about to be cancelled — otherwise a
        # legitimate same-slot adjustment would self-overlap and reject.
        booking = JobBookingConfirmedFactory()
        new_start = booking.scheduled_start
        new_end = booking.scheduled_end - timezone.timedelta(minutes=30)
        with patch('bookings.services.job_request_dispatch.dispatch_job_new_request_event'):
            child = orchestrator.reschedule(
                original_booking_id=booking.id,
                customer_user=booking.customer,
                new_scheduled_start=new_start,
                new_scheduled_end=new_end,
                finance=fake_finance,
            )
        assert child.scheduled_end == new_end
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_CANCELLED


# ---------------------------------------------------------------------------
# Default finance factory wiring
# ---------------------------------------------------------------------------


class TestDefaultFinanceResolution:
    def test_orchestrator_falls_back_to_null_adapter(self):
        # Smoke test: when ``finance=None`` (default), the orchestrator
        # resolves the production NullFinanceAdapter via the lazy factory.
        from bookings.adapters.null_finance import NullFinanceAdapter

        booking = JobBookingConfirmedFactory()
        with patch.object(orchestrator, '_broadcast'):
            orchestrator.en_route(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                # finance omitted on purpose
            )
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_EN_ROUTE


# ---------------------------------------------------------------------------
# Defensive hardening — bad input, lock ordering, missing rows.
#
# Pre-fix audit found the orchestrator would crash with a 500 on bad
# booking_id / quote_id / cash_amount / malformed line items. The
# canonical envelope contract requires every failure mode return a
# ``{status, code, message, errors}`` envelope; these tests pin that.
# ---------------------------------------------------------------------------


class TestLockBookingNotFound:
    """Every transition routes booking fetches through ``_lock_booking``,
    so wrapping its DoesNotExist into the canonical envelope auto-covers
    every transition function."""

    def test_en_route_unknown_booking_raises_404_envelope(self, fake_finance):
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.en_route(
                booking_id=999_999_999,
                technician_user=UserFactory(),
                finance=fake_finance,
            )
        assert exc_info.value.code == 'booking_not_found'
        assert exc_info.value.status_code == 404
        assert exc_info.value.message == 'Booking not found.'

    def test_cancel_unknown_booking_raises_404_envelope(self, fake_finance):
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.cancel_by_customer(
                booking_id=999_999_999,
                customer_user=UserFactory(),
                finance=fake_finance,
            )
        assert exc_info.value.status_code == 404


class TestQuoteNotFoundOnBooking:
    def test_approve_quote_with_unknown_id_raises_404(self, fake_finance):
        booking = JobBookingQuotedFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.approve_quote(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=999_999_999,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'quote_not_found'
        assert exc_info.value.status_code == 404
        assert exc_info.value.message == 'Quote not found on this booking.'

    def test_approve_quote_with_other_bookings_quote_raises_404(self, fake_finance):
        # IDOR-safety: quote belongs to a different booking. The
        # booking-scoped manager prevents the cross-leak; the test
        # confirms the canonical 404 surfaces (not "not submitted" or
        # similar leaks of the foreign quote's state).
        booking_a = JobBookingQuotedFactory()
        booking_b = JobBookingQuotedFactory()
        foreign_quote = QuoteFactory(booking=booking_b, status=Quote.STATUS_SUBMITTED)
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.approve_quote(
                booking_id=booking_a.id,
                customer_user=booking_a.customer,
                quote_id=foreign_quote.id,
                finance=fake_finance,
            )
        assert exc_info.value.status_code == 404

    def test_request_revision_with_unknown_quote_raises_404(self, fake_finance):
        booking = JobBookingQuotedFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.request_revision(
                booking_id=booking.id,
                customer_user=booking.customer,
                quote_id=999_999_999,
                reason='x',
                finance=fake_finance,
            )
        assert exc_info.value.status_code == 404


class TestSubmitQuoteMalformedInput:
    """The orchestrator is the canonical line-item validator (session-2
    serializers will catch most of this earlier, but the service must not
    crash). Every bad-input branch returns a field-keyed envelope."""

    def _booking(self):
        return JobBookingInspectingFactory()

    def test_non_dict_item_rejected(self, fake_finance):
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=self._booking().id,
                technician_user=UserFactory(),
                line_items=['not a dict'],
                finance=fake_finance,
            )
        assert exc_info.value.code == 'quote_band_violation'
        assert 'line_items[0]' in exc_info.value.errors

    def test_missing_sub_service_id_rejected(self, fake_finance):
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=self._booking().id,
                technician_user=UserFactory(),
                line_items=[{'priced_at': '500'}],
                finance=fake_finance,
            )
        assert 'line_items[0].sub_service_id' in exc_info.value.errors

    def test_missing_priced_at_rejected(self, fake_finance):
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('1500'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=self._booking().id,
                technician_user=UserFactory(),
                line_items=[{'sub_service_id': sub.id}],
                finance=fake_finance,
            )
        assert 'line_items[0].priced_at' in exc_info.value.errors

    def test_unparsable_priced_at_rejected(self, fake_finance):
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('1500'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=self._booking().id,
                technician_user=UserFactory(),
                line_items=[{'sub_service_id': sub.id, 'priced_at': 'oops'}],
                finance=fake_finance,
            )
        assert 'line_items[0].priced_at' in exc_info.value.errors

    def test_unparsable_quantity_rejected(self, fake_finance):
        sub = LaborSubServiceFactory(base_price=Decimal('500'), max_price=Decimal('1500'))
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.submit_quote(
                booking_id=self._booking().id,
                technician_user=UserFactory(),
                line_items=[{
                    'sub_service_id': sub.id,
                    'priced_at': '500',
                    'quantity': 'two',
                }],
                finance=fake_finance,
            )
        assert 'line_items[0].quantity' in exc_info.value.errors


class TestMarkCompleteCashAmountValidation:
    def test_zero_cash_rejected(self, fake_finance):
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('0'),
                finance=fake_finance,
            )
        assert exc_info.value.code == 'invalid_input'
        assert 'cash_amount' in exc_info.value.errors

    def test_invalid_method_rejected(self, fake_finance):
        # CLAUDE.md "CASH ONLY". Anything other than 'cash' is rejected
        # at the service boundary so a buggy or hostile client can't
        # smuggle 'mobile_money' / 'check' / '' onto the model field.
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('1500'),
                method='mobile_money',
                finance=fake_finance,
            )
        assert exc_info.value.code == 'invalid_input'
        assert 'method' in exc_info.value.errors


    def test_negative_cash_rejected(self, fake_finance):
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError):
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount=Decimal('-100'),
                finance=fake_finance,
            )

    def test_unparsable_cash_rejected(self, fake_finance):
        booking = JobBookingInProgressFactory()
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.mark_complete_with_cash(
                booking_id=booking.id,
                technician_user=booking.technician.user,
                cash_amount='not a number',
                finance=fake_finance,
            )
        assert 'cash_amount' in exc_info.value.errors

    def test_idempotent_replay_with_zero_does_not_validate(self, fake_finance):
        # Already-COMPLETED booking. Idempotent replay short-circuits
        # BEFORE the positive-cash guard fires — a network-flaky client
        # re-posting with a stale (or buggy) zero amount should NOT
        # surface a 400; the transaction was already terminal on the
        # first call.
        booking = JobBookingInProgressFactory(
            status=JobBooking.STATUS_COMPLETED,
            cash_collected_amount=Decimal('1500.00'),
            completed_at=timezone.now(),
        )
        result = orchestrator.mark_complete_with_cash(
            booking_id=booking.id,
            technician_user=booking.technician.user,
            cash_amount=Decimal('0'),
            finance=fake_finance,
        )
        assert result.status == JobBooking.STATUS_COMPLETED


class TestQuoteSubmittedUniqueness:
    """Belt-and-braces: the partial unique constraint on Quote prevents
    a bug-bypass of the orchestrator's supersede-then-create flow from
    creating two SUBMITTED quotes for the same (booking, is_upsell).
    Direct ORM creation bypasses the orchestrator and tests the DB."""

    def test_two_submitted_non_upsell_quotes_rejected(self):
        from django.db import IntegrityError
        booking = JobBookingInspectingFactory()
        Quote.objects.create(
            booking=booking, revision_number=1,
            status=Quote.STATUS_SUBMITTED, is_upsell=False,
            total_amount=Decimal('500'),
        )
        with pytest.raises(IntegrityError):
            Quote.objects.create(
                booking=booking, revision_number=2,
                status=Quote.STATUS_SUBMITTED, is_upsell=False,
                total_amount=Decimal('700'),
            )

    def test_submitted_upsell_and_non_upsell_coexist(self):
        # Different flavours don't collide on the partial index. A
        # legitimate (if rare) state to be in mid-supersede.
        booking = JobBookingInspectingFactory()
        Quote.objects.create(
            booking=booking, revision_number=1,
            status=Quote.STATUS_SUBMITTED, is_upsell=False,
            total_amount=Decimal('500'),
        )
        upsell = Quote.objects.create(
            booking=booking, revision_number=2,
            status=Quote.STATUS_SUBMITTED, is_upsell=True,
            total_amount=Decimal('300'),
        )
        assert upsell.id is not None

    def test_superseded_does_not_block_new_submitted(self):
        # Verify the orchestrator's supersede-then-create flow still
        # works with the constraint in place: prior SUPERSEDED rows
        # don't sit in the partial index.
        booking = JobBookingInspectingFactory()
        Quote.objects.create(
            booking=booking, revision_number=1,
            status=Quote.STATUS_SUPERSEDED, is_upsell=False,
            total_amount=Decimal('500'),
        )
        new = Quote.objects.create(
            booking=booking, revision_number=2,
            status=Quote.STATUS_SUBMITTED, is_upsell=False,
            total_amount=Decimal('700'),
        )
        assert new.id is not None


class TestAdminResolveDisputeLockOrdering:
    """The audit found admin_resolve_dispute locked ticket-then-booking
    while every user transition locks booking-first. The order is now
    booking-first to match. These tests pin the corrected behaviour
    against regression."""

    def test_unknown_ticket_raises_404(self, fake_finance):
        with pytest.raises(BookingValidationError) as exc_info:
            orchestrator.admin_resolve_dispute(
                ticket_id=999_999_999,
                admin_user=UserFactory(),
                outcome=SupportTicket.OUTCOME_DISMISS,
                notes='',
                final_status=JobBooking.STATUS_CANCELLED,
                finance=fake_finance,
            )
        assert exc_info.value.code == 'ticket_not_found'
        assert exc_info.value.status_code == 404

    def test_idempotent_resolved_ticket_returns_without_locking(self, fake_finance):
        # The unlocked-fetch + resolved-check path means this case never
        # acquires the booking lock. Hard to assert "no lock" directly
        # in pytest-django's savepoint mode, but we assert behavioural
        # equivalence: result is the same ticket, booking unchanged.
        booking = JobBookingFactory(status=JobBooking.STATUS_DISPUTED)
        ticket = SupportTicket.objects.create(
            booking=booking, opened_by=booking.customer,
            initial_reason='x', status=SupportTicket.STATUS_RESOLVED,
            resolution_outcome=SupportTicket.OUTCOME_DISMISS,
            resolved_at=timezone.now(),
        )
        result = orchestrator.admin_resolve_dispute(
            ticket_id=ticket.id,
            admin_user=UserFactory(),
            outcome=SupportTicket.OUTCOME_DISMISS,
            notes='retry',
            final_status=JobBooking.STATUS_CANCELLED,
            finance=fake_finance,
        )
        assert result.id == ticket.id
        booking.refresh_from_db()
        # Booking status untouched — early-return fired BEFORE the lock /
        # mutation pair.
        assert booking.status == JobBooking.STATUS_DISPUTED

"""Read-side tests for ``bookings.selectors.dispute_selector``."""

import pytest

from bookings.models import SupportTicket
from bookings.selectors.dispute_selector import (
    list_all_tickets,
    list_open_tickets,
)
from tests.factories.bookings import JobBookingInProgressFactory
from tests.factories.support import SupportTicketFactory, TicketEvidenceFactory


pytestmark = pytest.mark.django_db


class TestListOpenTickets:
    def test_filters_to_open_only(self):
        booking = JobBookingInProgressFactory()
        open_t = SupportTicketFactory(booking=booking, status=SupportTicket.STATUS_OPEN)
        SupportTicketFactory(
            booking=booking,
            status=SupportTicket.STATUS_RESOLVED,
            resolution_outcome=SupportTicket.OUTCOME_DISMISS,
        )
        result = list_open_tickets(booking)
        assert [t.id for t in result] == [open_t.id]

    def test_orders_newest_first(self):
        booking = JobBookingInProgressFactory()
        first = SupportTicketFactory(booking=booking)
        second = SupportTicketFactory(booking=booking)
        result = list_open_tickets(booking)
        # Both opened recently; second was created after first → newest first.
        assert result[0].id == second.id
        assert result[1].id == first.id

    def test_no_n_plus_one(self, django_assert_num_queries):
        # 1 query for tickets (with select_related opened_by).
        # 1 query for prefetched evidence.
        booking = JobBookingInProgressFactory()
        ticket = SupportTicketFactory(booking=booking)
        for _ in range(3):
            TicketEvidenceFactory(ticket=ticket)
        with django_assert_num_queries(2):
            tickets = list_open_tickets(booking)
            for t in tickets:
                _ = t.opened_by.username
                _ = list(t.evidence.all())


class TestListAllTickets:
    def test_includes_resolved(self):
        booking = JobBookingInProgressFactory()
        SupportTicketFactory(booking=booking, status=SupportTicket.STATUS_OPEN)
        SupportTicketFactory(
            booking=booking,
            status=SupportTicket.STATUS_RESOLVED,
            resolution_outcome=SupportTicket.OUTCOME_REFUND_CUSTOMER,
        )
        result = list_all_tickets(booking)
        assert len(result) == 2

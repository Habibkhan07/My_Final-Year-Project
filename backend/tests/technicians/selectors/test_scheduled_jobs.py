"""Tests for the tech-side scheduled-jobs selector.

Mirrors the structure of the customer-side bookings selector tests but
exercises the audience-flipped contract (customer block, payout block,
tech-framed UI copy). Performance contracts use
``django_assert_num_queries`` per CLAUDE.md selector testing rules.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from django.utils import timezone

from bookings.models import JobBooking
from technicians.selectors.scheduled_jobs import (
    CursorDecodeError,
    SEGMENT_PAST,
    SEGMENT_UPCOMING,
    _customer_display_name,
    _decode_cursor,
    _encode_cursor,
    _resolve_payout_block,
    _resolve_ui_block,
    count_scheduled_jobs,
    list_scheduled_jobs,
)
from tests.factories.accounts import UserFactory
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingConfirmedFactory,
    JobBookingFactory,
    JobBookingInProgressFactory,
)
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import JobCommissionFactory

pytestmark = pytest.mark.django_db


# ─────────────────────────────────────────────────────────────────────────
# Segment partition — Upcoming vs Past membership rules.
# ─────────────────────────────────────────────────────────────────────────


class TestSegmentPartition:
    """Status × scheduled_end determines which segment a booking lives in."""

    def test_active_mid_job_always_in_upcoming(self):
        """EN_ROUTE / ARRIVED / INSPECTING / QUOTED / IN_PROGRESS are
        live jobs; they never age out of Upcoming even if the original
        scheduled window has elapsed."""
        tech = TechnicianProfileFactory()
        past_end = timezone.now() - timezone.timedelta(hours=2)
        for status in (
            JobBooking.STATUS_EN_ROUTE,
            JobBooking.STATUS_ARRIVED,
            JobBooking.STATUS_INSPECTING,
            JobBooking.STATUS_QUOTED,
            JobBooking.STATUS_IN_PROGRESS,
        ):
            JobBookingFactory(
                technician=tech,
                status=status,
                scheduled_start=past_end - timezone.timedelta(hours=1),
                scheduled_end=past_end,
            )

        result = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_UPCOMING)
        assert len(result.items) == 5

    def test_ageable_in_upcoming_while_scheduled_end_in_future(self):
        """AWAITING / CONFIRMED count as Upcoming as long as the booking's
        scheduled window hasn't elapsed."""
        tech = TechnicianProfileFactory()
        future_end = timezone.now() + timezone.timedelta(hours=2)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            scheduled_start=future_end - timezone.timedelta(hours=1),
            scheduled_end=future_end,
        )
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_CONFIRMED,
            scheduled_start=future_end - timezone.timedelta(hours=1),
            scheduled_end=future_end,
        )

        result = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_UPCOMING)
        assert len(result.items) == 2

    def test_ageable_with_past_scheduled_end_falls_into_past(self):
        """A CONFIRMED slot that never advanced lifecycle and is now in
        the past should appear in Past, not Upcoming."""
        tech = TechnicianProfileFactory()
        past_end = timezone.now() - timezone.timedelta(hours=2)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_CONFIRMED,
            scheduled_start=past_end - timezone.timedelta(hours=1),
            scheduled_end=past_end,
        )

        upcoming = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_UPCOMING)
        past = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_PAST)
        assert len(upcoming.items) == 0
        assert len(past.items) == 1

    def test_past_contains_terminal_statuses(self):
        """All seven terminal statuses live in Past."""
        tech = TechnicianProfileFactory()
        for status in (
            JobBooking.STATUS_COMPLETED,
            JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_TECH_DECLINED,
            JobBooking.STATUS_TECH_NO_RESPONSE,
            JobBooking.STATUS_NO_SHOW,
            JobBooking.STATUS_DISPUTED,
        ):
            JobBookingFactory(technician=tech, status=status)

        result = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_PAST)
        assert len(result.items) == 7

    def test_counts_match_list_after_pagination(self):
        """Counts must equal the list's full paginated total — a
        mismatched badge is worse UX than a slightly stale one."""
        tech = TechnicianProfileFactory()
        for _ in range(7):
            JobBookingCompletedFactory(technician=tech)

        counts = count_scheduled_jobs(tech_profile=tech)
        all_ids = set()
        cursor = None
        while True:
            page = list_scheduled_jobs(
                tech_profile=tech,
                segment=SEGMENT_PAST,
                page_size=3,
                cursor=cursor,
            )
            for item in page.items:
                all_ids.add(item["id"])
            if not page.has_more:
                break
            cursor = page.next_cursor

        assert counts.past == 7
        assert len(all_ids) == 7


# ─────────────────────────────────────────────────────────────────────────
# Cursor pagination — opaque encode/decode + error path.
# ─────────────────────────────────────────────────────────────────────────


class TestCursorPagination:
    def test_encode_decode_round_trip(self):
        """A cursor must decode back to the exact (datetime, id) tuple
        that produced it — including microseconds."""
        when = timezone.now().replace(microsecond=123456)
        token = _encode_cursor(when, 42)
        decoded_dt, decoded_id = _decode_cursor(token)
        assert decoded_dt == when
        assert decoded_id == 42

    def test_bad_cursor_raises(self):
        """Malformed cursors propagate ``CursorDecodeError`` to the view,
        which maps to a 400 ``invalid_cursor`` envelope."""
        with pytest.raises(CursorDecodeError):
            _decode_cursor("not-base64!!!")

    def test_sort_direction_per_segment(self):
        """Upcoming → ASC (next-soonest first); Past → DESC (most-recent
        first). The Flutter card relies on this order."""
        tech = TechnicianProfileFactory()
        now = timezone.now()
        early_completed = JobBookingCompletedFactory(
            technician=tech,
            scheduled_start=now - timezone.timedelta(days=2),
        )
        late_completed = JobBookingCompletedFactory(
            technician=tech,
            scheduled_start=now - timezone.timedelta(hours=1),
        )
        early_upcoming = JobBookingConfirmedFactory(
            technician=tech,
            scheduled_start=now + timezone.timedelta(hours=1),
            scheduled_end=now + timezone.timedelta(hours=2),
        )
        late_upcoming = JobBookingConfirmedFactory(
            technician=tech,
            scheduled_start=now + timezone.timedelta(days=2),
            scheduled_end=now + timezone.timedelta(days=2, hours=1),
        )

        upcoming = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_UPCOMING)
        past = list_scheduled_jobs(tech_profile=tech, segment=SEGMENT_PAST)
        assert [i["id"] for i in upcoming.items] == [early_upcoming.id, late_upcoming.id]
        assert [i["id"] for i in past.items] == [late_completed.id, early_completed.id]


# ─────────────────────────────────────────────────────────────────────────
# UI block resolution — tech-framed copy table.
# ─────────────────────────────────────────────────────────────────────────


class TestUIBlockResolution:
    """The selector's ui block is the Dumb-UI contract. Drift here is a
    breaking change for the Flutter status-pill widget."""

    @pytest.mark.parametrize(
        "status,expected_tone",
        [
            (JobBooking.STATUS_AWAITING_TECH_ACCEPT, "warning"),
            (JobBooking.STATUS_CONFIRMED, "positive"),
            (JobBooking.STATUS_EN_ROUTE, "info"),
            (JobBooking.STATUS_ARRIVED, "info"),
            (JobBooking.STATUS_INSPECTING, "info"),
            (JobBooking.STATUS_QUOTED, "warning"),
            (JobBooking.STATUS_IN_PROGRESS, "info"),
            (JobBooking.STATUS_COMPLETED, "positive"),
            (JobBooking.STATUS_COMPLETED_INSPECTION_ONLY, "neutral"),
            (JobBooking.STATUS_CANCELLED, "neutral"),
            (JobBooking.STATUS_TECH_DECLINED, "negative"),
            (JobBooking.STATUS_TECH_NO_RESPONSE, "negative"),
            (JobBooking.STATUS_NO_SHOW, "negative"),
            (JobBooking.STATUS_DISPUTED, "negative"),
            (JobBooking.STATUS_PENDING, "neutral"),
        ],
    )
    def test_every_status_returns_tone_and_non_empty_headline(self, status, expected_tone):
        ui = _resolve_ui_block(
            status=status,
            customer_display_name="Sara M.",
            cancel_reason=None,
        )
        assert ui["badge_tone"] == expected_tone
        assert ui["badge_text"]
        assert ui["headline"]

    @pytest.mark.parametrize(
        "cancel_reason,expected_headline",
        [
            ("technician_cancelled", "You cancelled this booking"),
            ("customer_rescheduled", "Sara M. rescheduled"),
            ("customer_cancelled_pre_accept", "Sara M. cancelled"),
            (None, "Booking was cancelled"),
        ],
    )
    def test_cancelled_reason_discrimination(self, cancel_reason, expected_headline):
        ui = _resolve_ui_block(
            status=JobBooking.STATUS_CANCELLED,
            customer_display_name="Sara M.",
            cancel_reason=cancel_reason,
        )
        assert ui["headline"] == expected_headline

    @pytest.mark.parametrize(
        "status,expected_badge,expected_headline",
        [
            (
                JobBooking.STATUS_TECH_DECLINED,
                "Declined",
                "You declined this job",
            ),
            (
                JobBooking.STATUS_TECH_NO_RESPONSE,
                "Timed out",
                "You missed the response window",
            ),
        ],
    )
    def test_tech_acceptance_failure_discrimination(
        self, status, expected_badge, expected_headline
    ):
        # Pre-migration 0013: one REJECTED status + an EventLog reason
        # lookup. Post-0013: status discriminates directly.
        ui = _resolve_ui_block(
            status=status,
            customer_display_name="Sara M.",
            cancel_reason=None,
        )
        assert ui["badge_text"] == expected_badge
        assert ui["headline"] == expected_headline

    def test_customer_display_name_falls_back_to_username(self):
        """``get_full_name`` returns empty string when first/last are
        blank — the selector must fall back to ``username`` rather than
        rendering '' in the headline."""
        user = UserFactory(first_name="", last_name="", username="+923009999999")
        booking = JobBookingFactory(customer=user)
        assert _customer_display_name(booking) == "+923009999999"


# ─────────────────────────────────────────────────────────────────────────
# Payout resolution — two-tier sourcing.
# ─────────────────────────────────────────────────────────────────────────


class TestPayoutResolution:
    def test_completed_with_commission_uses_ledger_net(self):
        """When a JobCommission row exists, the payout is the
        snapshotted ``payout_amount - commission_amount`` (ledger truth)."""
        booking = JobBookingCompletedFactory(price_amount=Decimal("1100.00"))
        JobCommissionFactory(
            booking=booking,
            payout_amount=Decimal("1100.00"),
            commission_rate=Decimal("0.20"),
            commission_amount=Decimal("220.00"),
        )
        # Re-fetch via the selector base queryset to populate the
        # ``commission`` reverse OneToOne via select_related.
        booking.refresh_from_db()
        result = _resolve_payout_block(booking)

        assert result["amount"] == 880
        assert result["ui_label"] == "Rs. 880"
        assert result["context"] == "After Rs. 220 commission"

    def test_completed_without_commission_uses_projected_payout_label(self):
        """A COMPLETED row missing a JobCommission (seed/legacy only)
        should label as 'Payout' — not 'Est. payout' which would imply
        the job hasn't completed."""
        booking = JobBookingCompletedFactory(price_amount=Decimal("1000.00"))
        result = _resolve_payout_block(booking)

        assert result["context"] == "Payout"
        assert result["amount"] == 800  # 1000 * 0.80

    def test_completed_inspection_only_uses_inspection_fee(self):
        booking = JobBookingFactory(
            status=JobBooking.STATUS_COMPLETED_INSPECTION_ONLY,
            inspection_fee=Decimal("500.00"),
        )
        result = _resolve_payout_block(booking)

        assert result["amount"] == 500
        assert result["context"] == "Inspection fee (cash)"

    @pytest.mark.parametrize(
        "status",
        [
            JobBooking.STATUS_TECH_DECLINED,
            JobBooking.STATUS_TECH_NO_RESPONSE,
            JobBooking.STATUS_CANCELLED,
            JobBooking.STATUS_NO_SHOW,
            JobBooking.STATUS_DISPUTED,
        ],
    )
    def test_forgone_statuses_label(self, status):
        """Statuses that prevent earnings should label the payout as
        'Forgone' so the tech reads them as lost income, not real
        income."""
        booking = JobBookingFactory(status=status, price_amount=Decimal("1000.00"))
        result = _resolve_payout_block(booking)

        assert result["context"] == "Forgone"
        assert result["amount"] == 800

    def test_pre_completion_est_payout_label(self):
        booking = JobBookingInProgressFactory(price_amount=Decimal("1000.00"))
        result = _resolve_payout_block(booking)

        assert result["context"] == "Est. payout"
        assert result["amount"] == 800


# ─────────────────────────────────────────────────────────────────────────
# Selector performance — query count is the CLAUDE.md mandate.
# ─────────────────────────────────────────────────────────────────────────


class TestSelectorPerformance:
    def test_list_single_query(self, django_assert_num_queries):
        """A page takes exactly one SQL query — select_related fans out
        the joins. Pre-migration 0013 tech-failure pages fired a second
        query for an EventLog rejection-reason batch; that query is gone
        now (status carries the cause)."""
        tech = TechnicianProfileFactory()
        for _ in range(5):
            JobBookingCompletedFactory(technician=tech)

        with django_assert_num_queries(1):
            list_scheduled_jobs(
                tech_profile=tech, segment=SEGMENT_PAST, page_size=5
            )

    def test_list_with_tech_failure_rows_still_single_query(
        self, django_assert_num_queries,
    ):
        # Pre-0013 this fired a second query; post-0013 it doesn't.
        tech = TechnicianProfileFactory()
        for _ in range(5):
            JobBookingFactory(
                technician=tech, status=JobBooking.STATUS_TECH_DECLINED,
            )

        with django_assert_num_queries(1):
            list_scheduled_jobs(
                tech_profile=tech, segment=SEGMENT_PAST, page_size=5
            )

    def test_counts_two_queries(self, django_assert_num_queries):
        tech = TechnicianProfileFactory()
        with django_assert_num_queries(2):
            count_scheduled_jobs(tech_profile=tech)


# ─────────────────────────────────────────────────────────────────────────
# IDOR scope — the only thing standing between two techs' bookings.
# ─────────────────────────────────────────────────────────────────────────


class TestIDORScope:
    def test_list_scoped_to_tech(self):
        tech_a = TechnicianProfileFactory()
        tech_b = TechnicianProfileFactory()
        a_booking = JobBookingCompletedFactory(technician=tech_a)
        JobBookingCompletedFactory(technician=tech_b)

        result = list_scheduled_jobs(tech_profile=tech_a, segment=SEGMENT_PAST)

        assert [item["id"] for item in result.items] == [a_booking.id]

    def test_counts_scoped_to_tech(self):
        tech_a = TechnicianProfileFactory()
        tech_b = TechnicianProfileFactory()
        JobBookingCompletedFactory(technician=tech_a)
        for _ in range(4):
            JobBookingCompletedFactory(technician=tech_b)

        counts = count_scheduled_jobs(tech_profile=tech_a)
        assert counts.past == 1


# ─────────────────────────────────────────────────────────────────────────
# Address fallback — real → snapshot → None.
# ─────────────────────────────────────────────────────────────────────────


class TestAddressFallback:
    def test_set_null_address_falls_back_to_snapshot(self):
        """When the address FK was SET_NULL after deletion, the
        ``actual_address_snapshot`` (frozen at booking creation) is the
        next-best display source."""
        booking = JobBookingFactory(
            address=None,
            actual_address_snapshot="14 Street, Gulberg III, Lahore",
        )
        result = list_scheduled_jobs(
            tech_profile=booking.technician, segment=SEGMENT_PAST
        )
        # Re-run as past after the factory's default scheduling.
        # We don't depend on segment correctness here — just check that
        # the address_label uses the snapshot.
        all_items = result.items + list_scheduled_jobs(
            tech_profile=booking.technician, segment=SEGMENT_UPCOMING
        ).items
        addr_labels = [i["address_label"] for i in all_items]
        assert "14 Street, Gulberg III, Lahore" in addr_labels

    def test_empty_address_and_snapshot_returns_none(self):
        booking = JobBookingFactory(address=None, actual_address_snapshot="")
        result = list_scheduled_jobs(
            tech_profile=booking.technician, segment=SEGMENT_UPCOMING
        ) or list_scheduled_jobs(
            tech_profile=booking.technician, segment=SEGMENT_PAST
        )
        # The booking lands in one segment; pull whichever has it.
        all_items = (
            list_scheduled_jobs(
                tech_profile=booking.technician, segment=SEGMENT_UPCOMING
            ).items
            + list_scheduled_jobs(
                tech_profile=booking.technician, segment=SEGMENT_PAST
            ).items
        )
        assert all_items
        assert all_items[0]["address_label"] is None

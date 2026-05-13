from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from bookings.models import JobBooking
from technicians.selectors.metrics_selector import (
    PERIOD_DAY,
    PERIOD_MONTH,
    PERIOD_WEEK,
    PERIOD_YEAR,
    get_technician_metrics,
)
from tests.factories.bookings import JobBookingFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestPeriodWeek:
    """Default period — current ISO week, Mon–Sun, daily buckets."""

    def test_response_shape(self):
        tech = TechnicianProfileFactory()
        result = get_technician_metrics(tech, period=PERIOD_WEEK)

        assert result['period'] == PERIOD_WEEK
        assert result['total_jobs'] == 0
        assert result['total_cash'] == 0.0
        assert len(result['buckets']) == 7
        labels = [b['label'] for b in result['buckets']]
        assert labels == ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

    def test_today_counts_and_cash(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now,
            price_amount=Decimal('1500.00'),
        )
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now,
            price_amount=Decimal('2000.00'),
        )

        result = get_technician_metrics(tech, period=PERIOD_WEEK)

        assert result['total_jobs'] == 2
        assert result['total_cash'] == 3500.00
        # The bucket matching today must hold both jobs.
        today_label = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][now.weekday()]
        today_bucket = next(b for b in result['buckets'] if b['label'] == today_label)
        assert today_bucket['jobs'] == 2
        assert today_bucket['cash'] == 3500.00

    def test_excludes_last_week(self):
        tech = TechnicianProfileFactory()
        eight_days_ago = timezone.now() - timedelta(days=8)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=eight_days_ago,
            price_amount=Decimal('1000.00'),
        )

        result = get_technician_metrics(tech, period=PERIOD_WEEK)

        assert result['total_jobs'] == 0
        assert result['total_cash'] == 0.0
        # All seven daily buckets are zero.
        for bucket in result['buckets']:
            assert bucket['jobs'] == 0
            assert bucket['cash'] == 0.0


class TestPeriodDay:
    """Day period — last 7 days ending today, daily buckets. Today is 'Today'."""

    def test_response_shape(self):
        tech = TechnicianProfileFactory()
        result = get_technician_metrics(tech, period=PERIOD_DAY)

        assert result['period'] == PERIOD_DAY
        assert len(result['buckets']) == 7
        # The last bar is labelled 'Today'.
        assert result['buckets'][-1]['label'] == 'Today'

    def test_today_lands_in_last_bucket(self):
        tech = TechnicianProfileFactory()
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=timezone.now(),
            price_amount=Decimal('999.00'),
        )

        result = get_technician_metrics(tech, period=PERIOD_DAY)

        last = result['buckets'][-1]
        assert last['label'] == 'Today'
        assert last['jobs'] == 1
        assert last['cash'] == 999.00


class TestPeriodMonth:
    """Month period — last 30 days, daily buckets labelled by day-of-month."""

    def test_response_shape(self):
        tech = TechnicianProfileFactory()
        result = get_technician_metrics(tech, period=PERIOD_MONTH)

        assert result['period'] == PERIOD_MONTH
        assert len(result['buckets']) == 30

    def test_excludes_31_days_ago(self):
        tech = TechnicianProfileFactory()
        thirty_one_days_ago = timezone.now() - timedelta(days=31)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=thirty_one_days_ago,
            price_amount=Decimal('500.00'),
        )

        result = get_technician_metrics(tech, period=PERIOD_MONTH)

        assert result['total_jobs'] == 0
        assert result['total_cash'] == 0.0


class TestPeriodYear:
    """Year period — current year Jan-Dec, 12 monthly buckets."""

    def test_response_shape(self):
        tech = TechnicianProfileFactory()
        result = get_technician_metrics(tech, period=PERIOD_YEAR)

        assert result['period'] == PERIOD_YEAR
        assert len(result['buckets']) == 12
        labels = [b['label'] for b in result['buckets']]
        assert labels == [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ]

    def test_today_lands_in_current_month(self):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now,
            price_amount=Decimal('1234.00'),
        )

        result = get_technician_metrics(tech, period=PERIOD_YEAR)

        current_month = result['buckets'][now.month - 1]
        assert current_month['jobs'] == 1
        assert current_month['cash'] == 1234.00


class TestZeroState:
    """All four periods backfill zero buckets when there's no data."""

    @pytest.mark.parametrize('period,expected_count', [
        (PERIOD_DAY, 7),
        (PERIOD_WEEK, 7),
        (PERIOD_MONTH, 30),
        (PERIOD_YEAR, 12),
    ])
    def test_zero_state_per_period(self, period, expected_count):
        tech = TechnicianProfileFactory()

        result = get_technician_metrics(tech, period=period)

        assert result['period'] == period
        assert result['total_jobs'] == 0
        assert result['total_cash'] == 0.0
        assert len(result['buckets']) == expected_count
        for bucket in result['buckets']:
            assert bucket['jobs'] == 0
            assert bucket['cash'] == 0.0


class TestQueryCount:
    """Single aggregation query per call, regardless of data volume."""

    @pytest.mark.parametrize('period', [PERIOD_DAY, PERIOD_WEEK, PERIOD_MONTH, PERIOD_YEAR])
    def test_query_count(self, django_assert_num_queries, period):
        tech = TechnicianProfileFactory()
        now = timezone.now()
        for i in range(4):
            JobBookingFactory(
                technician=tech,
                status=JobBooking.STATUS_COMPLETED,
                scheduled_start=now - timedelta(hours=i),
                price_amount=Decimal('500.00'),
            )

        with django_assert_num_queries(1):
            get_technician_metrics(tech, period=period)


class TestUnknownPeriod:
    """Defence-in-depth check inside the selector."""

    def test_raises_value_error(self):
        tech = TechnicianProfileFactory()
        with pytest.raises(ValueError, match='Unknown period'):
            get_technician_metrics(tech, period='century')

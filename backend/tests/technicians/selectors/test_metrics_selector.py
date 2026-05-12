from datetime import timedelta
from decimal import Decimal

import pytest
from django.utils import timezone

from bookings.models import JobBooking
from technicians.selectors.metrics_selector import get_technician_metrics
from tests.factories.bookings import JobBookingFactory
from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import TransactionType
from wallet.services.ledger import record_transaction

pytestmark = pytest.mark.django_db


class TestGetTechnicianMetrics:
    def test_today_counts_and_cash(self):
        """Two completed jobs today → correct jobs_completed_today + cash_collected_today."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('5000.00'))
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
            scheduled_start=now + timedelta(hours=1),
            price_amount=Decimal('2000.00'),
        )

        result = get_technician_metrics(tech)

        assert result['jobs_completed_today'] == 2
        assert result['cash_collected_today'] == 3500.00

    def test_commission_deducted_today(self):
        """Commission from real ledger is returned as a positive figure."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('5000.00'))

        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-300.00'),
            memo='Commission for booking #1',
            transaction_reference_number='test-commission-001',
        )

        result = get_technician_metrics(tech)

        assert result['commission_deducted_today'] == 300.00

    def test_week_excludes_last_week(self):
        """A job completed 8 days ago does NOT appear in this-week totals."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))
        eight_days_ago = timezone.now() - timedelta(days=8)

        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=eight_days_ago,
            price_amount=Decimal('1000.00'),
        )

        result = get_technician_metrics(tech)

        assert result['jobs_completed_this_week'] == 0
        assert result['cash_collected_this_week'] == 0.0

    def test_today_counts_in_week_total(self):
        """Today's job appears in BOTH today and this-week totals."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('0.00'))

        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=timezone.now(),
            price_amount=Decimal('2000.00'),
        )

        result = get_technician_metrics(tech)

        assert result['jobs_completed_today'] == 1
        assert result['jobs_completed_this_week'] == 1
        assert result['cash_collected_today'] == 2000.00
        assert result['cash_collected_this_week'] == 2000.00

    def test_zero_state(self):
        """No jobs, no transactions → all five fields are zero."""
        tech = TechnicianProfileFactory()

        result = get_technician_metrics(tech)

        assert result['jobs_completed_today'] == 0
        assert result['cash_collected_today'] == 0.0
        assert result['commission_deducted_today'] == 0.0
        assert result['jobs_completed_this_week'] == 0
        assert result['cash_collected_this_week'] == 0.0

    def test_query_count(self, django_assert_num_queries):
        """Selector must use exactly 2 queries regardless of data volume."""
        tech = TechnicianProfileFactory(current_wallet_balance=Decimal('5000.00'))
        now = timezone.now()

        for i in range(4):
            JobBookingFactory(
                technician=tech,
                status=JobBooking.STATUS_COMPLETED,
                scheduled_start=now - timedelta(hours=i),
                price_amount=Decimal('500.00'),
            )
        record_transaction(
            technician=tech,
            transaction_type=TransactionType.COMMISSION_DEBIT,
            amount=Decimal('-100.00'),
            transaction_reference_number=f'qc-test-commission',
        )

        with django_assert_num_queries(2):
            get_technician_metrics(tech)

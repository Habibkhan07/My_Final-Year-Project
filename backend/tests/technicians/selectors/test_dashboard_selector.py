import pytest
from django.utils import timezone
from decimal import Decimal
from bookings.models import JobBooking
from technicians.selectors.dashboard_selector import get_technician_dashboard
from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db

class TestTechnicianDashboardSelector:
    def test_selector_metrics_calculation(self):
        """Test metrics are strictly calculated from COMPLETED jobs for today."""
        tech = TechnicianProfileFactory(current_wallet_balance=1500.00)
        
        now = timezone.now()
        
        # Job 1: Completed today
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now,
            price_amount=Decimal("1500.00")
        )
        
        # Job 2: Completed today
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now + timezone.timedelta(hours=1),
            price_amount=Decimal("2000.00")
        )
        
        # Job 3: Pending today (should not count in metrics)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_PENDING,
            scheduled_start=now + timezone.timedelta(hours=2),
            price_amount=Decimal("5000.00")
        )
        
        # Job 4: Completed yesterday (should not count)
        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_COMPLETED,
            scheduled_start=now - timezone.timedelta(days=1),
            price_amount=Decimal("1000.00")
        )
        
        dashboard = get_technician_dashboard(tech)
        
        assert dashboard["metrics"]["jobs_completed_today"] == 2
        assert dashboard["metrics"]["cash_collected_today"] == 3500.00
        assert dashboard["wallet_balance"] == 1500.00

    def test_selector_upcoming_jobs_sorting_and_assignment(self):
        """Test up_next_job is the earliest CONFIRMED job today, rest in later_today_jobs."""
        tech = TechnicianProfileFactory(is_online=True)
        customer_profile = CustomerProfileFactory()
        customer = customer_profile.user
        address = CustomerAddressFactory(
            customer=customer_profile,
            street_address="14 Street, Gulberg III",
            latitude=Decimal("31.5204"),
            longitude=Decimal("74.3587")
        )
        
        now = timezone.now()
        
        # Later job
        job_later = JobBookingFactory(
            technician=tech,
            customer=customer,
            address=address,
            status=JobBooking.STATUS_CONFIRMED,
            scheduled_start=now + timezone.timedelta(hours=4),
            price_context="Ceiling Fan Repair"
        )
        
        # Up next job (earliest)
        job_next = JobBookingFactory(
            technician=tech,
            customer=customer,
            address=address,
            status=JobBooking.STATUS_CONFIRMED,
            scheduled_start=now + timezone.timedelta(minutes=30),
            price_context="AC Deep Wash"
        )
        
        dashboard = get_technician_dashboard(tech)
        
        assert dashboard["is_online"] is True
        
        # Verify up next job
        assert dashboard["up_next_job"] is not None
        assert dashboard["up_next_job"]["job_id"] == job_next.id
        assert dashboard["up_next_job"]["service_title"] == "AC Deep Wash"
        assert dashboard["up_next_job"]["customer_name"] == customer.get_full_name()
        assert dashboard["up_next_job"]["address_text"] == "14 Street, Gulberg III"
        assert dashboard["up_next_job"]["lat"] == 31.5204
        assert dashboard["up_next_job"]["lng"] == 74.3587
        
        # Verify later today jobs
        assert len(dashboard["later_today_jobs"]) == 1
        assert dashboard["later_today_jobs"][0]["job_id"] == job_later.id
        assert dashboard["later_today_jobs"][0]["service_title"] == "Ceiling Fan Repair"

    def test_selector_handles_empty_state(self):
        """Test handling of no jobs for today."""
        tech = TechnicianProfileFactory()
        dashboard = get_technician_dashboard(tech)
        
        assert dashboard["up_next_job"] is None
        assert dashboard["later_today_jobs"] == []
        assert dashboard["metrics"]["jobs_completed_today"] == 0
        assert dashboard["metrics"]["cash_collected_today"] == 0.0

    def test_selector_query_count(self, django_assert_num_queries):
        """Verify we do not have N+1 query issues when fetching customer and address."""
        tech = TechnicianProfileFactory()
        now = timezone.now()
        
        # Create 5 confirmed jobs for today
        for i in range(5):
            customer_profile = CustomerProfileFactory()
            address = CustomerAddressFactory(customer=customer_profile)
            JobBookingFactory(
                technician=tech,
                customer=customer_profile.user,
                address=address,
                status=JobBooking.STATUS_CONFIRMED,
                scheduled_start=now + timezone.timedelta(minutes=5) + timezone.timedelta(hours=i)
            )
            
        # Should be a fixed number of queries:
        # 1. Fetch completed jobs (aggregate)
        # 2. Fetch confirmed jobs (list/fetch with select_related)
        with django_assert_num_queries(2):
            dashboard = get_technician_dashboard(tech)
            assert dashboard["up_next_job"] is not None
            assert len(dashboard["later_today_jobs"]) == 4

import pytest
from django.utils import timezone
from decimal import Decimal
from bookings.models import JobBooking
from technicians.selectors.dashboard_selector import get_technician_dashboard
from tests.factories.accounts import UserFactory, UserProfileFactory
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory
from tests.factories.bookings import JobBookingFactory

pytestmark = pytest.mark.django_db

class TestTechnicianDashboardSelector:
    def test_selector_upcoming_jobs_sorting_and_assignment(self):
        """Test up_next_job is the earliest CONFIRMED job today, rest in later_today_jobs."""
        tech = TechnicianProfileFactory(is_online=True)
        customer_profile = CustomerProfileFactory()
        customer = customer_profile.user
        UserProfileFactory(user=customer, phone="+923001234567")
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
        assert dashboard["up_next_job"]["customer_phone"] == "+923001234567"
        assert dashboard["up_next_job"]["address_text"] == "14 Street, Gulberg III"
        assert dashboard["up_next_job"]["lat"] == 31.5204
        assert dashboard["up_next_job"]["lng"] == 74.3587
        
        # Verify later today jobs
        assert len(dashboard["later_today_jobs"]) == 1
        assert dashboard["later_today_jobs"][0]["job_id"] == job_later.id
        assert dashboard["later_today_jobs"][0]["service_title"] == "Ceiling Fan Repair"

    def test_awaiting_job_does_not_appear_in_up_next(self):
        """
        AWAITING bookings are dispatched but not yet accepted by the
        technician — they belong in the dispatch/accept event surface, not
        the daily-plan widget. Up Next + Later Today must show only the
        jobs the tech is committed to (CONFIRMED). Flag #1 closure.
        """
        tech = TechnicianProfileFactory()
        now = timezone.now()

        JobBookingFactory(
            technician=tech,
            status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
            scheduled_start=now + timezone.timedelta(minutes=30),
            price_context="AC Deep Wash",
        )

        dashboard = get_technician_dashboard(tech)

        assert dashboard["up_next_job"] is None
        assert dashboard["later_today_jobs"] == []

    def test_selector_handles_empty_state(self):
        """Test handling of no jobs for today."""
        tech = TechnicianProfileFactory()
        dashboard = get_technician_dashboard(tech)

        assert dashboard["up_next_job"] is None
        assert dashboard["later_today_jobs"] == []
        assert "metrics" not in dashboard

    def test_selector_surfaces_has_work_location_true(self):
        """Factory default sets non-null lat/lng → has_work_location is True."""
        tech = TechnicianProfileFactory(work_address_label='Gulberg, Lahore')
        dashboard = get_technician_dashboard(tech)

        assert dashboard["has_work_location"] is True
        assert dashboard["work_address_label"] == 'Gulberg, Lahore'

    def test_selector_surfaces_has_work_location_false_when_null(self):
        tech = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=None,
            work_address_label=None,
        )
        dashboard = get_technician_dashboard(tech)

        assert dashboard["has_work_location"] is False
        assert dashboard["work_address_label"] is None

    def test_selector_requires_both_coords_for_has_work_location_true(self):
        """Half-set (only one of lat/lng non-null) must surface as False —
        matches the matchmaker's own pair-guard which excludes either-null."""
        tech_only_lat = TechnicianProfileFactory(
            base_latitude=31.5,
            base_longitude=None,
        )
        assert get_technician_dashboard(tech_only_lat)["has_work_location"] is False

        tech_only_lng = TechnicianProfileFactory(
            base_latitude=None,
            base_longitude=74.3,
        )
        assert get_technician_dashboard(tech_only_lng)["has_work_location"] is False

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
            
        # Dashboard selector only runs the confirmed-jobs query now.
        # Metrics queries live in metrics_selector (see test_metrics_selector.py).
        with django_assert_num_queries(1):
            dashboard = get_technician_dashboard(tech)
            assert dashboard["up_next_job"] is not None
            assert len(dashboard["later_today_jobs"]) == 4

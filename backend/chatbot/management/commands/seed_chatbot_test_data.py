"""Seed test data for the customer-side dispute chatbot.

  python manage.py seed_chatbot_test_data

Produces a state where the customer can log in and open the dispute
chatbot for a freshly-completed booking. No conversation rows are
pre-seeded — the chatbot opens at the UNDERSTAND phase on first tap.

Reuses the canonical customer / technician / catalog / address fixtures
from ``bookings.management.commands.seed_test_fixtures`` so the test
phones (``+923002222222`` customer, ``+923001111111`` tech) match across
both runbooks and an already-logged-in Flutter session keeps working.

Eligibility contract (mirrors ``DisputePersona.is_eligible_to_start``):
  - Booking must belong to the requesting user.
  - Booking status must be COMPLETED or COMPLETED_INSPECTION_ONLY.

This command stamps STATUS_COMPLETED plus the full timeline of phase
timestamps and cash-collection fields so the orchestrator UI selector
renders a coherent receipt — without those, the booking-detail screen
degrades to half-rendered panels and the dispute button is the only
thing on the page.
"""

from datetime import timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.utils import timezone

from bookings.management.commands.seed_test_fixtures import (
    Command as FixtureCommand,
    CUSTOMER_PHONE,
    TECH_PHONE,
)
from bookings.models import JobBooking


# Receipt math that matches the orchestrator's COMPLETED stamping:
#   inspection_fee + base_services_total - discount_applied = final_cash
INSPECTION_FEE = Decimal('500.00')
BASE_SERVICES_TOTAL = Decimal('2500.00')
DISCOUNT_APPLIED = Decimal('0.00')
FINAL_CASH = INSPECTION_FEE + BASE_SERVICES_TOTAL - DISCOUNT_APPLIED


class Command(BaseCommand):
    help = 'Seed a COMPLETED booking so the customer-side dispute chatbot is reachable.'

    def handle(self, *args, **opts):
        fixtures = FixtureCommand()
        service, sub_service = fixtures._ensure_catalog()
        customer_user, customer_token, address = fixtures._ensure_customer()
        _, _, tech_profile = fixtures._ensure_technician(sub_service)

        booking = self._create_completed_booking(
            customer_user=customer_user,
            tech_profile=tech_profile,
            service=service,
            sub_service=sub_service,
            address=address,
        )

        self._print_summary(
            customer_user=customer_user,
            customer_token=customer_token,
            booking=booking,
        )

    def _create_completed_booking(
        self, *, customer_user, tech_profile, service, sub_service, address,
    ):
        now = timezone.now()
        # Monotonically-increasing timeline ending "just now" so the
        # COMPLETED receipt looks fresh and the dispute window is open.
        scheduled_start = now - timedelta(hours=2)
        accepted_at = now - timedelta(minutes=115)
        en_route_at = now - timedelta(minutes=90)
        arrived_at = now - timedelta(minutes=75)
        ack_arrival_at = now - timedelta(minutes=74)
        inspection_at = now - timedelta(minutes=70)
        quote_at = now - timedelta(minutes=55)
        work_started_at = now - timedelta(minutes=50)
        completed_at = now - timedelta(minutes=5)

        return JobBooking.objects.create(
            technician=tech_profile,
            customer=customer_user,
            address=address,
            service=service,
            sub_service=sub_service,
            scheduled_start=scheduled_start,
            scheduled_end=scheduled_start + timedelta(minutes=60),
            status=JobBooking.STATUS_COMPLETED,
            price_amount=FINAL_CASH,
            price_context=f'{service.name} — {sub_service.name}',
            actual_address_snapshot=address.street_address,
            accepted_at=accepted_at,
            en_route_started_at=en_route_at,
            arrived_at=arrived_at,
            customer_acknowledged_arrival_at=ack_arrival_at,
            inspection_started_at=inspection_at,
            quote_first_submitted_at=quote_at,
            work_started_at=work_started_at,
            completed_at=completed_at,
            inspection_fee=INSPECTION_FEE,
            base_services_total=BASE_SERVICES_TOTAL,
            discount_applied=DISCOUNT_APPLIED,
            final_cash_to_collect=FINAL_CASH,
            cash_collected_amount=FINAL_CASH,
            cash_collected_at=completed_at,
        )

    def _print_summary(self, *, customer_user, customer_token, booking):
        bar = '=' * 64
        s = self.style.SUCCESS
        self.stdout.write('')
        self.stdout.write(s(bar))
        self.stdout.write(s('  CHATBOT TEST DATA READY'))
        self.stdout.write(s(bar))
        self.stdout.write(f'  Customer phone   : {CUSTOMER_PHONE}   (OTP: 123456)')
        self.stdout.write(f'  Customer user id : {customer_user.id}')
        self.stdout.write(f'  Customer token   : {customer_token.key}')
        self.stdout.write(f'  Tech phone       : {TECH_PHONE}   (OTP: 123456)')
        self.stdout.write('')
        self.stdout.write(s(f'  Booking id       : {booking.id}'))
        self.stdout.write(f'  Booking status   : {booking.status}')
        self.stdout.write(f'  Final cash       : Rs. {FINAL_CASH}')
        self.stdout.write('')
        self.stdout.write('  Next:')
        self.stdout.write(f'    1. Flutter login: {CUSTOMER_PHONE} / OTP 123456')
        self.stdout.write(f'    2. Bookings tab → open booking #{booking.id}')
        self.stdout.write(f'    3. Tap the dispute button → chatbot opens (UNDERSTAND phase)')
        self.stdout.write(s(bar))

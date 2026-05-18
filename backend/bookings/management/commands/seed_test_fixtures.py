"""
Seeds the persistent fixtures + a fresh AWAITING booking for the
customer-side Chrome test runbook.

  python manage.py seed_test_fixtures               # 1 fresh booking
  python manage.py seed_test_fixtures --count 5     # 5 fresh bookings

Persistent (kept across runs so the Chrome session stays logged in):
  - Catalog: Service "AC Repair" + SubService "Freon Gas Top-up"
  - Customer user (+923002222222) + CustomerProfile + Home address (Islamabad F-7)
  - Technician user (+923001111111) + TechnicianProfile (APPROVED) +
    TechnicianSkill linking to the sub-service so the tech can submit a quote
  - DRF tokens for both users (used by the customer Chrome client and by
    fake_tech_gps.py to impersonate the tech device)

Per run: N fresh JobBookings in AWAITING (default 1). Each invocation prints
the new booking id(s) plus the two tokens so you can paste them into
drive_booking and fake_tech_gps without re-logging-in on Chrome.
"""

import io
from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.utils import timezone
from PIL import Image
from rest_framework.authtoken.models import Token

from accounts.models import UserProfile
from bookings.models import JobBooking
from catalog.models import Service, SubService
from customers.models import CustomerAddress, CustomerProfile
from technicians.models import TechnicianProfile, TechnicianSkill

User = get_user_model()

# Test phones — matches the OTP DEBUG flow (any phone gets OTP 123456).
CUSTOMER_PHONE = '+923002222222'
TECH_PHONE = '+923001111111'

# Gulberg III, Lahore (around Liberty Market) — close enough to trigger
# the auto-transition geofence when the fake_tech_gps script feeds frames
# toward this point.
CUSTOMER_LAT = Decimal('31.5097')
CUSTOMER_LNG = Decimal('74.3478')
# Tech base ~1.5 km north (Gulberg II area, same longitude) so a steady-route
# fake_tech_gps run flips CONFIRMED → EN_ROUTE → ARRIVED on its own when
# --geofence is set.
TECH_BASE_LAT = 31.5230
TECH_BASE_LNG = 74.3478


class Command(BaseCommand):
    help = 'Seed persistent fixtures + N fresh AWAITING bookings for Chrome testing.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=1,
            help='How many fresh AWAITING bookings to create this run (default 1).',
        )

    def handle(self, *args, **opts):
        count = max(1, int(opts['count']))

        service, sub_service = self._ensure_catalog()
        customer_user, customer_token, address = self._ensure_customer()
        tech_user, tech_token, tech_profile = self._ensure_technician(sub_service)

        booking_ids = self._create_bookings(
            n=count,
            customer_user=customer_user,
            tech_profile=tech_profile,
            service=service,
            sub_service=sub_service,
            address=address,
        )

        self._print_summary(
            customer_user=customer_user,
            customer_token=customer_token,
            tech_user=tech_user,
            tech_token=tech_token,
            address=address,
            tech_profile=tech_profile,
            booking_ids=booking_ids,
        )

    # ---------------- catalog ----------------

    def _ensure_catalog(self):
        service, _ = Service.objects.get_or_create(
            name='AC Repair',
            defaults={
                'icon_name': 'ac_repair',
                'base_inspection_fee': Decimal('500.00'),
                'default_duration_minutes': 60,
            },
        )
        sub_service, _ = SubService.objects.get_or_create(
            service=service,
            name='Freon Gas Top-up',
            defaults={
                'base_price': Decimal('2500.00'),
                'is_fixed_price': True,
                'is_featured': True,
                'estimated_duration_minutes': 60,
                'icon_name': 'freon_gas',
            },
        )
        # Labor-priced companion item. Real AC repairs in this market
        # almost always have both a catalog charge (parts / refill /
        # fixed-rate service) AND the tech's labor for diagnostic and
        # workmanship. Seeding a labor sub-service lets `drive_booking
        # quote` build a realistic mixed quote so the customer-QUOTED
        # screen surfaces the "Negotiate price" button (which the
        # backend correctly omits on pure-fixed-price quotes).
        SubService.objects.get_or_create(
            service=service,
            name='Diagnostic & Labor',
            defaults={
                'base_price': Decimal('500.00'),
                'max_price': Decimal('2000.00'),
                'is_fixed_price': False,
                'is_featured': False,
                'estimated_duration_minutes': 30,
                'icon_name': 'ac_repair',
            },
        )
        return service, sub_service

    # ---------------- customer ----------------

    def _ensure_customer(self):
        user, created = User.objects.get_or_create(
            username=CUSTOMER_PHONE,
            defaults={'first_name': 'Test', 'last_name': 'Customer'},
        )
        if created:
            user.set_password('password123')
            user.save()
        UserProfile.objects.get_or_create(
            user=user,
            defaults={'phone': CUSTOMER_PHONE, 'is_technician': False},
        )
        profile, _ = CustomerProfile.objects.get_or_create(user=user)
        # Resilient to duplicate-label state. ``get_or_create`` raises
        # MultipleObjectsReturned on dev DBs that accumulated repeat
        # addresses across earlier test runs (the model doesn't enforce
        # uniqueness on label, only on (customer, primary_key)). Prefer
        # the most-recent matching row; only create if none exist.
        address = (
            CustomerAddress.objects
            .filter(customer=profile, label='Home')
            .order_by('-id')
            .first()
        )
        if address is None:
            address = CustomerAddress.objects.create(
                customer=profile,
                label='Home',
                street_address='Liberty Market, Gulberg III, Lahore',
                latitude=CUSTOMER_LAT,
                longitude=CUSTOMER_LNG,
                is_default=True,
                city='Lahore',
                country='PK',
                locality_label='Gulberg III, Lahore',
            )
        token, _ = Token.objects.get_or_create(user=user)
        return user, token, address

    # ---------------- technician ----------------

    def _ensure_technician(self, sub_service):
        user, created = User.objects.get_or_create(
            username=TECH_PHONE,
            defaults={'first_name': 'Test', 'last_name': 'Technician'},
        )
        if created:
            user.set_password('password123')
            user.save()
        UserProfile.objects.get_or_create(
            user=user,
            defaults={'phone': TECH_PHONE, 'is_technician': True},
        )

        profile, profile_created = TechnicianProfile.objects.get_or_create(
            user=user,
            defaults={
                # Demo tech is physically in Lahore Gulberg per
                # TECH_BASE_LAT/LNG below; keep `city` aligned so the
                # technician's city enum matches their actual coords.
                # Mirror the same flip in
                # technicians/.../seed_online_toggle.py (which also
                # creates this row depending on demo_journey.sh order).
                'city': 'LHR',
                'cnic_number': '35202-1111111-1',
                'status': 'APPROVED',
                'base_latitude': TECH_BASE_LAT,
                'base_longitude': TECH_BASE_LNG,
                'is_onboarding_complete': True,
                'is_active': True,
                'rating_average': Decimal('4.80'),
                'review_count': 50,
            },
        )
        if profile_created:
            # ImageField columns are required; tiny placeholder JPEGs satisfy
            # the not-null constraint without bringing PIL into the dep graph.
            placeholder = ContentFile(_tiny_jpeg(), name='placeholder.jpg')
            profile.profile_picture.save('tech_pp.jpg', placeholder, save=False)
            profile.cnic_front_image.save('tech_cnic.jpg', placeholder, save=False)
            profile.save()

        TechnicianSkill.objects.get_or_create(
            technician=profile,
            sub_service=sub_service,
        )
        # Tech is also qualified for the labor companion item so
        # `drive_booking quote` can attach it on any booking.
        for labor_sub in SubService.objects.filter(
            service=sub_service.service, is_fixed_price=False,
        ):
            TechnicianSkill.objects.get_or_create(
                technician=profile,
                sub_service=labor_sub,
            )

        token, _ = Token.objects.get_or_create(user=user)
        return user, token, profile

    # ---------------- bookings ----------------

    def _create_bookings(self, *, n, customer_user, tech_profile, service, sub_service, address):
        # All bookings start NOW + 5 min so they're plausibly "current"
        # for the orchestrator screen without colliding with each other.
        ids = []
        base = timezone.now()
        for i in range(n):
            start = base + timedelta(minutes=5 + i * 90)
            booking = JobBooking.objects.create(
                technician=tech_profile,
                customer=customer_user,
                address=address,
                service=service,
                sub_service=sub_service,
                scheduled_start=start,
                scheduled_end=start + timedelta(minutes=sub_service.estimated_duration_minutes or 60),
                status=JobBooking.STATUS_AWAITING_TECH_ACCEPT,
                price_amount=sub_service.base_price,
                price_context=f'{service.name} — {sub_service.name}',
                actual_address_snapshot=address.street_address,
            )
            ids.append(booking.id)
        return ids

    # ---------------- summary ----------------

    def _print_summary(self, *, customer_user, customer_token, tech_user, tech_token,
                       address, tech_profile, booking_ids):
        bar = '=' * 64
        s = self.style.SUCCESS
        self.stdout.write('')
        self.stdout.write(s(bar))
        self.stdout.write(s('  TEST FIXTURE READY'))
        self.stdout.write(s(bar))
        self.stdout.write(f'  Customer phone   : {CUSTOMER_PHONE}   (OTP: 123456)')
        self.stdout.write(f'  Customer user id : {customer_user.id}')
        self.stdout.write(f'  Customer token   : {customer_token.key}')
        self.stdout.write(f'  Address id       : {address.id}  ({address.latitude}, {address.longitude})')
        self.stdout.write('')
        self.stdout.write(f'  Tech phone       : {TECH_PHONE}   (OTP: 123456)')
        self.stdout.write(f'  Tech user id     : {tech_user.id}')
        self.stdout.write(f'  Tech profile id  : {tech_profile.id}')
        self.stdout.write(f'  Tech token       : {tech_token.key}')
        self.stdout.write('')
        self.stdout.write(s(f'  New bookings ({len(booking_ids)}, all AWAITING):'))
        for bid in booking_ids:
            self.stdout.write(f'    booking_id = {bid}')
        self.stdout.write('')
        self.stdout.write('  Next:')
        self.stdout.write(f'    python manage.py drive_booking {booking_ids[0]} confirm')
        self.stdout.write(f'    python scripts/fake_tech_gps.py --booking-id {booking_ids[0]} --token {tech_token.key}')
        self.stdout.write(s(bar))


def _tiny_jpeg() -> bytes:
    """1x1 placeholder JPEG bytes. Django's ImageField uses PIL.verify() on
    upload, so a real (if minimal) JPEG is required — a hand-crafted byte
    blob would be rejected."""
    img = Image.new('RGB', (1, 1), color='white')
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    return buf.getvalue()

import os
import django
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from django.contrib.auth.models import User
from accounts.models import UserProfile
from technicians.models import TechnicianProfile
from customers.models import CustomerProfile, CustomerAddress
from bookings.models import JobBooking
from catalog.models import Service

def populate():
    # Normalised Pakistani format
    phone_number = '+923001234567'
    
    # 1. Get/Create Technician
    tech_user, _ = User.objects.get_or_create(username=phone_number, defaults={'first_name': 'Test', 'last_name': 'Technician', 'email': 'tech@example.com'})
    tech_user.save()

    user_profile, _ = UserProfile.objects.get_or_create(user=tech_user, defaults={'phone': phone_number, 'is_technician': True})
    user_profile.is_technician = True
    user_profile.save()
    
    tech_profile, _ = TechnicianProfile.objects.get_or_create(user=tech_user)
    tech_profile.current_wallet_balance = Decimal('1850.00')
    tech_profile.is_online = True
    tech_profile.status = 'APPROVED'
    tech_profile.is_onboarding_complete = True
    tech_profile.save()

    # 2. Get/Create Customer
    customer_user, _ = User.objects.get_or_create(username='test_customer', defaults={'first_name': 'Ali', 'last_name': 'R.', 'email': 'customer@example.com'})
    customer_user.save()
    customer_profile, _ = CustomerProfile.objects.get_or_create(user=customer_user)
    
    address, _ = CustomerAddress.objects.get_or_create(
        customer=customer_profile,
        defaults={
            'label': 'Home',
            'street_address': '14 Street, Gulberg III',
            'latitude': Decimal('31.5204'),
            'longitude': Decimal('74.3587')
        }
    )

    # 3. Clear today's bookings for a clean state
    now = timezone.now()
    today = now.date()
    JobBooking.objects.filter(technician=tech_profile, scheduled_start__date=today).delete()

    # Catalog reference required on every JobBooking — pick or create a
    # parent Service. This script bypasses the service layer so the FK
    # must be supplied directly.
    service, _ = Service.objects.get_or_create(
        name='General Maintenance',
        defaults={'is_active': True, 'base_inspection_fee': Decimal('500.00')},
    )

    # 4. Create "Up Next" Job (Confirmed, 45 mins from now)
    JobBooking.objects.create(
        technician=tech_profile,
        customer=customer_user,
        address=address,
        service=service,
        scheduled_start=now + timedelta(minutes=45),
        scheduled_end=now + timedelta(minutes=105),
        status=JobBooking.STATUS_CONFIRMED,
        price_amount=Decimal('3200.00'),
        price_context='Full AC Service'
    )

    # 5. Create "Later Today" Jobs
    later_jobs = [
        ('DB Box Repair', 120, 150, Decimal('1200.00')),
        ('Washing Machine Fix', 180, 240, Decimal('2500.00')),
        ('Microwave Checkup', 300, 330, Decimal('1000.00')),
        ('Solar Panel Cleaning', 400, 480, Decimal('4500.00')),
    ]

    for title, start_m, end_m, price in later_jobs:
        JobBooking.objects.create(
            technician=tech_profile,
            customer=customer_user,
            address=address,
            service=service,
            scheduled_start=now + timedelta(minutes=start_m),
            scheduled_end=now + timedelta(minutes=end_m),
            status=JobBooking.STATUS_CONFIRMED,
            price_amount=price,
            price_context=title
        )

    # 6. Create "Completed Today" Jobs (to show metrics)
    # Even though it's the start of the day in UTC, let's add some "just completed" jobs
    # for the sake of the metrics UI.
    JobBooking.objects.create(
        technician=tech_profile,
        customer=customer_user,
        address=address,
        service=service,
        scheduled_start=now - timedelta(minutes=120),
        scheduled_end=now - timedelta(minutes=60),
        status=JobBooking.STATUS_COMPLETED,
        price_amount=Decimal('1500.00'),
        price_context='Morning Emergency Repair'
    )

    print(f"==================================================")
    print(f"SUCCESS: New Test Data Generated for {today}")
    print(f"Technician: {phone_number}")
    print(f"Jobs: 1 Up Next, 4 Later, 1 Completed")
    print(f"==================================================")

if __name__ == '__main__':
    populate()

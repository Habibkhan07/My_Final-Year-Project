import io
from datetime import timedelta
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from PIL import Image

# Import YOUR exact models
from catalog.models import Service, SubService
from marketing.models import Promotion
from customers.models import CustomerProfile, SavedAddress
from technicians.models import (
    TechnicianProfile, 
    TechnicianSkill, 
    TechnicianServicePerformance,
    TechnicianServiceLicense
)

User = get_user_model()

class Command(BaseCommand):
    help = 'Seeds the database with exact test data based on the strict provided schema.'

    def _generate_dummy_image(self, color, filename):
        """Creates a tiny dummy image in memory to bypass file upload requirements."""
        img = Image.new('RGB', (100, 100), color=color)
        img_io = io.BytesIO()
        img.save(img_io, format='JPEG')
        return ContentFile(img_io.getvalue(), name=filename)

    def handle(self, *args, **kwargs):
        self.stdout.write("🔥 Starting Strict Database Seed...")

        # ==========================================
        # 1. CATALOG DATA
        # ==========================================
        self.stdout.write("-> Creating Services & SubServices...")
        # icon_name keys map to Flutter assets at assets/icons/{icon_name}.svg
        ac_service, _ = Service.objects.get_or_create(
            name="AC Repair",
            defaults={'icon_name': 'ac_repair'}
        )
        plumbing_service, _ = Service.objects.get_or_create(
            name="Plumbing",
            defaults={'icon_name': 'plumbing'}
        )

        freon_gig, _ = SubService.objects.get_or_create(
            service=ac_service,
            name="Freon Gas Top-up",
            defaults={
                'base_price': 2500.00, 'is_fixed_price': True,
                'search_tags': ["gas", "cooling"],
                'icon_name': 'freon_gas',
                'card_image_url': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
            }
        )
        ac_service_gig, _ = SubService.objects.get_or_create(
            service=ac_service,
            name="General AC Servicing",
            defaults={
                'base_price': 1500.00, 'is_fixed_price': True,
                'icon_name': 'ac_repair',
                'card_image_url': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
            }
        )
        leak_gig, _ = SubService.objects.get_or_create(
            service=plumbing_service,
            name="Pipe Leak Repair",
            defaults={
                'base_price': 1000.00, 'is_fixed_price': True,
                'search_tags': ["drip", "water"],
                'icon_name': 'pipe_leak',
                'card_image_url': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400&q=80',
            }
        )

        # ==========================================
        # 2. MARKETING DATA
        # ==========================================
        self.stdout.write("-> Creating Promotions...")
        promo, created = Promotion.objects.get_or_create(
            name="Summer Cool Down",
            defaults={
                'discount_type': Promotion.DiscountType.PERCENTAGE,
                'discount_value': 15.00,
                'target_service': ac_service,
                'valid_from': timezone.now(),
                'valid_until': timezone.now() + timedelta(days=30),
            }
        )
        if created:
            promo.image.save('promo.jpg', self._generate_dummy_image('yellow', 'promo.jpg'))

        # ==========================================
        # 3. CUSTOMER DATA (For testing coordinates)
        # ==========================================
        self.stdout.write("-> Creating Test Customer...")
        cust_user, _ = User.objects.get_or_create(username="test_customer", email="cust@test.com")
        cust_user.set_password("password123")
        cust_user.save()

        customer_profile, _ = CustomerProfile.objects.get_or_create(user=cust_user)
        SavedAddress.objects.get_or_create(
            customer=customer_profile,
            label="Home (Lahore Center)",
            latitude=31.520400,
            longitude=74.358700,
            address_text="Center of Lahore for testing"
        )

        # ==========================================
        # 4. TECHNICIAN DATA (The Edge Cases)
        # ==========================================
        self.stdout.write("-> Creating Technicians & Matchmaking Variables...")
        
        # Test Location (Customer): Lahore (31.5204, 74.3587)
        test_cases = [
            # --- THE DEVELOPER CASES (Math & Logic) ---
            {"name": "TechA_Veteran", "lat": 31.5250, "lng": 74.3600, "v": 150, "R": 4.80, "service": ac_service, "gig": freon_gig, "active": True},
            {"name": "TechB_Rookie", "lat": 31.5300, "lng": 74.3500, "v": 1, "R": 5.00, "service": ac_service, "gig": freon_gig, "active": True},
            {"name": "TechC_Close", "lat": 31.5220, "lng": 74.3580, "v": 50, "R": 4.50, "service": ac_service, "gig": ac_service_gig, "active": True},
            {"name": "TechD_Plumber", "lat": 31.5204, "lng": 74.3587, "v": 200, "R": 4.90, "service": plumbing_service, "gig": leak_gig, "active": True},
            
            # --- THE SQA CASES (Trying to break the system) ---
            {"name": "TechE_ZeroReviews", "lat": 31.5210, "lng": 74.3590, "v": 0, "R": 0.00, "service": ac_service, "gig": freon_gig, "active": True}, # Math Crash Test
            {"name": "TechF_Suspended", "lat": 31.5205, "lng": 74.3588, "v": 500, "R": 5.00, "service": ac_service, "gig": freon_gig, "active": False}, # State Visibility Test
            {"name": "TechG_Ghost", "lat": None, "lng": None, "v": 100, "R": 4.50, "service": ac_service, "gig": freon_gig, "active": True}, # Null Data Crash Test
            {"name": "TechH_Boundary", "lat": 31.6110, "lng": 74.3587, "v": 100, "R": 5.00, "service": ac_service, "gig": freon_gig, "active": True}, # Exactly 10.07 km away (Should fail)
        ]

        for i, data in enumerate(test_cases):
            username = data['name'].lower()
            if User.objects.filter(username=username).exists():
                continue

            user = User.objects.create_user(
                username=username,
                email=f"{username}@test.com",
                password="password123",
                first_name=data['name'].split('_')[0],
                last_name=data['name'].split('_')[1]
            )

            profile = TechnicianProfile.objects.create(
                user=user,
                city='LHR',
                cnic_number=f"35202-222222{i}-1",
                experience_years=5,
                bio=f"Test data for {data['name']}",
                status='APPROVED' if data['active'] else 'PENDING', # SQA State Test
                base_latitude=data['lat'], # Might be None (SQA Null Test)
                base_longitude=data['lng'], 
                is_onboarding_complete=True,
                is_active=data['active'], # SQA Active Test
                review_count=data['v'],
                rating_average=data['R']
            )
            profile.profile_picture.save(f'{username}.jpg', self._generate_dummy_image('green', f'{username}.jpg'))
            profile.cnic_front_image.save(f'{username}_cnic.jpg', self._generate_dummy_image('gray', f'{username}_cnic.jpg'))

            TechnicianSkill.objects.create(technician=profile, sub_service=data['gig'], years_of_experience=5)
            
            license_obj = TechnicianServiceLicense.objects.create(technician=profile, service=data['service'])
            license_obj.license_picture.save(f'{username}_lic.jpg', self._generate_dummy_image('purple', f'{username}_lic.jpg'))

            TechnicianServicePerformance.objects.create(
                technician=profile,
                service=data['service'],
                review_count=data['v'],
                rating_average=data['R']
            )
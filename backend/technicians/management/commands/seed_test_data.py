import io
import datetime
from datetime import timedelta

from django.utils import timezone
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from PIL import Image
from rest_framework.authtoken.models import Token

from catalog.models import Service, SubService
from marketing.models import Promotion
from customers.models import CustomerProfile, SavedAddress
from technicians.models import (
    TechnicianProfile,
    TechnicianSkill,
    TechnicianServicePerformance,
    TechnicianServiceLicense,
    TechnicianSchedule,
    Review,
)

User = get_user_model()


class Command(BaseCommand):
    help = 'Seeds the database with test data for the full booking feature flow.'

    def _generate_dummy_image(self, color, filename):
        """Creates a tiny dummy image in memory to bypass file upload requirements."""
        img = Image.new('RGB', (100, 100), color=color)
        img_io = io.BytesIO()
        img.save(img_io, format='JPEG')
        return ContentFile(img_io.getvalue(), name=filename)

    def handle(self, *args, **kwargs):
        self.stdout.write('🔥 Starting Database Seed...')

        # ==========================================
        # 1. CATALOG DATA
        # ==========================================
        self.stdout.write('-> Creating Services & SubServices...')

        # icon_name keys map to Flutter assets at assets/icons/{icon_name}.svg
        ac_service, _ = Service.objects.get_or_create(
            name='AC Repair',
            defaults={'icon_name': 'ac_repair', 'base_inspection_fee': 500.00, 'default_duration_minutes': 60},
        )
        plumbing_service, _ = Service.objects.get_or_create(
            name='Plumbing',
            defaults={'icon_name': 'plumbing', 'base_inspection_fee': 500.00, 'default_duration_minutes': 60},
        )

        # Fixed-price gigs (Scenario A pricing on profile)
        freon_gig, _ = SubService.objects.get_or_create(
            service=ac_service,
            name='Freon Gas Top-up',
            defaults={
                'base_price': 2500.00,
                'is_fixed_price': True,
                'is_featured': True,
                'estimated_duration_minutes': 60,
                'search_tags': ['gas', 'cooling', 'freon'],
                'icon_name': 'freon_gas',
                'card_image_url': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
            },
        )
        ac_service_gig, _ = SubService.objects.get_or_create(
            service=ac_service,
            name='General AC Servicing',
            defaults={
                'base_price': 1500.00,
                'is_fixed_price': True,
                'is_featured': True,
                'estimated_duration_minutes': 90,
                'icon_name': 'ac_repair',
                'card_image_url': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
            },
        )
        leak_gig, _ = SubService.objects.get_or_create(
            service=plumbing_service,
            name='Pipe Leak Repair',
            defaults={
                'base_price': 1000.00,
                'is_fixed_price': True,
                'is_featured': True,
                'estimated_duration_minutes': 60,
                'search_tags': ['drip', 'water', 'leak'],
                'icon_name': 'pipe_leak',
                'card_image_url': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400&q=80',
            },
        )

        # Labor gig (Scenario B pricing on profile — is_fixed_price=False)
        # Platform sets the figure via ``base_price`` (catalog) after
        # migration 0014 dropped per-tech ``TechnicianSkill.labor_rate``.
        plumbing_labor_gig, _ = SubService.objects.get_or_create(
            service=plumbing_service,
            name='General Plumbing Repair',
            defaults={
                'base_price': 800.00,   # platform minimum — shown when tech has no rate set
                'is_fixed_price': False,
                'estimated_duration_minutes': 90,
                'search_tags': ['plumber', 'fix', 'repair', 'water'],
                'icon_name': 'plumbing',
            },
        )

        # ==========================================
        # 2. MARKETING DATA
        # ==========================================
        self.stdout.write('-> Creating Promotions...')
        promo, created = Promotion.objects.get_or_create(
            name='Summer Cool Down',
            defaults={
                'discount_type': Promotion.DiscountType.PERCENTAGE,
                'discount_value': 15.00,
                'target_service': ac_service,
                'valid_from': timezone.now(),
                'valid_until': timezone.now() + timedelta(days=30),
                'is_active': True,
                'is_featured_on_home': True,
            },
        )
        if created:
            promo.image.save('promo.jpg', self._generate_dummy_image('yellow', 'promo.jpg'))

        # ==========================================
        # 3. CUSTOMER DATA
        # ==========================================
        self.stdout.write('-> Creating Test Customer...')
        cust_user, _ = User.objects.get_or_create(
            username='test_customer',
            defaults={'email': 'cust@test.com', 'first_name': 'Test', 'last_name': 'Customer'},
        )
        cust_user.set_password('password123')
        cust_user.save()

        customer_profile, _ = CustomerProfile.objects.get_or_create(user=cust_user)

        # Primary address used by the Flutter booking flow (hardcoded addressId: 1 on fresh DB)
        home_address, _ = SavedAddress.objects.get_or_create(
            customer=customer_profile,
            label='Home (Lahore Center)',
            defaults={
                'latitude': 31.520400,
                'longitude': 74.358700,
                'address_text': 'Center of Lahore — used for geofence testing',
            },
        )
        # Second address for IDOR test coverage
        work_address, _ = SavedAddress.objects.get_or_create(
            customer=customer_profile,
            label='Office (DHA)',
            defaults={
                'latitude': 31.482300,
                'longitude': 74.401200,
                'address_text': 'DHA Phase 6 Lahore — second address for test variety',
            },
        )

        # DRF auth token for the test customer — required by POST /api/bookings/instant-book/
        token, _ = Token.objects.get_or_create(user=cust_user)

        # ==========================================
        # 4. TECHNICIAN DATA
        # ==========================================
        self.stdout.write('-> Creating Technicians...')

        # Customer test location: Lahore (31.5204, 74.3587)
        test_cases = [
            # --- DEVELOPER CASES (Math & Logic) ---
            # TechA: veteran, many reviews, high Bayesian score. Primary test subject.
            {'name': 'TechA_Veteran',  'lat': 31.5250, 'lng': 74.3600, 'v': 150, 'R': 4.80, 'service': ac_service,       'gig': freon_gig,      'active': True},
            # TechB: rookie with 1 perfect review — proves Bayesian trust constant suppresses them.
            {'name': 'TechB_Rookie',   'lat': 31.5300, 'lng': 74.3500, 'v': 1,   'R': 5.00, 'service': ac_service,       'gig': freon_gig,      'active': True},
            # TechC: closest geographically — tests distance sort.
            {'name': 'TechC_Close',    'lat': 31.5220, 'lng': 74.3580, 'v': 50,  'R': 4.50, 'service': ac_service,       'gig': ac_service_gig, 'active': True},
            # TechD: plumber — different service category; tests category filter.
            {'name': 'TechD_Plumber',  'lat': 31.5204, 'lng': 74.3587, 'v': 200, 'R': 4.90, 'service': plumbing_service, 'gig': leak_gig,       'active': True},

            # --- SQA CASES (Trying to break the system) ---
            {'name': 'TechE_ZeroReviews', 'lat': 31.5210, 'lng': 74.3590, 'v': 0,   'R': 0.00, 'service': ac_service, 'gig': freon_gig,  'active': True},   # Math crash test
            {'name': 'TechF_Suspended',   'lat': 31.5205, 'lng': 74.3588, 'v': 500, 'R': 5.00, 'service': ac_service, 'gig': freon_gig,  'active': False},  # status=PENDING visibility test
            {'name': 'TechG_Ghost',       'lat': None,    'lng': None,    'v': 100, 'R': 4.50, 'service': ac_service, 'gig': freon_gig,  'active': True},   # Null GPS crash test
            {'name': 'TechH_Boundary',    'lat': 31.6110, 'lng': 74.3587, 'v': 100, 'R': 5.00, 'service': ac_service, 'gig': freon_gig,  'active': True},   # ~10.07 km — should fail geofence
        ]

        created_profiles = {}
        for i, data in enumerate(test_cases):
            username = data['name'].lower()
            if User.objects.filter(username=username).exists():
                tech = TechnicianProfile.objects.get(user__username=username)
                created_profiles[data['name']] = tech
                continue

            user = User.objects.create_user(
                username=username,
                email=f'{username}@test.com',
                password='password123',
                first_name=data['name'].split('_')[0],
                last_name=data['name'].split('_')[1],
            )

            profile = TechnicianProfile.objects.create(
                user=user,
                city='LHR',
                cnic_number=f'35202-222222{i}-1',
                status='APPROVED' if data['active'] else 'PENDING',
                base_latitude=data['lat'],
                base_longitude=data['lng'],
                is_onboarding_complete=True,
                is_active=data['active'],
                review_count=data['v'],
                rating_average=data['R'],
            )
            profile.profile_picture.save(f'{username}.jpg', self._generate_dummy_image('green', f'{username}.jpg'))
            profile.cnic_front_image.save(f'{username}_cnic.jpg', self._generate_dummy_image('gray', f'{username}_cnic.jpg'))

            TechnicianSkill.objects.create(
                technician=profile,
                sub_service=data['gig'],
            )

            license_obj = TechnicianServiceLicense.objects.create(technician=profile, service=data['service'])
            license_obj.license_picture.save(f'{username}_lic.jpg', self._generate_dummy_image('purple', f'{username}_lic.jpg'))

            TechnicianServicePerformance.objects.create(
                technician=profile,
                service=data['service'],
                review_count=data['v'],
                rating_average=data['R'],
            )

            created_profiles[data['name']] = profile

        # ==========================================
        # 5. SCHEDULES (NEW)
        # Availability endpoint returns [] without this — booking feature untestable.
        # Mon–Sat (0–5) 9am–5pm. Sunday off.
        # ==========================================
        self.stdout.write('-> Creating Technician Schedules (Mon–Sat 9am–5pm)...')
        work_start = datetime.time(9, 0)
        work_end   = datetime.time(17, 0)
        working_days = [0, 1, 2, 3, 4, 5]  # Monday=0 … Saturday=5

        active_tech_names = [
            'TechA_Veteran', 'TechB_Rookie', 'TechC_Close',
            'TechD_Plumber', 'TechE_ZeroReviews', 'TechH_Boundary',
        ]
        for tech_name in active_tech_names:
            profile = created_profiles.get(tech_name)
            if not profile:
                continue
            for day in range(7):
                TechnicianSchedule.objects.get_or_create(
                    technician=profile,
                    day_of_week=day,
                    defaults={
                        'start_time': work_start,
                        'end_time': work_end,
                        'is_working': day in working_days,
                    },
                )

        # ==========================================
        # 6. LABOR SKILL FOR TechD_Plumber (NEW)
        # Adds a non-fixed-price skill so Scenario B pricing can be tested on
        # the profile screen (navigate via ?sub_service_id=<plumbing_labor_gig.id>).
        # ==========================================
        self.stdout.write('-> Adding labor skill to TechD_Plumber...')
        tech_d = created_profiles.get('TechD_Plumber')
        if tech_d:
            # Bridge row is pure membership after migration 0014.
            # The labor-gig figure now comes from the catalog row's
            # ``base_price``/``max_price`` band.
            TechnicianSkill.objects.get_or_create(
                technician=tech_d,
                sub_service=plumbing_labor_gig,
            )

        # ==========================================
        # 7. REVIEWS FOR TechA_Veteran (NEW)
        # Profile screen shows the top 2 most-recent reviews.
        # ==========================================
        self.stdout.write('-> Adding reviews for TechA_Veteran...')
        tech_a = created_profiles.get('TechA_Veteran')
        if tech_a and not tech_a.reviews.exists():
            Review.objects.create(
                technician=tech_a,
                reviewer=cust_user,
                rating=5,
                text='Excellent work! Fixed our AC in under an hour. Very professional and clean.',
            )
            Review.objects.create(
                technician=tech_a,
                reviewer=cust_user,
                rating=4,
                text='Good service, arrived on time. The Freon top-up resolved our cooling issue.',
            )

        # ==========================================
        # 8. PRINT SUMMARY
        # ==========================================
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('  SEED COMPLETE — TEST CREDENTIALS'))
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(f'  Customer username : test_customer')
        self.stdout.write(f'  Customer password : password123')
        self.stdout.write(f'  Auth Token        : {token.key}')
        self.stdout.write('')
        self.stdout.write(f'  Home address ID   : {home_address.id}  ← use this in select_time_sheet.dart (addressId)')
        self.stdout.write(f'  Work address ID   : {work_address.id}')
        self.stdout.write('')
        self.stdout.write('  Key technician IDs (for manual URL testing):')
        for name, prof in created_profiles.items():
            self.stdout.write(f'    {name:25s} → id={prof.id}')
        self.stdout.write('')
        self.stdout.write('  Pricing scenario URLs (append to /api/customers/technician-profile/<id>/):')
        self.stdout.write(f'    Scenario A (Fixed Gig)  : ?sub_service_id={freon_gig.id}')
        self.stdout.write(f'    Scenario B (Labor Gig)  : ?sub_service_id={plumbing_labor_gig.id}  (use TechD_Plumber id)')
        self.stdout.write(f'    Scenario C (Category)   : ?service_id={ac_service.id}')
        self.stdout.write(f'    With Promo              : ?service_id={ac_service.id}&promotion_id={promo.id}')
        self.stdout.write(self.style.SUCCESS('=' * 60))

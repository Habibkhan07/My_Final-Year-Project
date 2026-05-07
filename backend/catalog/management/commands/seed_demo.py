"""
Idempotent demo-data seeder for thesis screenshots.

Populates 8 service categories, 10 fixed-price gigs, and 10 Pakistani
technicians (with locally-generated initials avatars on brand colors)
so the customer home, search results, and technician profile screens
look populated and credible in screenshots.

Run:  python manage.py seed_demo
"""
import io
import json
import socket
import datetime
import urllib.request
from datetime import timedelta
from decimal import Decimal

from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from django.contrib.auth.models import User
from django.db import transaction
from django.utils import timezone
from PIL import Image, ImageDraw, ImageFont
from rest_framework.authtoken.models import Token

from catalog.models import Service, SubService
from accounts.models import UserProfile
from bookings.models import JobBooking
from customers.models import CustomerProfile, CustomerAddress
from technicians.models import (
    TechnicianProfile,
    TechnicianSkill,
    TechnicianServicePerformance,
    TechnicianServiceLicense,
    TechnicianSchedule,
    Review,
)


SERVICES = [
    {'name': 'AC Repair',     'icon': 'ac_repair',    'order': 1},
    {'name': 'Electrician',   'icon': 'electrician',  'order': 2},
    {'name': 'Plumbing',      'icon': 'plumbing',     'order': 3},
    {'name': 'Carpenter',     'icon': 'carpenter',    'order': 4},
    {'name': 'Painter',       'icon': 'painter',      'order': 5},
    {'name': 'Home Cleaning', 'icon': 'cleaning',     'order': 6},
    {'name': 'Geyser Repair', 'icon': 'geyser',       'order': 7},
    {'name': 'Pest Control',  'icon': 'pest_control', 'order': 8},
]


GIGS = [
    {
        'service': 'AC Repair', 'name': 'AC General Service (1.5-Ton Split)',
        'price': 1500, 'duration': 90, 'icon': 'ac_repair',
        'card': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
        'tags': ['ac', 'service', 'split', 'cooling'],
    },
    {
        'service': 'AC Repair', 'name': 'AC Gas Refill',
        'price': 4000, 'duration': 60, 'icon': 'freon_gas',
        'card': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=800&q=80',
        'tags': ['ac', 'gas', 'freon', 'refill'],
    },
    {
        'service': 'Electrician', 'name': 'Ceiling Fan Installation',
        'price': 1200, 'duration': 60, 'icon': 'electrician',
        'card': 'https://images.unsplash.com/photo-1606165230253-32de9f31c6c3?w=800&q=80',
        'tags': ['fan', 'ceiling', 'install', 'pankha'],
    },
    {
        'service': 'Electrician', 'name': 'Switch & Socket Replacement',
        'price': 800, 'duration': 45, 'icon': 'electrician',
        'card': 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&q=80',
        'tags': ['switch', 'socket', 'wiring', 'electric'],
    },
    {
        'service': 'Plumbing', 'name': 'Sink & Drain Unblocking',
        'price': 1500, 'duration': 60, 'icon': 'pipe_leak',
        'card': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=800&q=80',
        'tags': ['sink', 'drain', 'block', 'leak'],
    },
    {
        'service': 'Carpenter', 'name': 'Door & Lock Installation',
        'price': 2000, 'duration': 90, 'icon': 'carpenter',
        'card': 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&q=80',
        'tags': ['door', 'lock', 'wood', 'carpenter'],
    },
    {
        'service': 'Painter', 'name': 'Single Room Wall Painting',
        'price': 6500, 'duration': 240, 'icon': 'painter',
        'card': 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=800&q=80',
        'tags': ['paint', 'wall', 'room', 'rang'],
    },
    {
        'service': 'Home Cleaning', 'name': '3-Bedroom Deep Cleaning',
        'price': 8000, 'duration': 240, 'icon': 'cleaning',
        'card': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80',
        'tags': ['cleaning', 'deep', 'home', 'safai'],
    },
    {
        'service': 'Geyser Repair', 'name': 'Geyser Coil Replacement',
        'price': 2500, 'duration': 90, 'icon': 'geyser',
        'card': 'https://images.unsplash.com/photo-1582711012124-a56cf82d2dec?w=800&q=80',
        'tags': ['geyser', 'water', 'heater', 'coil'],
    },
    {
        'service': 'Pest Control', 'name': 'Cockroach & Insect Treatment',
        'price': 3500, 'duration': 120, 'icon': 'pest_control',
        'card': 'https://images.unsplash.com/photo-1632935190380-c19f1cd1cdba?w=800&q=80',
        'tags': ['pest', 'cockroach', 'insect', 'spray'],
    },
]


# Approx city centers — small offsets per tech for variety on map.
CITY_COORDS = {
    'LHR': (31.5204, 74.3587),
    'KHI': (24.8607, 67.0011),
    'ISL': (33.6844, 73.0479),
}


TECHS = [
    {'first': 'Muhammad Bilal',    'last': 'Ahmed',    'phone': '+923001112201',
     'city': 'LHR', 'jitter': (+0.0120, -0.0080),
     'gig': 'AC General Service (1.5-Ton Split)', 'rating': 4.8, 'reviews': 47, 'exp': 8,
     'color': '#2563eb', 'bio': 'Certified split-AC technician with 8 years of service across Lahore. Specialises in fast on-site diagnostics and gas leak repairs.'},
    {'first': 'Ali Raza',          'last': 'Khan',     'phone': '+923001112202',
     'city': 'KHI', 'jitter': (+0.0050, +0.0070),
     'gig': 'Ceiling Fan Installation', 'rating': 4.6, 'reviews': 32, 'exp': 6,
     'color': '#16a34a', 'bio': 'Licensed electrician based in Karachi. Trained on industrial wiring; available for residential installations and emergency callouts.'},
    {'first': 'Hamza',             'last': 'Tariq',    'phone': '+923001112203',
     'city': 'ISL', 'jitter': (-0.0100, +0.0040),
     'gig': 'Sink & Drain Unblocking', 'rating': 4.7, 'reviews': 28, 'exp': 5,
     'color': '#dc2626', 'bio': 'Plumber specialising in modern fittings, drainage systems and water-tank cleaning across Islamabad and Rawalpindi.'},
    {'first': 'Usman',             'last': 'Shahbaz',  'phone': '+923001112204',
     'city': 'LHR', 'jitter': (-0.0060, +0.0090),
     'gig': 'Door & Lock Installation', 'rating': 4.5, 'reviews': 19, 'exp': 7,
     'color': '#ea580c', 'bio': 'Experienced carpenter handling door installations, custom shelving and furniture repair across Lahore.'},
    {'first': 'Imran',             'last': 'Hussain',  'phone': '+923001112205',
     'city': 'ISL', 'jitter': (+0.0080, -0.0030),
     'gig': 'Single Room Wall Painting', 'rating': 4.4, 'reviews': 15, 'exp': 4,
     'color': '#9333ea', 'bio': 'Wall painter offering matte, distemper and weather-shield finishes. Clean drop-cloth setup and same-day touch-ups.'},
    {'first': 'Asad Mehmood',      'last': 'Qureshi',  'phone': '+923001112206',
     'city': 'KHI', 'jitter': (-0.0040, -0.0090),
     'gig': '3-Bedroom Deep Cleaning', 'rating': 4.9, 'reviews': 61, 'exp': 9,
     'color': '#0891b2', 'bio': 'Runs a small home-cleaning crew in Karachi. Deep-cleaning, post-renovation cleanup, and kitchen degreasing specialist.'},
    {'first': 'Faisal',            'last': 'Iqbal',    'phone': '+923001112207',
     'city': 'LHR', 'jitter': (+0.0110, +0.0030),
     'gig': 'Geyser Coil Replacement', 'rating': 4.6, 'reviews': 22, 'exp': 5,
     'color': '#db2777', 'bio': 'Geyser and water-heater technician. Handles instant geysers, storage geysers, and solar-electric hybrid units.'},
    {'first': 'Adnan',             'last': 'Mansoor',  'phone': '+923001112208',
     'city': 'ISL', 'jitter': (+0.0030, -0.0070),
     'gig': 'Cockroach & Insect Treatment', 'rating': 4.5, 'reviews': 17, 'exp': 6,
     'color': '#ca8a04', 'bio': 'Certified pest-control operator. Targeted treatments for cockroaches, termites and bed-bugs using government-approved chemicals.'},
    {'first': 'Khalid',            'last': 'Mahmood',  'phone': '+923001112209',
     'city': 'LHR', 'jitter': (-0.0090, -0.0050),
     'gig': 'AC Gas Refill', 'rating': 4.7, 'reviews': 38, 'exp': 7,
     'color': '#4f46e5', 'bio': 'Independent AC technician serving Lahore for 7 years. Fully equipped van with gauges, vacuum pumps and recovery cylinders.'},
    {'first': 'Tariq Aziz',        'last': 'Sheikh',   'phone': '+923001112210',
     'city': 'KHI', 'jitter': (+0.0070, +0.0050),
     'gig': 'Switch & Socket Replacement', 'rating': 4.8, 'reviews': 44, 'exp': 10,
     'color': '#059669', 'bio': 'Senior electrician with a decade of experience. Wiring, switchgear, and DB-board upgrades for homes and offices.'},
]


REVIEW_TEMPLATES = [
    (5, 'Excellent work! Arrived on time and finished within the hour. Very professional.'),
    (5, 'Highly recommended. Clean work, fair pricing, and great communication throughout.'),
    (4, 'Good service overall. Technician was knowledgeable and resolved the issue quickly.'),
    (5, 'Top quality job. The whole team was respectful of our home and very thorough.'),
    (4, 'Reliable and skilled. Will definitely book again for our next maintenance round.'),
]


def _hex_to_rgb(hex_color):
    h = hex_color.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def _generate_avatar(initials, hex_color):
    """256x256 PNG with white initials centered on a solid brand-color square."""
    size = 256
    img = Image.new('RGB', (size, size), color=_hex_to_rgb(hex_color))
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 110)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), initials, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    x = (size - text_w) // 2 - bbox[0]
    y = (size - text_h) // 2 - bbox[1]
    draw.text((x, y), initials, fill='white', font=font)
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    return ContentFile(buf.getvalue(), name='avatar.png')


def _generate_dummy_image(color, name):
    img = Image.new('RGB', (200, 200), color=color)
    buf = io.BytesIO()
    img.save(buf, format='JPEG')
    return ContentFile(buf.getvalue(), name=name)


def _fetch_indian_male_portraits(count, log):
    """Returns list of `count` JPEG-bytes photos, or None if any step fails."""
    try:
        socket.setdefaulttimeout(10)
        url = f'https://randomuser.me/api/?nat=in&gender=male&results={count}&inc=picture'
        req = urllib.request.Request(url, headers={'User-Agent': 'fyp-demo-seed/1.0'})
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode('utf-8'))
        results = data.get('results') or []
        if len(results) < count:
            log(f'  randomuser.me returned only {len(results)}/{count} portraits')
            return None
        photos = []
        for r in results:
            photo_url = r['picture']['large']
            preq = urllib.request.Request(photo_url, headers={'User-Agent': 'fyp-demo-seed/1.0'})
            with urllib.request.urlopen(preq) as p:
                photos.append(p.read())
        return photos
    except Exception as exc:
        log(f'  randomuser.me fetch failed: {exc}')
        return None


def _initials(first, last):
    return f"{first[0].upper()}{last[0].upper()}"


# Pre-phone-username versions of the seeded users — created by an earlier
# version of this seed where username was ad-hoc rather than the phone.
# Auth uses `User.objects.get_or_create(username=phone)`, so these old rows
# steal the phone via UserProfile.phone unique constraint and break OTP login
# with a 409. We delete them here to make the seed self-healing.
LEGACY_DEMO_USERNAMES = [
    'demo_customer',
    'bilal_ahmed', 'raza_khan', 'hamza_tariq', 'usman_shahbaz',
    'imran_hussain', 'mehmood_qureshi', 'faisal_iqbal', 'adnan_mansoor',
    'khalid_mahmood', 'aziz_sheikh',
]


class Command(BaseCommand):
    help = 'Seeds Pakistani-context demo data (categories, gigs, technicians) for thesis screenshots.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--refresh-photos', action='store_true',
            help='Fetch fresh portrait photos from randomuser.me (overwrites existing avatars).',
        )

    @transaction.atomic
    def handle(self, *args, **opts):
        self.stdout.write(self.style.MIGRATE_HEADING('Seeding demo data for thesis screenshots...'))

        # Self-heal: drop legacy username rows so the phone-as-username
        # convention can claim the phone numbers without IntegrityError.
        legacy_qs = User.objects.filter(username__in=LEGACY_DEMO_USERNAMES)
        legacy_count = legacy_qs.count()
        if legacy_count:
            self.stdout.write(f'-> Removing {legacy_count} legacy non-phone-username row(s)')
            legacy_qs.delete()

        refresh_photos = opts.get('refresh_photos', False)
        portrait_photos = None
        if refresh_photos:
            self.stdout.write('-> Fetching real portraits from randomuser.me (nat=in, gender=male)...')
            portrait_photos = _fetch_indian_male_portraits(len(TECHS), self.stdout.write)
            if portrait_photos is None:
                self.stdout.write(self.style.WARNING('  Falling back to initials avatars for missing photos.'))

        # 1. SERVICES
        self.stdout.write('-> Services (8)')
        service_objs = {}
        for s in SERVICES:
            obj, _ = Service.objects.update_or_create(
                name=s['name'],
                defaults={
                    'icon_name': s['icon'],
                    'display_order': s['order'],
                    'is_active': True,
                    'base_inspection_fee': Decimal('500.00'),
                    'default_duration_minutes': 60,
                },
            )
            service_objs[s['name']] = obj

        # 2. GIGS (fixed-price, featured on home)
        self.stdout.write('-> Fixed-price gigs (10)')
        gig_objs = {}
        for g in GIGS:
            obj, _ = SubService.objects.update_or_create(
                service=service_objs[g['service']],
                name=g['name'],
                defaults={
                    'base_price': Decimal(str(g['price'])),
                    'is_fixed_price': True,
                    'is_featured': True,
                    'estimated_duration_minutes': g['duration'],
                    'icon_name': g['icon'],
                    'card_image_url': g['card'],
                    'search_tags': g['tags'],
                },
            )
            gig_objs[g['name']] = obj

        # 3. DEMO CUSTOMER — username MUST equal phone (auth uses get_or_create(username=phone))
        cust_phone = '+923009999999'
        self.stdout.write(f'-> Demo customer (phone {cust_phone}, OTP 123456)')
        cust_user, _ = User.objects.update_or_create(
            username=cust_phone,
            defaults={'email': 'demo@fypdemo.pk', 'first_name': 'Ahmed', 'last_name': 'Raza'},
        )
        cust_user.set_password('demo123')
        cust_user.save()
        UserProfile.objects.update_or_create(
            user=cust_user,
            defaults={'phone': cust_phone, 'is_technician': False},
        )
        cust_profile, _ = CustomerProfile.objects.get_or_create(user=cust_user)
        CustomerAddress.objects.update_or_create(
            customer=cust_profile, label='Home',
            defaults={
                'street_address': 'House 12, Street 4, Gulberg III, Lahore',
                'latitude': Decimal('31.520400'), 'longitude': Decimal('74.358700'),
                'is_default': True, 'city': 'Lahore', 'country': 'PK',
            },
        )
        CustomerAddress.objects.update_or_create(
            customer=cust_profile, label='Office',
            defaults={
                'street_address': 'Suite 5, Arfa Software Tech Park, Ferozepur Road, Lahore',
                'latitude': Decimal('31.482300'), 'longitude': Decimal('74.401200'),
                'is_default': False, 'city': 'Lahore', 'country': 'PK',
            },
        )
        token, _ = Token.objects.get_or_create(user=cust_user)

        # 4. TECHNICIANS
        self.stdout.write('-> Technicians (10) with avatars + skills + schedules + reviews')
        cnic_seq = 0
        tech_by_slug = {}  # populated below; used by bookings section
        for idx, t in enumerate(TECHS):
            cnic_seq += 1
            # Auth uses phone-as-username, so the seeded user must match.
            # We keep a separate `slug` only for filenames (avatars, CNICs).
            username = t['phone']
            slug = f"{t['first'].split()[-1].lower()}_{t['last'].lower()}"
            user, created = User.objects.update_or_create(
                username=username,
                defaults={
                    'email': f'{slug}@fypdemo.pk',
                    'first_name': t['first'],
                    'last_name': t['last'],
                },
            )
            if created or not user.has_usable_password():
                user.set_password('demo123')
                user.save()

            UserProfile.objects.update_or_create(
                user=user,
                defaults={'phone': t['phone'], 'is_technician': True},
            )

            base_lat, base_lng = CITY_COORDS[t['city']]
            lat = base_lat + t['jitter'][0]
            lng = base_lng + t['jitter'][1]

            profile, _ = TechnicianProfile.objects.update_or_create(
                user=user,
                defaults={
                    'city': t['city'],
                    'cnic_number': f'35202-{cnic_seq:07d}-1',
                    'experience_years': t['exp'],
                    'bio': t['bio'],
                    'status': 'APPROVED',
                    'base_latitude': lat,
                    'base_longitude': lng,
                    'is_onboarding_complete': True,
                    'is_active': True,
                    'rating_average': Decimal(str(t['rating'])),
                    'review_count': t['reviews'],
                },
            )
            tech_by_slug[slug] = profile

            # Avatar:
            #   --refresh-photos → real portrait if randomuser.me succeeded, else initials
            #   default          → keep existing, only fill if missing
            if refresh_photos or not profile.profile_picture:
                if portrait_photos and idx < len(portrait_photos):
                    profile.profile_picture.save(
                        f'{slug}.jpg',
                        ContentFile(portrait_photos[idx], name=f'{slug}.jpg'),
                    )
                else:
                    profile.profile_picture.save(
                        f'{slug}.png',
                        _generate_avatar(_initials(t['first'], t['last']), t['color']),
                    )
            if not profile.cnic_front_image:
                profile.cnic_front_image.save(
                    f'{slug}_cnic.jpg',
                    _generate_dummy_image('gray', f'{slug}_cnic.jpg'),
                )

            # Skill linking tech to their gig
            gig = gig_objs[t['gig']]
            TechnicianSkill.objects.update_or_create(
                technician=profile, sub_service=gig,
                defaults={'years_of_experience': t['exp']},
            )

            # Service license
            parent_service = gig.service
            license_obj, lic_created = TechnicianServiceLicense.objects.get_or_create(
                technician=profile, service=parent_service,
            )
            if lic_created or not license_obj.license_picture:
                license_obj.license_picture.save(
                    f'{slug}_lic.jpg',
                    _generate_dummy_image('purple', f'{slug}_lic.jpg'),
                )

            # Bayesian performance row
            TechnicianServicePerformance.objects.update_or_create(
                technician=profile, service=parent_service,
                defaults={'review_count': t['reviews'], 'rating_average': float(t['rating'])},
            )

            # Schedule: Mon–Sat 9–5
            for day in range(7):
                TechnicianSchedule.objects.update_or_create(
                    technician=profile, day_of_week=day,
                    defaults={
                        'start_time': datetime.time(9, 0),
                        'end_time': datetime.time(17, 0),
                        'is_working': day < 6,
                    },
                )

            # 2 reviews per tech (use first 2 templates rotated by index)
            if not profile.reviews.exists():
                for offset in range(2):
                    rating, text = REVIEW_TEMPLATES[(cnic_seq + offset) % len(REVIEW_TEMPLATES)]
                    Review.objects.create(
                        technician=profile, reviewer=cust_user,
                        rating=rating, text=text,
                    )

        # 5. BOOKINGS — populate demo_customer's My Bookings list (past + upcoming)
        # AND Bilal Ahmed's tech dashboard (today's completed + upcoming).
        # Idempotent: wipes demo_customer's existing bookings then recreates fresh
        # date-anchored ones, so reruns don't accumulate stale rows.
        self.stdout.write('-> Demo bookings (10) — past + today + upcoming')

        JobBooking.objects.filter(customer=cust_user).delete()

        # Bilal: online + topped-up wallet so the dashboard header looks alive.
        bilal = tech_by_slug['bilal_ahmed']
        bilal.is_online = True
        bilal.current_wallet_balance = Decimal('4250.00')
        bilal.save(update_fields=['is_online', 'current_wallet_balance'])

        now = timezone.now()
        today_9am = now.replace(hour=9, minute=0, second=0, microsecond=0)
        today_1130 = now.replace(hour=11, minute=30, second=0, microsecond=0)
        # Upcoming bookings — clamp inside today so the dashboard shows them.
        end_of_day = now.replace(hour=23, minute=30, second=0, microsecond=0)
        upnext_time = min(now + timedelta(minutes=90), end_of_day - timedelta(hours=1))
        later_time = min(now + timedelta(hours=3), end_of_day)

        BOOKINGS = [
            # tech_username, service, gig, addr, start, dur_min, price, status, context
            ('aziz_sheikh',     'Electrician',    'Switch & Socket Replacement',         'Home',
                now - timedelta(days=14, hours=4), 45, 800, 'COMPLETED', 'Switch & Socket — 45 min'),
            ('mehmood_qureshi', 'Home Cleaning',  '3-Bedroom Deep Cleaning',             'Home',
                now - timedelta(days=7, hours=4),  240, 8000, 'COMPLETED', 'Deep Cleaning — 4 hrs'),
            ('faisal_iqbal',    'Geyser Repair',  'Geyser Coil Replacement',             'Home',
                now - timedelta(days=3, hours=2),  90, 2500, 'COMPLETED', 'Geyser Repair — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair',      'AC General Service (1.5-Ton Split)',  'Home',
                today_9am, 90, 1500, 'COMPLETED', 'AC General — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair',      'AC Gas Refill',                       'Office',
                today_1130, 60, 4000, 'COMPLETED', 'AC Gas Refill — 1 hr'),
            ('bilal_ahmed',     'AC Repair',      'AC General Service (1.5-Ton Split)',  'Home',
                upnext_time, 90, 1500, 'CONFIRMED', 'AC General — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair',      'AC Gas Refill',                       'Home',
                later_time, 60, 4000, 'CONFIRMED', 'AC Gas Refill — 1 hr'),
            ('hamza_tariq',     'Plumbing',       'Sink & Drain Unblocking',             'Home',
                (now + timedelta(days=1)).replace(hour=10, minute=0, second=0, microsecond=0),
                60, 1500, 'CONFIRMED', 'Sink Unblocking — 1 hr'),
            ('imran_hussain',   'Painter',        'Single Room Wall Painting',           'Home',
                (now + timedelta(days=3)).replace(hour=13, minute=0, second=0, microsecond=0),
                240, 6500, 'CONFIRMED', 'Wall Painting — 4 hrs'),
            ('adnan_mansoor',   'Pest Control',   'Cockroach & Insect Treatment',        'Home',
                (now + timedelta(days=5)).replace(hour=11, minute=0, second=0, microsecond=0),
                120, 3500, 'AWAITING',  'Pest Treatment — 2 hrs'),
        ]

        addr_map = {
            'Home':   CustomerAddress.objects.get(customer=cust_profile, label='Home'),
            'Office': CustomerAddress.objects.get(customer=cust_profile, label='Office'),
        }

        for tech_slug, svc_name, gig_name, addr_label, start, dur, price, status, ctx in BOOKINGS:
            tech = tech_by_slug[tech_slug]
            JobBooking.objects.create(
                technician=tech,
                customer=cust_user,
                address=addr_map[addr_label],
                service=service_objs[svc_name],
                sub_service=gig_objs[gig_name],
                scheduled_start=start,
                scheduled_end=start + timedelta(minutes=dur),
                status=status,
                price_amount=Decimal(str(price)),
                price_context=ctx,
            )

        # 6. SUMMARY
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('  DEMO SEED COMPLETE'))
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(f'  Categories     : {len(SERVICES)}')
        self.stdout.write(f'  Featured gigs  : {len(GIGS)}')
        self.stdout.write(f'  Technicians    : {len(TECHS)}  (all APPROVED, all visible)')
        self.stdout.write(f'  Bookings       : {len(BOOKINGS)} for demo_customer')
        self.stdout.write(f'  Bilal\'s today  : 2 completed + 1 upNext + 1 laterToday')
        self.stdout.write(f'  Bilal\'s wallet : Rs. 4,250 (online=True for dashboard)')
        self.stdout.write('')
        self.stdout.write('  Customer login (for screenshots):')
        self.stdout.write(f'    username : demo_customer')
        self.stdout.write(f'    password : demo123')
        self.stdout.write(f'    phone    : +923009999999')
        self.stdout.write(f'    token    : {token.key}')
        self.stdout.write('')
        self.stdout.write('  Technicians use phones +923001112201 .. +923001112210')
        self.stdout.write('  All passwords: demo123')
        self.stdout.write(self.style.SUCCESS('=' * 60))

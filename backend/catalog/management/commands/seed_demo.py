"""
Idempotent demo-data seeder for thesis screenshots and viva demo.

Populates 5 service categories, 20 sub-services (mix of fixed-price and
labor-quoted), 1 promotion (PIL-generated brand banner), 10 Pakistani
technicians (with locally-generated initials avatars on brand colors),
1 demo customer with two addresses, and 10 bookings spanning past /
today / upcoming so every dashboard surface has live data.

Run:
  python manage.py flush_catalog      # destructive: wipe existing catalog + dependents
  python manage.py seed_demo          # idempotent re-seed
"""
import io
import json
import socket
import datetime
import urllib.request
from datetime import timedelta
from decimal import Decimal

from django.core.management import call_command
from django.core.management.base import BaseCommand
from django.core.files.base import ContentFile
from django.contrib.auth.models import User
from django.db import transaction
from django.utils import timezone
from PIL import Image, ImageDraw, ImageFont
from rest_framework.authtoken.models import Token

from catalog.models import Service, SubService
from marketing.models import Promotion
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


# 5 service categories. Names match what Pakistani urban customers say —
# avoid "HVAC" or "Sanitary" jargon; "AC" and "Plumbing" are universal.
SERVICES = [
    {'name': 'AC Repair & Service', 'icon': 'ac_repair',    'order': 1, 'duration': 90},
    {'name': 'Electrician',         'icon': 'electrician',  'order': 2, 'duration': 60},
    {'name': 'Plumbing',            'icon': 'plumbing',     'order': 3, 'duration': 60},
    {'name': 'Home Cleaning',       'icon': 'cleaning',     'order': 4, 'duration': 90},
    {'name': 'Pest Control',        'icon': 'pest_control', 'order': 5, 'duration': 90},
]


# Sub-services. `kind` is the only branch:
#   'fixed' → is_fixed_price=True,  base_price=fixed price,        max_price=None
#   'labor' → is_fixed_price=False, base_price=lower of rate band, max_price=upper
#
# Names are deliberately quantity-free. "Per fan", "per room", "(1.5-Ton)"
# qualifiers were dropped — the schema can't encode quantity, and any
# count baked into the name invites the viva panel to ask "what if it's
# two?". Variable-scope work (whole-home cleaning, multi-sofa sets, large
# termite jobs) lives under the LABOR sub-services where the technician
# inspects and quotes.
#
# `card` is only set for fixed-price gigs — only fixed gigs surface as
# hero cards on the home screen, and labor gigs would never use it.
# All `card` URLs are verified Unsplash IDs carried over from the prior
# seed (or reused within a service where a single hero photo covers
# multiple sub-tasks credibly). Guessing new IDs risks 404s mid-demo.
GIGS = [
    # ── AC Repair & Service ───────────────────────────────────────────
    {
        'service': 'AC Repair & Service', 'name': 'AC General Service',
        'kind': 'fixed', 'price': 1500, 'duration': 90,
        'icon': 'ac_repair',
        'card': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
        'tags': ['ac', 'service', 'split', 'cooling', 'cleaning'],
        'desc': 'Standard split-AC service: coil + filter wash, blower clean, '
                'gas pressure check, drain flush. Technician confirms scope on arrival.',
    },
    {
        'service': 'AC Repair & Service', 'name': 'AC Gas Refill',
        'kind': 'fixed', 'price': 4000, 'duration': 60,
        'icon': 'freon_gas',
        'card': 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=800&q=80',
        'tags': ['ac', 'gas', 'freon', 'refill', 'r-22', 'r-410'],
        'desc': 'Full re-gas with leak and pressure check. Supports R-22, R-410A '
                'and R-32 (inverter). Refrigerant cost included.',
    },
    {
        'service': 'AC Repair & Service', 'name': 'AC Installation',
        'kind': 'fixed', 'price': 3500, 'duration': 120,
        'icon': 'ac_repair',
        'card': 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=800&q=80',
        'tags': ['ac', 'install', 'fitting', 'mount'],
        'desc': 'Indoor and outdoor unit fitting, copper piping (up to 10 ft included), '
                'bracket mount and pressure test. Window AC quoted separately.',
    },
    {
        'service': 'AC Repair & Service', 'name': 'AC Repair (Cooling / Leak / PCB)',
        'kind': 'labor', 'min_price': 800, 'max_price': 2500, 'duration': 60,
        'icon': 'ac_repair',
        'tags': ['ac', 'repair', 'fault', 'pcb', 'capacitor', 'awaz'],
        'desc': 'Not cooling, water leakage, awaz (noise), PCB or capacitor faults. '
                'Technician diagnoses on-site and quotes labor + parts.',
    },

    # ── Electrician ───────────────────────────────────────────────────
    {
        'service': 'Electrician', 'name': 'Ceiling Fan Installation',
        'kind': 'fixed', 'price': 1200, 'duration': 60,
        'icon': 'fan',
        'card': 'https://images.unsplash.com/photo-1606165230253-32de9f31c6c3?w=800&q=80',
        'tags': ['fan', 'ceiling', 'install', 'pankha'],
        'desc': 'Bracket mount, wiring, capacitor check on an existing ceiling '
                'hook. New hook + slab drilling quoted as add-on.',
    },
    {
        'service': 'Electrician', 'name': 'Switch & Socket Replacement',
        'kind': 'fixed', 'price': 600, 'duration': 30,
        'icon': 'electrician',
        'card': 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=800&q=80',
        'tags': ['switch', 'socket', 'wiring', 'electric'],
        'desc': 'Single switch or socket changeover. Standard fitting + tools '
                'included. Customer supplies branded fixture if preferred.',
    },
    {
        'service': 'Electrician', 'name': 'Wiring Inspection & Fault Finding',
        'kind': 'labor', 'min_price': 1000, 'max_price': 3500, 'duration': 90,
        'icon': 'electrician',
        'tags': ['wiring', 'fault', 'short', 'breaker', 'mcb', 'trip'],
        'desc': 'Short circuit, breaker tripping, ground fault diagnosis. '
                'Includes meter testing and visible-run inspection.',
    },
    {
        'service': 'Electrician', 'name': 'Light Fitting (LED Panel / Chandelier)',
        'kind': 'labor', 'min_price': 700, 'max_price': 2500, 'duration': 60,
        'icon': 'electrician',
        'tags': ['light', 'led', 'panel', 'chandelier', 'fitting'],
        'desc': 'False-ceiling cutouts, hanging fixtures, dimmer wiring. '
                'Heavy chandeliers may require slab anchor — quoted on-site.',
    },

    # ── Plumbing ──────────────────────────────────────────────────────
    {
        'service': 'Plumbing', 'name': 'Sink & Drain Unblocking',
        'kind': 'fixed', 'price': 1500, 'duration': 60,
        'icon': 'pipe_leak',
        'card': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=800&q=80',
        'tags': ['sink', 'drain', 'block', 'choke', 'kitchen', 'basin'],
        'desc': 'Hand-snake plus chemical clear for a choked kitchen sink or '
                'wash-basin drain. Heavy blockages may require labor variant.',
    },
    {
        'service': 'Plumbing', 'name': 'Commode / Flush Tank Repair',
        'kind': 'fixed', 'price': 1800, 'duration': 75,
        'icon': 'toilet',
        'card': 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=800&q=80',
        'tags': ['commode', 'flush', 'tank', 'toilet', 'wc'],
        'desc': 'Flush rebuild, washer and valve change, leak fix. Compatible '
                'with Master, Sonex, Porta and common Pakistani brands.',
    },
    {
        'service': 'Plumbing', 'name': 'Leak Detection & Pipe Repair',
        'kind': 'labor', 'min_price': 800, 'max_price': 3000, 'duration': 60,
        'icon': 'pipe_leak',
        'tags': ['leak', 'seepage', 'pipe', 'repair', 'pprc', 'gi'],
        'desc': 'Wall and floor seepage, joint leaks, hidden pipe damage. '
                'PPRC, GI and PVC fittings handled. Wall-chase work quoted on-site.',
    },
    {
        'service': 'Plumbing', 'name': 'Water Motor / Pressure Pump Installation',
        'kind': 'labor', 'min_price': 1200, 'max_price': 4000, 'duration': 90,
        'icon': 'water_pump',
        'tags': ['motor', 'pump', 'tullu', 'donkey', 'booster', 'pressure'],
        'desc': 'Tullu, donkey or booster pump fitting with pressure tuning. '
                'New piping or tank shifting quoted separately.',
    },

    # ── Home Cleaning ─────────────────────────────────────────────────
    {
        'service': 'Home Cleaning', 'name': 'Kitchen Deep Clean',
        'kind': 'fixed', 'price': 3500, 'duration': 150,
        'icon': 'kitchen',
        'card': 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=800&q=80',
        'tags': ['kitchen', 'deep', 'clean', 'chimney', 'degrease', 'chiknai'],
        'desc': 'Chimney, hob, tiles and cabinet interiors. Steam degrease '
                'for chiknai (built-up oil). Single residential kitchen.',
    },
    {
        'service': 'Home Cleaning', 'name': 'Home Deep Cleaning',
        'kind': 'labor', 'min_price': 5000, 'max_price': 12000, 'duration': 240,
        'icon': 'cleaning',
        'tags': ['home', 'deep', 'cleaning', 'safai', 'dusting', 'mopping'],
        'desc': 'Full residential deep clean — bedrooms, lounge, baths, kitchen. '
                'Technician walks through and quotes based on property size.',
    },
    {
        'service': 'Home Cleaning', 'name': 'Sofa & Carpet Shampooing',
        'kind': 'labor', 'min_price': 1500, 'max_price': 6000, 'duration': 90,
        'icon': 'sofa',
        'tags': ['sofa', 'carpet', 'shampoo', 'upholstery', 'stain'],
        'desc': 'Hot-water extraction, stain treatment and deodoriser. '
                'Quick-dry method. Technician quotes after counting pieces on-site.',
    },
    {
        'service': 'Home Cleaning', 'name': 'Post-Construction Cleanup',
        'kind': 'labor', 'min_price': 3000, 'max_price': 15000, 'duration': 180,
        'icon': 'cleaning',
        'tags': ['construction', 'cleanup', 'post', 'renovation', 'cement', 'paint'],
        'desc': 'Cement and paint stain removal, debris haul-out, polish. '
                'Technician quotes after walkthrough of the renovated area.',
    },

    # ── Pest Control ──────────────────────────────────────────────────
    {
        'service': 'Pest Control', 'name': 'Cockroach Gel-Bait Treatment',
        'kind': 'fixed', 'price': 2500, 'duration': 60,
        'icon': 'pest_control',
        'card': 'https://images.unsplash.com/photo-1632935190380-c19f1cd1cdba?w=800&q=80',
        'tags': ['cockroach', 'lal beg', 'gel', 'bait', 'kitchen'],
        'desc': 'Targeted gel-bait application in kitchen and washroom cracks. '
                'Single-visit treatment. Safe for children and pets.',
    },
    {
        'service': 'Pest Control', 'name': 'Bed Bug Spot Treatment',
        'kind': 'fixed', 'price': 3000, 'duration': 60,
        'icon': 'pest_control',
        'card': 'https://images.unsplash.com/photo-1632935190380-c19f1cd1cdba?w=800&q=80',
        'tags': ['bed bug', 'khatmal', 'spot', 'mattress', 'spray'],
        'desc': 'Mattress, bed-frame and crevice spray with residual chemical. '
                'Khatmal treatment for known infestation areas.',
    },
    {
        'service': 'Pest Control', 'name': 'Termite (Deemak) Treatment',
        'kind': 'labor', 'min_price': 3500, 'max_price': 9000, 'duration': 120,
        'icon': 'pest_control',
        'tags': ['termite', 'deemak', 'wood', 'frame', 'injection'],
        'desc': 'Drill and chemical injection at door frames, skirting and '
                'wood furniture. Technician inspects and quotes by area.',
    },
    {
        'service': 'Pest Control', 'name': 'General Disinfection / Fumigation',
        'kind': 'labor', 'min_price': 2000, 'max_price': 6000, 'duration': 90,
        'icon': 'pest_control',
        'tags': ['disinfection', 'fumigation', 'sanitisation', 'spray'],
        'desc': 'Whole-property fogging and surface spray. Suitable for '
                'post-illness sanitisation. Quoted by sq.ft after walkthrough.',
    },
]


# Lahore-only seed. All 30 techs operate within ~10km of the customer's
# Gulberg III address (31.5204, 74.3587) so the Haversine geofence at
# bookings/services/instant_book_service.py:210 doesn't reject bookings
# during the demo. Lat/lng is explicit per tech (no jitter computation)
# — keeps the seed inspectable.
#
# Slugs for techs 1-10 are preserved from the prior seed so the BOOKINGS
# list below (which keys on `<lastname-segment>_<lastname>` slugs) keeps
# working without rewrites.
TECHS = [
    # ── Slot 1-10 : original slugs preserved (BOOKINGS list references them) ─
    {'first': 'Muhammad Bilal', 'last': 'Ahmed',    'phone': '+923001112201',
     'lat': 31.5240, 'lng': 74.3520, 'work_address': 'Gulberg III, Lahore',
     'gig': 'AC General Service',                       'rating': 4.8, 'reviews': 47, 'color': '#2563eb'},
    {'first': 'Ali Raza',       'last': 'Khan',     'phone': '+923001112202',
     'lat': 31.5145, 'lng': 74.3520, 'work_address': 'Gulberg II, Lahore',
     'gig': 'Ceiling Fan Installation',                 'rating': 4.6, 'reviews': 32, 'color': '#16a34a'},
    {'first': 'Hamza',          'last': 'Tariq',    'phone': '+923001112203',
     'lat': 31.5100, 'lng': 74.3450, 'work_address': 'Liberty Market, Lahore',
     'gig': 'Sink & Drain Unblocking',                  'rating': 4.7, 'reviews': 28, 'color': '#dc2626'},
    {'first': 'Usman',          'last': 'Shahbaz',  'phone': '+923001112204',
     'lat': 31.4990, 'lng': 74.3880, 'work_address': 'Lahore Cantt, Lahore',
     'gig': 'Light Fitting (LED Panel / Chandelier)',   'rating': 4.5, 'reviews': 19, 'color': '#ea580c'},
    {'first': 'Imran',          'last': 'Hussain',  'phone': '+923001112205',
     'lat': 31.5024, 'lng': 74.3232, 'work_address': 'Garden Town, Lahore',
     'gig': 'Sofa & Carpet Shampooing',                 'rating': 4.4, 'reviews': 15, 'color': '#9333ea'},
    {'first': 'Asad Mehmood',   'last': 'Qureshi',  'phone': '+923001112206',
     'lat': 31.4860, 'lng': 74.3179, 'work_address': 'Model Town, Lahore',
     'gig': 'Home Deep Cleaning',                       'rating': 4.9, 'reviews': 61, 'color': '#0891b2'},
    {'first': 'Faisal',         'last': 'Iqbal',    'phone': '+923001112207',
     'lat': 31.4778, 'lng': 74.4055, 'work_address': 'DHA Phase 4, Lahore',
     'gig': 'Water Motor / Pressure Pump Installation', 'rating': 4.6, 'reviews': 22, 'color': '#db2777'},
    {'first': 'Adnan',          'last': 'Mansoor',  'phone': '+923001112208',
     'lat': 31.4985, 'lng': 74.4145, 'work_address': 'Cavalry Ground, Lahore',
     'gig': 'Cockroach Gel-Bait Treatment',             'rating': 4.5, 'reviews': 17, 'color': '#ca8a04'},
    {'first': 'Khalid',         'last': 'Mahmood',  'phone': '+923001112209',
     'lat': 31.5163, 'lng': 74.3022, 'work_address': 'Iqbal Town, Lahore',
     'gig': 'AC Gas Refill',                            'rating': 4.7, 'reviews': 38, 'color': '#4f46e5'},
    {'first': 'Tariq Aziz',     'last': 'Sheikh',   'phone': '+923001112210',
     'lat': 31.5384, 'lng': 74.3260, 'work_address': 'Shadman, Lahore',
     'gig': 'Switch & Socket Replacement',              'rating': 4.8, 'reviews': 44, 'color': '#059669'},
    # ── Slot 11-30 : new techs ─────────────────────────────────────────────
    {'first': 'Hassan Ali',     'last': 'Malik',    'phone': '+923001112211',
     'lat': 31.5210, 'lng': 74.3600, 'work_address': 'Gulberg III, Lahore',
     'gig': 'AC General Service',                       'rating': 4.5, 'reviews': 21, 'color': '#7c3aed'},
    {'first': 'Umar Farooq',    'last': 'Bhatti',   'phone': '+923001112212',
     'lat': 31.5103, 'lng': 74.3650, 'work_address': 'Gulberg V, Lahore',
     'gig': 'AC Gas Refill',                            'rating': 4.4, 'reviews': 14, 'color': '#0ea5e9'},
    {'first': 'Yasir Mehmood',  'last': 'Sandhu',   'phone': '+923001112213',
     'lat': 31.4936, 'lng': 74.3109, 'work_address': 'Faisal Town, Lahore',
     'gig': 'AC Installation',                          'rating': 4.7, 'reviews': 34, 'color': '#10b981'},
    {'first': 'Adeel',          'last': 'Akram',    'phone': '+923001112214',
     'lat': 31.5497, 'lng': 74.3436, 'work_address': 'Mall Road, Lahore',
     'gig': 'AC Installation',                          'rating': 4.6, 'reviews': 26, 'color': '#f59e0b'},
    {'first': 'Nauman',         'last': 'Hashmi',   'phone': '+923001112215',
     'lat': 31.5103, 'lng': 74.2887, 'work_address': 'Allama Iqbal Town, Lahore',
     'gig': 'AC Repair (Cooling / Leak / PCB)',         'rating': 4.3, 'reviews': 9,  'color': '#ef4444'},
    {'first': 'Waqas',          'last': 'Anwar',    'phone': '+923001112216',
     'lat': 31.4980, 'lng': 74.3884, 'work_address': 'Lahore Cantt, Lahore',
     'gig': 'Ceiling Fan Installation',                 'rating': 4.5, 'reviews': 18, 'color': '#84cc16'},
    {'first': 'Rizwan',         'last': 'Latif',    'phone': '+923001112217',
     'lat': 31.4694, 'lng': 74.2728, 'work_address': 'Johar Town, Lahore',
     'gig': 'Switch & Socket Replacement',              'rating': 4.6, 'reviews': 24, 'color': '#a855f7'},
    {'first': 'Salman',         'last': 'Akhtar',   'phone': '+923001112218',
     'lat': 31.4860, 'lng': 74.3179, 'work_address': 'Model Town, Lahore',
     'gig': 'Wiring Inspection & Fault Finding',        'rating': 4.7, 'reviews': 29, 'color': '#06b6d4'},
    {'first': 'Kashif',         'last': 'Zaman',    'phone': '+923001112219',
     'lat': 31.5024, 'lng': 74.3232, 'work_address': 'Garden Town, Lahore',
     'gig': 'General Disinfection / Fumigation',        'rating': 4.4, 'reviews': 12, 'color': '#22c55e'},
    {'first': 'Saad',           'last': 'Khurram',  'phone': '+923001112220',
     'lat': 31.5145, 'lng': 74.3520, 'work_address': 'Gulberg II, Lahore',
     'gig': 'Sink & Drain Unblocking',                  'rating': 4.5, 'reviews': 16, 'color': '#f97316'},
    {'first': 'Junaid',         'last': 'Aslam',    'phone': '+923001112221',
     'lat': 31.5210, 'lng': 74.3580, 'work_address': 'Gulberg III, Lahore',
     'gig': 'Commode / Flush Tank Repair',              'rating': 4.6, 'reviews': 20, 'color': '#3b82f6'},
    {'first': 'Waleed',         'last': 'Younis',   'phone': '+923001112222',
     'lat': 31.5384, 'lng': 74.3260, 'work_address': 'Shadman, Lahore',
     'gig': 'Leak Detection & Pipe Repair',             'rating': 4.5, 'reviews': 17, 'color': '#14b8a6'},
    {'first': 'Zain',           'last': 'Bashir',   'phone': '+923001112223',
     'lat': 31.4778, 'lng': 74.4055, 'work_address': 'DHA Phase 4, Lahore',
     'gig': 'Leak Detection & Pipe Repair',             'rating': 4.0, 'reviews': 5,  'color': '#e11d48'},
    {'first': 'Shahid',         'last': 'Saeed',    'phone': '+923001112224',
     'lat': 31.5103, 'lng': 74.3650, 'work_address': 'Gulberg V, Lahore',
     'gig': 'Kitchen Deep Clean',                       'rating': 4.7, 'reviews': 31, 'color': '#8b5cf6'},
    {'first': 'Aamir',          'last': 'Sial',     'phone': '+923001112225',
     'lat': 31.4936, 'lng': 74.3109, 'work_address': 'Faisal Town, Lahore',
     'gig': 'Kitchen Deep Clean',                       'rating': 4.5, 'reviews': 19, 'color': '#65a30d'},
    {'first': 'Naveed',         'last': 'Rana',     'phone': '+923001112226',
     'lat': 31.5163, 'lng': 74.3022, 'work_address': 'Iqbal Town, Lahore',
     'gig': 'Home Deep Cleaning',                       'rating': 4.6, 'reviews': 23, 'color': '#0284c7'},
    {'first': 'Sohail',         'last': 'Rashid',   'phone': '+923001112227',
     'lat': 31.4985, 'lng': 74.4145, 'work_address': 'Cavalry Ground, Lahore',
     'gig': 'Post-Construction Cleanup',                'rating': 4.2, 'reviews': 7,  'color': '#d946ef'},
    {'first': 'Mansoor',        'last': 'Mirza',    'phone': '+923001112228',
     'lat': 31.5128, 'lng': 74.3433, 'work_address': 'Liberty Market, Lahore',
     'gig': 'Cockroach Gel-Bait Treatment',             'rating': 4.9, 'reviews': 58, 'color': '#facc15'},
    {'first': 'Asim',           'last': 'Butt',     'phone': '+923001112229',
     'lat': 31.5103, 'lng': 74.2887, 'work_address': 'Allama Iqbal Town, Lahore',
     'gig': 'Bed Bug Spot Treatment',                   'rating': 4.4, 'reviews': 11, 'color': '#fb7185'},
    {'first': 'Rashid',         'last': 'Chaudhry', 'phone': '+923001112230',
     'lat': 31.4694, 'lng': 74.2728, 'work_address': 'Johar Town, Lahore',
     'gig': 'Termite (Deemak) Treatment',               'rating': 4.6, 'reviews': 25, 'color': '#1e40af'},
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


# Karigar brand gradient: #2563EB (primaryContainer) top → #0051AE (brand) bottom.
# Matches the existing CTA gradient direction in lib/core/theme/app_colors.dart
# so the promo banner on the home screen reads as the same visual language as
# every primary button in the app.
_BRAND_TOP = (37, 99, 235)    # #2563EB
_BRAND_BOT = (0, 81, 174)     # #0051AE


def _generate_promo_banner() -> ContentFile:
    """Production-grade promo banner: 1200x600 vertical brand gradient
    with subtle decorative orbs on the right edge.

    Pure visual backdrop — no text, no wordmark. The Flutter promo card
    overlays its own headline, description and Claim CTA on top, so any
    text baked into the banner image becomes duplicate noise behind the
    chrome (and a Karigar wordmark on a Karigar app is redundant).
    """
    W, H = 1200, 600
    img = Image.new('RGB', (W, H), color=_BRAND_BOT)
    draw = ImageDraw.Draw(img)

    # Vertical gradient — scan-lines top→bottom. 600 calls instead of
    # 720k per-pixel sets is ~1000x faster than a pixel loop.
    for y in range(H):
        t = y / (H - 1)
        r = int(_BRAND_TOP[0] * (1 - t) + _BRAND_BOT[0] * t)
        g = int(_BRAND_TOP[1] * (1 - t) + _BRAND_BOT[1] * t)
        b = int(_BRAND_TOP[2] * (1 - t) + _BRAND_BOT[2] * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b))

    # Two large soft orbs on the right edge — add depth and a sense of
    # brand polish without competing with the Flutter chrome on the left.
    # Approximated alpha by lightening the brand color toward white
    # (RGB image, no alpha plane).
    def _tint(base, white_amt):
        return tuple(int(base[i] * (1 - white_amt) + 255 * white_amt) for i in range(3))

    soft   = _tint(_BRAND_TOP, 0.18)
    softer = _tint(_BRAND_TOP, 0.10)
    draw.ellipse([W - 380, -180, W + 180, 380], fill=soft)
    draw.ellipse([W - 180, H - 280, W + 260, H + 180], fill=softer)

    buf = io.BytesIO()
    img.save(buf, format='PNG', optimize=True)
    return ContentFile(buf.getvalue(), name='karigar_promo.png')


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


class Command(BaseCommand):
    help = 'Seeds Pakistani-context demo data (categories, gigs, technicians, promotion) for viva demo.'

    @transaction.atomic
    def handle(self, *args, **opts):
        self.stdout.write(self.style.MIGRATE_HEADING('Seeding demo data for viva demo...'))

        # Full reset of non-catalog state. Preserves superusers (so /admin
        # stays reachable) and the catalog (Service / SubService / Promotion
        # remain — that's our previously-seeded richer catalog). Wipes:
        #   - all users (except superusers) + their UserProfile + CustomerProfile
        #   - all TechnicianProfile + bridge rows + schedules + reviews
        #   - all wallet rows (transactions, topups, withdrawals, accounts)
        #   - all JobBooking + Quote + QuoteLineItem + BookingItem
        # This is the same wipe demo_journey.sh uses every run — well-tested
        # path through every PROTECT FK chain.
        self.stdout.write('-> Wiping non-catalog data (users / bookings / wallet / tech profiles)...')
        call_command('wipe_all_except_catalog', verbosity=0)

        # Always fetch real portraits from randomuser.me — initials avatars
        # look low-effort for a supervisor demo. The fetch retrieves 30
        # portraits in one HTTP call. Falls back to per-tech initials on
        # any network or parsing failure (existing helper handles it).
        self.stdout.write(f'-> Fetching {len(TECHS)} portraits from randomuser.me (nat=in, gender=male)...')
        portrait_photos = _fetch_indian_male_portraits(len(TECHS), self.stdout.write)
        if portrait_photos is None:
            self.stdout.write(self.style.WARNING('  Falling back to initials avatars.'))

        # 1. SERVICES
        self.stdout.write(f'-> Services ({len(SERVICES)})')
        service_objs = {}
        for s in SERVICES:
            obj, _ = Service.objects.update_or_create(
                name=s['name'],
                defaults={
                    'icon_name': s['icon'],
                    'display_order': s['order'],
                    'is_active': True,
                    'base_inspection_fee': Decimal('500.00'),
                    'default_duration_minutes': s['duration'],
                },
            )
            service_objs[s['name']] = obj

        # 2. SUB-SERVICES (fixed + labor mix; all featured on home for demo).
        # `kind` branches the pricing fields — see GIGS docstring.
        n_fixed = sum(1 for g in GIGS if g['kind'] == 'fixed')
        n_labor = sum(1 for g in GIGS if g['kind'] == 'labor')
        self.stdout.write(f'-> Sub-services ({len(GIGS)}: {n_fixed} fixed + {n_labor} labor)')
        gig_objs = {}
        for g in GIGS:
            is_fixed = g['kind'] == 'fixed'
            if is_fixed:
                price_defaults = {
                    'is_fixed_price': True,
                    'base_price': Decimal(str(g['price'])),
                    'max_price': None,
                }
            else:  # labor
                price_defaults = {
                    'is_fixed_price': False,
                    'base_price': Decimal(str(g['min_price'])),
                    'max_price': Decimal(str(g['max_price'])),
                }
            obj, _ = SubService.objects.update_or_create(
                service=service_objs[g['service']],
                name=g['name'],
                defaults={
                    **price_defaults,
                    # Only fixed-price gigs surface as hero cards on the home
                    # screen. Labor gigs are discoverable through the service
                    # category but not featured (no representative price point).
                    'is_featured': is_fixed,
                    'estimated_duration_minutes': g['duration'],
                    'icon_name': g['icon'],
                    'card_image_url': g.get('card'),
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
        self.stdout.write(f'-> Technicians ({len(TECHS)}) with avatars + skills + schedules + reviews')
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

            # Mirror the real auth flow at accounts/services/auth_service.py:121
            # — every user (technician or not) gets a CustomerProfile on
            # OTP signup. The earlier seed skipped this for techs, which
            # diverged from the production DB shape (a real tech who later
            # tries to book a service would already have a CustomerProfile).
            CustomerProfile.objects.get_or_create(user=user)

            profile, _ = TechnicianProfile.objects.update_or_create(
                user=user,
                defaults={
                    'city': 'LHR',
                    'cnic_number': f'35202-{cnic_seq:07d}-1',
                    'status': 'APPROVED',
                    'base_latitude': t['lat'],
                    'base_longitude': t['lng'],
                    'work_address_label': t['work_address'],
                    'max_travel_radius_km': 10,
                    'is_onboarding_complete': True,
                    'is_active': True,
                    # Every seeded tech is "online" so the customer-side
                    # matchmaker (technicians/selectors/matchmaking_selectors.py)
                    # surfaces them in discovery. The matchmaker filters on
                    # is_online=True; without this flag the tech is invisible
                    # to the customer no matter how high their rating.
                    # Bilal's wallet override below is a separate signal
                    # (tops up his dashboard balance) and remains in place.
                    'is_online': True,
                    'rating_average': Decimal(str(t['rating'])),
                    'review_count': t['reviews'],
                },
            )
            tech_by_slug[slug] = profile

            # Avatar: real portrait if randomuser.me succeeded, else initials.
            # The wipe at the top of handle() means every tech here is fresh —
            # no existing-photo branch needed.
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

            # Skill linking tech to their gig. Bridge row is now pure
            # membership — ``years_of_experience`` was dropped in 0014.
            gig = gig_objs[t['gig']]
            TechnicianSkill.objects.get_or_create(
                technician=profile, sub_service=gig,
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

        # Labor-gig bookings get a representative quote within the rate band
        # (midpoint-ish). Fixed-gig bookings use the locked base_price.
        BOOKINGS = [
            # tech_username, service, gig, addr, start, dur_min, price, status, context
            ('aziz_sheikh',     'Electrician',          'Switch & Socket Replacement',                'Home',
                now - timedelta(days=14, hours=4), 30, 600, 'COMPLETED', 'Switch & Socket — 30 min'),
            ('mehmood_qureshi', 'Home Cleaning',        'Home Deep Cleaning',                         'Home',
                now - timedelta(days=7, hours=4),  240, 8500, 'COMPLETED', 'Deep Cleaning — 4 hrs'),
            ('faisal_iqbal',    'Plumbing',             'Water Motor / Pressure Pump Installation',   'Home',
                now - timedelta(days=3, hours=2),  90, 2500, 'COMPLETED', 'Pump Install — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair & Service',  'AC General Service',                         'Home',
                today_9am, 90, 1500, 'COMPLETED', 'AC General — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair & Service',  'AC Gas Refill',                              'Office',
                today_1130, 60, 4000, 'COMPLETED', 'AC Gas Refill — 1 hr'),
            ('bilal_ahmed',     'AC Repair & Service',  'AC General Service',                         'Home',
                upnext_time, 90, 1500, 'CONFIRMED', 'AC General — 1.5 hrs'),
            ('bilal_ahmed',     'AC Repair & Service',  'AC Gas Refill',                              'Home',
                later_time, 60, 4000, 'CONFIRMED', 'AC Gas Refill — 1 hr'),
            ('hamza_tariq',     'Plumbing',             'Sink & Drain Unblocking',                    'Home',
                (now + timedelta(days=1)).replace(hour=10, minute=0, second=0, microsecond=0),
                60, 1500, 'CONFIRMED', 'Sink Unblocking — 1 hr'),
            ('imran_hussain',   'Home Cleaning',        'Sofa & Carpet Shampooing',                   'Home',
                (now + timedelta(days=3)).replace(hour=13, minute=0, second=0, microsecond=0),
                90, 3500, 'CONFIRMED', 'Sofa Shampoo — 1.5 hrs'),
            ('adnan_mansoor',   'Pest Control',         'Cockroach Gel-Bait Treatment',               'Home',
                (now + timedelta(days=5)).replace(hour=11, minute=0, second=0, microsecond=0),
                60, 2500, 'AWAITING',  'Cockroach Treatment — 1 hr'),
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

        # 6. PROMOTION — single AC-themed launch offer with PIL-generated
        # brand banner. Banner uses the same vertical gradient direction as
        # AppColors.ctaGradient (lib/core/theme/app_colors.dart) so it reads
        # as the same visual language as every primary button in the app.
        self.stdout.write('-> Promotion (1) — AC launch offer + PIL brand banner')
        promo_now = timezone.now()
        promo, promo_created = Promotion.objects.update_or_create(
            name='Launch Offer — Rs. 300 OFF AC Service',
            defaults={
                'description': 'Get Rs. 300 OFF your first AC service bill. '
                               'Auto-applied at quote acceptance — inspection '
                               'fee is unaffected.',
                'discount_type': Promotion.DiscountType.FIXED,
                'discount_value': Decimal('300'),
                'target_service': service_objs['AC Repair & Service'],
                'funded_by': Promotion.FundingSource.PLATFORM,
                'valid_from': promo_now,
                'valid_until': promo_now + timedelta(days=60),
                'is_active': True,
                'is_featured_on_home': True,
            },
        )
        # Always re-render the banner on seed run — cheap (~50ms) and means
        # rebrand tweaks land without needing a manual admin upload.
        promo.image.save(
            'karigar_ac_launch.png',
            _generate_promo_banner(),
        )

        # 7. SUMMARY
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('  DEMO SEED COMPLETE'))
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(f'  Services       : {len(SERVICES)}')
        self.stdout.write(f'  Sub-services   : {len(GIGS)}  ({n_fixed} fixed + {n_labor} labor)')
        self.stdout.write(f'  Technicians    : {len(TECHS)}  (all APPROVED, all Lahore, radius 10km)')
        self.stdout.write(f'  Bookings       : {len(BOOKINGS)} for demo_customer')
        self.stdout.write(f'  Promotion      : 1 ({"created" if promo_created else "updated"}) + banner re-rendered')
        self.stdout.write(f'  Bilal\'s today  : 2 completed + 1 upNext + 1 laterToday')
        self.stdout.write(f'  Bilal\'s wallet : Rs. 4,250 (online=True for dashboard)')
        self.stdout.write('')
        self.stdout.write('  Customer login (for screenshots):')
        self.stdout.write(f'    phone    : +923009999999')
        self.stdout.write(f'    OTP      : 123456 (DEBUG=True)')
        self.stdout.write(f'    token    : {token.key}')
        self.stdout.write('')
        self.stdout.write(f'  Technicians use phones +923001112201 .. +9230011122{len(TECHS):02d}')
        self.stdout.write('  All passwords: demo123')
        self.stdout.write(self.style.SUCCESS('=' * 60))

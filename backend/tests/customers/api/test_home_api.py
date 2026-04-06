import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta

from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory

pytestmark = pytest.mark.django_db

class TestCustomerHomeFeedAPI:

    @pytest.fixture
    def api_client(self):
        return APIClient()

    @pytest.fixture
    def setup_data(self):
        # 1. Categories
        ServiceFactory(name="Plumbing", is_active=True, display_order=1, base_inspection_fee=500.00)
        
        # 2. Fixed Gigs
        service_ac = ServiceFactory(name="AC Service", is_active=True, display_order=2, base_inspection_fee=600.00)
        sub_ac_wash = SubServiceFactory(
            name="AC Wash", 
            service=service_ac, 
            is_fixed_price=True, 
            is_featured=True,
            base_price=1500.00,
            max_price=1500.00
        )
        
        # 3. Promotions
        PromotionFactory(
            name="Summer Promo",
            description=None, # Explicitly null to test dynamic generation
            target_service=service_ac,
            is_active=True,
            is_featured_on_home=True,
            valid_from=timezone.now() - timedelta(days=1),
            valid_until=timezone.now() + timedelta(days=5),
            discount_type='PERCENTAGE',
            discount_value=20.00
        )
        
        # 4. Top Technicians (Lahore: lat 31.5204, lng 74.3587)
        tech = TechnicianProfileFactory(
            base_latitude=31.5204,
            base_longitude=74.3587,
            is_active=True,
            is_onboarding_complete=True,
            rating_average=4.9,
            review_count=120
        )
        # Linking to AC Service via a skill
        TechnicianSkillFactory(technician=tech, sub_service=sub_ac_wash)

    def test_get_home_feed_success(self, api_client, setup_data):
        url = reverse('customer-home-feed') 
        
        # Valid Lahore Coordinates
        response = api_client.get(url, {'lat': '31.5204', 'lng': '74.3587'})
        
        assert response.status_code == 200
        data = response.json()
        
        # Assert Contract Structure
        assert 'categories' in data
        assert 'promotions' in data
        assert 'fixed_gigs' in data
        assert 'top_technicians' in data
        
        # Assert Data Integrity (Dumb UI compliance)
        assert len(data['categories']) == 2 # Plumbing + AC Service
        
        assert len(data['promotions']) == 1
        assert "Get 20% OFF the total bill" in data['promotions'][0]['promo_description']
        
        assert len(data['fixed_gigs']) == 1
        assert data['fixed_gigs'][0]['name'] == "AC Wash"
        assert data['fixed_gigs'][0]['base_price'] == "1500.00"
        
        assert len(data['top_technicians']) == 1
        tech_data = data['top_technicians'][0]
        assert tech_data['primary_category'] == "AC Service"
        
        # Unified Money Corner check for Home Feed (Default should be Inspection Fee since no intent is passed)
        assert tech_data['primary_price'] == "Rs. 500" # Global default
        assert tech_data['price_context'] == "Inspection Fee"

    def test_get_home_feed_invalid_gps_fallback(self, api_client, setup_data):
        url = reverse('customer-home-feed')
        response = api_client.get(url, {'lat': 'invalid_string', 'lng': 'null'})
        assert response.status_code == 200
        data = response.json()
        assert len(data['top_technicians']) == 1
        assert 'distance_km' not in data['top_technicians'][0]

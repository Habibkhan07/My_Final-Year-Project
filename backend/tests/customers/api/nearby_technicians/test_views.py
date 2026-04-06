import pytest
from rest_framework.test import APIClient
from django.urls import reverse
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory
from tests.factories.technicians import TechnicianProfileFactory, TechnicianSkillFactory

@pytest.mark.django_db
class TestTechnicianDiscoveryListView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('nearby-technicians-list')

    def test_scenario_1_category_intent(self):
        """Scenario 1: Category Click -> Show Inspection Fee"""
        service = ServiceFactory(base_inspection_fee=600.00)
        sub_service = SubServiceFactory(service=service)
        # Technician with this skill
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True, rating_average=4.5, review_count=10)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service)
        
        response = self.client.get(f"{self.url}?service_id={service.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 600"
        assert tech_data['price_context'] == "Inspection Fee"
        assert tech_data['promo_tag'] is None

    def test_scenario_2_fixed_gig_intent(self):
        """Scenario 2: Fixed Price Gig (SubService base == max)"""
        sub_service = SubServiceFactory(base_price=1500.00, max_price=1500.00, name="AC Wash")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service)
        
        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 1500"
        assert tech_data['price_context'] == "Fixed Price"

    def test_scenario_3_variable_labor_rate_single(self):
        """Scenario 3: Variable Job (Technician sets a single labor rate)"""
        sub_service = SubServiceFactory(base_price=800.00, max_price=2000.00, name="Pipe Leak")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        # Technician picks a specific rate
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, base_rate=1200.00, max_rate=1200.00)
        
        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 1,200"
        assert tech_data['price_context'] == "Labor Rate"

    def test_scenario_3_variable_labor_rate_range(self):
        """Scenario 3: Variable Job (Technician sets a pricing window)"""
        sub_service = SubServiceFactory(base_price=800.00, max_price=2000.00, name="Pipe Leak")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        # Technician picks a range
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, base_rate=1000.00, max_rate=1400.00)
        
        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 1,000 - 1,400"
        assert tech_data['price_context'] == "Labor Rate"

    def test_scenario_4_promo_click(self):
        """Scenario 4: Promo Click -> Keep original price, add promo_tag"""
        service = ServiceFactory(base_inspection_fee=500.00, name="Plumbing")
        sub_service = SubServiceFactory(service=service)
        promo = PromotionFactory(
            discount_type='PERCENTAGE', 
            discount_value=20.00, 
            target_service=service, 
            description="20% Off Final Bill"
        )
        
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service)
        
        response = self.client.get(f"{self.url}?promotion_id={promo.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 500"
        assert tech_data['price_context'] == "Inspection Fee"
        assert tech_data['promo_tag'] == "20% Off Final Bill"

    def test_search_query_acts_as_variable_intent(self):
        """Search query matching a sub-service should trigger Scenario 3 logic"""
        sub_service = SubServiceFactory(name="Plumbing Leak", base_price=800.00, max_price=2000.00)
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, base_rate=1100.00, max_rate=1100.00)
        
        response = self.client.get(f"{self.url}?q=Plumb")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 1,100"
        assert tech_data['price_context'] == "Labor Rate"

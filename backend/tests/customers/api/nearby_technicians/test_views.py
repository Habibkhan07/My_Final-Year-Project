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
        """Scenario 2: Fixed Price Gig — is_fixed_price flag drives the pricing decision, not price equality"""
        sub_service = SubServiceFactory(base_price=1500.00, max_price=1500.00, is_fixed_price=True, name="AC Wash")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service)

        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")

        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]

        assert tech_data['primary_price'] == "Rs. 1,500"
        assert tech_data['price_context'] == "Fixed Price"

    def test_scenario_2_variable_with_equal_prices_is_not_fixed(self):
        """
        Regression: A sub-service with equal base/max prices but is_fixed_price=False
        must show Labor Fee, not Fixed Price. The old price-equality heuristic was wrong.
        """
        sub_service = SubServiceFactory(base_price=1500.00, max_price=1500.00, is_fixed_price=False, name="AC Check")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, labor_rate=1500.00)

        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")

        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]

        # Must NOT be Fixed Price just because prices happen to match
        assert tech_data['price_context'] == "Labor Fee"

    def test_scenario_3_variable_labor_rate_single(self):
        """Scenario 3: Variable Job (Technician sets a single labor rate)"""
        sub_service = SubServiceFactory(base_price=800.00, max_price=2000.00, name="Pipe Leak")
        tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        # Technician picks a specific rate
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, labor_rate=1200.00)
        
        response = self.client.get(f"{self.url}?sub_service_id={sub_service.id}")
        
        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]
        
        assert tech_data['primary_price'] == "Rs. 1,200"
        assert tech_data['price_context'] == "Labor Fee"

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
        TechnicianSkillFactory(technician=tech, sub_service=sub_service, labor_rate=1100.00)

        response = self.client.get(f"{self.url}?q=Plumb")

        assert response.status_code == 200
        data = response.json()
        tech_data = data['results'][0]

        assert tech_data['primary_price'] == "Rs. 1,100"
        assert tech_data['price_context'] == "Labor Fee"

    # --- REGRESSION TESTS: GPS-less filter correctness (Bug Fix) ---

    def test_promo_excludes_wrong_service_technicians_without_gps(self):
        """
        REGRESSION: Promo 'Claim Now' must only return technicians who offer the promo's
        target service. Previously the GPS failsafe returned ALL technicians (including
        plumbers for an AC promo) because domain filters ran AFTER the early return.
        """
        service_ac = ServiceFactory(name="AC Repair", base_inspection_fee=500.00)
        service_plumbing = ServiceFactory(name="Plumbing", base_inspection_fee=500.00)
        sub_ac = SubServiceFactory(service=service_ac)
        sub_plumb = SubServiceFactory(service=service_plumbing)

        ac_tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=ac_tech, sub_service=sub_ac)

        plumber = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=plumber, sub_service=sub_plumb)

        promo = PromotionFactory(target_service=service_ac, description="20% Off AC")

        # No lat/lng — this is what triggered the bug
        response = self.client.get(f"{self.url}?promotion_id={promo.id}")

        assert response.status_code == 200
        ids = [t['id'] for t in response.json()['results']]
        assert ac_tech.id in ids
        assert plumber.id not in ids, "Plumber must NOT appear in an AC service promo"

    def test_service_filter_applies_without_gps(self):
        """
        REGRESSION: service_id filter must work even when no GPS coordinates are provided.
        Domain eligibility is independent of location data.
        """
        service_ac = ServiceFactory(name="AC Repair")
        service_plumbing = ServiceFactory(name="Plumbing")
        sub_ac = SubServiceFactory(service=service_ac)
        sub_plumb = SubServiceFactory(service=service_plumbing)

        ac_tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=ac_tech, sub_service=sub_ac)

        plumber = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=plumber, sub_service=sub_plumb)

        response = self.client.get(f"{self.url}?service_id={service_ac.id}")

        assert response.status_code == 200
        ids = [t['id'] for t in response.json()['results']]
        assert ac_tech.id in ids
        assert plumber.id not in ids

    def test_sub_service_filter_applies_without_gps(self):
        """
        REGRESSION: sub_service_id filter must work even when no GPS coordinates are provided.
        Only technicians with that exact skill should be returned.
        """
        service = ServiceFactory(name="AC Repair")
        sub_gas_refill = SubServiceFactory(service=service, name="Gas Refill")
        sub_install = SubServiceFactory(service=service, name="AC Install")

        refill_tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=refill_tech, sub_service=sub_gas_refill)

        install_tech = TechnicianProfileFactory(is_active=True, is_onboarding_complete=True)
        TechnicianSkillFactory(technician=install_tech, sub_service=sub_install)

        response = self.client.get(f"{self.url}?sub_service_id={sub_gas_refill.id}")

        assert response.status_code == 200
        ids = [t['id'] for t in response.json()['results']]
        assert refill_tech.id in ids
        assert install_tech.id not in ids, "Install tech must NOT appear in Gas Refill results"

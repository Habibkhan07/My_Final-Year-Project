import pytest
from customers.selectors.intent_selector import resolve_discovery_intent
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.marketing import PromotionFactory

@pytest.mark.django_db
class TestIntentSelector:

    def test_resolve_discovery_intent_priority_search_over_ids(self):
        """
        Scenario: User provides a promotion_id but also a search query 'q'.
        Business Rule: Search query should override and resolve to the most relevant Gig.
        """
        # 1. Setup a Service and a Promotion
        service_plumbing = ServiceFactory(name="Plumbing")
        promo = PromotionFactory(target_service=service_plumbing)
        
        # 2. Setup a different Gig that matches a search query
        sub_ac = SubServiceFactory(name="AC Repair")
        
        # 3. Call the selector with BOTH
        resolved_service, resolved_subservice, resolved_promo, final_service_id, final_sub_service_id = resolve_discovery_intent(
            q="AC",
            promotion_id=promo.id
        )
        
        # ASSERTIONS
        # The promo is still resolved (for display purposes)
        assert resolved_promo.id == promo.id
        
        # But the SubService is resolved based on the Search Query 'AC'
        assert resolved_subservice.id == sub_ac.id
        assert final_sub_service_id == sub_ac.id
        
        # Service is inferred from the resolved SubService (AC), not the Promo (Plumbing)
        assert resolved_service.id == sub_ac.service.id

    def test_resolve_discovery_intent_resolves_promo_target(self):
        """Verify that a promotion correctly resolves its target service."""
        service = ServiceFactory(name="Electrical")
        promo = PromotionFactory(target_service=service)
        
        resolved_service, _, resolved_promo, final_service_id, _ = resolve_discovery_intent(
            promotion_id=promo.id
        )
        
        assert resolved_promo.id == promo.id
        assert resolved_service.id == service.id
        assert final_service_id == service.id

    def test_resolve_discovery_intent_handles_invalid_ids_gracefully(self):
        """Ensures the selector doesn't crash on non-existent IDs."""
        res = resolve_discovery_intent(service_id="9999", promotion_id="8888")
        
        # Should return Nones, not raise DoesNotExist
        assert all(val is None for val in res)

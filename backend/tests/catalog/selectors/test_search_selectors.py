import pytest
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from catalog.selectors.search_selectors import get_subservices_by_query

pytestmark = pytest.mark.django_db

class TestSearchSelectors:

    def test_get_subservices_by_query_short_keyword(self, django_assert_num_queries):
        """Keywords less than 2 chars should return empty instantly (0 DB hits)."""
        with django_assert_num_queries(0):
            results = get_subservices_by_query(search_text="a")
            assert len(results) == 0

    def test_get_subservices_by_query_empty_keyword(self, django_assert_num_queries):
        """Empty keyword should return empty instantly (0 DB hits)."""
        with django_assert_num_queries(0):
            results = get_subservices_by_query(search_text="")
            assert len(results) == 0

    def test_get_subservices_by_query_matches_name(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(is_active=True)
        SubServiceFactory(name="Leaky Pipe Repair", service=service)
        SubServiceFactory(name="Gas Leak Detection", service=service)
        SubServiceFactory(name="Something Else", service=service)

        # Action & Assert (1 query for the list)
        with django_assert_num_queries(1):
            results = get_subservices_by_query(search_text="leak")
            assert len(results) == 2
            names = [r.name for r in results]
            assert "Leaky Pipe Repair" in names
            assert "Gas Leak Detection" in names

    def test_get_subservices_by_query_matches_service_name(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(name="Electrician", is_active=True)
        SubServiceFactory(name="Ceiling Fan Install", service=service)
        SubServiceFactory(name="Switchboard Repair", service=service)

        other_service = ServiceFactory(name="Plumber", is_active=True)
        SubServiceFactory(name="Pipe Fixing", service=other_service)

        # Action & Assert
        with django_assert_num_queries(1):
            results = get_subservices_by_query(search_text="electr")
            assert len(results) == 2
            names = [r.name for r in results]
            assert "Ceiling Fan Install" in names
            assert "Switchboard Repair" in names

    def test_get_subservices_by_query_matches_search_tags(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(name="Electrician", is_active=True)
        SubServiceFactory(name="Wiring Short Circuit", service=service, search_tags=["bijli", "current", "spark"])
        
        other_service = ServiceFactory(name="Plumber", is_active=True)
        SubServiceFactory(name="Tap Fixing", service=other_service, search_tags=["pani", "leak"])

        # Action & Assert
        with django_assert_num_queries(1):
            results = get_subservices_by_query(search_text="bijli")
            assert len(results) == 1
            assert results[0].name == "Wiring Short Circuit"

    def test_get_subservices_by_query_n_plus_one_protection(self, django_assert_num_queries):
        # Setup
        service = ServiceFactory(is_active=True, name="Test Service")
        SubServiceFactory(name="Test Sub 1", service=service)
        SubServiceFactory(name="Test Sub 2", service=service)

        # Action & Assert N+1 on service FK
        with django_assert_num_queries(1):
            results = get_subservices_by_query(search_text="test")
            for sub in results:
                _ = sub.service.name  # Accessing foreign key should not trigger new query

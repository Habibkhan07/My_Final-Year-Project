import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from tests.factories.catalog import ServiceFactory, SubServiceFactory

pytestmark = pytest.mark.django_db

class TestCatalogSearchAPI:

    @pytest.fixture
    def api_client(self):
        return APIClient()

    @pytest.fixture
    def setup_data(self):
        # 1. Category
        service_electrician = ServiceFactory(name="Electrician", is_active=True)
        
        # 2. Sub-Services
        SubServiceFactory(
            name="Wiring Short Circuit", 
            service=service_electrician, 
            base_price=500.00,
            is_fixed_price=False,
            search_tags=["bijli", "short"]
        )
        SubServiceFactory(
            name="Ceiling Fan Repair", 
            service=service_electrician, 
            base_price=800.00,
            is_fixed_price=True
        )

    def test_search_by_query_success(self, api_client, setup_data):
        url = reverse('catalog-search')
        
        # Search for "Wiring"
        response = api_client.get(url, {'q': 'Wiring'})
        
        assert response.status_code == 200
        data = response.json()
        
        assert 'results' in data
        assert len(data['results']) == 1
        result = data['results'][0]
        assert result['name'] == "Wiring Short Circuit"
        assert result['category_name'] == "Electrician"
        assert result['base_price'] == "500.00" # Explicit string check
        assert result['is_fixed_price'] is False

    def test_search_by_tag_success(self, api_client, setup_data):
        url = reverse('catalog-search')
        
        # Search for colloquial tag "bijli"
        response = api_client.get(url, {'q': 'bijli'})
        
        assert response.status_code == 200
        data = response.json()
        assert len(data['results']) == 1
        assert data['results'][0]['name'] == "Wiring Short Circuit"

    def test_search_min_chars_returns_empty(self, api_client, setup_data):
        url = reverse('catalog-search')
        
        # Search for "a" (less than 2 chars)
        response = api_client.get(url, {'q': 'a'})
        
        assert response.status_code == 200
        data = response.json()
        assert len(data['results']) == 0

    def test_search_no_query_returns_empty(self, api_client, setup_data):
        url = reverse('catalog-search')
        response = api_client.get(url)
        
        assert response.status_code == 200
        data = response.json()
        assert len(data['results']) == 0

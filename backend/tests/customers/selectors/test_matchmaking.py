import pytest
import uuid
from django.urls import reverse
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.technicians import (
    TechnicianProfileFactory, 
    TechnicianSkillFactory, 
    TechnicianServicePerformanceFactory
)

pytestmark = pytest.mark.django_db

class TestMatchmakingDefinitive:

    @pytest.fixture
    def setup_data(self):
        data = {}
        data['service_ac'] = ServiceFactory(name="AC Repair")
        data['sub_ac_refill'] = SubServiceFactory(service=data['service_ac'], name="Gas Refill")
        data['sub_ac_install'] = SubServiceFactory(service=data['service_ac'], name="AC Install")
        
        data['service_plumbing'] = ServiceFactory(name="Plumbing")
        data['sub_plumb'] = SubServiceFactory(service=data['service_plumbing'], name="Drain Cleaning")
        
        data['cust_lat'] = 31.5204
        data['cust_lng'] = 74.3587
        data['url'] = reverse('nearby-technicians-list')
        return data

    def _create_persona(self, lat, lng, reviews, rating, active=True, onboarded=True, skill=None):
        profile = TechnicianProfileFactory(
            base_latitude=lat, 
            base_longitude=lng,
            is_active=active, 
            is_onboarding_complete=onboarded,
            review_count=reviews, 
            rating_average=rating, 
            status='APPROVED' if active else 'PENDING'
        )
        if skill:
            TechnicianSkillFactory(technician=profile, sub_service=skill)
            # Matchmaking Selector uses TechnicianServicePerformance for category-specific scores
            TechnicianServicePerformanceFactory(
                technician=profile, 
                service=skill.service, 
                review_count=reviews, 
                rating_average=rating
            )
        return profile

    def test_haversine_epsilon_precision(self, client, setup_data):
        d = setup_data
        lat_9km = d['cust_lat'] + (9.0 / 111.32)
        lat_11km = d['cust_lat'] + (11.0 / 111.32)
        
        self._create_persona(lat_9km, d['cust_lng'], 10, 5.0, skill=d['sub_ac_refill'])
        self._create_persona(lat_11km, d['cust_lng'], 10, 5.0, skill=d['sub_ac_refill'])

        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}&service_id={d['service_ac'].id}")
        assert res.status_code == 200
        # DRF Pagination wraps results in 'results' key
        assert len(res.data['results']) == 1

    def test_null_island_and_negative_coordinates(self, client, setup_data):
        d = setup_data
        self._create_persona(0.0, 0.0, 10, 5.0, skill=d['sub_ac_refill']) 
        self._create_persona(-34.6037, -58.3816, 10, 5.0, skill=d['sub_ac_refill']) 
        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}")
        assert len(res.data['results']) == 0

    def test_bayesian_confidence_and_tie_breakers(self, client, setup_data):
        d = setup_data
        for _ in range(5):
            self._create_persona(d['cust_lat'], d['cust_lng'], 50, 3.8, skill=d['sub_ac_refill'])

        self._create_persona(d['cust_lat'], d['cust_lng'], 1, 5.0, skill=d['sub_ac_refill'])
        vet = self._create_persona(d['cust_lat'], d['cust_lng'], 200, 4.8, skill=d['sub_ac_refill'])
        vet_far = self._create_persona(d['cust_lat'] + (1.0/111.32), d['cust_lng'], 200, 4.8, skill=d['sub_ac_refill'])

        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}&service_id={d['service_ac'].id}")
        
        assert res.data['results'][0]['id'] == vet.id
        assert res.data['results'][1]['id'] == vet_far.id

    def test_zero_state_division_safety(self, client, setup_data):
        d = setup_data
        self._create_persona(d['cust_lat'], d['cust_lng'], 0, 0.0, skill=d['sub_ac_refill'])
        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}")
        assert res.status_code == 200

    def test_strict_state_leakage(self, client, setup_data):
        d = setup_data
        self._create_persona(d['cust_lat'], d['cust_lng'], 100, 5.0, active=False, skill=d['sub_ac_refill'])
        self._create_persona(d['cust_lat'], d['cust_lng'], 100, 5.0, onboarded=False, skill=d['sub_ac_refill'])
        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}")
        assert len(res.data['results']) == 0

    def test_sub_service_precision_leak(self, client, setup_data):
        d = setup_data
        self._create_persona(d['cust_lat'], d['cust_lng'], 100, 5.0, skill=d['sub_ac_install'])
        res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}&sub_service_id={d['sub_ac_refill'].id}")
        assert len(res.data['results']) == 0

    def test_garbage_payload_fuzzing(self, client, setup_data):
        d = setup_data
        self._create_persona(d['cust_lat'], d['cust_lng'], 10, 5.0, skill=d['sub_ac_refill'])
        res1 = client.get(f"{d['url']}?lat=DROP_TABLE&lng=NULL")
        assert res1.status_code == 200
        res2 = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}&service_id=99999999")
        assert res2.status_code == 200

    def test_n_plus_one_and_serializer_contract(self, client, setup_data, django_assert_num_queries):
        d = setup_data
        for _ in range(10):
            self._create_persona(d['cust_lat'], d['cust_lng'], 5, 4.0, skill=d['sub_ac_refill'])
        
        # Paginated response does an extra COUNT(*) query usually.
        # 1 for count, 1 for platform_avg, 1 for main tech query, 2 for prefetches.
        # Plus 1 for Service lookup in intent_selector
        # Total = 6 queries.
        with django_assert_num_queries(6):
            res = client.get(f"{d['url']}?lat={d['cust_lat']}&lng={d['cust_lng']}&service_id={d['service_ac'].id}")
        
        assert res.status_code == 200
        assert 'distance_km' in res.data['results'][0]

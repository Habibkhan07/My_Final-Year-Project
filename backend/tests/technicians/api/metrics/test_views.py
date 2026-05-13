import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory

pytestmark = pytest.mark.django_db


class TestTechnicianMetricsView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-metrics')

    def test_unauthenticated_returns_401(self):
        response = self.client.get(self.url)
        assert response.status_code == 401

    def test_non_technician_returns_403(self):
        user = UserFactory()  # no TechnicianProfile attached
        self.client.force_authenticate(user=user)

        response = self.client.get(self.url)

        assert response.status_code == 403
        body = response.json()
        assert body['code'] == 'permission_denied'

    def test_default_period_is_week(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url)

        assert response.status_code == 200
        body = response.json()
        assert body['period'] == 'week'
        assert len(body['buckets']) == 7

    @pytest.mark.parametrize('period,expected_buckets', [
        ('day', 7),
        ('week', 7),
        ('month', 30),
        ('year', 12),
    ])
    def test_period_query_param_picks_buckets(self, period, expected_buckets):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url, {'period': period})

        assert response.status_code == 200
        body = response.json()
        assert body['period'] == period
        assert len(body['buckets']) == expected_buckets

    def test_invalid_period_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.get(self.url, {'period': 'century'})

        assert response.status_code == 400
        body = response.json()
        assert body['code'] == 'validation_error'
        assert 'period' in body['errors']

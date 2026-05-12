"""Coverage for GET /api/technicians/me/quotable-sub-services/

Cases pinned:
  * 401 unauthenticated.
  * 403 logged-in user with no TechnicianProfile.
  * 400 missing / non-int service_id.
  * 200 happy path returns only skills under the requested service.
  * 200 cross-tech isolation — another tech's skills never leak.
  * 200 empty list for a service the tech has no skill in.
  * Ordering: fixed-price first, then name asc.
"""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.catalog import (
    FixedPriceSubServiceFactory,
    LaborSubServiceFactory,
    ServiceFactory,
    SubServiceFactory,
)
from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianSkillFactory,
)

pytestmark = pytest.mark.django_db


class TestQuotableSubServicesView:
    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('quotable-sub-services')

    # ------------------------------------------------------------------
    # auth + identity
    # ------------------------------------------------------------------

    def test_unauthenticated(self):
        response = self.client.get(self.url, {'service_id': 1})
        assert response.status_code == 401

    def test_not_a_technician(self):
        user = UserFactory()
        self.client.force_authenticate(user=user)
        response = self.client.get(self.url, {'service_id': 1})
        assert response.status_code == 403
        body = response.json()
        assert body['code'] == 'permission_denied'

    # ------------------------------------------------------------------
    # input validation
    # ------------------------------------------------------------------

    def test_missing_service_id(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url)
        assert response.status_code == 400
        body = response.json()
        assert body['code'] == 'validation_error'
        assert 'service_id' in body['errors']

    def test_non_integer_service_id(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url, {'service_id': 'abc'})
        assert response.status_code == 400
        body = response.json()
        assert body['code'] == 'validation_error'

    # ------------------------------------------------------------------
    # happy path
    # ------------------------------------------------------------------

    def test_returns_only_techs_skills_under_the_requested_service(self):
        ac = ServiceFactory(name='AC Repair')
        plumbing = ServiceFactory(name='Plumbing')

        ac_gig = FixedPriceSubServiceFactory(service=ac, name='Gas Refill', base_price=2500)
        ac_labor = LaborSubServiceFactory(service=ac, name='Diagnostic')
        plumbing_gig = SubServiceFactory(service=plumbing, name='Leak Fix')

        tech = TechnicianProfileFactory()
        # Tech is qualified on both AC sub-services but not the plumbing one.
        TechnicianSkillFactory(technician=tech, sub_service=ac_gig)
        TechnicianSkillFactory(technician=tech, sub_service=ac_labor)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url, {'service_id': ac.id})
        assert response.status_code == 200

        body = response.json()
        ids = {row['id'] for row in body}
        assert ids == {ac_gig.id, ac_labor.id}
        assert plumbing_gig.id not in ids

    def test_cross_tech_isolation(self):
        ac = ServiceFactory(name='AC Repair')
        gig = FixedPriceSubServiceFactory(service=ac)

        me = TechnicianProfileFactory()
        them = TechnicianProfileFactory()
        # The OTHER tech holds the skill, not us.
        TechnicianSkillFactory(technician=them, sub_service=gig)

        self.client.force_authenticate(user=me.user)
        response = self.client.get(self.url, {'service_id': ac.id})
        assert response.status_code == 200
        assert response.json() == []

    def test_empty_when_tech_has_no_skill_under_this_service(self):
        ac = ServiceFactory(name='AC Repair')
        plumbing = ServiceFactory(name='Plumbing')
        plumbing_gig = SubServiceFactory(service=plumbing)

        tech = TechnicianProfileFactory()
        TechnicianSkillFactory(technician=tech, sub_service=plumbing_gig)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url, {'service_id': ac.id})
        assert response.status_code == 200
        assert response.json() == []

    # ------------------------------------------------------------------
    # serializer contract
    # ------------------------------------------------------------------

    def test_response_payload_shape(self):
        ac = ServiceFactory()
        gig = FixedPriceSubServiceFactory(
            service=ac, name='Gas Refill', base_price=2500,
        )
        tech = TechnicianProfileFactory()
        TechnicianSkillFactory(technician=tech, sub_service=gig)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url, {'service_id': ac.id})
        body = response.json()
        assert len(body) == 1
        row = body[0]
        assert set(row.keys()) == {
            'id',
            'name',
            'base_price',
            'max_price',
            'is_fixed_price',
        }
        assert row['name'] == 'Gas Refill'
        assert row['is_fixed_price'] is True
        # Fixed-price rows ship `max_price=None` so the frontend can
        # detect "lock the price field" without re-checking the bool.
        assert row['max_price'] is None

    # ------------------------------------------------------------------
    # ordering
    # ------------------------------------------------------------------

    def test_ordering_fixed_first_then_name(self):
        ac = ServiceFactory()
        # Build deliberately out-of-order rows.
        a_labor = LaborSubServiceFactory(service=ac, name='A Diagnostic')
        z_fixed = FixedPriceSubServiceFactory(service=ac, name='Z Gas Refill')
        m_fixed = FixedPriceSubServiceFactory(service=ac, name='M Compressor')
        b_labor = LaborSubServiceFactory(service=ac, name='B Cleaning')

        tech = TechnicianProfileFactory()
        for sub in (a_labor, z_fixed, m_fixed, b_labor):
            TechnicianSkillFactory(technician=tech, sub_service=sub)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url, {'service_id': ac.id})
        names = [row['name'] for row in response.json()]
        # Fixed-price first (M before Z by name), then labor (A before B).
        assert names == ['M Compressor', 'Z Gas Refill', 'A Diagnostic', 'B Cleaning']

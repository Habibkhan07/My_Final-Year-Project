"""HTTP-level tests for ``/api/technicians/me/skills/``.

Mirrors the work_location test layout — pytest + factory_boy +
APIClient, no DRF APITestCase. Every authenticated path resolves the
caller's ``TechnicianProfile`` from ``request.user``, so the tests
seed a fresh user per case and force-authenticate via APIClient.
"""
from __future__ import annotations

import pytest
from django.urls import reverse
from rest_framework.test import APIClient

from technicians.models import TechnicianSkill
from tests.factories.accounts import UserFactory
from tests.factories.catalog import ServiceFactory, SubServiceFactory
from tests.factories.technicians import (
    TechnicianProfileFactory,
    TechnicianServiceLicenseFactory,
    TechnicianSkillFactory,
)


def _enable_category(tech, sub):
    """Seed a ``TechnicianServiceLicense`` row for the sub's parent
    service so the add-skill category gate passes. The license picture
    defaults to None — the gate cares only about row existence."""
    TechnicianServiceLicenseFactory(technician=tech, service=sub.service)

pytestmark = pytest.mark.django_db


class TestMySkillsListView:
    """``GET /api/technicians/me/skills/``"""

    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-my-skills')

    def test_unauthenticated_returns_401(self):
        assert self.client.get(self.url).status_code == 401

    def test_pure_customer_returns_403_envelope(self):
        """A logged-in user with no ``tech_profile`` should get the
        standard ``permission_denied`` envelope, NOT a 500 from the
        OneToOne lookup."""
        self.client.force_authenticate(user=UserFactory())

        response = self.client.get(self.url)

        assert response.status_code == 403
        body = response.json()
        assert body['code'] == 'permission_denied'
        assert 'user' in body['errors']

    def test_lists_my_skills_grouped_by_service(self):
        tech = TechnicianProfileFactory()
        ac_service = ServiceFactory(name='AC Service')
        plumbing_service = ServiceFactory(name='Plumbing')
        sub_b = SubServiceFactory(service=ac_service, name='Gas Refill')
        sub_a = SubServiceFactory(service=ac_service, name='Coil Clean')
        sub_c = SubServiceFactory(service=plumbing_service, name='Leak Fix')
        TechnicianSkillFactory(technician=tech, sub_service=sub_b)
        TechnicianSkillFactory(technician=tech, sub_service=sub_a)
        TechnicianSkillFactory(technician=tech, sub_service=sub_c)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url)

        assert response.status_code == 200
        rows = response.json()
        # Ordering: service name asc, then sub-service name asc.
        # AC Service: Coil Clean, Gas Refill; then Plumbing: Leak Fix.
        names = [r['sub_service']['name'] for r in rows]
        assert names == ['Coil Clean', 'Gas Refill', 'Leak Fix']

    def test_lists_only_my_skills_not_other_techs(self):
        """IDOR sanity: another tech's skills are never in my list."""
        me = TechnicianProfileFactory()
        other = TechnicianProfileFactory()
        mine = SubServiceFactory(name='Mine')
        theirs = SubServiceFactory(name='Theirs')
        TechnicianSkillFactory(technician=me, sub_service=mine)
        TechnicianSkillFactory(technician=other, sub_service=theirs)

        self.client.force_authenticate(user=me.user)
        rows = self.client.get(self.url).json()

        names = [r['sub_service']['name'] for r in rows]
        assert names == ['Mine']

    def test_read_shape_includes_nested_service(self):
        tech = TechnicianProfileFactory()
        service = ServiceFactory(name='HVAC', icon_name='hvac_icon')
        sub = SubServiceFactory(
            service=service,
            name='Inverter Repair',
            icon_name='inverter',
            is_fixed_price=True,
        )
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        self.client.force_authenticate(user=tech.user)
        row = self.client.get(self.url).json()[0]

        assert row['sub_service']['name'] == 'Inverter Repair'
        assert row['sub_service']['icon_name'] == 'inverter'
        assert row['sub_service']['is_fixed_price'] is True
        assert row['sub_service']['service']['name'] == 'HVAC'
        assert row['sub_service']['service']['icon_name'] == 'hvac_icon'

    def test_list_has_no_n_plus_one(
        self, django_assert_max_num_queries,
    ):
        """Selector uses ``select_related('sub_service__service')`` so 20
        skills resolve in a single JOIN. We assert MAX queries (not
        ==) because the test client's auth lookup behaviour is
        environment-sensitive — what matters here is the absence of
        per-row sub-queries, i.e. no growth as rows scale."""
        tech = TechnicianProfileFactory()
        for _ in range(20):
            TechnicianSkillFactory(technician=tech)

        self.client.force_authenticate(user=tech.user)
        with django_assert_max_num_queries(5):
            response = self.client.get(self.url)
            assert response.status_code == 200
            assert len(response.json()) == 20


class TestMySkillsCreateView:
    """``POST /api/technicians/me/skills/``"""

    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-my-skills')

    def test_unauthenticated_returns_401(self):
        response = self.client.post(self.url, data={'sub_service_id': 1}, format='json')
        assert response.status_code == 401

    def test_pure_customer_returns_403(self):
        self.client.force_authenticate(user=UserFactory())
        response = self.client.post(self.url, data={'sub_service_id': 1}, format='json')
        assert response.status_code == 403

    def test_post_creates_skill_with_null_labor_rate_and_zero_years(self):
        """Contract: the add endpoint never collects labor_rate or years.
        Both must be set to safe defaults by the service."""
        tech = TechnicianProfileFactory()
        sub = SubServiceFactory()
        _enable_category(tech, sub)
        # Tech has >= 1 skill (matches the BE invariant).
        TechnicianSkillFactory(technician=tech)

        self.client.force_authenticate(user=tech.user)
        response = self.client.post(
            self.url,
            data={'sub_service_id': sub.id},
            format='json',
        )

        assert response.status_code == 201
        body = response.json()
        assert body['sub_service']['id'] == sub.id

        row = TechnicianSkill.objects.get(technician=tech, sub_service=sub)
        assert row.labor_rate is None
        assert row.years_of_experience == 0

    def test_post_duplicate_returns_409(self):
        tech = TechnicianProfileFactory()
        sub = SubServiceFactory()
        _enable_category(tech, sub)
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        self.client.force_authenticate(user=tech.user)
        response = self.client.post(
            self.url,
            data={'sub_service_id': sub.id},
            format='json',
        )

        assert response.status_code == 409
        body = response.json()
        assert body['code'] == 'duplicate_skill'

    def test_post_unknown_sub_service_returns_404(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(
            self.url,
            data={'sub_service_id': 999999},
            format='json',
        )

        assert response.status_code == 404

    def test_post_invalid_payload_returns_400(self):
        tech = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech.user)

        response = self.client.post(self.url, data={}, format='json')

        assert response.status_code == 400
        assert 'sub_service_id' in response.json()['errors']

    def test_post_new_category_returns_403_category_not_allowed(self):
        """The category gate: a tech without a ``TechnicianServiceLicense``
        row for the sub-service's parent service is rejected with a
        typed 403 envelope. Closes the bypass where any approved tech
        could silently jump categories without admin re-evaluation.
        """
        tech = TechnicianProfileFactory()
        # Tech opted into Plumbing at onboarding (license row exists)
        # but tries to add an HVAC skill (no HVAC license).
        plumbing = ServiceFactory(name='Plumbing')
        hvac = ServiceFactory(name='HVAC')
        plumbing_sub = SubServiceFactory(service=plumbing)
        hvac_sub = SubServiceFactory(service=hvac)
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        TechnicianSkillFactory(technician=tech, sub_service=plumbing_sub)

        self.client.force_authenticate(user=tech.user)
        response = self.client.post(
            self.url,
            data={'sub_service_id': hvac_sub.id},
            format='json',
        )

        assert response.status_code == 403
        body = response.json()
        assert body['code'] == 'category_not_allowed'
        # Service name is in the errors map so the FE can name the
        # category in the snackbar.
        assert body['errors']['service_name'] == ['HVAC']
        # Row must NOT have been written — the guard fires before
        # the create.
        assert not TechnicianSkill.objects.filter(
            technician=tech, sub_service=hvac_sub,
        ).exists()


class TestMySkillsDeleteView:
    """``DELETE /api/technicians/me/skills/<sub_service_id>/``"""

    def setup_method(self):
        self.client = APIClient()

    def _url(self, sub_service_id: int) -> str:
        return reverse(
            'tech-my-skills-detail',
            kwargs={'sub_service_id': sub_service_id},
        )

    def test_unauthenticated_returns_401(self):
        assert self.client.delete(self._url(1)).status_code == 401

    def test_pure_customer_returns_403(self):
        self.client.force_authenticate(user=UserFactory())
        assert self.client.delete(self._url(1)).status_code == 403

    def test_delete_happy_path(self):
        tech = TechnicianProfileFactory()
        keep = SubServiceFactory()
        drop = SubServiceFactory()
        TechnicianSkillFactory(technician=tech, sub_service=keep)
        TechnicianSkillFactory(technician=tech, sub_service=drop)

        self.client.force_authenticate(user=tech.user)
        response = self.client.delete(self._url(drop.id))

        assert response.status_code == 204
        assert not TechnicianSkill.objects.filter(
            technician=tech, sub_service=drop,
        ).exists()
        assert TechnicianSkill.objects.filter(
            technician=tech, sub_service=keep,
        ).exists()

    def test_delete_last_skill_returns_400(self):
        """Removing the tech's last skill is rejected — they would be
        invisible to the matchmaker, which is a silent failure mode."""
        tech = TechnicianProfileFactory()
        only_one = SubServiceFactory()
        TechnicianSkillFactory(technician=tech, sub_service=only_one)

        self.client.force_authenticate(user=tech.user)
        response = self.client.delete(self._url(only_one.id))

        assert response.status_code == 400
        body = response.json()
        assert body['code'] == 'last_skill_required'
        # Row must remain — the guard fires before the delete.
        assert TechnicianSkill.objects.filter(
            technician=tech, sub_service=only_one,
        ).exists()

    def test_delete_unknown_skill_returns_404(self):
        tech = TechnicianProfileFactory()
        # Tech has SOME skills (so the last-skill guard isn't what
        # rejects it) but not the one being deleted.
        TechnicianSkillFactory(technician=tech)
        unrelated = SubServiceFactory()

        self.client.force_authenticate(user=tech.user)
        response = self.client.delete(self._url(unrelated.id))

        assert response.status_code == 404

    def test_delete_other_techs_skill_returns_404_not_403(self):
        """IDOR: passing another tech's sub_service id just looks like
        a missing bridge row for the caller. No information leak."""
        me = TechnicianProfileFactory()
        TechnicianSkillFactory(technician=me)
        other = TechnicianProfileFactory()
        their_sub = SubServiceFactory()
        TechnicianSkillFactory(technician=other, sub_service=their_sub)

        self.client.force_authenticate(user=me.user)
        response = self.client.delete(self._url(their_sub.id))

        assert response.status_code == 404
        # Other tech's skill must be untouched.
        assert TechnicianSkill.objects.filter(
            technician=other, sub_service=their_sub,
        ).exists()


class TestMyServiceCategoriesView:
    """``GET /api/technicians/me/service-categories/`` — picker catalog."""

    def setup_method(self):
        self.client = APIClient()
        self.url = reverse('tech-service-categories')

    def test_unauthenticated_returns_401(self):
        assert self.client.get(self.url).status_code == 401

    def test_pure_customer_returns_403(self):
        self.client.force_authenticate(user=UserFactory())
        assert self.client.get(self.url).status_code == 403

    def test_returns_only_licensed_categories(self):
        """The catalog is filtered to parent services the tech holds
        a ``TechnicianServiceLicense`` row for. Other services in the
        catalog must not leak through, even if the tech has skills
        under them (impossible in practice, but the gate is on the
        license table, not the skill table)."""
        tech = TechnicianProfileFactory()
        plumbing = ServiceFactory(name='Plumbing', icon_name='pipe')
        hvac = ServiceFactory(name='HVAC', icon_name='ac')
        electrical = ServiceFactory(name='Electrical')  # not licensed

        SubServiceFactory(service=plumbing, name='Leak Fix')
        SubServiceFactory(service=plumbing, name='Drain Clean')
        SubServiceFactory(service=hvac, name='Gas Refill')
        SubServiceFactory(service=electrical, name='Wiring')

        # Tech opted into Plumbing + HVAC at onboarding.
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        TechnicianServiceLicenseFactory(technician=tech, service=hvac)

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url)

        assert response.status_code == 200
        body = response.json()
        # Only licensed categories appear; ordering is service.name asc.
        names = [s['name'] for s in body]
        assert names == ['HVAC', 'Plumbing']
        # Each service exposes its full sub_services list — the gate
        # is on the parent service, not on the sub-service rows.
        plumbing_subs = [s['name'] for s in body[1]['sub_services']]
        assert sorted(plumbing_subs) == ['Drain Clean', 'Leak Fix']

    def test_returns_licensed_category_even_with_no_current_skills(self):
        """The key behavior that makes license-as-source-of-truth
        defensible: a tech who dropped all skills under a category
        STILL sees that category in the picker — the license row
        survives skill churn."""
        tech = TechnicianProfileFactory()
        plumbing = ServiceFactory(name='Plumbing')
        electrical = ServiceFactory(name='Electrical')

        SubServiceFactory(service=plumbing, name='Leak Fix')
        electrical_sub = SubServiceFactory(service=electrical, name='Wiring')

        # Tech opted into Plumbing at onboarding (license row exists)
        # but currently has ZERO Plumbing skills. They DO have an
        # Electrical skill (to satisfy the >= 1 skill invariant).
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        TechnicianServiceLicenseFactory(technician=tech, service=electrical)
        TechnicianSkillFactory(technician=tech, sub_service=electrical_sub)

        self.client.force_authenticate(user=tech.user)
        body = self.client.get(self.url).json()

        names = [s['name'] for s in body]
        # Plumbing must appear even though the tech has no Plumbing
        # skills right now — the license row is the gate anchor.
        assert 'Plumbing' in names
        assert 'Electrical' in names

    def test_wire_shape_includes_icon_and_fixed_price(self):
        """Wire contract: icon_name on both levels, is_fixed_price on
        sub-services. Matches the FE's AvailableServiceModel parser."""
        tech = TechnicianProfileFactory()
        service = ServiceFactory(name='HVAC', icon_name='hvac_icon')
        SubServiceFactory(
            service=service,
            name='Inverter Repair',
            icon_name='inverter',
            is_fixed_price=True,
        )
        TechnicianServiceLicenseFactory(technician=tech, service=service)

        self.client.force_authenticate(user=tech.user)
        body = self.client.get(self.url).json()

        assert body[0]['icon_name'] == 'hvac_icon'
        # Verify the surfaced sub-service entry — there's only one
        # under HVAC in this test, and the wire contract carries
        # icon_name + is_fixed_price.
        inverter = next(
            s for s in body[0]['sub_services'] if s['name'] == 'Inverter Repair'
        )
        assert inverter['icon_name'] == 'inverter'
        assert inverter['is_fixed_price'] is True

    def test_returns_empty_when_no_licenses(self):
        """Defensive case: a tech with zero license rows sees an
        empty catalog. Should be unreachable in practice (onboarding
        auto-creates license rows for every parent service the tech
        picked skills under), but covered for contract fidelity."""
        tech = TechnicianProfileFactory()
        # Tech has skills but somehow no licenses (out-of-band admin
        # state). Catalog has services but none are licensed for this
        # tech.
        TechnicianSkillFactory(technician=tech)
        ServiceFactory(name='Plumbing')

        self.client.force_authenticate(user=tech.user)
        response = self.client.get(self.url)

        assert response.status_code == 200
        assert response.json() == []

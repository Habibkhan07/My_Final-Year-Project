"""Service-layer tests for ``technicians.services.skills_service``.

The HTTP tests already exercise the happy path end-to-end; this file
focuses on the rules the service enforces independent of the wire:
defaults applied on add, the duplicate guard, and the last-skill guard
on remove (including its interaction with select_for_update).
"""
from __future__ import annotations

import pytest
from rest_framework.exceptions import NotFound

from technicians.exceptions import (
    DuplicateSkillError,
    LastSkillRequiredError,
    ServiceCategoryNotAllowedError,
)
from technicians.models import TechnicianSkill
from technicians.services.skills_service import add_skill, remove_skill
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


class TestAddSkill:
    def test_creates_row_with_safe_defaults(self):
        """The CRUD endpoint never collects labor_rate or years — the
        service must write NULL / 0 so the column contract stays
        unambiguous for the onboarding-refactor migration."""
        tech = TechnicianProfileFactory()
        sub = SubServiceFactory()
        # Seed a license row under the same parent so the category
        # gate passes. Also seed a skill so the tech satisfies the
        # >=1 skill invariant (a real BE state never has zero skills).
        _enable_category(tech, sub)
        TechnicianSkillFactory(technician=tech)

        skill = add_skill(technician=tech, sub_service_id=sub.id)

        assert skill.labor_rate is None
        assert skill.years_of_experience == 0
        assert skill.sub_service_id == sub.id

    def test_unknown_sub_service_raises_not_found(self):
        tech = TechnicianProfileFactory()
        with pytest.raises(NotFound):
            add_skill(technician=tech, sub_service_id=999999)

    def test_duplicate_raises_typed_409(self):
        tech = TechnicianProfileFactory()
        sub = SubServiceFactory()
        _enable_category(tech, sub)
        TechnicianSkillFactory(technician=tech, sub_service=sub)

        with pytest.raises(DuplicateSkillError):
            add_skill(technician=tech, sub_service_id=sub.id)

    def test_new_category_raises_typed_403(self):
        """The category gate: a tech without a ``TechnicianServiceLicense``
        row for the sub-service's parent service cannot add the skill,
        even if every other check would pass.

        The guard fires BEFORE the duplicate check and BEFORE the
        create — verified by the absence of a TechnicianSkill row
        after the failed call.
        """
        tech = TechnicianProfileFactory()
        plumbing = ServiceFactory(name='Plumbing')
        hvac = ServiceFactory(name='HVAC')
        plumbing_sub = SubServiceFactory(service=plumbing)
        # Tech opted into Plumbing at onboarding (license row exists).
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        TechnicianSkillFactory(technician=tech, sub_service=plumbing_sub)
        # HVAC is a new category for them.
        new_category_sub = SubServiceFactory(service=hvac)

        with pytest.raises(ServiceCategoryNotAllowedError):
            add_skill(technician=tech, sub_service_id=new_category_sub.id)

        assert not TechnicianSkill.objects.filter(
            technician=tech, sub_service=new_category_sub,
        ).exists()

    def test_category_gate_allows_under_licensed_service(self):
        """Sanity check on the positive case: adding a NEW sub-service
        under a service the tech holds a license row for must succeed.
        This is the "expand within your onboarded category" happy path.
        """
        tech = TechnicianProfileFactory()
        plumbing = ServiceFactory(name='Plumbing')
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        held = SubServiceFactory(service=plumbing, name='Leak Fix')
        new = SubServiceFactory(service=plumbing, name='Drain Clean')
        TechnicianSkillFactory(technician=tech, sub_service=held)

        skill = add_skill(technician=tech, sub_service_id=new.id)

        assert skill.sub_service_id == new.id

    def test_category_gate_decoupled_from_current_skills(self):
        """A tech who opted into Plumbing but has zero current skills
        under it can still add a Plumbing sub-service — the license
        row survives skill churn. This is the key behavior that
        makes the license-table-as-source-of-truth design defensible:
        "which categories did I opt into" is independent of "what
        skills do I currently offer".

        We seed a skill under an UNRELATED service to satisfy the
        ``>= 1`` skill invariant without affecting the gate decision.
        """
        tech = TechnicianProfileFactory()
        plumbing = ServiceFactory(name='Plumbing')
        electrical = ServiceFactory(name='Electrical')
        TechnicianServiceLicenseFactory(technician=tech, service=plumbing)
        # Tech currently offers an Electrical skill (so they're not at
        # zero skills); no Plumbing skills at all right now.
        electrical_sub = SubServiceFactory(service=electrical)
        TechnicianSkillFactory(technician=tech, sub_service=electrical_sub)

        # Re-adding into Plumbing should work because the license row
        # is the gate, not the current skill set.
        plumbing_sub = SubServiceFactory(service=plumbing)
        skill = add_skill(technician=tech, sub_service_id=plumbing_sub.id)

        assert skill.sub_service_id == plumbing_sub.id


class TestRemoveSkill:
    def test_removes_existing_row(self):
        tech = TechnicianProfileFactory()
        keep = SubServiceFactory()
        drop = SubServiceFactory()
        TechnicianSkillFactory(technician=tech, sub_service=keep)
        TechnicianSkillFactory(technician=tech, sub_service=drop)

        remove_skill(technician=tech, sub_service_id=drop.id)

        assert not TechnicianSkill.objects.filter(
            technician=tech, sub_service=drop,
        ).exists()

    def test_missing_skill_raises_not_found(self):
        tech = TechnicianProfileFactory()
        TechnicianSkillFactory(technician=tech)
        unrelated_sub = SubServiceFactory()

        with pytest.raises(NotFound):
            remove_skill(technician=tech, sub_service_id=unrelated_sub.id)

    def test_last_skill_raises_typed_error(self):
        """Min=1 invariant: a tech with zero skills is invisible to the
        matchmaker. The guard fires BEFORE the row is deleted so the
        FE retry path is safe — the row must still exist after the
        failed call."""
        tech = TechnicianProfileFactory()
        only = SubServiceFactory()
        TechnicianSkillFactory(technician=tech, sub_service=only)

        with pytest.raises(LastSkillRequiredError):
            remove_skill(technician=tech, sub_service_id=only.id)

        # The row survives the guard.
        assert TechnicianSkill.objects.filter(
            technician=tech, sub_service=only,
        ).exists()

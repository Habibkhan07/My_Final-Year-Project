"""Tech-side skills add/remove writes.

Backs ``POST`` and ``DELETE`` on ``/api/technicians/me/skills/``. The
endpoint scopes every operation to ``request.user.tech_profile`` — no
``technician_id`` ever crosses the wire — so the service stays
IDOR-free by construction.

Add-flow rules:
  * **Category gate** — the parent service must be in the tech's
    onboarded categories (a ``TechnicianServiceLicense`` row exists
    for it). Fires BEFORE the duplicate check; raises
    ``ServiceCategoryNotAllowedError`` (HTTP 403,
    ``category_not_allowed``).
  * ``years_of_experience`` defaults to 0; the UI does not collect it.
  * ``labor_rate`` is written as NULL. The column stays on the model
    for back-compat with bookings/pricing; the onboarding refactor
    session will decide whether to drop it or move it to per-quote.
  * Duplicate ``(technician, sub_service)`` raises
    ``DuplicateSkillError`` (HTTP 409, ``duplicate_skill``).

Remove-flow rules:
  * Minimum **one** skill — mirrors the ``validate_skills`` rule on the
    onboarding serializer. A tech with zero skills is invisible to the
    matchmaker and would silently lose all incoming jobs. Triggers
    ``LastSkillRequiredError`` (HTTP 400, ``last_skill_required``).
  * The parent ``TechnicianProfile`` row is taken under
    ``select_for_update`` so two concurrent removes for different
    sub-services cannot race past the count guard.
"""
from __future__ import annotations

from django.db import IntegrityError, transaction
from rest_framework.exceptions import NotFound

from catalog.models import SubService

from ..exceptions import (
    DuplicateSkillError,
    LastSkillRequiredError,
    ServiceCategoryNotAllowedError,
)
from ..models import TechnicianProfile, TechnicianServiceLicense, TechnicianSkill


def add_skill(
    *,
    technician: TechnicianProfile,
    sub_service_id: int,
) -> TechnicianSkill:
    """Attach a sub-service to the technician's skill set.

    SECURITY: ``technician`` is resolved upstream from
    ``request.user.tech_profile``; the caller cannot inject another
    tech's id.

    Raises:
      NotFound — when ``sub_service_id`` does not resolve to a row.
      ServiceCategoryNotAllowedError — when the sub-service's parent
        service is not one the tech opted into at onboarding (no
        matching ``TechnicianServiceLicense`` row). Fires BEFORE the
        duplicate check.
      DuplicateSkillError — when the bridge row already exists.
    """
    with transaction.atomic():
        # Resolve the catalog row first so a bad id surfaces as a clean
        # 404 instead of a 500 IntegrityError from the FK below.
        try:
            sub_service = SubService.objects.select_related('service').get(
                id=sub_service_id,
            )
        except SubService.DoesNotExist:
            raise NotFound(detail='Sub-service not found.')

        # Category gate. A tech may only add sub-services whose PARENT
        # service is in the set of categories they opted into at
        # onboarding — encoded by the ``TechnicianServiceLicense`` row
        # set. The onboarding finalize service auto-creates one license
        # row per parent service the tech picked skills under (the
        # ``license_picture`` is optional, the ROW is the gate anchor),
        # so every approved tech has a non-empty license row set.
        #
        # Decoupling row-existence from picture-existence is what makes
        # this anchor universally evaluable — earlier iterations gated
        # on either ``TechnicianSkill.sub_service__service`` (couldn't
        # express "category opted into but currently no skills there")
        # or on a strict picture-required license (locked out the
        # license-less). The license-row anchor handles both.
        #
        # Effect: a plumber-onboarded tech can keep adding plumbing
        # sub-services freely; if they drop every plumbing skill they
        # can still re-add (the license row survives the skill churn);
        # trying to add AC Repair when they never picked HVAC at
        # onboarding gets a clean 403.
        works_in_category = TechnicianServiceLicense.objects.filter(
            technician=technician,
            service=sub_service.service,
        ).exists()
        if not works_in_category:
            raise ServiceCategoryNotAllowedError(
                service_name=sub_service.service.name,
            )

        # Pre-check the duplicate so the response is a typed 409 rather
        # than a raw IntegrityError from the ``unique_together`` index.
        # The check + create still race in principle; the second-attempt
        # catch below covers the (small) gap.
        already_have_it = TechnicianSkill.objects.filter(
            technician=technician,
            sub_service=sub_service,
        ).exists()
        if already_have_it:
            raise DuplicateSkillError(sub_service_id=sub_service_id)

        try:
            skill = TechnicianSkill.objects.create(
                technician=technician,
                sub_service=sub_service,
                years_of_experience=0,
                labor_rate=None,
            )
        except IntegrityError:
            # The ``unique_together`` index would surface as an
            # ``IntegrityError`` if the pre-check raced. Re-cast to the
            # typed duplicate so the view layer stays simple. Narrowed
            # from a bare ``except Exception`` so transient DB errors
            # (deadlocks, connection drops) no longer masquerade as
            # ``duplicate_skill``.
            raise DuplicateSkillError(sub_service_id=sub_service_id)

        return skill


def remove_skill(
    *,
    technician: TechnicianProfile,
    sub_service_id: int,
) -> None:
    """Detach a sub-service from the technician's skill set.

    SECURITY: scoped to ``technician`` from the auth layer.

    Raises:
      NotFound — when no bridge row exists for this
        (technician, sub_service) pair.
      LastSkillRequiredError — when removing this row would leave the
        tech with zero skills.
    """
    with transaction.atomic():
        # Lock the PARENT ``TechnicianProfile`` row to serialize all
        # remove operations for this tech. Locking only the target skill
        # row would not protect the count guard below: two concurrent
        # removes for *different* sub-services would each lock their own
        # row, each snapshot-read ``count() == 2`` (REPEATABLE READ on
        # InnoDB), each pass the ``<= 1`` guard, and both commit — the
        # tech ends up with zero skills, silently invisible to the
        # matchmaker. The profile-row lock makes the count + delete
        # atomic per tech without serializing across the whole table.
        TechnicianProfile.objects.select_for_update().get(pk=technician.pk)

        try:
            skill = TechnicianSkill.objects.get(
                technician=technician,
                sub_service_id=sub_service_id,
            )
        except TechnicianSkill.DoesNotExist:
            raise NotFound(detail='Skill not found.')

        # Last-skill guard. Mirrors onboarding's ``validate_skills``
        # contract: a tech with zero skills is invisible to the
        # matchmaker and would silently lose every incoming dispatch.
        remaining = (
            TechnicianSkill.objects
            .filter(technician=technician)
            .count()
        )
        if remaining <= 1:
            raise LastSkillRequiredError()

        skill.delete()


__all__ = ['add_skill', 'remove_skill']

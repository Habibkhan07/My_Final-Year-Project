"""Selector for the tech-side quote builder catalog dropdown.

Returns the sub-services a given technician can legitimately attach to a
quote — i.e. sub-services they hold a `TechnicianSkill` row for. Scoped
to the booking's parent service so the dropdown is short and on-topic.

SECURITY: filtering is by the *authenticated* technician's profile only.
The view never accepts a `technician_id` path/query param; the id is
derived from `request.user.tech_profile`. Without this scope, a tech
could enumerate another tech's skills (mild PII leak about who knows
what) or — worse — assemble a quote from sub-services they aren't
licensed for, bypassing the marketplace's qualification gate.
"""
from __future__ import annotations

from typing import Iterable

from catalog.models import SubService
from technicians.models import TechnicianProfile


def list_quotable_sub_services(
    *,
    technician: TechnicianProfile,
    service_id: int,
) -> Iterable[SubService]:
    """Sub-services the technician can charge for, under a given parent service.

    Returns rows ordered by:
      1. ``is_fixed_price`` desc — fixed gigs first (they're the customer's
         primary booking surface; the tech's mental model also lists them
         before labor),
      2. ``name`` asc — alphabetical secondary so the dropdown is
         predictable.

    The filter routes through ``TechnicianProfile.skills`` (M2M through
    ``TechnicianSkill``, ``related_name='technicians'`` on the reverse).
    ``.distinct()`` is required because the M2M join can multiply rows if
    a skill row exists more than once (it shouldn't, but the bridge has
    no uniqueness constraint at the DB level).
    """
    return (
        SubService.objects
        .filter(
            service_id=service_id,
            technicians=technician,
        )
        .order_by('-is_fixed_price', 'name')
        .distinct()
    )


__all__ = ['list_quotable_sub_services']

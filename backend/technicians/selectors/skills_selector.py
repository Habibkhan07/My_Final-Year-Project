"""Selectors for tech-side skills CRUD.

The technician's profile-tab "My Skills" surface reads from here.
All queries are scoped to the calling technician — the views never
accept a ``technician_id`` param, so IDOR is structurally impossible.

Pricing column ``TechnicianSkill.labor_rate`` is not surfaced through
these selectors. New rows added via the CRUD endpoint write NULL;
existing rows (seeded via the onboarding finalize path) keep their
value until the onboarding refactor decides on the migration. Either
way the labor-rate read/write contract is owned by bookings/pricing,
not by this selector — see ``bookings/selectors/pricing_selector.py``.
"""
from __future__ import annotations

from django.db.models import Prefetch, QuerySet

from catalog.models import Service, SubService
from technicians.models import (
    TechnicianProfile,
    TechnicianServiceLicense,
    TechnicianSkill,
)


def list_my_skills(*, technician: TechnicianProfile) -> QuerySet[TechnicianSkill]:
    """Return the technician's skill rows, with sub_service + service prefetched.

    Ordering:
      1. parent service name (alphabetical) so the FE can render a
         service-grouped list without a second pass,
      2. sub-service name (alphabetical secondary).

    ``select_related`` walks the FK chain in a single JOIN so the FE's
    nested serializer never triggers N+1. Tested via
    ``django_assert_max_num_queries`` in ``test_api.py``.
    """
    return (
        TechnicianSkill.objects
        .filter(technician=technician)
        .select_related('sub_service__service')
        .order_by('sub_service__service__name', 'sub_service__name')
    )


def list_my_service_categories(
    *,
    technician: TechnicianProfile,
) -> list[dict]:
    """Return the service tree filtered to the tech's onboarded categories.

    "Onboarded category" = a parent ``Service`` for which the tech
    holds a ``TechnicianServiceLicense`` row. The onboarding finalize
    service auto-creates one row per parent service the tech picked
    skills under, so every approved tech has a non-empty license set.

    Backs the Add Skill picker. The ``add_skill`` service enforces the
    same gate on the write path; this selector is the FE-side filter
    that keeps the tech from tapping into a guaranteed-403 path.

    Anchoring on ``TechnicianServiceLicense`` (not ``TechnicianSkill``)
    means a tech who drops all skills under a category still sees that
    category in the picker — they opted into it at onboarding and the
    license row survives the skill churn. "What categories can I work
    in" is decoupled from "what skills do I currently offer."

    Shape matches ``service_selectors.get_services_with_subservices``
    exactly so the Flutter ``AvailableServiceModel`` deserializes
    without a branch.

    Sub-services are eager-loaded via a single prefetch — no N+1 even
    for a tech who works across many categories.
    """
    licensed_service_ids = TechnicianServiceLicense.objects.filter(
        technician=technician,
    ).values_list('service_id', flat=True)

    services = (
        Service.objects
        .filter(id__in=licensed_service_ids)
        .prefetch_related(
            Prefetch(
                'sub_services',
                queryset=SubService.objects.order_by('name'),
            ),
        )
        .order_by('name')
    )

    return [
        {
            'id': s.id,
            'name': s.name,
            'icon_name': s.icon_name,
            'sub_services': [
                {
                    'id': sub.id,
                    'name': sub.name,
                    'base_price': str(sub.base_price),
                    'max_price': str(sub.max_price) if sub.max_price else None,
                    'icon_name': sub.icon_name,
                    'is_fixed_price': sub.is_fixed_price,
                }
                for sub in s.sub_services.all()
            ],
        }
        for s in services
    ]


__all__ = ['list_my_skills', 'list_my_service_categories']

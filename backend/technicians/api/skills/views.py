"""HTTP layer for tech-side skills CRUD.

Two views, three operations:
  * ``MySkillsView`` — ``GET`` lists the caller's skills,
                       ``POST`` adds a new one.
  * ``MySkillsDetailView`` — ``DELETE`` removes one by sub-service id.

Both views are thin: parse the request, resolve
``request.user.tech_profile``, hand off to selector/service, serialize
the result. Business rules (duplicate guard, last-skill guard) live
in the service; field validation lives in the serializer.

SECURITY: there is no ``technician_id`` anywhere in the URL or the
body. ``request.user.tech_profile`` is the only key. A non-technician
caller (no ``tech_profile``) gets a clean 403 envelope before any
write path runs.
"""
from __future__ import annotations

from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from technicians.selectors.skills_selector import (
    list_my_service_categories,
    list_my_skills,
)
from technicians.services.skills_service import add_skill, remove_skill

from .serializers import AddSkillWriteSerializer, MySkillReadSerializer


def _resolve_tech_profile(request) -> TechnicianProfile | None:
    """Return the caller's ``TechnicianProfile`` or ``None`` for pure customers.

    Centralised so every view in this module reports the same 403
    envelope for the "logged in but not a technician" case. The OneToOne
    raises ``RelatedObjectDoesNotExist`` (a subclass of
    ``TechnicianProfile.DoesNotExist``) when the row is missing.
    """
    try:
        return request.user.tech_profile
    except TechnicianProfile.DoesNotExist:
        return None


def _build_non_tech_response() -> Response:
    """Fresh 403 envelope per call.

    Not module-level: a shared ``Response`` would carry rendered state
    across requests, and DRF's response object isn't safe to reuse.
    """
    return Response(
        {
            'status': 403,
            'code': 'permission_denied',
            'message': 'User is not a registered technician.',
            'errors': {'user': ['Technician profile not found.']},
        },
        status=status.HTTP_403_FORBIDDEN,
    )


class MySkillsView(APIView):
    """``/api/technicians/me/skills/`` — list / add.

    GET returns a list of the caller's skill rows (sub-service +
    parent service nested). POST takes a single ``sub_service_id``
    and creates the bridge row.

    SECURITY: ``IsAuthenticated`` gates auth; the ``request.user
    .tech_profile`` resolution is the only IDOR gate — there is no
    technician_id in the URL.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        tech = _resolve_tech_profile(request)
        if tech is None:
            return _build_non_tech_response()

        rows = list_my_skills(technician=tech)
        data = MySkillReadSerializer(rows, many=True).data
        return Response(data, status=status.HTTP_200_OK)

    def post(self, request):
        tech = _resolve_tech_profile(request)
        if tech is None:
            return _build_non_tech_response()

        serializer = AddSkillWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        skill = add_skill(
            technician=tech,
            sub_service_id=serializer.validated_data['sub_service_id'],
        )

        # Re-serialize through the read shape so the FE's repository
        # can merge the new row into the cached list without a second
        # GET. ``select_related`` was not done on the freshly created
        # row; access ``.sub_service.service`` will trigger one extra
        # query, but POST is a single-shot — N+1 isn't a concern here.
        body = MySkillReadSerializer(skill).data
        return Response(body, status=status.HTTP_201_CREATED)


class MySkillsDetailView(APIView):
    """``/api/technicians/me/skills/<sub_service_id>/`` — delete.

    Keyed by ``sub_service_id`` (the catalog row), not by the bridge
    row's PK. The semantics are "remove this specialty from my skill
    set"; the bridge row id is an implementation detail the FE never
    needs.

    SECURITY: every query in the service is scoped to ``tech``; an
    attacker passing another tech's sub_service id just gets a 404
    because the (their_tech, that_sub) bridge row doesn't exist.
    """

    permission_classes = [IsAuthenticated]

    def delete(self, request, sub_service_id: int):
        tech = _resolve_tech_profile(request)
        if tech is None:
            return _build_non_tech_response()

        remove_skill(technician=tech, sub_service_id=sub_service_id)
        return Response(status=status.HTTP_204_NO_CONTENT)


class MyServiceCategoriesView(APIView):
    """``GET /api/technicians/me/service-categories/`` — picker catalog.

    Returns the service tree filtered to the categories the caller
    currently works in — i.e. the parent services of their existing
    ``TechnicianSkill`` rows. The Add Skill picker hits this instead
    of the broad onboarding metadata endpoint so the tech only sees
    sub-services they're qualified to add. The add-skill write path
    enforces the same gate on the server (`category_not_allowed`),
    so the filter is defence-in-depth, not the only check.

    The wire shape matches ``onboarding/metadata/`` byte-for-byte —
    the FE reuses the same ``AvailableServiceModel`` parser.

    Why this gate and not ``TechnicianServiceLicense``: license uploads
    are optional at onboarding, so a license-based filter would lock
    out every license-less tech. The skill parent-service anchor is
    universally applicable because every approved tech has ``>= 1``
    skill row.

    SECURITY: scoped to ``request.user.tech_profile``. No
    ``technician_id`` in the URL or body — IDOR-impossible.
    """

    permission_classes = [IsAuthenticated]

    def get(self, request):
        tech = _resolve_tech_profile(request)
        if tech is None:
            return _build_non_tech_response()

        data = list_my_service_categories(technician=tech)
        return Response(data, status=status.HTTP_200_OK)

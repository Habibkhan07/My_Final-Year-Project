"""GET /api/technicians/me/quotable-sub-services/?service_id=N

Returns the sub-services the *authenticated* technician can attach to a
quote under the given parent service. Filtered by the
``TechnicianSkill`` bridge so a plumber never sees AC sub-services, and
the marketplace's qualification gate is preserved.

SECURITY: technician identity comes from ``request.user.tech_profile``;
the endpoint accepts no ``technician_id`` param. Without the
``me``-style scope, a tech could enumerate another tech's skills.
"""
from __future__ import annotations

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.api.quote_catalog.serializers import (
    QuotableSubServiceSerializer,
)
from technicians.models import TechnicianProfile
from technicians.selectors.quote_catalog_selector import (
    list_quotable_sub_services,
)


class QuotableSubServicesView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # 1. Resolve the calling user's TechnicianProfile.
        # SECURITY: tech identity is the authenticated user — never a path or
        # query param — so one tech cannot list another's skills.
        try:
            technician = request.user.tech_profile
        except TechnicianProfile.DoesNotExist:
            return Response(
                {
                    'status': 403,
                    'code': 'permission_denied',
                    'message': 'User is not a registered technician.',
                    'errors': {'user': ['Technician profile not found.']},
                },
                status=403,
            )

        # 2. Parse + validate ?service_id=N.
        raw = request.query_params.get('service_id')
        if raw is None:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'service_id query parameter is required.',
                    'errors': {'service_id': ['This field is required.']},
                },
                status=400,
            )
        try:
            service_id = int(raw)
        except (TypeError, ValueError):
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'service_id must be an integer.',
                    'errors': {'service_id': [f'invalid literal: {raw!r}']},
                },
                status=400,
            )

        # 3. Selector + serialize.
        qs = list_quotable_sub_services(
            technician=technician,
            service_id=service_id,
        )
        data = QuotableSubServiceSerializer(qs, many=True).data
        return Response(data)

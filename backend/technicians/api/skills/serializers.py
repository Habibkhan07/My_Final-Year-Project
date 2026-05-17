"""Wire shapes for the tech-side skills CRUD endpoint.

Read shape mirrors what the FE 'My Skills' tile renders — sub-service
name + icon + parent service so the list can be grouped by service
without a second round-trip.

Write shape is intentionally tiny — a single ``sub_service_id``. The
bridge row is pure membership after migrations 0013/0014 (2026-05-17
onboarding refactor); pricing comes from ``catalog.SubService.base_price``
now, not from any per-tech column.
"""
from __future__ import annotations

from rest_framework import serializers

from technicians.models import TechnicianSkill


class MySkillReadSerializer(serializers.ModelSerializer):
    """Egress shape for ``GET /api/technicians/me/skills/``.

    A list of these. Service-grouped sort order is provided by the
    selector; the FE relies on it for the section headers.

    ``get_sub_service`` assembles the nested dict inline rather than
    delegating to child serializers — the shape is small (~6 fields
    across two levels) and inlining keeps the wire contract visible
    on one screen.
    """

    sub_service = serializers.SerializerMethodField()

    class Meta:
        model = TechnicianSkill
        fields = ['id', 'sub_service']

    def get_sub_service(self, obj: TechnicianSkill) -> dict:
        sub = obj.sub_service
        return {
            'id': sub.id,
            'name': sub.name,
            # ``icon_name`` flows to the FE's ``IconAssets.path()``
            # helper — the SVG ships with the Flutter app, never
            # served from the BE.
            'icon_name': sub.icon_name,
            'is_fixed_price': sub.is_fixed_price,
            'service': {
                'id': sub.service.id,
                'name': sub.service.name,
                'icon_name': sub.service.icon_name,
            },
        }


class AddSkillWriteSerializer(serializers.Serializer):
    """Ingress shape for ``POST /api/technicians/me/skills/``.

    Single field — picking a sub-service IS the operation. The bridge
    row is pure membership; no pricing or experience columns.
    """

    sub_service_id = serializers.IntegerField(min_value=1)

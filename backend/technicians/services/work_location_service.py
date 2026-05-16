"""Tech work-location writes.

Fat-service layer for PATCH /api/technicians/me/work-location/. The endpoint
takes no PK — the caller updates their own ``TechnicianProfile`` — so the
service simply scopes by ``user`` and writes the three model fields plus the
display label. The matchmaker reads ``base_latitude`` / ``base_longitude`` /
``max_travel_radius_km`` directly, so once this commits the technician becomes
discoverable on the next bounding-box query.

A REJECTED profile is intentionally allowed to update its location — a rejected
tech can still re-apply via the onboarding flow, and locking out their work
location during the rejected window would just produce a stale-data bug.
"""
from __future__ import annotations

from django.db import transaction
from rest_framework.exceptions import NotFound

from ..models import TechnicianProfile


def update_work_location(*, user, validated_data: dict) -> TechnicianProfile:
    """Persist the caller's work location and travel radius.

    SECURITY: scopes the lookup by ``user``; the URL carries no PK so there is
    no IDOR surface — a caller cannot target another tech's profile.
    """
    with transaction.atomic():
        try:
            profile = (
                TechnicianProfile.objects
                .select_for_update()
                .get(user=user)
            )
        except TechnicianProfile.DoesNotExist:
            # Pure customers don't have a TechnicianProfile. Returning 404
            # (rather than 403) matches the "endpoint operates on /me/" shape:
            # the resource just doesn't exist for this caller.
            raise NotFound(detail="No technician profile for this user.")

        profile.base_latitude = validated_data['latitude']
        profile.base_longitude = validated_data['longitude']

        if 'max_travel_radius_km' in validated_data:
            profile.max_travel_radius_km = validated_data['max_travel_radius_km']

        if 'work_address_label' in validated_data:
            # ``allow_blank`` + ``allow_null`` in the serializer means a caller
            # can clear the label by sending null/"". Persist verbatim — the
            # selector normalises display.
            profile.work_address_label = (
                validated_data['work_address_label'] or None
            )

        profile.save(update_fields=[
            'base_latitude',
            'base_longitude',
            'max_travel_radius_km',
            'work_address_label',
        ])

        return profile

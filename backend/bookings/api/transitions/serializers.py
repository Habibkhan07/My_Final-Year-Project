"""Request + response serializers for the manual phase-marker endpoints
(``start-inspection``, ``en-route``, ``arrived``).

The auto path is via ``POST /api/bookings/<id>/tech-location/`` which
calls ``auto_transition.evaluate_on_location``; these endpoints exist
as the manual override (e.g. tech with no GPS, or a frontend fallback).
"""
from __future__ import annotations

from rest_framework import serializers

from bookings.models import JobBooking


class StartInspectionRequestSerializer(serializers.Serializer):
    """No body fields — booking id is in the URL, actor is request.user."""


class StartInspectionResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "inspection_started_at"]


class EnRouteRequestSerializer(serializers.Serializer):
    """No body fields."""


class EnRouteResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "en_route_started_at"]


class ArrivedRequestSerializer(serializers.Serializer):
    """Optional GPS coords for the strict-mode geofence check.

    When ``BOOKING_GEOFENCE_STRICT`` is True AND both fields are
    supplied, the view rejects the call with ``400 not_at_customer_location``
    when the Haversine distance to the customer's address exceeds
    ``ARRIVED_THRESHOLD_METERS`` (100m). When the flag is False (default),
    the same mismatch only logs a warning.
    """
    current_lat = serializers.FloatField(required=False, min_value=-90.0, max_value=90.0)
    current_lng = serializers.FloatField(required=False, min_value=-180.0, max_value=180.0)


class ArrivedResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = ["id", "status", "arrived_at"]

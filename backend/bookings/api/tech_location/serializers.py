"""GPS ingress request + response shapes for ``tech_location``."""
from __future__ import annotations

from rest_framework import serializers


class TechLocationRequestSerializer(serializers.Serializer):
    lat = serializers.FloatField(min_value=-90.0, max_value=90.0)
    lng = serializers.FloatField(min_value=-180.0, max_value=180.0)
    accuracy_meters = serializers.FloatField(required=False, min_value=0.0)
    heading = serializers.FloatField(required=False, min_value=0.0, max_value=360.0)


class TechLocationResponseSerializer(serializers.Serializer):
    published = serializers.BooleanField()
    transition_fired = serializers.CharField(allow_null=True)

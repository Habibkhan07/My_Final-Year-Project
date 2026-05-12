"""Response serializer for the customer-arriving endpoint.

Returns the timestamp the customer ACK landed (or stays the same on
idempotent re-tap) so the UI can compute the "✓ Notified at X:XX"
relative-time display without a follow-up detail GET.
"""
from __future__ import annotations

from rest_framework import serializers

from bookings.models import JobBooking


class CustomerArrivingResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = [
            "id",
            "status",
            "customer_acknowledged_arrival_at",
        ]

"""
Response serializer for the technician-side accept / decline endpoints.

There is no request serializer — the booking id is in the URL and the
acting technician is taken from the authenticated user. The body is
empty by contract.
"""
from rest_framework import serializers


class JobBookingActionResponseSerializer(serializers.Serializer):
    """
    Small, stable shape the Flutter client mirrors into a typed model.
    Echoing the post-action ``status`` lets the client distinguish
    accept-success (CONFIRMED) from decline-success (REJECTED) without
    having to compare against a constant on the wire.
    """
    booking_id = serializers.IntegerField(source="id")
    status = serializers.CharField()

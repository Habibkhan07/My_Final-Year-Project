"""Serializers for the technician online-toggle endpoint.

Write contract is intentionally minimal: a single boolean keyed by name
matching the column on TechnicianProfile. Read contract returns the
post-write state plus the current balance so the FE can reconcile both
fields from one round trip.
"""
from rest_framework import serializers


class OnlineToggleInputSerializer(serializers.Serializer):
    """Ingress contract for ``POST /api/technicians/me/online/``.

    Single field — ``is_online`` — required to disambiguate a tap from
    a stale rapid-fire double-click. The FE always sends the explicit
    target value rather than "toggle whatever it is now", so the
    backend never has to read-modify-write across HTTP requests.
    """
    # SECURITY: explicit single-field whitelist. NEVER ``__all__`` — a
    # passthrough write to ``status`` / ``is_staff`` / wallet fields
    # would be catastrophic. Mass-assignment guard per CLAUDE.md.
    is_online = serializers.BooleanField(required=True)


class OnlineToggleOutputSerializer(serializers.Serializer):
    """Egress contract for the same endpoint's 200 response.

    Returns ``is_online`` after the commit and the current wallet
    balance — letting the FE patch both fields without a separate
    dashboard refetch.
    """
    is_online = serializers.BooleanField(read_only=True)
    current_wallet_balance = serializers.CharField(read_only=True)

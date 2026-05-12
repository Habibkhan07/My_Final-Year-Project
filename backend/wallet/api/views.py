"""Wallet HTTP surface — tech-facing.

Thin views per the project convention. Each view:
  1. Parses request, applies the IDOR guard (must be a TechnicianProfile).
  2. Delegates to a selector (read) or a service (write).
  3. Returns the response with the standard error envelope on failure.

Tonight ships only the balance read endpoint. Thursday adds POST
``/topups/`` and POST ``/withdrawals/`` + the JazzCash callback.
"""
from __future__ import annotations

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from wallet.selectors.wallet_selectors import get_wallet_balance


# SECURITY: every endpoint scopes to ``request.user.tech_profile`` —
# the only path to a TechnicianProfile in this module. A customer-role
# user has no tech_profile attribute, so the AttributeError → 403
# branch below fires structurally. There is no path-id parameter that
# could be IDOR'd.


class WalletBalanceView(APIView):
    """GET /api/technicians/wallet/  →  {balance, as_of}.

    Returns the tech's denormalized current balance plus a server
    timestamp the frontend can show as "balance as of {time}". The
    realtime WALLET_BALANCE_UPDATED frame patches this in place
    between explicit reads, so the typical refresh cadence is event-
    driven, not polling.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
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

        return Response(get_wallet_balance(technician))

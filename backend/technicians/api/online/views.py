"""HTTP layer for the user-initiated online toggle.

Thin view — parses request, delegates to ``set_online``, returns the
post-commit state. All lockout / status semantics live in the service.

The endpoint counterpart to the ledger's auto-offline gate in
``wallet/services/ledger.py``: the ledger flips ``is_online = False``
when balance goes negative; this endpoint is how the tech flips it
back up (or down on their own).
"""
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.services.online_status import set_online

from .serializers import (
    OnlineToggleInputSerializer,
    OnlineToggleOutputSerializer,
)


class TechnicianOnlineToggleView(APIView):
    """``POST /api/technicians/me/online/`` — flip the caller's online flag.

    Body: ``{"is_online": true | false}``.
    Returns 200 with ``{"is_online", "current_wallet_balance"}``.

    Refuses with:
      * 403 ``wallet_lockout`` — ``is_online=true`` while balance < 0.
      * 403 ``permission_denied`` — tech profile missing or not APPROVED.

    SECURITY: IsAuthenticated + the service scopes the write to
    ``request.user`` only. The URL carries no PK — IDOR-impossible.
    """

    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = OnlineToggleInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = set_online(
            user=request.user,
            desired=serializer.validated_data['is_online'],
        )
        return Response(
            OnlineToggleOutputSerializer(result).data,
            status=status.HTTP_200_OK,
        )

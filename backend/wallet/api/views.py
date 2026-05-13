"""Wallet HTTP surface — tech-facing.

Thin views per the project convention. Each view:
  1. Parses request, applies the IDOR guard (must be a TechnicianProfile).
  2. Delegates to a selector (read) or a service (write).
  3. Returns the response with the standard error envelope on failure.
"""
from __future__ import annotations

from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from wallet.selectors.wallet_selectors import (
    DEFAULT_PAGE_SIZE,
    InvalidCursor,
    MAX_PAGE_SIZE,
    get_wallet_balance,
    list_transactions,
)


# SECURITY: every endpoint scopes to ``request.user.tech_profile`` —
# the only path to a TechnicianProfile in this module. A customer-role
# user has no tech_profile attribute, so the AttributeError → 403
# branch below fires structurally. There is no path-id parameter that
# could be IDOR'd.


def _require_technician(request):
    """Return ``(technician, None)`` on success or ``(None, response)`` to short-circuit.

    Two ways a request can fail this gate:
      * Customer user (no ``tech_profile`` reverse relation populated) →
        ``TechnicianProfile.DoesNotExist`` from the descriptor.
      * Authenticated but never applied as a tech (no related row).
    Both collapse to the same 403 envelope — we do not differentiate so
    the response surface stays predictable for the frontend.
    """
    try:
        technician = request.user.tech_profile
    except TechnicianProfile.DoesNotExist:
        return None, Response(
            {
                'status': 403,
                'code': 'permission_denied',
                'message': 'User is not a registered technician.',
                'errors': {'user': ['Technician profile not found.']},
            },
            status=403,
        )
    return technician, None


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
        technician, error_response = _require_technician(request)
        if error_response is not None:
            return error_response
        return Response(get_wallet_balance(technician))


class WalletTransactionListView(APIView):
    """GET /api/technicians/wallet/transactions/?cursor=…&page_size=…

    Returns one cursor-paginated page of the tech's wallet ledger,
    newest-first. Cash transactions are NOT here — those live on the
    Metrics screen because the wallet is strictly platform-side money.

    The selector shapes ``ui_icon/ui_title/ui_subtitle/ui_amount_color``
    so the Flutter TransactionRow widget never branches on
    ``transaction_type``.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        technician, error_response = _require_technician(request)
        if error_response is not None:
            return error_response

        cursor = request.query_params.get('cursor') or None
        page_size_raw = request.query_params.get('page_size')

        page_size = DEFAULT_PAGE_SIZE
        if page_size_raw is not None:
            try:
                page_size = int(page_size_raw)
            except ValueError:
                return Response(
                    {
                        'status': 400,
                        'code': 'validation_error',
                        'message': 'page_size must be an integer.',
                        'errors': {'page_size': ['Must be an integer.']},
                    },
                    status=400,
                )
            if page_size < 1 or page_size > MAX_PAGE_SIZE:
                return Response(
                    {
                        'status': 400,
                        'code': 'validation_error',
                        'message': f'page_size must be between 1 and {MAX_PAGE_SIZE}.',
                        'errors': {'page_size': [f'Out of range (1..{MAX_PAGE_SIZE}).']},
                    },
                    status=400,
                )

        try:
            page = list_transactions(technician, cursor=cursor, page_size=page_size)
        except InvalidCursor:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Invalid cursor.',
                    'errors': {'cursor': ['Cursor could not be decoded.']},
                },
                status=400,
            )

        return Response(page)

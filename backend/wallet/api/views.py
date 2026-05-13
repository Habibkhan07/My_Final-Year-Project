"""Wallet HTTP surface.

Three audiences share this module:

1. **Tech-facing reads** (``WalletBalanceView``, ``WalletTransactionListView``,
   ``TopupStatusView``) — DRF-authenticated, IsTechnician gate.
2. **Tech-facing writes** (``TopupCreateView``) — same auth, returns a
   bridge URL the Flutter app pushes into a webview.
3. **Gateway-facing** (``TopupBridgeView``, ``JazzCashReturnView``) —
   unauthenticated by design. The bridge view is gated by a
   TimestampSigner-signed token bound to the topup id (5-minute TTL).
   The return view is gated by the gateway adapter's SecureHash
   verification inside ``apply_gateway_callback``.

Thin views per the project convention. Each view:
  1. Parses request, applies the appropriate auth gate.
  2. Delegates to a selector (read) or a service (write).
  3. Returns the response with the standard error envelope on failure.
"""
from __future__ import annotations

from django.core.exceptions import ImproperlyConfigured
from django.core.signing import BadSignature, SignatureExpired
from django.http import HttpResponse
from django.shortcuts import render
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from technicians.models import TechnicianProfile
from wallet.models import WalletTopup
from wallet.selectors.wallet_selectors import (
    DEFAULT_PAGE_SIZE,
    InvalidCursor,
    MAX_PAGE_SIZE,
    get_wallet_balance,
    list_transactions,
)
from wallet.services.topup_service import (
    TopupAmountOutOfRange,
    apply_gateway_callback,
    start_topup,
    unsign_bridge_token,
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


# ---------------------------------------------------------------------------
# Top-up flow
# ---------------------------------------------------------------------------

class TopupCreateView(APIView):
    """POST /api/technicians/wallet/topups/  body: ``{"amount": 1000}``

    Starts a Hosted Checkout top-up. Returns ``{topup_id, redirect_url}``
    where ``redirect_url`` points to OUR bridge endpoint — the Flutter
    app pushes it into a webview which auto-submits the gateway form.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        technician, error_response = _require_technician(request)
        if error_response is not None:
            return error_response

        raw_amount = request.data.get('amount')
        try:
            amount_rs = int(raw_amount)
        except (TypeError, ValueError):
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': 'Amount must be a whole-rupee integer.',
                    'errors': {'amount': ['Must be an integer.']},
                },
                status=400,
            )

        # SECURITY: technician is sourced from request.user.tech_profile;
        # the service writes a WalletTopup scoped to that profile only.
        try:
            result = start_topup(technician=technician, amount_rs=amount_rs)
        except TopupAmountOutOfRange as exc:
            return Response(
                {
                    'status': 400,
                    'code': 'validation_error',
                    'message': str(exc),
                    'errors': {
                        'amount': [
                            f'Out of range (Rs.{exc.minimum}..Rs.{exc.maximum}).'
                        ],
                    },
                },
                status=400,
            )
        except ImproperlyConfigured as exc:
            # The bound gateway raised at construct time (missing creds).
            # Surface as a service-level 503 so the FE can show a "top-up
            # is temporarily unavailable" rather than a generic 500.
            return Response(
                {
                    'status': 503,
                    'code': 'gateway_unavailable',
                    'message': 'Top-up gateway is not configured. Please try again later.',
                    'errors': {'gateway': [str(exc)]},
                },
                status=503,
            )

        return Response(
            {
                'topup_id': result.topup_id,
                'redirect_url': result.redirect_url,
            },
            status=201,
        )


class TopupStatusView(APIView):
    """GET /api/technicians/wallet/topups/<id>/

    The Flutter ``TopupNotifier`` polls this while the webview is open
    until ``gateway_status`` reaches a terminal state.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, topup_id: int):
        technician, error_response = _require_technician(request)
        if error_response is not None:
            return error_response

        # SECURITY: scope the lookup to the requesting technician —
        # tech A cannot poll tech B's topup, even by guessing the id.
        try:
            topup = WalletTopup.objects.get(pk=topup_id, technician=technician)
        except WalletTopup.DoesNotExist:
            return Response(
                {
                    'status': 404,
                    'code': 'not_found',
                    'message': 'Top-up not found.',
                    'errors': {'topup_id': ['No such top-up for this technician.']},
                },
                status=404,
            )

        return Response(
            {
                'topup_id': topup.id,
                'status': topup.gateway_status,
                'amount': str(topup.amount_attempted),
                'gateway_name': topup.gateway_name,
                'initiated_at': topup.initiated_at.isoformat(),
                'completed_at': (
                    topup.completed_at.isoformat() if topup.completed_at else None
                ),
            }
        )


@method_decorator(csrf_exempt, name='dispatch')
class TopupBridgeView(APIView):
    """GET /api/technicians/wallet/topups/<id>/bridge/?t=<signed>

    Renders an auto-submitting HTML form (real gateway) or a manual
    Pay/Decline page (mock gateway, demo fallback). The Flutter webview
    loads this URL and the resulting POST goes either to JazzCash's
    hosted checkout or to our own return view.

    Unauthenticated — the ``t=`` parameter is a TimestampSigner-signed
    token bound to ``topup_id`` with a 5-minute TTL. This is the auth.

    # SECURITY: the bridge URL can be loaded without a JWT (the Flutter
    # webview can't easily set the Authorization header on a page-load).
    # The signed token is the only access control; its 5-minute TTL
    # limits the replay window.
    """
    permission_classes = [AllowAny]
    authentication_classes: list = []

    def get(self, request, topup_id: int):
        token = request.query_params.get('t', '')
        try:
            signed_topup_id = unsign_bridge_token(token)
        except SignatureExpired:
            return HttpResponse(
                'Bridge token expired. Please return to the app and start the '
                'top-up again.',
                status=400,
                content_type='text/plain; charset=utf-8',
            )
        except BadSignature:
            return HttpResponse(
                'Invalid bridge token.',
                status=400,
                content_type='text/plain; charset=utf-8',
            )

        if signed_topup_id != topup_id:
            return HttpResponse(
                'Bridge token does not match this top-up.',
                status=400,
                content_type='text/plain; charset=utf-8',
            )

        try:
            topup = WalletTopup.objects.get(pk=topup_id)
        except WalletTopup.DoesNotExist:
            return HttpResponse(
                'Top-up not found.', status=404,
                content_type='text/plain; charset=utf-8',
            )

        # Mock gateway — render a manual Pay/Decline page so demo-day
        # fallback (when sandbox is down) is end-to-end testable
        # without leaving the app.
        if topup.gateway_name == 'mock':
            from django.conf import settings as dj_settings
            return render(
                request,
                'wallet/topup_bridge_mock.html',
                {
                    'topup': topup,
                    'session_id': topup.gateway_session_id,
                    'return_url': dj_settings.JAZZCASH_RETURN_URL or (
                        f'{dj_settings.SITE_URL}/api/wallet/gateway/jazzcash/return/'
                    ),
                },
            )

        # Real gateway — render the auto-submitting form. The adapter
        # already computed pp_SecureHash and stashed every pp_* field
        # on gateway_request_payload at start_topup time.
        from django.conf import settings as dj_settings
        return render(
            request,
            'wallet/topup_bridge_jazzcash.html',
            {
                'action': dj_settings.JAZZCASH_HOSTED_URL,
                'fields': topup.gateway_request_payload or {},
            },
        )


@method_decorator(csrf_exempt, name='dispatch')
class JazzCashReturnView(APIView):
    """POST /api/wallet/gateway/jazzcash/return/

    JazzCash POSTs the transaction outcome to this URL. In Hosted
    Checkout this is BOTH the user-redirect AND the webhook (one
    channel) — the customer's browser is sent here via a POST that
    also carries the authoritative result fields.

    Always returns 200 with a tiny HTML page so:
      (a) JazzCash stops retrying (any non-200 triggers retry storms).
      (b) The user's webview has something to land on; the Flutter
          NavigationDelegate detects the URL match and pops the webview.

    # SECURITY: unauthenticated and CSRF-exempt by design — the security
    # boundary is the gateway adapter's SecureHash verification (inside
    # apply_gateway_callback). A forged POST with the wrong hash hits
    # the noop / FAILED path and never mutates the ledger.
    """
    permission_classes = [AllowAny]
    authentication_classes: list = []

    def post(self, request):
        # ``request.data`` works for form-encoded AND JSON; JazzCash
        # POSTs form-encoded but tests can send JSON via APIClient.
        raw_payload = {k: v for k, v in request.data.items()}

        result = apply_gateway_callback(raw_payload=raw_payload)

        if result.matched and result.succeeded:
            heading = 'Top-up successful'
            body = 'Returning to the app…'
        elif result.matched and result.failure_reason:
            heading = 'Top-up failed'
            body = f'Reason: {result.failure_reason}. Returning to the app…'
        elif result.matched:
            heading = 'Top-up status pending'
            body = 'We are checking the result. Returning to the app…'
        else:
            # No matched topup — likely stale retry from a long-gone txn.
            heading = 'Top-up reference not recognised'
            body = 'You can close this window safely.'

        return render(
            request,
            'wallet/topup_return.html',
            {'heading': heading, 'body': body},
            status=200,
        )

    def get(self, request):
        """Some gateways issue a GET for browser previews — accept and
        render a placeholder so the webview doesn't show an error. The
        actual settlement only happens on POST."""
        return render(
            request,
            'wallet/topup_return.html',
            {
                'heading': 'Waiting for top-up result',
                'body': 'If you see this for more than a few seconds, return to the app.',
            },
            status=200,
        )

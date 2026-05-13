"""Top-up service — orchestrates the Hosted Checkout flow start-to-finish.

Two entry points:

* ``start_topup(technician, amount_rs)`` — called by ``TopupCreateView``
  when the tech taps "Top up Rs.X" in the wallet screen. Creates a
  ``WalletTopup`` row, calls the gateway adapter, mints a signed bridge
  URL, and returns the bridge URL to the view so the Flutter app can
  push it into an in-app webview.

* ``apply_gateway_callback(raw_payload)`` — called by
  ``JazzCashReturnView`` when JazzCash POSTs the result to our
  pp_ReturnURL. Looks up the matching ``WalletTopup`` via
  ``pp_TxnRefNo``, runs the gateway's ``verify_topup``, and on success
  writes the ``TOPUP_CREDIT`` ledger row through
  ``wallet.services.ledger.record_transaction``. Idempotent on retry.

Atomicity and idempotency are layered:

  - ``start_topup`` runs the WalletTopup row create + the gateway call
    in one ``transaction.atomic()``; if the gateway raises, no orphaned
    row.
  - ``apply_gateway_callback`` ``select_for_update`` s the WalletTopup
    row, short-circuits if the status is already terminal (prevents
    double-credit on JazzCash retry), and lets ``record_transaction``'s
    own idempotency key (``f'topup:{topup.id}'``) catch any race that
    slips past the row lock.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Any

from django.conf import settings
from django.core.signing import BadSignature, SignatureExpired, TimestampSigner
from django.db import transaction
from django.urls import reverse
from django.utils import timezone

from technicians.models import TechnicianProfile
from wallet.models import TopupStatus, TransactionType, WalletTopup
from wallet.services.gateway_factory import get_gateway
from wallet.services.ledger import record_transaction


# SECURITY: every call site receives a TechnicianProfile already scoped to
# request.user.tech_profile via the view's _require_technician gate. There
# is no implicit user lookup in this module. apply_gateway_callback is
# unauthenticated by design — the security boundary there is the gateway
# adapter's SecureHash verification + the select_for_update + terminal-
# status idempotency guard.


# Whole-rupee amount window. Hard floor of Rs.100 keeps demo/forgetful test
# inputs out; ceiling of Rs.25,000 matches the JazzCash sandbox per-txn cap
# (production may differ — recalibrate against the merchant onboarding pack).
MIN_TOPUP_RUPEES = 100
MAX_TOPUP_RUPEES = 25_000

# TimestampSigner salt for the bridge URL token. Distinct from any other
# signer in the codebase so a leaked token can only be replayed against
# this exact code path.
_BRIDGE_SIGNER_SALT = 'wallet.topup.bridge.v1'

# Bridge URL TTL — the webview loads the bridge once on push, so 5min is
# generous. Re-loads after expiry just regenerate via the FE retrying
# start_topup; no recovery flow needed.
_BRIDGE_TTL_SECONDS = 300


# --- DTOs --------------------------------------------------------------------

@dataclass(frozen=True)
class StartTopupResult:
    topup_id: int
    redirect_url: str


@dataclass(frozen=True)
class ApplyCallbackResult:
    """Outcome of ``apply_gateway_callback``. View renders identical HTML
    regardless — the FE polls /topups/<id>/ for the authoritative state.
    """
    matched: bool          # False if no WalletTopup row matched pp_TxnRefNo
    noop: bool             # True if we short-circuited on terminal status
    succeeded: bool        # True when we wrote a TOPUP_CREDIT row this call
    failure_reason: str = ''


# --- Domain errors -----------------------------------------------------------

class TopupAmountOutOfRange(Exception):
    """Raised when the requested top-up amount is outside the allowed window."""

    def __init__(self, amount: int, minimum: int, maximum: int) -> None:
        super().__init__(
            f'Top-up amount Rs.{amount} is out of range '
            f'(allowed: Rs.{minimum}..Rs.{maximum})'
        )
        self.amount = amount
        self.minimum = minimum
        self.maximum = maximum


# --- Bridge token sign / verify ---------------------------------------------

def sign_bridge_token(topup_id: int) -> str:
    """Mint the signed token that gates the bridge view."""
    return TimestampSigner(salt=_BRIDGE_SIGNER_SALT).sign(str(topup_id))


def unsign_bridge_token(token: str) -> int:
    """Verify the bridge token; return the topup id. Raises ``BadSignature``
    or ``SignatureExpired`` on tamper / TTL breach."""
    raw = TimestampSigner(salt=_BRIDGE_SIGNER_SALT).unsign(
        token, max_age=_BRIDGE_TTL_SECONDS
    )
    return int(raw)


# --- start_topup ------------------------------------------------------------

def start_topup(
    *,
    technician: TechnicianProfile,
    amount_rs: int,
) -> StartTopupResult:
    """Begin a Hosted Checkout top-up; return the URL the FE webview opens.

    The returned ``redirect_url`` points at our OWN bridge endpoint
    (``/api/technicians/wallet/topups/<id>/bridge/?t=<signed>``), NOT
    directly at JazzCash. The bridge renders the gateway's auto-
    submitting form server-side so merchant credentials and the
    SecureHash never travel through the app's network traffic.

    # SECURITY: the WalletTopup is created scoped to the passed-in
    # technician (caller's responsibility to source from request.user);
    # the bridge token is TimestampSigner-bound to the topup id and
    # cannot be forged without the SECRET_KEY.
    """
    if amount_rs < MIN_TOPUP_RUPEES or amount_rs > MAX_TOPUP_RUPEES:
        raise TopupAmountOutOfRange(
            amount=amount_rs,
            minimum=MIN_TOPUP_RUPEES,
            maximum=MAX_TOPUP_RUPEES,
        )

    gateway_name = getattr(settings, 'DEFAULT_PAYMENT_GATEWAY', 'mock')

    with transaction.atomic():
        topup = WalletTopup.objects.create(
            technician=technician,
            amount_attempted=Decimal(amount_rs),
            gateway_name=gateway_name,
            gateway_status=TopupStatus.PENDING,
        )

        gateway = get_gateway(gateway_name)
        # The gateway may raise (e.g. ImproperlyConfigured at construct
        # time or a deterministic build-time error). Let it propagate —
        # the outer atomic rolls back the WalletTopup row, so we don't
        # leave an orphaned PENDING row in the DB.
        session = gateway.initiate_topup(
            technician=technician,
            amount=Decimal(amount_rs),
        )

        # Stash everything the bridge view + the verify_topup callback
        # will need. The redirect_url returned by the adapter is the
        # gateway's ACTION URL (where the form will POST to); the FE
        # never sees it directly — only the bridge URL we mint here.
        topup.gateway_session_id = session.gateway_session_id
        topup.gateway_request_payload = dict(session.request_payload or {})

        bridge_path = reverse(
            'wallet-topup-bridge', kwargs={'topup_id': topup.id}
        )
        bridge_token = sign_bridge_token(topup.id)
        bridge_url = f'{settings.SITE_URL}{bridge_path}?t={bridge_token}'

        topup.gateway_redirect_url = bridge_url
        topup.gateway_status = TopupStatus.REDIRECTED
        topup.save(
            update_fields=[
                'gateway_session_id',
                'gateway_request_payload',
                'gateway_redirect_url',
                'gateway_status',
            ]
        )

    return StartTopupResult(topup_id=topup.id, redirect_url=bridge_url)


# --- apply_gateway_callback -------------------------------------------------

# Status set that means "we've already settled this topup — re-applying is
# a no-op". Used as the idempotency guard inside the locked transaction.
_TERMINAL_STATUSES = {
    TopupStatus.COMPLETED,
    TopupStatus.FAILED,
    TopupStatus.EXPIRED,
    TopupStatus.ABANDONED,
}


def apply_gateway_callback(*, raw_payload: dict[str, Any]) -> ApplyCallbackResult:
    """Process a gateway-pushed callback. Idempotent on retry.

    Looks up the ``WalletTopup`` by ``pp_TxnRefNo`` (or ``status`` for the
    mock adapter — see below). On a match, runs the bound gateway's
    ``verify_topup`` and either writes the ``TOPUP_CREDIT`` row or marks
    the topup ``FAILED``.

    Mock-bridge support: when the bridge view is in mock mode, its
    buttons POST a payload shaped like JazzCash's but with the mock's
    own session id. The mock adapter's ``verify_topup`` examines a
    ``status`` field; both look up via ``pp_TxnRefNo``.

    # SECURITY: this function is unauthenticated by design (JazzCash
    # POSTs cross-origin; CSRF doesn't apply). The gateway's
    # verify_topup performs the actual cryptographic check; this
    # function trusts whatever the adapter returns.
    """
    txn_ref = (raw_payload.get('pp_TxnRefNo') or '').strip()
    if not txn_ref:
        return ApplyCallbackResult(matched=False, noop=False, succeeded=False)

    try:
        topup = WalletTopup.objects.select_related('technician').get(
            gateway_session_id=txn_ref
        )
    except WalletTopup.DoesNotExist:
        return ApplyCallbackResult(matched=False, noop=False, succeeded=False)

    with transaction.atomic():
        # Re-fetch under select_for_update inside the atomic. Two parallel
        # callbacks for the same txn_ref (JazzCash retry + late primary
        # POST) serialize at this lock; the second sees the terminal
        # status and short-circuits.
        locked_topup = WalletTopup.objects.select_for_update().get(pk=topup.pk)

        # Persist the raw payload for forensic audit BEFORE we mutate
        # status. Even a "noop" call stashes the latest payload so
        # support can compare retries.
        locked_topup.gateway_callback_payload = dict(raw_payload)

        if locked_topup.gateway_status in _TERMINAL_STATUSES:
            locked_topup.save(update_fields=['gateway_callback_payload'])
            return ApplyCallbackResult(
                matched=True,
                noop=True,
                succeeded=locked_topup.gateway_status == TopupStatus.COMPLETED,
            )

        gateway = get_gateway(locked_topup.gateway_name)
        verify_result = gateway.verify_topup(
            session_id=locked_topup.gateway_session_id,
            callback_payload=raw_payload,
        )

        if verify_result.ok:
            wt = record_transaction(
                technician=locked_topup.technician,
                transaction_type=TransactionType.TOPUP_CREDIT,
                amount=locked_topup.amount_attempted,
                transaction_reference_number=f'topup:{locked_topup.id}',
                gateway_reference=verify_result.gateway_transaction_id,
                memo='Wallet top-up',
            )
            locked_topup.wallet_transaction = wt
            locked_topup.gateway_status = TopupStatus.COMPLETED
            locked_topup.completed_at = timezone.now()
            locked_topup.save(
                update_fields=[
                    'wallet_transaction',
                    'gateway_status',
                    'completed_at',
                    'gateway_callback_payload',
                ]
            )
            return ApplyCallbackResult(
                matched=True, noop=False, succeeded=True,
            )

        # Verification failed — mark FAILED and stash the reason.
        locked_topup.gateway_status = TopupStatus.FAILED
        locked_topup.save(
            update_fields=['gateway_status', 'gateway_callback_payload']
        )
        return ApplyCallbackResult(
            matched=True,
            noop=False,
            succeeded=False,
            failure_reason=verify_result.failure_reason,
        )


__all__ = [
    'BadSignature',
    'SignatureExpired',
    'StartTopupResult',
    'ApplyCallbackResult',
    'TopupAmountOutOfRange',
    'MIN_TOPUP_RUPEES',
    'MAX_TOPUP_RUPEES',
    'start_topup',
    'apply_gateway_callback',
    'sign_bridge_token',
    'unsign_bridge_token',
]

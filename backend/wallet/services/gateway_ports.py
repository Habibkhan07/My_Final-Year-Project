"""Payment gateway port — the abstraction over JazzCash, EasyPaisa, etc.

Two layers of abstraction in the wallet domain:

1. ``FinancePort`` (lives in ``bookings.services.finance_ports``) — bookings →
   wallet. Captures the booking lifecycle events that have financial side
   effects. The wallet app's ``WalletFinanceAdapter`` implements it.
2. ``PaymentGatewayPort`` (this file) — wallet → external payment processor.
   Captures everything the wallet needs from a real-world money mover.
   ``MockJazzCashGateway`` ships tonight; real ``JazzCashGateway`` lands
   Thursday. ``EasyPaisaGateway`` is a v1.1 drop-in.

The two ports are separate so the ledger layer has zero knowledge of gateway
specifics. The ledger never imports anything from ``wallet.adapters`` —
gateways feed data IN via the wallet service layer, then the wallet service
calls ``record_transaction`` which is gateway-agnostic. Adding EasyPaisa
later: implement this Protocol in a new file + register in
``settings.PAYMENT_GATEWAYS``. Zero ledger / model changes.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import Any, Protocol


# --- DTOs (return shapes) ----------------------------------------------------

@dataclass(frozen=True)
class TopupSession:
    """In-flight top-up handle returned by ``initiate_topup``.

    Persisted onto ``WalletTopup`` so a subsequent callback can be correlated
    back to this attempt. The gateway-side identifier (``gateway_session_id``)
    is opaque — the wallet service does not interpret it; it only uses it
    as a lookup key when a webhook arrives.

    ``request_payload`` is an OPTIONAL dict of HTTP form fields the gateway
    expects the merchant's browser to POST to it (e.g. JazzCash's
    ``pp_*`` parameter set plus ``pp_SecureHash``). Adapters whose flow is
    a plain GET redirect leave it as ``None``; adapters whose flow is an
    HTTP POST page redirection populate it. The wallet service stashes it
    onto ``WalletTopup.gateway_request_payload`` so the bridge view can
    render an auto-submitting HTML form server-side, keeping merchant
    credentials and the SecureHash out of the app's network traffic.
    """
    gateway_session_id: str
    redirect_url: str
    request_payload: dict[str, str] | None = None


@dataclass(frozen=True)
class TopupResult:
    """Verification outcome from ``verify_topup``.

    ``ok=True`` ⇒ wallet service writes the ``TOPUP_CREDIT`` ledger row.
    ``ok=False`` ⇒ wallet service marks ``WalletTopup.gateway_status=FAILED``
    and does NOT touch the ledger.

    ``gateway_transaction_id`` is the gateway's own permanent reference
    for the successful charge (e.g. JazzCash ``ppmpf-xxx``). Surfaced on
    ``WalletTransaction.gateway_reference`` for forensic queries.
    """
    ok: bool
    gateway_transaction_id: str
    failure_reason: str = ''


@dataclass(frozen=True)
class PayoutInitiation:
    """Stub return shape for ``initiate_payout`` — admin-side flow lands Thu.

    Holds the gateway's correlation reference for an outgoing payout
    (admin-triggered, out-of-band). The thesis flow says admin processes
    withdrawals manually via the merchant portal; this Port exists so the
    code path is uniform when a future automated payout API drops in.
    """
    gateway_reference: str
    estimated_settlement_minutes: int = 0


# --- The Port ----------------------------------------------------------------

class PaymentGatewayPort(Protocol):
    """Surface every payment gateway adapter must implement.

    Methods are deliberately keyword-only at the call site for legibility
    and to discourage positional drift between adapters. All adapters must
    be safe to instantiate without arguments (factory contract); gateway
    credentials are loaded from ``django.conf.settings`` inside the
    adapter, not passed through the Port.
    """

    def initiate_topup(
        self,
        *,
        technician: Any,  # TechnicianProfile, but loosely typed at port boundary
        amount: Decimal,
    ) -> TopupSession:
        """Start a top-up flow with the gateway.

        Adapters should NOT write any rows — the wallet service is responsible
        for persisting the returned ``TopupSession`` onto ``WalletTopup``.
        Adapters MAY raise on transient gateway errors (timeout, 5xx); the
        wallet service translates those into a domain failure that surfaces
        a retryable message to the tech.
        """
        ...

    def verify_topup(
        self,
        *,
        session_id: str,
        callback_payload: dict[str, Any],
    ) -> TopupResult:
        """Verify a gateway callback against the previously started session.

        ``callback_payload`` is the raw POST body from the gateway (after
        signature verification, which is the adapter's responsibility).
        The mock adapter accepts anything; real adapters MUST verify the
        signature/HMAC before returning ``ok=True``.
        """
        ...

    def initiate_payout(
        self,
        *,
        withdrawal_request: Any,
        payout_account: Any,
    ) -> PayoutInitiation:
        """Trigger an outgoing payout to the tech's bank/JazzCash account.

        Tonight: mock returns a stub reference. Thursday's real adapter:
        either calls the gateway's payout API (when available) or returns
        an empty reference indicating "admin must process out-of-band."
        The withdrawal admin flow tolerates both.
        """
        ...

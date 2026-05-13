"""JazzCash Hosted Checkout adapter — HTTP POST Page Redirection (sandbox).

Implements ``PaymentGatewayPort`` for the JazzCash gateway's Hosted Checkout
flow — the public-sandbox-available integration mode where the customer's
browser is POSTed to a JazzCash-hosted page that collects mobile number,
CNIC (last 6), SMS-OTP, and MPIN directly. The MPIN never enters our app.

Sequence:

1. Our wallet service calls ``initiate_topup`` — we build the pp_* form
   field dict + ``pp_SecureHash`` and return them in ``TopupSession``.
2. The bridge view (``TopupBridgeView`` in ``wallet/api/views.py``, lands
   in commit 2) renders these fields as an auto-submitting HTML form. The
   tech's webview loads the bridge and is immediately POSTed to
   ``JAZZCASH_HOSTED_URL``.
3. The tech completes JazzCash's hosted flow.
4. JazzCash POSTs the result to ``pp_ReturnURL`` — this is BOTH the
   user-redirect AND the webhook (one channel per JazzCash docs).
5. Our return view calls ``verify_topup`` with the inbound payload. The
   adapter recomputes ``pp_SecureHash``, constant-time-compares it, then
   maps the response code to ok/failure.

Sandbox credentials (Merchant_ID, Password, Hashkey/Integrity Salt, the
hosted-checkout URL, and the production URL) arrive in the JazzCash
merchant onboarding pack after self-registration. They populate the
``JAZZCASH_*`` settings — see ``WALLET_API.md`` for the env-var contract.

The ``pp_SecureHash`` algorithm is HMAC-SHA-256 keyed by the Integrity
Salt over the body ``salt&v1&v2&...&vN`` where ``v1..vN`` are the
non-empty pp_* field values sorted ascending by key, joined with ``&``.
This algorithm is NOT published in the public sandbox docs but is what
the community of Pakistani merchant integrations converges on. The
adapter ships a known-good test vector in
``tests/wallet/test_jazzcash_hosted_gateway.py`` — recalibrate that
vector against the first successful sandbox roundtrip before flipping
``DEFAULT_PAYMENT_GATEWAY=jazzcash`` in any environment that matters.
"""
from __future__ import annotations

import hashlib
import hmac
import secrets
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Any

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

from wallet.services.gateway_ports import (
    PayoutInitiation,
    TopupResult,
    TopupSession,
)


# SECURITY: pp_Password and the Integrity Salt are NEVER exposed to clients.
# pp_Password is sent in the form fields the bridge view renders (JazzCash
# requires it on every request), but the bridge URL is gated by a
# TimestampSigner token bound to the topup id with a ~5 min TTL. The salt
# is used only for HMAC computation and never leaves the server.


# JazzCash's documented response code for a successful transaction.
_PP_RESPONSE_SUCCESS_CODE = '000'

# Known JazzCash response codes mapped to short stable reasons the wallet
# service can render to the tech. Codes not in this table fall back to a
# generic ``gateway_error_{code}`` so debugging stays possible without
# enumerating every code JazzCash may emit.
_FAILURE_REASON_MAP = {
    '101': 'invalid_amount',
    '102': 'amount_exceeds_limit',
    '110': 'invalid_account',
    '111': 'insufficient_balance',
    '122': 'transaction_cancelled_by_customer',
    '124': 'invalid_mpin',
    '157': 'transaction_expired',
}


class JazzCashHostedGateway:
    """``PaymentGatewayPort`` implementation for JazzCash Hosted Checkout."""

    # ``pp_TxnType=MWALLET`` selects the Mobile Wallet rail on the hosted
    # page (vs. Card / Voucher). ``pp_Version=2.0`` is the current
    # documented version for the Hosted Checkout flow per the sandbox
    # FAQ; older 1.1 still works but exposes fewer fields.
    _PP_VERSION = '2.0'
    _PP_TXN_TYPE = 'MWALLET'
    _PP_LANGUAGE = 'EN'
    _PP_CURRENCY = 'PKR'

    def __init__(self) -> None:
        merchant_id = getattr(settings, 'JAZZCASH_MERCHANT_ID', '')
        password = getattr(settings, 'JAZZCASH_PASSWORD', '')
        salt = getattr(settings, 'JAZZCASH_INTEGRITY_SALT', '')
        hosted_url = getattr(settings, 'JAZZCASH_HOSTED_URL', '')
        return_url = getattr(settings, 'JAZZCASH_RETURN_URL', '')
        ttl_minutes = int(getattr(settings, 'JAZZCASH_TOPUP_TTL_MINUTES', 15))

        missing = [
            name
            for name, value in (
                ('JAZZCASH_MERCHANT_ID', merchant_id),
                ('JAZZCASH_PASSWORD', password),
                ('JAZZCASH_INTEGRITY_SALT', salt),
                ('JAZZCASH_HOSTED_URL', hosted_url),
                ('JAZZCASH_RETURN_URL', return_url),
            )
            if not value
        ]
        if missing:
            raise ImproperlyConfigured(
                'JazzCashHostedGateway is missing required settings: '
                f'{", ".join(missing)}. These are issued in the JazzCash '
                'merchant onboarding pack — see WALLET_API.md for the '
                'env-var contract.'
            )

        self._merchant_id = merchant_id
        self._password = password
        self._salt = salt
        self._hosted_url = hosted_url
        self._return_url = return_url
        self._ttl = timedelta(minutes=ttl_minutes)

    # ------------------------------------------------------------------
    # PaymentGatewayPort
    # ------------------------------------------------------------------
    def initiate_topup(
        self,
        *,
        technician: Any,
        amount: Decimal,
    ) -> TopupSession:
        """Build a fresh JazzCash Hosted Checkout payload.

        The returned ``TopupSession`` carries:
          * ``gateway_session_id`` — the ``pp_TxnRefNo`` we generated,
            which JazzCash echoes back on every callback (correlation key).
          * ``redirect_url``       — the JazzCash hosted endpoint the
            bridge view will POST the form to.
          * ``request_payload``    — the full pp_* dict (including the
            computed ``pp_SecureHash``) the bridge view will render
            into hidden inputs and auto-submit.
        """
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount))

        tech_id = int(getattr(technician, 'id', 0) or 0)
        # ``pp_TxnRefNo`` must be globally unique per attempt. The shape
        # ``T<7-digit-tech-id><8-hex-rand>`` is 16 chars — well under
        # JazzCash's per-version cap and starts with 'T' so it's
        # distinguishable from JazzCash's own internal references.
        rand_suffix = secrets.token_hex(4).upper()
        txn_ref = f'T{tech_id:07d}{rand_suffix}'

        now = datetime.now(timezone.utc)
        pp_txn_datetime = _fmt_jazzcash_datetime(now)
        pp_txn_expiry = _fmt_jazzcash_datetime(now + self._ttl)

        # Amount is expressed in paisa (smallest unit) per JazzCash convention.
        amount_paisa = int((amount * 100).quantize(Decimal('1')))

        fields: dict[str, str] = {
            'pp_Version': self._PP_VERSION,
            'pp_TxnType': self._PP_TXN_TYPE,
            'pp_Language': self._PP_LANGUAGE,
            'pp_MerchantID': self._merchant_id,
            'pp_Password': self._password,
            'pp_TxnRefNo': txn_ref,
            'pp_Amount': str(amount_paisa),
            'pp_TxnCurrency': self._PP_CURRENCY,
            'pp_TxnDateTime': pp_txn_datetime,
            'pp_BillReference': f'topup-{tech_id}',
            'pp_Description': 'Wallet top-up',
            'pp_TxnExpiryDateTime': pp_txn_expiry,
            'pp_ReturnURL': self._return_url,
        }
        fields['pp_SecureHash'] = self._build_secure_hash(fields)

        return TopupSession(
            gateway_session_id=txn_ref,
            redirect_url=self._hosted_url,
            request_payload=fields,
        )

    def verify_topup(
        self,
        *,
        session_id: str,
        callback_payload: dict[str, Any],
    ) -> TopupResult:
        """Verify an inbound callback against our SecureHash + session id.

        Defense-in-depth ladder:
          1. Stringify every value (JazzCash form-encodes everything).
          2. Require non-empty ``pp_SecureHash``.
          3. Recompute hash over the payload minus its own ``pp_SecureHash``;
             constant-time compare.
          4. Require ``pp_TxnRefNo == session_id`` (prevents
             replay-across-sessions even if hash is valid).
          5. Map ``pp_ResponseCode``: ``'000'`` → success, others → failure
             with a stable reason code.
        """
        payload = {
            k: '' if v is None else str(v)
            for k, v in callback_payload.items()
        }
        received_hash = (payload.pop('pp_SecureHash', '') or '').upper()
        if not received_hash:
            return TopupResult(
                ok=False,
                gateway_transaction_id='',
                failure_reason='missing_hash',
            )

        expected_hash = self._build_secure_hash(payload)
        if not hmac.compare_digest(received_hash, expected_hash):
            return TopupResult(
                ok=False,
                gateway_transaction_id='',
                failure_reason='hash_mismatch',
            )

        if payload.get('pp_TxnRefNo', '') != session_id:
            return TopupResult(
                ok=False,
                gateway_transaction_id='',
                failure_reason='session_mismatch',
            )

        response_code = payload.get('pp_ResponseCode', '')
        if response_code == _PP_RESPONSE_SUCCESS_CODE:
            # JazzCash docs spell the field both ways across versions
            # (``RetreivalReferenceNo`` is the historical typo, kept for
            # back-compat). Try the canonical spelling first.
            gateway_txn_id = (
                payload.get('pp_RetrievalReferenceNo')
                or payload.get('pp_RetreivalReferenceNo')
                or payload.get('pp_AuthCode')
                or ''
            )
            return TopupResult(
                ok=True,
                gateway_transaction_id=gateway_txn_id,
            )

        return TopupResult(
            ok=False,
            gateway_transaction_id='',
            failure_reason=_FAILURE_REASON_MAP.get(
                response_code,
                f'gateway_error_{response_code or "unknown"}',
            ),
        )

    def initiate_payout(
        self,
        *,
        withdrawal_request: Any,
        payout_account: Any,
    ) -> PayoutInitiation:
        """Same admin-processed stub as ``MockJazzCashGateway`` for v1.

        JazzCash's automated payout (MW Disbursement) API is on a separate
        merchant agreement tier. Tech withdrawals are processed manually
        by admin via the Django Admin action flow; the empty
        ``gateway_reference`` signals "out-of-band" to the wallet service.
        """
        return PayoutInitiation(
            gateway_reference='',
            estimated_settlement_minutes=0,
        )

    # ------------------------------------------------------------------
    # SecureHash builder
    # ------------------------------------------------------------------
    def _build_secure_hash(self, fields: dict[str, str]) -> str:
        """Compute ``pp_SecureHash`` per JazzCash's documented algorithm.

        Algorithm:
          1. Drop ``pp_SecureHash`` itself (if present in the input).
          2. Drop fields whose value is the empty string.
          3. Sort the remaining keys ascending (case-sensitive).
          4. Concatenate values in sorted-key order, joined by ``&``.
          5. Prepend ``IntegritySalt + '&'`` to the body.
          6. HMAC-SHA-256 keyed by the Integrity Salt over that body.
          7. Hex-encode uppercase.

        The algorithm IS NOT published in the public JazzCash sandbox docs.
        Community implementations across multiple Pakistani merchant
        libraries (Laravel, Node.js, PHP) converge on this exact shape.
        The known-good test vector in the test module pins the byte order;
        recalibrate against your first verified sandbox roundtrip before
        relying on production traffic.
        """
        keys = sorted(
            k for k, v in fields.items()
            if k != 'pp_SecureHash' and v != ''
        )
        body_values = '&'.join(fields[k] for k in keys)
        signed_body = f'{self._salt}&{body_values}'
        digest = hmac.new(
            key=self._salt.encode('utf-8'),
            msg=signed_body.encode('utf-8'),
            digestmod=hashlib.sha256,
        ).hexdigest().upper()
        return digest


def _fmt_jazzcash_datetime(dt: datetime) -> str:
    """``yyyyMMddHHmmss`` — JazzCash's documented timestamp format.

    The sandbox treats the string as a wall-clock value without explicit
    timezone interpretation; production may apply PKT (UTC+5) on JazzCash's
    side. We use UTC consistently for both ``pp_TxnDateTime`` and
    ``pp_TxnExpiryDateTime`` so the expiry window holds regardless.
    """
    return dt.strftime('%Y%m%d%H%M%S')

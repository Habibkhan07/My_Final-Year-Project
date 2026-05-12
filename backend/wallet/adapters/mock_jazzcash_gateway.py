"""In-memory JazzCash-shaped gateway adapter for dev + tests.

Exercises the ``PaymentGatewayPort`` surface so the wallet service is
forced to talk to the Protocol rather than reach into JazzCash specifics.
Without this adapter shipping tonight, the abstraction would be untested
and Thursday's real ``JazzCashGateway`` could quietly diverge.

Behaviour:
* ``initiate_topup`` — returns a deterministic fake redirect URL and a
  UUID-shaped session id. No network call. No state stored.
* ``verify_topup`` — accepts any callback by default. Returns ``ok=False``
  iff the callback payload explicitly contains ``{'status': 'failed'}``,
  so failure paths are testable.
* ``initiate_payout`` — returns a stub reference; admin still processes
  the actual payout out-of-band on Thursday.

This adapter is the production default in dev (``DEFAULT_PAYMENT_GATEWAY='mock'``
in settings) and the only adapter loaded during tests.
"""
from __future__ import annotations

import uuid
from decimal import Decimal
from typing import Any

from wallet.services.gateway_ports import (
    PaymentGatewayPort,
    PayoutInitiation,
    TopupResult,
    TopupSession,
)


class MockJazzCashGateway:
    """In-memory ``PaymentGatewayPort`` implementation.

    Implements the Protocol structurally — no inheritance — so a future
    adapter author can copy-paste this file and replace the bodies without
    inheriting any base class.
    """

    def initiate_topup(
        self,
        *,
        technician: Any,
        amount: Decimal,
    ) -> TopupSession:
        # Deterministic per-call session — uses uuid4 so repeated calls in a
        # test produce distinct sessions (matches the real gateway's
        # behaviour of issuing a fresh transaction id per request).
        session_id = f'mock-{uuid.uuid4()}'
        return TopupSession(
            gateway_session_id=session_id,
            redirect_url=f'https://mock-jazzcash.local/redirect/{session_id}',
        )

    def verify_topup(
        self,
        *,
        session_id: str,
        callback_payload: dict[str, Any],
    ) -> TopupResult:
        # Failure injection: callers pass ``{'status': 'failed', 'reason': '...'}``
        # in tests to exercise the failure code path.
        if callback_payload.get('status') == 'failed':
            return TopupResult(
                ok=False,
                gateway_transaction_id='',
                failure_reason=callback_payload.get('reason', 'mock_failure'),
            )
        # Synthesize a stable gateway transaction id from the session id so
        # tests can assert idempotency against it.
        return TopupResult(
            ok=True,
            gateway_transaction_id=f'mock-txn-{session_id}',
        )

    def initiate_payout(
        self,
        *,
        withdrawal_request: Any,
        payout_account: Any,
    ) -> PayoutInitiation:
        # No-op stub. Admin records the real out-of-band payout reference
        # via ``WithdrawalRequest.admin_external_ref`` on Thursday's admin
        # action. The Port exists so the call site is uniform.
        return PayoutInitiation(
            gateway_reference='',
            estimated_settlement_minutes=0,
        )

"""Service-level tests for ``wallet.services.topup_service``.

These tests run against the ``mock`` gateway (``DEFAULT_PAYMENT_GATEWAY=mock``
is the pytest-django default per the existing wallet test config) so we
exercise the orchestration without needing real JazzCash credentials.
A separate test (``test_jazzcash_hosted_gateway.py``) pins the JazzCash
adapter's algorithm; this file pins the service that wires everything
together.

Coverage:
* ``start_topup`` happy path — amount validation, WalletTopup row
  created with the right gateway, bridge URL signed and reachable.
* ``apply_gateway_callback`` happy path — TOPUP_CREDIT ledger row
  written, technician balance increased, topup transitioned to COMPLETED.
* Idempotency — replaying the same callback is a no-op.
* Failure path — mock failure injection marks topup FAILED, no ledger
  mutation, no balance change.
* Unknown ``pp_TxnRefNo`` — returns ``matched=False`` cleanly.
* Bridge token sign/verify round-trip + tamper detection.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from django.core.signing import BadSignature

from tests.factories.technicians import TechnicianProfileFactory
from wallet.models import TopupStatus, TransactionType, WalletTopup, WalletTransaction
from wallet.services.topup_service import (
    MAX_TOPUP_RUPEES,
    MIN_TOPUP_RUPEES,
    TopupAmountOutOfRange,
    apply_gateway_callback,
    sign_bridge_token,
    start_topup,
    unsign_bridge_token,
)


pytestmark = pytest.mark.django_db


# ---------------------------------------------------------------------------
# start_topup
# ---------------------------------------------------------------------------

class TestStartTopupHappyPath:
    def test_creates_topup_in_redirected_state(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()

        result = start_topup(technician=tech, amount_rs=500)

        topup = WalletTopup.objects.get(pk=result.topup_id)
        assert topup.technician_id == tech.id
        assert topup.amount_attempted == Decimal('500')
        assert topup.gateway_name == 'mock'
        assert topup.gateway_status == TopupStatus.REDIRECTED
        # Mock adapter session_id starts with 'mock-' (assertion lives
        # in test_mock_jazzcash_gateway.py).
        assert topup.gateway_session_id.startswith('mock-')

    def test_returns_bridge_url_for_the_topup(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()

        result = start_topup(technician=tech, amount_rs=500)

        assert f'/topups/{result.topup_id}/bridge/' in result.redirect_url
        assert result.redirect_url.startswith('http://testserver')
        assert '?t=' in result.redirect_url

    def test_stashes_request_payload_when_adapter_provides(self, settings):
        # Mock gateway returns request_payload=None; this stays None on
        # the row. The shape (dict | None) is exercised here so the
        # JazzCash adapter (which DOES return a dict) doesn't surprise.
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()

        result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=result.topup_id)

        # Mock returns None → service stashes an empty dict (per
        # ``dict(session.request_payload or {})``). Either is acceptable;
        # the important property is "not a string".
        assert isinstance(topup.gateway_request_payload, dict)


class TestStartTopupValidation:
    def test_amount_below_min_raises(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        tech = TechnicianProfileFactory()

        with pytest.raises(TopupAmountOutOfRange) as exc:
            start_topup(technician=tech, amount_rs=MIN_TOPUP_RUPEES - 1)
        assert exc.value.minimum == MIN_TOPUP_RUPEES

    def test_amount_above_max_raises(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        tech = TechnicianProfileFactory()

        with pytest.raises(TopupAmountOutOfRange) as exc:
            start_topup(technician=tech, amount_rs=MAX_TOPUP_RUPEES + 1)
        assert exc.value.maximum == MAX_TOPUP_RUPEES

    def test_amount_at_min_succeeds(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()

        result = start_topup(technician=tech, amount_rs=MIN_TOPUP_RUPEES)
        topup = WalletTopup.objects.get(pk=result.topup_id)
        assert topup.amount_attempted == Decimal(MIN_TOPUP_RUPEES)

    def test_no_orphan_row_when_gateway_raises(self, settings, mocker):
        # If the adapter raises inside the atomic, the WalletTopup
        # create must roll back. No orphaned PENDING rows.
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()

        mocker.patch(
            'wallet.adapters.mock_jazzcash_gateway.MockJazzCashGateway.initiate_topup',
            side_effect=RuntimeError('gateway down'),
        )

        with pytest.raises(RuntimeError):
            start_topup(technician=tech, amount_rs=500)

        assert WalletTopup.objects.filter(technician=tech).count() == 0


# ---------------------------------------------------------------------------
# apply_gateway_callback
# ---------------------------------------------------------------------------

class TestApplyCallbackSuccess:
    def _start(self, tech, amount=500):
        # Helper: returns the WalletTopup created by start_topup.
        result = start_topup(technician=tech, amount_rs=amount)
        return WalletTopup.objects.get(pk=result.topup_id)

    def test_writes_topup_credit_ledger_row(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        topup = self._start(tech, amount=500)

        result = apply_gateway_callback(
            raw_payload={'pp_TxnRefNo': topup.gateway_session_id}
        )

        assert result.matched is True
        assert result.succeeded is True
        assert result.noop is False

        topup.refresh_from_db()
        assert topup.gateway_status == TopupStatus.COMPLETED
        assert topup.completed_at is not None
        assert topup.wallet_transaction is not None

        wt = topup.wallet_transaction
        assert wt.transaction_type == TransactionType.TOPUP_CREDIT
        assert wt.amount == Decimal('500')
        assert wt.transaction_reference_number == f'topup:{topup.id}'

    def test_increases_technician_balance(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        # Factory default may store balance as float; coerce to Decimal
        # for arithmetic. The ledger writes correct Decimal values back.
        starting_balance = Decimal(str(tech.current_wallet_balance))
        topup = self._start(tech, amount=500)

        apply_gateway_callback(
            raw_payload={'pp_TxnRefNo': topup.gateway_session_id}
        )

        tech.refresh_from_db()
        assert tech.current_wallet_balance == starting_balance + Decimal('500')

    def test_stashes_raw_callback_payload(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        topup = self._start(tech, amount=500)

        apply_gateway_callback(
            raw_payload={
                'pp_TxnRefNo': topup.gateway_session_id,
                'pp_ResponseCode': '000',
                'pp_NewField': 'value',
            }
        )

        topup.refresh_from_db()
        assert topup.gateway_callback_payload is not None
        assert topup.gateway_callback_payload['pp_NewField'] == 'value'


class TestApplyCallbackIdempotency:
    def test_replay_is_noop(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        start_result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=start_result.topup_id)
        session_id = topup.gateway_session_id

        # First call writes the ledger.
        first = apply_gateway_callback(raw_payload={'pp_TxnRefNo': session_id})
        assert first.succeeded is True
        assert first.noop is False

        ledger_count_after_first = WalletTransaction.objects.filter(technician=tech).count()

        # Second call — same payload, returns noop=True, no second ledger row.
        second = apply_gateway_callback(raw_payload={'pp_TxnRefNo': session_id})
        assert second.matched is True
        assert second.noop is True
        assert second.succeeded is True  # reports the existing terminal state

        ledger_count_after_second = WalletTransaction.objects.filter(technician=tech).count()
        assert ledger_count_after_second == ledger_count_after_first

    def test_balance_does_not_double_credit(self, settings):
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        start_result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=start_result.topup_id)

        # Factory default may store balance as float; coerce to Decimal
        # for arithmetic. The ledger writes correct Decimal values back.
        starting_balance = Decimal(str(tech.current_wallet_balance))

        apply_gateway_callback(raw_payload={'pp_TxnRefNo': topup.gateway_session_id})
        apply_gateway_callback(raw_payload={'pp_TxnRefNo': topup.gateway_session_id})
        apply_gateway_callback(raw_payload={'pp_TxnRefNo': topup.gateway_session_id})

        tech.refresh_from_db()
        assert tech.current_wallet_balance == starting_balance + Decimal('500')


class TestApplyCallbackFailure:
    def test_failure_marks_topup_failed_no_ledger_write(self, settings):
        # Mock adapter treats ``status=failed`` in the callback as a failure.
        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        settings.SITE_URL = 'http://testserver'
        tech = TechnicianProfileFactory()
        start_result = start_topup(technician=tech, amount_rs=500)
        topup = WalletTopup.objects.get(pk=start_result.topup_id)
        # Factory default may store balance as float; coerce to Decimal
        # for arithmetic. The ledger writes correct Decimal values back.
        starting_balance = Decimal(str(tech.current_wallet_balance))

        result = apply_gateway_callback(
            raw_payload={
                'pp_TxnRefNo': topup.gateway_session_id,
                'status': 'failed',
                'reason': 'cancelled_by_customer',
            }
        )

        assert result.matched is True
        assert result.succeeded is False
        assert result.failure_reason == 'cancelled_by_customer'

        topup.refresh_from_db()
        assert topup.gateway_status == TopupStatus.FAILED
        assert topup.wallet_transaction is None

        tech.refresh_from_db()
        assert tech.current_wallet_balance == starting_balance


class TestApplyCallbackUnknown:
    def test_unknown_txn_ref_returns_unmatched(self, settings):
        # Stale JazzCash retry referencing a long-gone txn ref.
        result = apply_gateway_callback(
            raw_payload={'pp_TxnRefNo': 'DOES-NOT-EXIST'}
        )
        assert result.matched is False
        assert result.noop is False
        assert result.succeeded is False

    def test_missing_txn_ref_returns_unmatched(self):
        result = apply_gateway_callback(raw_payload={})
        assert result.matched is False


# ---------------------------------------------------------------------------
# Bridge token sign / verify
# ---------------------------------------------------------------------------

class TestBridgeToken:
    def test_round_trip(self):
        token = sign_bridge_token(42)
        assert unsign_bridge_token(token) == 42

    def test_tampered_token_rejected(self):
        token = sign_bridge_token(42)
        tampered = token[:-3] + 'XXX'
        with pytest.raises(BadSignature):
            unsign_bridge_token(tampered)

    def test_signs_distinct_topups_to_distinct_tokens(self):
        # Different topup ids → different tokens (sanity, not a security
        # property; TimestampSigner already guarantees this).
        a = sign_bridge_token(1)
        b = sign_bridge_token(2)
        assert a != b

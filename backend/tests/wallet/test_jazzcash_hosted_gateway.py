"""Tests for ``JazzCashHostedGateway`` (Hosted Checkout adapter).

These pin the public contract the real JazzCash sandbox will be wired
against. They cover:

* Port conformance (Protocol-shaped surface).
* Fail-loud on missing credentials at instantiation time.
* ``initiate_topup`` builds the full pp_* payload with the right shape
  (amount in paisa, sorted-key SecureHash, all required JazzCash fields).
* SecureHash algorithm properties (deterministic, tamper-evident,
  drops empty values, drops ``pp_SecureHash`` itself from its own input).
* ``verify_topup`` round-trip: a payload signed by ``initiate_topup``
  (plus the canonical success fields) verifies as ``ok=True``.
* The full failure ladder: missing hash, hash mismatch, session-id
  mismatch (replay-across-sessions defense), known JazzCash failure
  codes, unknown failure codes.

A hand-calibrated test vector for the exact hex digest is NOT pinned here
— JazzCash's public docs don't publish the algorithm, so the vector
should be recalibrated against the first verified sandbox roundtrip.
The properties tested below pin the algorithm's shape; recalibration
catches byte-order drift.
"""
from __future__ import annotations

from decimal import Decimal
from types import SimpleNamespace

import pytest
from django.core.exceptions import ImproperlyConfigured
from django.test import override_settings

from wallet.adapters.jazzcash_hosted_gateway import (
    JazzCashHostedGateway,
    _fmt_jazzcash_datetime,
)
from wallet.services.gateway_ports import (
    PayoutInitiation,
    TopupResult,
    TopupSession,
)


# ---------------------------------------------------------------------------
# Fixtures / helpers
# ---------------------------------------------------------------------------

_TEST_SETTINGS = dict(
    JAZZCASH_MERCHANT_ID='MC12345',
    JAZZCASH_PASSWORD='pw_abcdef',
    JAZZCASH_INTEGRITY_SALT='SaltyMcSalt',
    JAZZCASH_HOSTED_URL='https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/',
    JAZZCASH_RETURN_URL='https://api.test.local/api/wallet/gateway/jazzcash/return/',
    JAZZCASH_TOPUP_TTL_MINUTES=15,
)


@pytest.fixture
def gateway():
    with override_settings(**_TEST_SETTINGS):
        yield JazzCashHostedGateway()


def _tech(id_: int = 42):
    """Lightweight stand-in for a TechnicianProfile — the adapter only
    reads ``.id`` off it. Avoids dragging the ORM into a pure-logic test."""
    return SimpleNamespace(id=id_)


# ---------------------------------------------------------------------------
# Port conformance
# ---------------------------------------------------------------------------

class TestPortConformance:
    def test_implements_port_structurally(self, gateway):
        # @runtime_checkable on the Protocol would let us isinstance-check;
        # the existing port isn't decorated, so asserting the method surface
        # is sufficient and matches the pattern in test_mock_jazzcash_gateway.
        assert callable(gateway.initiate_topup)
        assert callable(gateway.verify_topup)
        assert callable(gateway.initiate_payout)


# ---------------------------------------------------------------------------
# Settings validation
# ---------------------------------------------------------------------------

class TestRequiresCredentials:
    @pytest.mark.parametrize('missing_key', [
        'JAZZCASH_MERCHANT_ID',
        'JAZZCASH_PASSWORD',
        'JAZZCASH_INTEGRITY_SALT',
        'JAZZCASH_HOSTED_URL',
        'JAZZCASH_RETURN_URL',
    ])
    def test_missing_setting_raises_improperly_configured(self, missing_key):
        # Override one key at a time to '' and confirm the constructor
        # raises with that key's name in the message.
        partial = {**_TEST_SETTINGS, missing_key: ''}
        with override_settings(**partial):
            with pytest.raises(ImproperlyConfigured) as exc:
                JazzCashHostedGateway()
        assert missing_key in str(exc.value)

    def test_lists_all_missing_keys_in_one_message(self):
        partial = {**_TEST_SETTINGS}
        for key in ('JAZZCASH_MERCHANT_ID', 'JAZZCASH_PASSWORD'):
            partial[key] = ''
        with override_settings(**partial):
            with pytest.raises(ImproperlyConfigured) as exc:
                JazzCashHostedGateway()
        message = str(exc.value)
        assert 'JAZZCASH_MERCHANT_ID' in message
        assert 'JAZZCASH_PASSWORD' in message


# ---------------------------------------------------------------------------
# initiate_topup
# ---------------------------------------------------------------------------

class TestInitiateTopup:
    def test_returns_session_with_request_payload(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        assert isinstance(session, TopupSession)
        assert session.request_payload is not None
        assert isinstance(session.request_payload, dict)

    def test_redirect_url_is_jazzcash_hosted_url(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        assert session.redirect_url == _TEST_SETTINGS['JAZZCASH_HOSTED_URL']

    def test_session_id_matches_pp_txn_ref_no(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        assert session.gateway_session_id == session.request_payload['pp_TxnRefNo']

    def test_session_id_shape(self, gateway):
        # ``T<7-digit-tech-id><8-hex-uppercase-rand>`` = 16 chars.
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        ref = session.gateway_session_id
        assert ref.startswith('T0000042')
        assert len(ref) == 16

    def test_amount_is_in_paisa(self, gateway):
        # Rs.500.00 → 50000 paisa, stringified.
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        assert session.request_payload['pp_Amount'] == '50000'

    def test_amount_accepts_non_decimal(self, gateway):
        # Service callers may pass int/str; the adapter coerces.
        session = gateway.initiate_topup(technician=_tech(42), amount=1000)
        assert session.request_payload['pp_Amount'] == '100000'

    def test_carries_all_required_fields(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        payload = session.request_payload
        for key in (
            'pp_Version', 'pp_TxnType', 'pp_Language', 'pp_MerchantID',
            'pp_Password', 'pp_TxnRefNo', 'pp_Amount', 'pp_TxnCurrency',
            'pp_TxnDateTime', 'pp_TxnExpiryDateTime', 'pp_ReturnURL',
            'pp_SecureHash',
        ):
            assert key in payload, f'Missing pp_ field: {key}'
            assert payload[key] != '', f'Empty value for {key}'

    def test_fixed_fields_have_expected_values(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        payload = session.request_payload
        assert payload['pp_Version'] == '2.0'
        assert payload['pp_TxnType'] == 'MWALLET'
        assert payload['pp_Language'] == 'EN'
        assert payload['pp_TxnCurrency'] == 'PKR'
        assert payload['pp_MerchantID'] == 'MC12345'
        assert payload['pp_ReturnURL'] == _TEST_SETTINGS['JAZZCASH_RETURN_URL']

    def test_secure_hash_is_64_hex_uppercase(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        secure_hash = session.request_payload['pp_SecureHash']
        assert len(secure_hash) == 64
        assert secure_hash == secure_hash.upper()
        # All chars must be hex.
        int(secure_hash, 16)  # raises ValueError if not hex

    def test_each_call_returns_distinct_txn_ref(self, gateway):
        a = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        b = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        assert a.gateway_session_id != b.gateway_session_id

    def test_expiry_is_after_txn_datetime(self, gateway):
        session = gateway.initiate_topup(technician=_tech(42), amount=Decimal('500'))
        payload = session.request_payload
        # Both are yyyyMMddHHmmss; lexicographic compare works.
        assert payload['pp_TxnExpiryDateTime'] > payload['pp_TxnDateTime']


# ---------------------------------------------------------------------------
# _build_secure_hash properties
# ---------------------------------------------------------------------------

class TestSecureHashAlgorithm:
    def test_deterministic_for_same_input(self, gateway):
        fields = {'pp_A': 'x', 'pp_B': 'y', 'pp_C': 'z'}
        a = gateway._build_secure_hash(fields)
        b = gateway._build_secure_hash(fields)
        assert a == b

    def test_tampering_any_value_changes_hash(self, gateway):
        baseline = {'pp_A': 'x', 'pp_B': 'y'}
        digest_a = gateway._build_secure_hash(baseline)
        digest_b = gateway._build_secure_hash({**baseline, 'pp_A': 'X'})
        assert digest_a != digest_b

    def test_key_reorder_does_not_change_hash(self, gateway):
        # Sorted-by-key is the algorithm; insertion order is irrelevant.
        a = gateway._build_secure_hash({'pp_A': 'x', 'pp_B': 'y'})
        b = gateway._build_secure_hash({'pp_B': 'y', 'pp_A': 'x'})
        assert a == b

    def test_empty_value_excluded_from_hash(self, gateway):
        # Empty values are explicitly excluded per the algorithm spec.
        with_empty = {'pp_A': 'x', 'pp_B': ''}
        without_empty = {'pp_A': 'x'}
        assert gateway._build_secure_hash(with_empty) == gateway._build_secure_hash(without_empty)

    def test_own_secure_hash_field_dropped_from_input(self, gateway):
        # If a caller accidentally includes pp_SecureHash in the input,
        # the algorithm drops it (otherwise it'd be impossible to recompute
        # the hash that's about to be assigned).
        a = gateway._build_secure_hash({'pp_A': 'x'})
        b = gateway._build_secure_hash({'pp_A': 'x', 'pp_SecureHash': 'GARBAGE'})
        assert a == b


# ---------------------------------------------------------------------------
# verify_topup round-trip
# ---------------------------------------------------------------------------

class TestVerifyTopupRoundTrip:
    """Use ``initiate_topup`` to mint a payload, decorate it with the
    canonical success fields, re-sign it, and confirm ``verify_topup``
    returns ``ok=True``. This is the strongest correctness test we can
    write without a real sandbox roundtrip."""

    def _sign_callback(self, gateway, session, response_code, retrieval_ref=''):
        # Build the payload JazzCash WOULD POST back to us if it accepted
        # (or rejected) this transaction.
        payload = dict(session.request_payload)
        payload.pop('pp_SecureHash', None)
        payload['pp_ResponseCode'] = response_code
        payload['pp_ResponseMessage'] = 'Test response'
        if retrieval_ref:
            payload['pp_RetrievalReferenceNo'] = retrieval_ref
        payload['pp_SecureHash'] = gateway._build_secure_hash(payload)
        return payload

    def test_success_round_trip(self, gateway):
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        callback = self._sign_callback(
            gateway, session, response_code='000', retrieval_ref='RRN-77777'
        )
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=callback,
        )
        assert isinstance(result, TopupResult)
        assert result.ok is True
        assert result.gateway_transaction_id == 'RRN-77777'
        assert result.failure_reason == ''

    def test_success_accepts_legacy_typo_field_name(self, gateway):
        # JazzCash historically spells it ``pp_RetreivalReferenceNo``;
        # the adapter must tolerate the typo so production rollouts don't
        # silently drop the gateway txn id.
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        payload = dict(session.request_payload)
        payload.pop('pp_SecureHash', None)
        payload['pp_ResponseCode'] = '000'
        payload['pp_RetreivalReferenceNo'] = 'TYPO-1'
        payload['pp_SecureHash'] = gateway._build_secure_hash(payload)
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=payload,
        )
        assert result.ok is True
        assert result.gateway_transaction_id == 'TYPO-1'

    def test_failure_known_code_maps_to_stable_reason(self, gateway):
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        callback = self._sign_callback(gateway, session, response_code='124')
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=callback,
        )
        assert result.ok is False
        assert result.failure_reason == 'invalid_mpin'
        assert result.gateway_transaction_id == ''

    def test_failure_unknown_code_falls_through_to_generic_reason(self, gateway):
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        callback = self._sign_callback(gateway, session, response_code='999')
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=callback,
        )
        assert result.ok is False
        assert result.failure_reason == 'gateway_error_999'


class TestVerifyTopupSecurity:
    def test_missing_hash_rejected(self, gateway):
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        payload = dict(session.request_payload)
        payload.pop('pp_SecureHash', None)
        payload['pp_ResponseCode'] = '000'
        # NO pp_SecureHash → reject.
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=payload,
        )
        assert result.ok is False
        assert result.failure_reason == 'missing_hash'

    def test_bad_hash_rejected(self, gateway):
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        payload = dict(session.request_payload)
        payload['pp_ResponseCode'] = '000'
        payload['pp_SecureHash'] = 'F' * 64  # plausible shape, wrong digest
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=payload,
        )
        assert result.ok is False
        assert result.failure_reason == 'hash_mismatch'

    def test_session_id_mismatch_rejected_even_when_hash_valid(self, gateway):
        # Replay-across-sessions: an attacker signs a valid payload with
        # OUR salt for txn_ref X, then submits it under our lookup of
        # txn_ref Y. The hash verifies but the session check must fail.
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        payload = dict(session.request_payload)
        payload.pop('pp_SecureHash', None)
        payload['pp_ResponseCode'] = '000'
        payload['pp_SecureHash'] = gateway._build_secure_hash(payload)

        result = gateway.verify_topup(
            session_id='T9999999XXXXXXXX',  # different from payload pp_TxnRefNo
            callback_payload=payload,
        )
        assert result.ok is False
        assert result.failure_reason == 'session_mismatch'

    def test_extra_unknown_fields_in_callback_are_signed_over(self, gateway):
        # JazzCash may add fields in future versions; as long as both
        # sides sign over the same set, verification still works.
        session = gateway.initiate_topup(technician=_tech(7), amount=Decimal('300'))
        payload = dict(session.request_payload)
        payload.pop('pp_SecureHash', None)
        payload['pp_ResponseCode'] = '000'
        payload['pp_NewFieldFromJazzCash'] = 'something'
        payload['pp_SecureHash'] = gateway._build_secure_hash(payload)
        result = gateway.verify_topup(
            session_id=session.gateway_session_id,
            callback_payload=payload,
        )
        assert result.ok is True


# ---------------------------------------------------------------------------
# initiate_payout
# ---------------------------------------------------------------------------

class TestInitiatePayout:
    def test_returns_empty_stub(self, gateway):
        # JazzCash automated disbursement is on a separate merchant tier;
        # the wallet service treats empty gateway_reference as "admin
        # processes out-of-band" — same shape as MockJazzCashGateway.
        result = gateway.initiate_payout(withdrawal_request=None, payout_account=None)
        assert isinstance(result, PayoutInitiation)
        assert result.gateway_reference == ''
        assert result.estimated_settlement_minutes == 0


# ---------------------------------------------------------------------------
# Datetime helper
# ---------------------------------------------------------------------------

class TestDatetimeFormatter:
    def test_yyyymmddhhmmss_format(self):
        from datetime import datetime, timezone
        dt = datetime(2026, 5, 13, 21, 30, 5, tzinfo=timezone.utc)
        assert _fmt_jazzcash_datetime(dt) == '20260513213005'

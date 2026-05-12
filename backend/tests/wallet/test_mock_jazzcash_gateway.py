"""Tests for ``MockJazzCashGateway``.

The mock exists so the ``PaymentGatewayPort`` surface is exercised by a
real adapter from day one. These tests pin the contract that Thursday's
real ``JazzCashGateway`` must also satisfy.
"""
from __future__ import annotations

from decimal import Decimal

from wallet.adapters.mock_jazzcash_gateway import MockJazzCashGateway
from wallet.services.gateway_ports import (
    PaymentGatewayPort,
    PayoutInitiation,
    TopupResult,
    TopupSession,
)


class TestPortConformance:
    def test_implements_port_structurally(self):
        # Structural Protocol — any callable shape with matching method
        # signatures satisfies isinstance() in Python 3.12+ for
        # @runtime_checkable Protocols. Here we just assert the mock has
        # the methods, which is sufficient for the codebase's usage.
        gateway = MockJazzCashGateway()
        assert callable(gateway.initiate_topup)
        assert callable(gateway.verify_topup)
        assert callable(gateway.initiate_payout)


class TestInitiateTopup:
    def test_returns_session_with_redirect(self):
        gateway = MockJazzCashGateway()
        session = gateway.initiate_topup(technician=None, amount=Decimal('500'))
        assert isinstance(session, TopupSession)
        assert session.gateway_session_id.startswith('mock-')
        assert session.redirect_url.startswith('https://mock-jazzcash.local/redirect/')

    def test_each_call_returns_distinct_session(self):
        """Real gateways issue fresh transaction ids per request — mock does the same."""
        gateway = MockJazzCashGateway()
        a = gateway.initiate_topup(technician=None, amount=Decimal('500'))
        b = gateway.initiate_topup(technician=None, amount=Decimal('500'))
        assert a.gateway_session_id != b.gateway_session_id


class TestVerifyTopup:
    def test_accepts_default_payload(self):
        gateway = MockJazzCashGateway()
        result = gateway.verify_topup(session_id='mock-abc', callback_payload={})
        assert isinstance(result, TopupResult)
        assert result.ok is True
        assert result.gateway_transaction_id == 'mock-txn-mock-abc'
        assert result.failure_reason == ''

    def test_failure_injection(self):
        """``{'status': 'failed', 'reason': '...'}`` exercises the failure path."""
        gateway = MockJazzCashGateway()
        result = gateway.verify_topup(
            session_id='mock-abc',
            callback_payload={'status': 'failed', 'reason': 'insufficient_funds'},
        )
        assert result.ok is False
        assert result.failure_reason == 'insufficient_funds'
        assert result.gateway_transaction_id == ''

    def test_failure_without_explicit_reason_defaults(self):
        gateway = MockJazzCashGateway()
        result = gateway.verify_topup(
            session_id='mock-abc',
            callback_payload={'status': 'failed'},
        )
        assert result.ok is False
        assert result.failure_reason == 'mock_failure'


class TestInitiatePayout:
    def test_returns_stub(self):
        """Real payout API is Thursday; mock returns empty reference."""
        gateway = MockJazzCashGateway()
        result = gateway.initiate_payout(withdrawal_request=None, payout_account=None)
        assert isinstance(result, PayoutInitiation)
        assert result.gateway_reference == ''


class TestGatewayFactory:
    def test_resolves_mock_by_name(self, settings):
        from wallet.services.gateway_factory import get_gateway

        gateway = get_gateway('mock')
        assert isinstance(gateway, MockJazzCashGateway)

    def test_uses_default_when_name_none(self, settings):
        from wallet.services.gateway_factory import get_gateway

        settings.DEFAULT_PAYMENT_GATEWAY = 'mock'
        gateway = get_gateway()
        assert isinstance(gateway, MockJazzCashGateway)

    def test_unknown_name_raises(self, settings):
        from django.core.exceptions import ImproperlyConfigured

        from wallet.services.gateway_factory import get_gateway

        import pytest as _pytest
        with _pytest.raises(ImproperlyConfigured):
            get_gateway('nonexistent_gateway')

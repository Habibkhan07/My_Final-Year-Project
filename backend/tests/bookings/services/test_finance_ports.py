"""Tests for the FinancePort Protocol + NullFinanceAdapter + factory wiring."""

from decimal import Decimal

from bookings.adapters import get_default_finance_service
from bookings.adapters.null_finance import NullFinanceAdapter
from bookings.services.finance_ports import FinancePort


class TestNullFinanceAdapter:
    def test_can_accept_job_returns_true_none(self):
        a = NullFinanceAdapter()
        assert a.can_accept_job(technician=None, payout_amount=Decimal('1000')) == (True, None)

    def test_record_commission_returns_none(self):
        assert NullFinanceAdapter().record_commission(booking=None, amount=Decimal('100')) is None

    def test_apply_inspection_fee_decision_no_op(self):
        a = NullFinanceAdapter()
        assert a.apply_inspection_fee_decision(booking=None, decision='accepted') is None
        assert a.apply_inspection_fee_decision(booking=None, decision='declined') is None

    def test_apply_cancellation_charge_no_op(self):
        a = NullFinanceAdapter()
        for actor in ('customer', 'tech'):
            for phase in ('pre_accept', 'pre_arrival', 'post_arrival'):
                assert a.apply_cancellation_charge(
                    booking=None, actor=actor, phase=phase,
                ) is None

    def test_record_cash_collected_no_op(self):
        a = NullFinanceAdapter()
        assert a.record_cash_collected(
            booking=None, amount=Decimal('1500'), method='cash',
        ) is None


class TestProtocolConformance:
    """The Protocol declaration is structural — verify the null adapter
    has every method the Protocol declares."""

    def test_method_set_matches(self):
        protocol_methods = {n for n in dir(FinancePort) if not n.startswith('_')}
        adapter_methods = {n for n in dir(NullFinanceAdapter) if not n.startswith('_')}
        missing = protocol_methods - adapter_methods
        assert not missing, f'NullFinanceAdapter is missing: {missing}'


class TestDefaultFactory:
    def test_returns_null_adapter_instance(self):
        instance = get_default_finance_service()
        assert isinstance(instance, NullFinanceAdapter)

    def test_lazy_import_does_not_pull_finance_at_module_load(self):
        # The factory imports inside the function body. Verify the public
        # bookings.services namespace is free of finance code at import time.
        import bookings.services as services_pkg
        # If the lazy boundary was broken, NullFinanceAdapter would be
        # accessible from the services package — assert it isn't.
        assert not hasattr(services_pkg, 'NullFinanceAdapter')

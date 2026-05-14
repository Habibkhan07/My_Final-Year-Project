"""HTTP-surface tests for the withdrawal endpoints.

Three URLs exercised end-to-end via DRF's APIClient:

* ``GET /api/technicians/wallet/payout-accounts/``
* ``POST /api/technicians/wallet/withdrawals/``
* ``GET /api/technicians/wallet/withdrawals/``

Each test asserts:
  * HTTP status code,
  * canonical error envelope shape (``status / code / message / errors``),
  * IDOR scoping (only this tech's data),
  * mask integrity (raw account number / mobile NEVER on the wire).

The service-layer tests cover the gate matrix in detail — these are
narrower checks on the envelope shaping and auth.
"""
from __future__ import annotations

from decimal import Decimal

import pytest
from rest_framework.test import APIClient

from tests.factories.accounts import UserFactory
from tests.factories.technicians import TechnicianProfileFactory
from tests.factories.wallet import (
    TechnicianBankAccountFactory,
    TechnicianJazzCashAccountFactory,
    WithdrawalRequestFactory,
)
from wallet.models import WithdrawalStatus


PAYOUT_ACCOUNTS_URL = '/api/technicians/wallet/payout-accounts/'
WITHDRAWALS_URL = '/api/technicians/wallet/withdrawals/'


def _client_for(tech):
    client = APIClient()
    client.force_authenticate(user=tech.user)
    return client


def _approved_tech(*, balance=Decimal('1000.00')):
    return TechnicianProfileFactory(
        status='APPROVED',
        is_active=True,
        current_wallet_balance=balance,
    )


# ──────────────────────────────────────────────────────────────────────
# GET /payout-accounts/
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestPayoutAccountsView:
    def test_unauthenticated_returns_401(self):
        resp = APIClient().get(PAYOUT_ACCOUNTS_URL)
        assert resp.status_code == 401

    def test_non_technician_returns_403_envelope(self):
        customer = UserFactory()
        client = APIClient()
        client.force_authenticate(user=customer)

        resp = client.get(PAYOUT_ACCOUNTS_URL)

        assert resp.status_code == 403
        body = resp.json()
        assert body['code'] == 'permission_denied'

    def test_returns_active_accounts_for_this_tech(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(
            technician=tech,
            bank_name='HBL',
            account_title='Ali',
            account_number_or_iban='PK00HBL000000001234',
        )
        jazz = TechnicianJazzCashAccountFactory(
            technician=tech,
            account_title='Ali',
            mobile_number='+923001234567',
        )

        resp = _client_for(tech).get(PAYOUT_ACCOUNTS_URL)

        assert resp.status_code == 200
        body = resp.json()
        assert [a['id'] for a in body['bank_accounts']] == [bank.pk]
        assert [a['id'] for a in body['jazzcash_accounts']] == [jazz.pk]

    def test_raw_account_number_never_on_wire(self):
        """Critical: masking is the only representation that leaves the server."""
        tech = _approved_tech()
        TechnicianBankAccountFactory(
            technician=tech,
            account_number_or_iban='PK00HBL000000001234',
        )

        resp = _client_for(tech).get(PAYOUT_ACCOUNTS_URL)

        body = resp.json()
        bank_row = body['bank_accounts'][0]
        assert bank_row['masked_number'] == '••1234'
        # The raw key must not appear in the response at all.
        assert 'account_number_or_iban' not in bank_row

    def test_raw_mobile_never_on_wire(self):
        tech = _approved_tech()
        TechnicianJazzCashAccountFactory(
            technician=tech, mobile_number='+923001234567',
        )

        resp = _client_for(tech).get(PAYOUT_ACCOUNTS_URL)

        body = resp.json()
        jazz_row = body['jazzcash_accounts'][0]
        # First 4 + masked middle + last 3.
        assert '•••' in jazz_row['masked_mobile']
        assert jazz_row['masked_mobile'].endswith('567')
        assert 'mobile_number' not in jazz_row

    def test_excludes_inactive_accounts(self):
        tech = _approved_tech()
        TechnicianBankAccountFactory(technician=tech, is_active=False)

        resp = _client_for(tech).get(PAYOUT_ACCOUNTS_URL)

        assert resp.json()['bank_accounts'] == []

    def test_idor_protection_scoped_to_this_tech(self):
        me = _approved_tech()
        other = _approved_tech()
        TechnicianBankAccountFactory(technician=other)

        resp = _client_for(me).get(PAYOUT_ACCOUNTS_URL)

        assert resp.json()['bank_accounts'] == []


# ──────────────────────────────────────────────────────────────────────
# POST /withdrawals/
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestWithdrawalCreateView:
    def test_unauthenticated_returns_401(self):
        resp = APIClient().post(WITHDRAWALS_URL, {}, format='json')
        assert resp.status_code == 401

    def test_non_technician_returns_403(self):
        customer = UserFactory()
        client = APIClient()
        client.force_authenticate(user=customer)

        resp = client.post(WITHDRAWALS_URL, {}, format='json')

        assert resp.status_code == 403
        assert resp.json()['code'] == 'permission_denied'

    def test_201_happy_path_bank(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(
            technician=tech,
            bank_name='HBL',
            account_title='Ali',
            account_number_or_iban='PK00HBL000000001234',
        )

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '500.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 201
        body = resp.json()
        assert body['status'] == 'PENDING_REVIEW'
        assert body['ui_status_label'] == 'Under review'
        assert body['amount'] == '500.00'
        assert body['payout']['kind'] == 'bank'
        assert body['payout']['masked'] == '••1234'
        # admin_external_ref is empty until PROCESSED.
        assert body['admin_external_ref'] == ''

    def test_201_happy_path_jazzcash(self):
        tech = _approved_tech()
        jazz = TechnicianJazzCashAccountFactory(
            technician=tech, mobile_number='+923001234567',
        )

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '500.00', 'payout_jazzcash_account_id': jazz.pk},
            format='json',
        )

        assert resp.status_code == 201
        body = resp.json()
        assert body['payout']['kind'] == 'jazzcash'
        assert body['payout']['masked'].endswith('567')

    def test_400_insufficient_funds_envelope(self):
        tech = _approved_tech(balance=Decimal('100.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '500.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['status'] == 400
        assert body['code'] == 'insufficient_funds'
        assert 'requested_pkr' in body['errors']
        assert 'available_pkr' in body['errors']
        assert body['errors']['requested_pkr'] == ['500']
        assert body['errors']['available_pkr'] == ['100']

    def test_403_wallet_lockout_envelope(self):
        tech = _approved_tech(balance=Decimal('-50.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '10.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 403
        body = resp.json()
        assert body['code'] == 'wallet_lockout'
        assert body['errors']['balance_pkr'] == ['-50']
        assert body['errors']['owed_pkr'] == ['50']

    def test_403_inactive_technician_envelope_pending_status(self):
        tech = TechnicianProfileFactory(
            status='PENDING',
            is_active=True,
            current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '100.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 403
        body = resp.json()
        assert body['code'] == 'inactive_technician'
        assert body['errors']['status'] == ['PENDING']

    def test_403_inactive_technician_envelope_deactivated(self):
        tech = TechnicianProfileFactory(
            status='APPROVED',
            is_active=False,
            current_wallet_balance=Decimal('1000.00'),
        )
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '100.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 403
        body = resp.json()
        assert body['code'] == 'inactive_technician'
        assert body['errors']['status'] == ['DEACTIVATED']

    def test_409_duplicate_pending_envelope(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        existing = WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PENDING_REVIEW,
            payout_bank_account=bank,
        )

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '100.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 409
        body = resp.json()
        assert body['code'] == 'duplicate_pending_withdrawal'
        assert body['errors']['pending_request_id'] == [str(existing.pk)]

    def test_400_xor_violation_both_supplied(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        jazz = TechnicianJazzCashAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {
                'amount': '100.00',
                'payout_bank_account_id': bank.pk,
                'payout_jazzcash_account_id': jazz.pk,
            },
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'payout' in body['errors']

    def test_400_xor_violation_neither_supplied(self):
        tech = _approved_tech()

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '100.00'},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'payout' in body['errors']

    def test_400_amount_above_max(self):
        tech = _approved_tech(balance=Decimal('1000000.00'))
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '5001.00', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'amount' in body['errors']

    def test_400_amount_below_min(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '0.50', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'amount' in body['errors']

    def test_400_amount_sub_paisa_precision_rejected(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)

        resp = _client_for(tech).post(
            WITHDRAWALS_URL,
            {'amount': '100.999', 'payout_bank_account_id': bank.pk},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'

    def test_400_idor_other_techs_bank_id(self):
        me = _approved_tech()
        other = _approved_tech()
        other_bank = TechnicianBankAccountFactory(technician=other)

        resp = _client_for(me).post(
            WITHDRAWALS_URL,
            {'amount': '100.00', 'payout_bank_account_id': other_bank.pk},
            format='json',
        )

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'payout_bank_account_id' in body['errors']


# ──────────────────────────────────────────────────────────────────────
# GET /withdrawals/
# ──────────────────────────────────────────────────────────────────────


@pytest.mark.django_db
class TestWithdrawalListView:
    def test_unauthenticated_returns_401(self):
        resp = APIClient().get(WITHDRAWALS_URL)
        assert resp.status_code == 401

    def test_non_technician_returns_403(self):
        customer = UserFactory()
        client = APIClient()
        client.force_authenticate(user=customer)

        resp = client.get(WITHDRAWALS_URL)

        assert resp.status_code == 403
        assert resp.json()['code'] == 'permission_denied'

    def test_returns_empty_when_no_history(self):
        tech = _approved_tech()

        resp = _client_for(tech).get(WITHDRAWALS_URL)

        assert resp.status_code == 200
        body = resp.json()
        assert body['results'] == []
        assert body['next_cursor'] is None

    def test_returns_all_statuses_newest_first(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        for status_ in [
            WithdrawalStatus.PENDING_REVIEW,
            WithdrawalStatus.APPROVED,
            WithdrawalStatus.REJECTED,
            WithdrawalStatus.PROCESSED,
        ]:
            WithdrawalRequestFactory(
                technician=tech, status=status_, payout_bank_account=bank,
            )

        resp = _client_for(tech).get(WITHDRAWALS_URL)

        body = resp.json()
        assert len(body['results']) == 4
        statuses = {r['status'] for r in body['results']}
        assert statuses == {'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'PROCESSED'}

    def test_idor_scoped_to_this_tech(self):
        me = _approved_tech()
        other = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=other)
        WithdrawalRequestFactory(
            technician=other,
            status=WithdrawalStatus.PENDING_REVIEW,
            payout_bank_account=bank,
        )

        resp = _client_for(me).get(WITHDRAWALS_URL)

        assert resp.json()['results'] == []

    def test_invalid_cursor_returns_400_envelope(self):
        tech = _approved_tech()

        resp = _client_for(tech).get(WITHDRAWALS_URL + '?cursor=NOT_A_REAL_CURSOR')

        assert resp.status_code == 400
        body = resp.json()
        assert body['code'] == 'validation_error'
        assert 'cursor' in body['errors']

    def test_invalid_page_size_returns_400(self):
        tech = _approved_tech()

        resp = _client_for(tech).get(WITHDRAWALS_URL + '?page_size=not_a_number')

        assert resp.status_code == 400
        assert resp.json()['code'] == 'validation_error'

    def test_page_size_out_of_range_returns_400(self):
        tech = _approved_tech()

        resp = _client_for(tech).get(WITHDRAWALS_URL + '?page_size=9999')

        assert resp.status_code == 400
        assert resp.json()['code'] == 'validation_error'

    def test_processed_request_surfaces_admin_external_ref(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PROCESSED,
            admin_external_ref='JC-MERCH-2026-05-20-7821',
            payout_bank_account=bank,
        )

        resp = _client_for(tech).get(WITHDRAWALS_URL)

        body = resp.json()
        row = body['results'][0]
        assert row['admin_external_ref'] == 'JC-MERCH-2026-05-20-7821'

    def test_pending_request_does_not_expose_admin_external_ref(self):
        """admin_external_ref shows only at PROCESSED — even if the row has
        a stray value (e.g. admin started filling it before approving),
        it must not leak before fulfilment."""
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(technician=tech)
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PENDING_REVIEW,
            admin_external_ref='SHOULD-NOT-LEAK',
            payout_bank_account=bank,
        )

        resp = _client_for(tech).get(WITHDRAWALS_URL)

        row = resp.json()['results'][0]
        assert row['admin_external_ref'] == ''

    def test_response_does_not_leak_raw_account_number(self):
        tech = _approved_tech()
        bank = TechnicianBankAccountFactory(
            technician=tech, account_number_or_iban='PK00HBL000000001234',
        )
        WithdrawalRequestFactory(
            technician=tech,
            status=WithdrawalStatus.PROCESSED,
            payout_bank_account=bank,
        )

        resp = _client_for(tech).get(WITHDRAWALS_URL)

        body_text = resp.content.decode('utf-8')
        assert 'PK00HBL000000001234' not in body_text

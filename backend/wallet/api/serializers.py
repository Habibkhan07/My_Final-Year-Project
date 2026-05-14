"""DRF serializers for the wallet HTTP surface.

Three families live here:

* :class:`PayoutAccountsResponseSerializer` — read-only, feeds the
  withdrawal screen's "Payout to" picker. Masks account numbers and
  mobile numbers so the wire never carries raw PII.

* :class:`WithdrawalRequestCreateSerializer` — write-only. Strict field
  whitelist; XOR validation; decimal bounds. Defends the service layer
  from malformed input.

* :class:`WithdrawalRequestReadSerializer` — read-only response shape
  for both the create (201) and list (200) endpoints. Carries
  ``ui_status_label`` so the frontend renders without branching on
  ``status``.

CLAUDE.md mass-assignment rule: NEVER ``fields = '__all__'`` on write
serializers. Every write field is explicitly whitelisted below.
"""
from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from wallet.models import (
    TechnicianBankAccount,
    TechnicianJazzCashAccount,
    WithdrawalRequest,
    WithdrawalStatus,
)
from wallet.services.withdrawal_service import (
    MAX_WITHDRAWAL_RUPEES,
    MIN_WITHDRAWAL_RUPEES,
)


# ---------------------------------------------------------------------------
# Payout-account read serializers
# ---------------------------------------------------------------------------

def _mask_account_number(raw: str) -> str:
    """Return ``"••" + last 4`` of an account number / IBAN.

    Defensive against short strings: anything ≤ 4 chars renders as
    ``"••" + raw`` so the masking function never errors on edge inputs.
    Empty input returns ``"••••"`` — better to show a placeholder than
    leak a clue about the underlying length.
    """
    if not raw:
        return '••••'
    last4 = raw[-4:] if len(raw) >= 4 else raw
    return f'••{last4}'


def _mask_mobile_number(raw: str) -> str:
    """Return ``first4 + "•••" + last3`` of a Pakistan MSISDN.

    Designed for ``+923001234567`` shaped strings → ``+923•••567``. Falls
    back to a fully-masked sentinel for unexpected shapes so the wire
    never accidentally carries the raw number when the masking math
    fails.
    """
    if not raw or len(raw) < 7:
        return '•••••••'
    return f'{raw[:4]}•••{raw[-3:]}'


class BankPayoutAccountReadSerializer(serializers.ModelSerializer):
    """Public-safe view of a :class:`TechnicianBankAccount`.

    The masked field is the ONLY representation of the account number
    that ever leaves the server. The raw column is never serialized.
    """

    masked_number = serializers.SerializerMethodField()

    class Meta:
        model = TechnicianBankAccount
        # Explicit field list — no '__all__'.
        fields = ('id', 'bank_name', 'account_title', 'masked_number')
        read_only_fields = fields

    def get_masked_number(self, obj: TechnicianBankAccount) -> str:
        return _mask_account_number(obj.account_number_or_iban)


class JazzCashPayoutAccountReadSerializer(serializers.ModelSerializer):
    """Public-safe view of a :class:`TechnicianJazzCashAccount`."""

    masked_mobile = serializers.SerializerMethodField()

    class Meta:
        model = TechnicianJazzCashAccount
        fields = ('id', 'account_title', 'masked_mobile')
        read_only_fields = fields

    def get_masked_mobile(self, obj: TechnicianJazzCashAccount) -> str:
        return _mask_mobile_number(obj.mobile_number)


class PayoutAccountsResponseSerializer(serializers.Serializer):
    """Wrapper shape for ``GET /api/technicians/wallet/payout-accounts/``.

    Two parallel lists so the frontend renders two distinct sections in
    the picker without needing to branch on a discriminator field.
    """

    bank_accounts = BankPayoutAccountReadSerializer(many=True, read_only=True)
    jazzcash_accounts = JazzCashPayoutAccountReadSerializer(many=True, read_only=True)


# ---------------------------------------------------------------------------
# Withdrawal request write serializer
# ---------------------------------------------------------------------------

class WithdrawalRequestCreateSerializer(serializers.Serializer):
    """Input contract for ``POST /api/technicians/wallet/withdrawals/``.

    NOT a ``ModelSerializer`` — the create path goes through the service,
    not ``serializer.save()``, so the serializer's only job is field
    validation. This keeps the mass-assignment surface explicitly empty:
    there is no path from "field defined on serializer" to "field written
    on model".

    Fields:
      * ``amount`` — Decimal-typed. Bounded to ``[MIN_WITHDRAWAL_RUPEES,
        MAX_WITHDRAWAL_RUPEES]`` (defined in withdrawal_service). The
        service re-validates these bounds as defense in depth.
      * ``payout_bank_account_id`` / ``payout_jazzcash_account_id`` —
        positive integers. Exactly one must be supplied (XOR enforced
        by ``validate()``).
    """

    amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=MIN_WITHDRAWAL_RUPEES,
        max_value=MAX_WITHDRAWAL_RUPEES,
        # Decimal-only ingress. Reject scientific notation / Inf / NaN at
        # the DRF layer — DecimalField does this by default but we keep
        # ``coerce_to_string=False`` so the service receives a real
        # Decimal, not a string.
        coerce_to_string=False,
    )
    payout_bank_account_id = serializers.IntegerField(
        required=False,
        allow_null=True,
        min_value=1,
    )
    payout_jazzcash_account_id = serializers.IntegerField(
        required=False,
        allow_null=True,
        min_value=1,
    )

    def validate(self, attrs):
        """XOR rule: exactly one of bank / jazzcash must be supplied.

        Both null OR both set → 400. Same error message for both shapes
        so a probing client cannot distinguish "I sent both" from "I
        sent neither" — both are user error of the same class.
        """
        bank_id = attrs.get('payout_bank_account_id')
        jazz_id = attrs.get('payout_jazzcash_account_id')
        both_null = bank_id is None and jazz_id is None
        both_set = bank_id is not None and jazz_id is not None
        if both_null or both_set:
            raise serializers.ValidationError({
                'payout': [
                    'Exactly one of payout_bank_account_id or '
                    'payout_jazzcash_account_id is required.'
                ],
            })
        return attrs


# ---------------------------------------------------------------------------
# Withdrawal request read serializer
# ---------------------------------------------------------------------------

_UI_STATUS_LABELS: dict[str, str] = {
    WithdrawalStatus.PENDING_REVIEW: 'Under review',
    WithdrawalStatus.APPROVED: 'Approved (processing)',
    WithdrawalStatus.REJECTED: 'Rejected',
    WithdrawalStatus.PROCESSED: 'Processed',
}


class WithdrawalRequestReadSerializer(serializers.ModelSerializer):
    """Response shape for create (201) and list (200) endpoints.

    Dumb-UI ready: the frontend reads ``ui_status_label`` rather than
    branching on ``status``, and reads ``payout`` (a nested dict with
    ``kind`` / ``label`` / ``masked``) rather than checking which of
    the two FK fields is non-null.

    ``admin_external_ref`` is surfaced only when the request reaches
    PROCESSED — pending / approved / rejected requests have no external
    transfer to reference. This narrowing keeps the wire payload clean
    and avoids dangling-data confusion in the UI.
    """

    ui_status_label = serializers.SerializerMethodField()
    payout = serializers.SerializerMethodField()
    admin_external_ref = serializers.SerializerMethodField()

    class Meta:
        model = WithdrawalRequest
        # Explicit field list. ``technician``, ``reviewed_by``, and the
        # FK ids are intentionally NOT in the public response — the
        # technician is implicit (always the requester), the reviewer is
        # an admin user the tech has no business seeing, and the raw FK
        # ids are replaced by the masked ``payout`` block.
        fields = (
            'id',
            'amount',
            'status',
            'ui_status_label',
            'payout',
            'admin_external_ref',
            'requested_at',
            'reviewed_at',
        )
        read_only_fields = fields

    def get_ui_status_label(self, obj: WithdrawalRequest) -> str:
        return _UI_STATUS_LABELS.get(obj.status, obj.status)

    def get_payout(self, obj: WithdrawalRequest) -> dict:
        """Return ``{kind, label, masked}`` for the picked payout target.

        ``kind`` ∈ ``{"bank", "jazzcash"}`` so the frontend renders the
        right icon without re-checking which FK is set. ``label`` is the
        human-readable account title; ``masked`` is the partial number.
        """
        if obj.payout_bank_account_id is not None:
            acct = obj.payout_bank_account
            return {
                'kind': 'bank',
                'label': f'{acct.bank_name} — {acct.account_title}',
                'masked': _mask_account_number(acct.account_number_or_iban),
            }
        if obj.payout_jazzcash_account_id is not None:
            acct = obj.payout_jazzcash_account
            return {
                'kind': 'jazzcash',
                'label': f'JazzCash — {acct.account_title}',
                'masked': _mask_mobile_number(acct.mobile_number),
            }
        # The DB CheckConstraint prevents both being null. This branch
        # is unreachable — kept as a defensive default for forensic
        # readability rather than a real code path.
        return {'kind': 'unknown', 'label': '', 'masked': ''}

    def get_admin_external_ref(self, obj: WithdrawalRequest) -> str:
        if obj.status == WithdrawalStatus.PROCESSED:
            return obj.admin_external_ref or ''
        return ''


class WithdrawalRequestListResponseSerializer(serializers.Serializer):
    """Wrapper for the cursor-paginated history endpoint."""

    results = WithdrawalRequestReadSerializer(many=True, read_only=True)
    next_cursor = serializers.CharField(allow_null=True, required=False)

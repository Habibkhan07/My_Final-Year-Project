"""Combined complete + cash collection (sprint meta §14 rule 2).

There is no separate ``mark-complete`` endpoint — the tech taps a single
``Cash Collected: Rs. X`` button bound to ``final_cash_to_collect`` and
this endpoint flips ``IN_PROGRESS → COMPLETED`` while stamping the cash
columns. The ``method`` parameter is reserved for future expansion (e.g.
mobile-money receipts); CLAUDE.md restricts it to ``'cash'`` for v1 and
the orchestrator enforces that frozenset gate.
"""
from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from bookings.models import JobBooking


class ConfirmCashReceivedRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=Decimal("0.01"),
    )
    method = serializers.ChoiceField(
        choices=[("cash", "Cash")],
        default="cash",
    )


class ConfirmCashReceivedResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = JobBooking
        fields = [
            "id",
            "status",
            "cash_collected_amount",
            "cash_collected_at",
            "cash_collection_method",
            "completed_at",
        ]

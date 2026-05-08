"""Quote endpoints (submit / approve / decline / request-revision).

The orchestrator is the canonical line-item validator (band check,
empty-quote rejection, decimal coercion). These serializers do shape +
type validation only — broader semantic validation surfaces from the
orchestrator as ``BookingValidationError``.
"""
from __future__ import annotations

from rest_framework import serializers


class QuoteLineItemInputSerializer(serializers.Serializer):
    sub_service_id = serializers.IntegerField(min_value=1)
    # Audit P2 (Pass 2 / C5-new): bound quantity to keep the
    # orchestrator's ``priced_at * quantity`` arithmetic inside the
    # Decimal(max_digits=10) ceiling (max line_total = 99,999,999.99).
    # Without an upper bound, a tech sending ``quantity=2147483647``
    # alongside a moderate ``priced_at`` overflows the line_total
    # column and either truncates silently or raises a 500. The cap
    # 999 covers every realistic scenario (the labor catalog tops out
    # at ~50 units/job).
    quantity = serializers.IntegerField(min_value=1, max_value=999, default=1)
    # Decimal-as-string is the canonical wire format. The orchestrator
    # coerces via ``Decimal(str(...))`` and rejects unparseable values.
    priced_at = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        min_value=0,
    )


class SubmitQuoteRequestSerializer(serializers.Serializer):
    is_upsell = serializers.BooleanField(default=False)
    line_items = QuoteLineItemInputSerializer(many=True, allow_empty=False)


class QuoteLineItemResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    sub_service_id = serializers.IntegerField()
    sub_service_name = serializers.CharField(source="sub_service.name")
    quantity = serializers.IntegerField()
    priced_at = serializers.DecimalField(max_digits=10, decimal_places=2)
    line_total = serializers.DecimalField(max_digits=10, decimal_places=2)


class QuoteResponseSerializer(serializers.Serializer):
    """Output shape for ``POST /quotes/`` and the active-quote slot of
    the booking-detail response."""
    id = serializers.IntegerField()
    booking_id = serializers.IntegerField()
    revision_number = serializers.IntegerField()
    status = serializers.CharField()
    total_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    is_upsell = serializers.BooleanField()
    line_items = QuoteLineItemResponseSerializer(many=True)
    submitted_at = serializers.DateTimeField()


class ApproveQuoteResponseSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    status = serializers.CharField()
    final_cash_to_collect = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        allow_null=True,
    )


class DeclineQuoteRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=2000,
    )


class DeclineQuoteResponseSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    status = serializers.CharField()
    final_cash_to_collect = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        allow_null=True,
    )


class RequestRevisionRequestSerializer(serializers.Serializer):
    reason = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=2000,
    )


class RequestRevisionResponseSerializer(serializers.Serializer):
    booking_id = serializers.IntegerField()
    status = serializers.CharField()
    superseded_quote_id = serializers.IntegerField()

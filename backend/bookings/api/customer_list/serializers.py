"""
Customer-side bookings list / counts serializers.

These serializers are wire-format only — request validation on ingress
and shape rendering on egress. All business logic lives in the selector
(``bookings/selectors/customer_bookings_selector.py``).

The list response is **already a dict** by the time it reaches the view
(the selector returns a typed dataclass with primitive fields). The
serializers here exist to:

1. Validate / normalize inbound query params with friendly error keys
   that surface in the standard error envelope.
2. Document the egress shape in code, even though the selector hands
   the view a wire-ready dict — so a future refactor that replaces the
   dict with a model-based path doesn't have to re-derive the shape
   from scratch.
"""
from __future__ import annotations

from rest_framework import serializers

from bookings.selectors.customer_bookings_selector import (
    ALLOWED_SEGMENTS,
    ALLOWED_STATUSES,
    DEFAULT_PAGE_SIZE,
    MAX_PAGE_SIZE,
    SEGMENT_UPCOMING,
)


class _CsvStatusField(serializers.CharField):
    """
    Comma-separated list of ``JobBooking.status`` values. Accepts any
    casing; emits uppercase. Empty / missing → None (selector falls
    back to segment).
    """
    def to_internal_value(self, data):
        raw = super().to_internal_value(data) or ""
        if not raw.strip():
            return None
        parts = [p.strip().upper() for p in raw.split(",") if p.strip()]
        unknown = [p for p in parts if p not in ALLOWED_STATUSES]
        if unknown:
            raise serializers.ValidationError(
                f"Unknown status value(s): {', '.join(unknown)}."
            )
        return parts


class CustomerBookingsListQuerySerializer(serializers.Serializer):
    """
    Validates GET /api/bookings/ query params.

    Required: none. All fields are optional with sensible defaults baked
    into the selector.

    ``segment`` is the dumb-UI shortcut Flutter sends. ``status`` is the
    explicit-filter escape hatch reserved for future filter chips —
    when present it overrides the segment-implied status set.
    """
    segment = serializers.ChoiceField(
        choices=sorted(ALLOWED_SEGMENTS),
        required=False,
        default=SEGMENT_UPCOMING,
    )
    status = _CsvStatusField(required=False, allow_blank=True, default=None)
    cursor = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=512,
        default=None,
    )
    page_size = serializers.IntegerField(
        required=False,
        min_value=1,
        max_value=MAX_PAGE_SIZE,
        default=DEFAULT_PAGE_SIZE,
    )
    since = serializers.DateTimeField(required=False, default=None)


class _BookingServiceSerializer(serializers.Serializer):
    """Dumb-UI: ``icon_name`` keys into Flutter's ``IconAssets.path()``."""
    name = serializers.CharField()
    icon_name = serializers.CharField(allow_blank=True)


class _BookingTechnicianSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    display_name = serializers.CharField()
    profile_picture_url = serializers.CharField(allow_null=True)


class _BookingPriceSerializer(serializers.Serializer):
    """Both raw amount and pre-formatted label cross the wire — see CLAUDE.md."""
    amount = serializers.IntegerField()
    context = serializers.CharField(allow_blank=True)
    ui_label = serializers.CharField()


class _BookingUiSerializer(serializers.Serializer):
    """Server-side dumb-UI block. Mirrored client-side in event-patch mapper."""
    badge_text = serializers.CharField()
    badge_tone = serializers.CharField()
    headline = serializers.CharField()


class BookingListItemSerializer(serializers.Serializer):
    """
    The unit of the list response. Card-shaped, intentionally lighter
    than the (forthcoming) detail serializer — no full address, no
    sub-service description, no timeline.
    """
    id = serializers.IntegerField()
    status = serializers.CharField()
    service = _BookingServiceSerializer()
    technician = _BookingTechnicianSerializer()
    address_label = serializers.CharField(allow_null=True)
    scheduled_start = serializers.CharField()
    scheduled_end = serializers.CharField()
    created_at = serializers.CharField()
    price = _BookingPriceSerializer()
    ui = _BookingUiSerializer()


class BookingsListResponseSerializer(serializers.Serializer):
    """List envelope. ``server_time`` anchors client-side relative formatting."""
    items = BookingListItemSerializer(many=True)
    next_cursor = serializers.CharField(allow_null=True)
    has_more = serializers.BooleanField()
    server_time = serializers.CharField()


class BookingsCountsResponseSerializer(serializers.Serializer):
    upcoming = serializers.IntegerField()
    past = serializers.IntegerField()
    server_time = serializers.CharField()

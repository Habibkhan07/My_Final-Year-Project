"""Booking-detail response — full payload for the orchestrator screen.

Composed via ``to_representation`` over a dict the view assembles from:
  * the booking row (with eager joins on customer, address, technician)
  * the active quote (selector handles prefetches)
  * the booking item snapshot
  * the open-tickets count
  * the resolved ``ui`` block (orchestrator_ui selector)
  * the ``available_transitions`` projection (transition_validator selector)

Serializer-driven shape — not a ModelSerializer — because we're
producing a hand-shaped contract the Flutter screen consumes verbatim,
not a Django-model passthrough.
"""
from __future__ import annotations

from rest_framework import serializers

from bookings.api.quotes.serializers import QuoteResponseSerializer


class _BookingItemResponseSerializer(serializers.Serializer):
    """Wire shape for an accepted ``BookingItem`` row.

    Distinct from ``QuoteLineItemResponseSerializer`` even though the two
    look almost identical: the field names diverge (``BookingItem`` has
    ``price_charged``; ``QuoteLineItem`` has ``priced_at``) and only this
    one carries ``sourced_quote_id``. Reusing the quote-line serializer
    here would raise ``AttributeError: 'BookingItem' object has no
    attribute 'priced_at'`` at runtime — silently undetected because no
    booking-detail test fixture currently includes a BookingItem row.
    """
    id = serializers.IntegerField()
    sub_service_id = serializers.IntegerField()
    sub_service_name = serializers.CharField(source="sub_service.name")
    quantity = serializers.IntegerField()
    price_charged = serializers.DecimalField(max_digits=10, decimal_places=2)
    line_total = serializers.DecimalField(max_digits=10, decimal_places=2)
    sourced_quote_id = serializers.IntegerField(allow_null=True)


class _ServiceMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    icon_name = serializers.CharField()


class _SubServiceMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()
    is_fixed_price = serializers.BooleanField()
    base_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    max_price = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        allow_null=True,
    )


class _AddressMiniSerializer(serializers.Serializer):
    label = serializers.CharField()
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    # Maps to ``CustomerAddress.street_address``; the wire field is
    # ``address_text`` because the frontend uses it as a generic string
    # blob and may render reverse-geocoded suburb labels too.
    address_text = serializers.CharField()


class _TechnicianMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    display_name = serializers.CharField()
    profile_picture_url = serializers.CharField(allow_null=True)
    # Mirrors customer.phone_no — sourced from the tech's UserProfile so
    # the customer-side summary card can offer a tel: deep link. Empty
    # string when the tech's UserProfile is missing the phone (legacy /
    # system accounts).
    phone_no = serializers.CharField(allow_blank=True)
    # Bayesian-averaged rating shown in the summary card. Decimal on the
    # model; we surface the raw string so the frontend can parse to int
    # rupees-style or render as-is.
    rating_average = serializers.DecimalField(max_digits=3, decimal_places=2)


class _CustomerMiniSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    full_name = serializers.CharField()
    phone_no = serializers.CharField()


class _PhaseTimestampsSerializer(serializers.Serializer):
    accepted_at = serializers.DateTimeField(allow_null=True)
    en_route_started_at = serializers.DateTimeField(allow_null=True)
    arrived_at = serializers.DateTimeField(allow_null=True)
    # InDrive-style "I'm coming out" ACK from the customer; null until the
    # customer taps the CTA on the ARRIVED screen.
    customer_acknowledged_arrival_at = serializers.DateTimeField(allow_null=True)
    inspection_started_at = serializers.DateTimeField(allow_null=True)
    quote_first_submitted_at = serializers.DateTimeField(allow_null=True)
    work_started_at = serializers.DateTimeField(allow_null=True)
    completed_at = serializers.DateTimeField(allow_null=True)


class _PricingSerializer(serializers.Serializer):
    inspection_fee = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )
    base_services_total = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )
    discount_applied = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )
    final_cash_to_collect = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )
    promo_code_snapshot = serializers.CharField(allow_null=True)
    promo_discount_snapshot = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )


class _CashCollectionSerializer(serializers.Serializer):
    amount = serializers.DecimalField(
        max_digits=10, decimal_places=2, allow_null=True,
    )
    at = serializers.DateTimeField(allow_null=True)
    method = serializers.CharField()


class _UiActionSerializer(serializers.Serializer):
    label = serializers.CharField()
    endpoint = serializers.CharField()
    method = serializers.CharField()
    style = serializers.ChoiceField(
        choices=["primary", "destructive", "neutral"],
        required=False,
    )


class _UiBlockSerializer(serializers.Serializer):
    status_label = serializers.CharField()
    body_text = serializers.CharField(allow_blank=True)
    primary_action = _UiActionSerializer(allow_null=True)
    secondary_actions = _UiActionSerializer(many=True, default=list)
    show_tracking = serializers.BooleanField()
    show_quote_card = serializers.BooleanField()
    show_dispute_button = serializers.BooleanField()
    tone = serializers.ChoiceField(
        choices=["positive", "warning", "negative", "neutral", "info"],
    )


class BookingDetailResponseSerializer(serializers.Serializer):
    """Composed shape for ``GET /api/bookings/<id>/``.

    The view assembles a payload dict; this serializer's
    ``to_representation`` shapes every field the frontend consumes.
    Read-only contract — no ``create`` / ``update`` paths.
    """

    def to_representation(self, payload: dict):
        booking = payload["booking"]
        request = self.context.get("request")

        # Audit P1-02: TechnicianProfile.profile_picture is an ImageField,
        # not a URL field. Build absolute URI via request when available.
        tech_profile_url = None
        if booking.technician.profile_picture:
            tech_profile_url = booking.technician.profile_picture.url
            if request is not None:
                tech_profile_url = request.build_absolute_uri(tech_profile_url)

        # Audit P1-01: User has no ``phone_no``; phone lives on
        # accounts.UserProfile (default reverse accessor ``userprofile``).
        # A User without a UserProfile (legacy/system accounts) falls
        # back to empty string rather than raising.
        try:
            customer_phone = booking.customer.userprofile.phone or ""
        except AttributeError:
            customer_phone = ""
        # Same lookup for the technician's underlying User. Same
        # missing-profile fallback applies.
        try:
            technician_phone = booking.technician.user.userprofile.phone or ""
        except AttributeError:
            technician_phone = ""

        return {
            "id": booking.id,
            "status": booking.status,
            "service": _ServiceMiniSerializer({
                "id": booking.service.id,
                "name": booking.service.name,
                "icon_name": getattr(booking.service, "icon_name", "") or "",
            }).data,
            "sub_service": (
                _SubServiceMiniSerializer({
                    "id": booking.sub_service.id,
                    "name": booking.sub_service.name,
                    "is_fixed_price": booking.sub_service.is_fixed_price,
                    "base_price": booking.sub_service.base_price,
                    "max_price": booking.sub_service.max_price,
                }).data
                if booking.sub_service_id is not None
                else None
            ),
            "technician": _TechnicianMiniSerializer({
                "id": booking.technician.id,
                "display_name": (
                    booking.technician.user.get_full_name()
                    or booking.technician.user.username
                ),
                "profile_picture_url": tech_profile_url,
                "phone_no": technician_phone,
                "rating_average": booking.technician.rating_average,
            }).data,
            "customer": _CustomerMiniSerializer({
                "id": booking.customer.id,
                "full_name": (
                    booking.customer.get_full_name()
                    or booking.customer.username
                ),
                "phone_no": customer_phone,
            }).data,
            "address": (
                _AddressMiniSerializer({
                    "label": booking.address.label,
                    "latitude": booking.address.latitude,
                    "longitude": booking.address.longitude,
                    "address_text": booking.address.street_address,
                }).data
                if booking.address is not None
                else None
            ),
            "address_snapshot": booking.actual_address_snapshot,
            "scheduled_start": booking.scheduled_start.isoformat(),
            "scheduled_end": booking.scheduled_end.isoformat(),
            "phase_timestamps": _PhaseTimestampsSerializer({
                "accepted_at": booking.accepted_at,
                "en_route_started_at": booking.en_route_started_at,
                "arrived_at": booking.arrived_at,
                "customer_acknowledged_arrival_at": booking.customer_acknowledged_arrival_at,
                "inspection_started_at": booking.inspection_started_at,
                "quote_first_submitted_at": booking.quote_first_submitted_at,
                "work_started_at": booking.work_started_at,
                "completed_at": booking.completed_at,
            }).data,
            "pricing": _PricingSerializer({
                "inspection_fee": booking.inspection_fee,
                "base_services_total": booking.base_services_total,
                "discount_applied": booking.discount_applied,
                "final_cash_to_collect": booking.final_cash_to_collect,
                "promo_code_snapshot": booking.promo_code_snapshot,
                "promo_discount_snapshot": booking.promo_discount_snapshot,
            }).data,
            "cash_collection": _CashCollectionSerializer({
                "amount": booking.cash_collected_amount,
                "at": booking.cash_collected_at,
                "method": booking.cash_collection_method,
            }).data,
            "parent_booking_id": booking.parent_booking_id,
            # Reschedule lineage forward-pointer. When this booking is the
            # CANCELLED original of a reschedule chain, surface the child's
            # id so the orchestrator screen can render a "Continued on #N"
            # callout — otherwise a customer/tech who returns to the
            # original (e.g. via a stale FCM tap) is stranded with no way
            # back to the live booking. Pulled from the related_name on
            # the parent FK; we pick the most recently created child to
            # tolerate the (theoretical) case of a chain longer than one.
            "child_booking_id": payload["child_booking_id"],
            "cancel_reason": booking.cancel_reason,
            "no_show_actor": booking.no_show_actor,
            "active_quote": (
                _serialize_active_quote(payload["active_quote"])
                if payload["active_quote"] is not None
                else None
            ),
            "booking_items": _BookingItemResponseSerializer(
                payload["booking_items"], many=True,
            ).data,
            "open_tickets_count": payload["open_tickets_count"],
            "ui": _UiBlockSerializer(payload["ui"]).data,
            "available_transitions": payload["available_transitions"],
        }


def _serialize_active_quote(quote) -> dict:
    """Map a ``Quote`` instance to ``QuoteResponseSerializer`` input shape."""
    return QuoteResponseSerializer({
        "id": quote.id,
        "booking_id": quote.booking_id,
        "revision_number": quote.revision_number,
        "status": quote.status,
        "total_amount": quote.total_amount,
        "is_upsell": quote.is_upsell,
        "line_items": list(quote.line_items.all()),
        "submitted_at": quote.submitted_at,
    }).data

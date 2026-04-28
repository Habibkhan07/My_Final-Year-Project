from rest_framework import serializers


class InstantBookSerializer(serializers.Serializer):
    """
    Validates the payload for ``POST /api/bookings/instant-book/``.

    ``scheduled_start`` / ``scheduled_end`` must be timezone-aware ISO 8601
    strings (Flutter sends PKT datetimes with ``+05:00`` offset). DRF's
    ``DateTimeField`` parses them into aware datetimes; Django stores in UTC.

    Catalog reference IDs (``service_id`` / ``sub_service_id`` /
    ``promotion_id``) carry the customer's discovery intent through to the
    booking. They are not user-typed at booking time — Flutter threads them
    through from the URL the customer arrived on (search match, gig tile,
    category tile, promo banner). The service layer re-validates the
    triplet for consistency before persisting.

    The previous ``price_context`` ingress field has been removed; the
    server now derives the customer-receipt label from the resolved
    catalog references.
    """
    technician_id   = serializers.IntegerField(min_value=1)
    address_id      = serializers.IntegerField(min_value=1)
    service_id      = serializers.IntegerField(min_value=1)
    sub_service_id  = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    promotion_id    = serializers.IntegerField(min_value=1, required=False, allow_null=True)
    scheduled_start = serializers.DateTimeField()
    scheduled_end   = serializers.DateTimeField()
    price_amount    = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0)

    def validate(self, data):
        if data['scheduled_end'] <= data['scheduled_start']:
            raise serializers.ValidationError(
                {'scheduled_end': ['scheduled_end must be after scheduled_start.']}
            )
        return data

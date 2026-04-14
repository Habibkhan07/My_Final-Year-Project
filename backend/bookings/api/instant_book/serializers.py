from rest_framework import serializers


class InstantBookSerializer(serializers.Serializer):
    """
    Validates the payload for POST /api/bookings/instant-book/.

    scheduled_start / scheduled_end must be timezone-aware ISO 8601 strings
    (Flutter sends PKT datetimes with +05:00 offset). DRF's DateTimeField
    parses them into aware datetime objects; Django stores them in UTC.
    """
    technician_id  = serializers.IntegerField(min_value=1)
    address_id     = serializers.IntegerField(min_value=1)
    scheduled_start = serializers.DateTimeField()
    scheduled_end   = serializers.DateTimeField()
    price_amount    = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=0)
    price_context   = serializers.CharField(max_length=50, required=False, default='', allow_blank=True)

    def validate(self, data):
        if data['scheduled_end'] <= data['scheduled_start']:
            raise serializers.ValidationError(
                {'scheduled_end': ['scheduled_end must be after scheduled_start.']}
            )
        return data

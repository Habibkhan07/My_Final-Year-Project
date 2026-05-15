from rest_framework import serializers


class TechnicianWorkLocationReadSerializer(serializers.Serializer):
    """Egress shape for GET /api/technicians/me/work-location/.

    ``is_set`` is the field UIs branch on — derived server-side from
    (latitude is not None and longitude is not None) so Flutter never has to
    encode that rule. The dashboard banner reads the same flag via the
    dashboard payload's ``has_work_location`` so the tech does not need a
    second round-trip just to decide whether to nag.
    """

    is_set = serializers.BooleanField()
    latitude = serializers.FloatField(allow_null=True)
    longitude = serializers.FloatField(allow_null=True)
    max_travel_radius_km = serializers.IntegerField()
    work_address_label = serializers.CharField(allow_null=True, allow_blank=True)


class TechnicianWorkLocationWriteSerializer(serializers.Serializer):
    """Ingress shape for PATCH /api/technicians/me/work-location/.

    Bounds are enforced here, not at the service — keeping the contract
    declarative makes the error envelope's ``errors`` map field-accurate
    without the service having to know about HTTP shapes.
    """

    latitude = serializers.FloatField(min_value=-90.0, max_value=90.0)
    longitude = serializers.FloatField(min_value=-180.0, max_value=180.0)
    max_travel_radius_km = serializers.IntegerField(
        required=False, min_value=1, max_value=100,
    )
    work_address_label = serializers.CharField(
        required=False, allow_null=True, allow_blank=True, max_length=200,
    )

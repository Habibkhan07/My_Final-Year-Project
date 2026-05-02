from rest_framework import serializers
from customers.models import CustomerAddress


# The 7 client-supplied structured locality fields. The Flutter map-picker
# reverse-geocodes (Google in prod, OSM Nominatim in dev) and POSTs these
# alongside lat/lng. Backend stores verbatim. lat/lng remains the trusted
# source for distance/matchmaking; these are display-only.
_LOCALITY_FIELDS = (
    'neighborhood', 'suburb', 'city', 'state', 'country',
    'postal_code', 'locality_label',
)


class CustomerAddressReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerAddress
        fields = [
            'id', 'label', 'street_address', 'latitude', 'longitude',
            'is_default', 'created_at',
            *_LOCALITY_FIELDS,
        ]
        read_only_fields = fields


class CustomerAddressWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerAddress
        fields = [
            'label', 'street_address', 'latitude', 'longitude', 'is_default',
            *_LOCALITY_FIELDS,
        ]
        # All structured locality fields are optional on the wire — older
        # Flutter clients during rollout may not send them, and Google/OSM
        # often return partial coverage (e.g. rural rows have no suburb).
        extra_kwargs = {
            field: {'required': False, 'allow_null': True}
            for field in _LOCALITY_FIELDS
        }

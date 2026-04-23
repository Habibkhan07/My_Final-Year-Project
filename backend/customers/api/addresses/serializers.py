from rest_framework import serializers
from customers.models import CustomerAddress


class CustomerAddressReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerAddress
        fields = ['id', 'label', 'street_address', 'latitude', 'longitude', 'is_default', 'created_at']
        read_only_fields = fields


class CustomerAddressWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerAddress
        fields = ['label', 'street_address', 'latitude', 'longitude', 'is_default']

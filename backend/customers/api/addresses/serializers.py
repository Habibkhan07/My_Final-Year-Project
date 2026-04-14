from rest_framework import serializers
from ...models import SavedAddress

class SavedAddressSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedAddress
        fields = ['id', 'label', 'latitude', 'longitude', 'address_text']

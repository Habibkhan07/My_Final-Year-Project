from rest_framework import serializers
from catalog.models import SubService

class SubServiceSearchSerializer(serializers.ModelSerializer):
    """
    Egress transformation for live search results.
    Pulls data across the foreign key efficiently.
    """
    category_name = serializers.CharField(source='service.name', read_only=True)
    category_icon_name = serializers.CharField(source='service.icon_name', read_only=True)
    base_price = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=True)

    class Meta:
        model = SubService
        fields = [
            'id',
            'name',
            'category_name',
            'category_icon_name',
            'icon_name',
            'card_image_url',
            'base_price',
            'is_fixed_price',
        ]
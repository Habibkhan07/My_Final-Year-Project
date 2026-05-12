"""Response shape for the quotable-sub-services endpoint.

Whitelist explicit. Per CLAUDE.md "Mass Assignment: NEVER `fields =
'__all__'` on write serializers." This is read-only egress, but explicit
field lists keep the wire contract auditable when the SubService model
grows new columns (e.g. `is_featured`, `search_tags`).

`max_price` is null when the row is fixed-price; the frontend uses null
as the signal to lock the price field and substitute `base_price`.
"""
from __future__ import annotations

from rest_framework import serializers

from catalog.models import SubService


class QuotableSubServiceSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubService
        fields = [
            'id',
            'name',
            'base_price',
            'max_price',
            'is_fixed_price',
        ]
        read_only_fields = fields

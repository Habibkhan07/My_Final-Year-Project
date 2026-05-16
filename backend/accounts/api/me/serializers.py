"""
Profile (`/api/accounts/me/`) serializers.

Read and write contracts are intentionally separate classes:
- `MeOutputSerializer` is a `ModelSerializer` reading from `User` joined to
  `UserProfile` — phone and is_technician live on the profile.
- `MeUpdateSerializer` is a plain `Serializer` with an explicit field
  whitelist, so PATCH cannot ever write through to `phone`, `is_technician`,
  `is_staff`, etc. Mass-assignment guard per the CLAUDE.md security rule.
"""
from rest_framework import serializers
from django.contrib.auth.models import User


class MeOutputSerializer(serializers.ModelSerializer):
    """
    Egress contract for `GET /api/accounts/me/` and the PATCH response.

    `phone` and `is_technician` are sourced from the related `UserProfile`
    row via `source='userprofile.<field>'`. The view's selector ensures
    `userprofile` is already joined on the request user — no N+1.
    """
    phone = serializers.CharField(source='userprofile.phone', read_only=True)
    is_technician = serializers.BooleanField(
        source='userprofile.is_technician', read_only=True
    )

    class Meta:
        model = User
        # SECURITY: explicit whitelist. NEVER `__all__` — would leak
        # is_staff / is_superuser / password hash / last_login.
        fields = ['id', 'first_name', 'last_name', 'phone', 'is_technician']
        read_only_fields = fields  # GET-side serializer is fully read-only.


class MeUpdateSerializer(serializers.Serializer):
    """
    Ingress contract for `PATCH /api/accounts/me/`.

    Only `first_name` and `last_name` are writeable here. Phone changes
    require a re-OTP flow; `is_technician` flips only through admin
    approval of a TechnicianProfile. Both are intentionally not exposed.

    `max_length=150` mirrors `auth.User.first_name` / `last_name`.
    """
    first_name = serializers.CharField(max_length=150)
    last_name = serializers.CharField(max_length=150)

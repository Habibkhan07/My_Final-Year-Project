"""DRF serializers for the customer-side review surface.

Three serializers:

* ``ReviewSubmitSerializer`` — write-side. Whitelisted fields; never
  ``__all__``. Validates tag keys against
  ``technicians.constants.review_tags.ALL_TAG_KEYS`` at the boundary
  so the service layer never sees unknown keys from a malformed
  client payload.
* ``ReviewDetailSerializer`` — read-side single row. Composes a safe
  display name ("Ali K.") so the API never leaks the reviewer's full
  last name to the public tech profile page.
* ``BookingReviewResponseSerializer`` — wraps the GET body with the
  predefined-tag dictionary so the FE can render the chip set without
  a second round-trip.
"""
from __future__ import annotations

from rest_framework import serializers

from technicians.constants.review_tags import (
    ALL_TAG_KEYS,
    CONSTRUCTIVE_TAGS,
    POSITIVE_TAGS,
)
from technicians.models import Review


class ReviewSubmitSerializer(serializers.Serializer):
    """Write-side validation. Mirrors the service's ``ValueError``
    invariants at the wire boundary so the failure path is a 400
    envelope, not a 500 from an escaped ``ValueError``.

    The view passes ``validated_data`` straight to the service —
    field names match the service kwargs by design.
    """

    rating = serializers.IntegerField(min_value=1, max_value=5)
    tags = serializers.ListField(
        child=serializers.CharField(),
        required=False,
        allow_empty=True,
        max_length=10,  # hard cap matches the largest bucket; defence-in-depth
    )
    text = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=500,
        trim_whitespace=True,
    )

    def validate_tags(self, value: list[str]) -> list[str]:
        """Reject any tag key not in the predefined vocabulary.

        Surfaces unknown keys in the error envelope's ``tags`` field
        so the Flutter ``_mapFailures`` switch can disable the
        specific offending chip rather than blanket-error the form.
        """
        unknown = [k for k in value if k not in ALL_TAG_KEYS]
        if unknown:
            raise serializers.ValidationError(
                f"Unknown tag(s): {', '.join(unknown)}"
            )
        # Drop duplicates here too, preserving order. The service does
        # the same — doing it at the boundary as well means the
        # validated_data dict already matches what the DB will store,
        # and tests asserting on validated_data don't need to
        # post-process.
        seen: set[str] = set()
        deduped: list[str] = []
        for k in value:
            if k not in seen:
                seen.add(k)
                deduped.append(k)
        return deduped


class ReviewDetailSerializer(serializers.ModelSerializer):
    """Single review row for both the booking-detail response and the
    paginated public list on the tech profile screen.

    ``reviewer_name`` is composed server-side as "First L." — never
    the full last name. Customer privacy + protects the customer from
    targeted follow-up by a disgruntled tech.
    """

    reviewer_name = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ["id", "rating", "tags", "text", "created_at", "reviewer_name"]
        read_only_fields = fields  # this serializer is read-only

    def get_reviewer_name(self, obj: Review) -> str:
        reviewer = obj.reviewer
        if reviewer is None:
            return "Anonymous"
        first = (reviewer.first_name or "").strip()
        last = (reviewer.last_name or "").strip()
        if not first and not last:
            # Fall back to the local part of the username so the
            # response never renders as a literal empty string.
            return (reviewer.username or "Customer").split("@")[0]
        if first and last:
            return f"{first} {last[0].upper()}."
        return first or last


class _PredefinedTagSerializer(serializers.Serializer):
    """Wire shape for a single chip — mirrors the TypedDict in
    ``technicians.constants.review_tags``."""

    key = serializers.CharField()
    label = serializers.CharField()


class BookingReviewResponseSerializer(serializers.Serializer):
    """GET ``/api/bookings/<id>/review/`` body.

    ``review`` is null when the customer hasn't submitted yet — the FE
    uses that to switch between the form body and the thank-you body.

    ``predefined_tags`` carries BOTH the positive and constructive
    chip sets in one response so the FE can swap them client-side as
    the user's selected rating changes, without a second round-trip.
    Adds ~250 bytes per response; negligible.
    """

    review = ReviewDetailSerializer(allow_null=True)
    predefined_tags = serializers.SerializerMethodField()

    def get_predefined_tags(self, _obj) -> dict:
        return {
            "positive": _PredefinedTagSerializer(POSITIVE_TAGS, many=True).data,
            "constructive": _PredefinedTagSerializer(CONSTRUCTIVE_TAGS, many=True).data,
        }


class TechnicianReviewsPageSerializer(serializers.Serializer):
    """Response shape for ``GET /api/technicians/<id>/reviews/``."""

    reviews = ReviewDetailSerializer(many=True)
    next_cursor = serializers.IntegerField(allow_null=True)
    has_more = serializers.BooleanField()

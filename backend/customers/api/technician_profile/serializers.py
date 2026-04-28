# customers/api/technician_profile/serializers.py
from rest_framework import serializers
from technicians.models import TechnicianProfile, TechnicianSkill, Review
from bookings.selectors import resolve_booking_intent


class ReviewSummarySerializer(serializers.ModelSerializer):
    """Top 2 most-recent customer reviews shown on the profile page."""
    reviewer_name = serializers.SerializerMethodField()

    class Meta:
        model = Review
        fields = ['reviewer_name', 'rating', 'text']

    def get_reviewer_name(self, obj):
        if obj.reviewer:
            return obj.reviewer.get_full_name() or obj.reviewer.username
        return "Anonymous"


class SkillSummarySerializer(serializers.ModelSerializer):
    """
    Represents a single skill chip on the profile page.
    icon_name maps to assets/icons/{icon_name}.svg on the Flutter side.
    """
    name = serializers.CharField(source='sub_service.name', read_only=True)
    # allow_null=True: SubService.icon_name is null=True in the DB. Flutter
    # maps non-null values to assets/icons/{icon_name}.svg; treats null as
    # "no icon" and falls back to a generic placeholder.
    icon_name = serializers.CharField(source='sub_service.icon_name', read_only=True, allow_null=True)

    class Meta:
        model = TechnicianSkill
        fields = ['name', 'icon_name']


class TechnicianProfileDetailSerializer(serializers.ModelSerializer):
    """
    Full profile serializer for GET /api/customers/technician-profile/{id}/.

    Pricing engine implements 3 mutually-exclusive scenarios with an absolute
    promo firewall on fixed-price gigs (Scenario A).

    Context keys expected (injected by view):
      - resolved_service    : Service | None
      - resolved_subservice : SubService | None
      - resolved_promo      : Promotion | None
    """
    full_name = serializers.SerializerMethodField()
    profile_picture = serializers.ImageField(read_only=True)

    # Numeric fields (kept raw for any Flutter-side display needs)
    rating_average = serializers.FloatField(read_only=True)
    distance_km = serializers.FloatField(read_only=True, required=False)
    bayesian_score = serializers.FloatField(read_only=True, required=False)

    # Dumb UI strings
    ui_rating_text = serializers.SerializerMethodField()
    primary_price = serializers.SerializerMethodField()
    primary_price_raw = serializers.SerializerMethodField()
    price_context = serializers.SerializerMethodField()
    promo_tag = serializers.SerializerMethodField()

    # Expandable data
    skills = serializers.SerializerMethodField()
    recent_reviews = serializers.SerializerMethodField()

    class Meta:
        model = TechnicianProfile
        fields = [
            'id',
            'full_name',
            'city',
            'profile_picture',
            'rating_average',
            'review_count',
            'experience_years',
            'bio',
            'distance_km',
            'bayesian_score',
            'is_active',
            'ui_rating_text',
            'primary_price',
            'primary_price_raw',
            'price_context',
            'promo_tag',
            'skills',
            'recent_reviews',
        ]

    def get_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

    def get_ui_rating_text(self, obj):
        # Star prefix requested by spec to distinguish from the list card format
        return f"⭐ {obj.rating_average} ({obj.review_count} jobs)"

    def get_skills(self, obj):
        # all_skills prefetched by selector — no extra DB hit
        all_skills = getattr(obj, 'all_skills', [])
        return SkillSummarySerializer(all_skills, many=True).data

    def get_recent_reviews(self, obj):
        # recent_reviews_list prefetched by selector (top 2, newest first)
        reviews = getattr(obj, 'recent_reviews_list', [])
        return ReviewSummarySerializer(reviews, many=True).data

    # ------------------------------------------------------------------
    # CONTEXTUAL PRICING ENGINE
    # ------------------------------------------------------------------

    def _resolve_pricing(self, obj):
        """
        Returns (primary_price, primary_price_raw, price_context, promo_tag).

        Logic lives in ``bookings.selectors.resolve_booking_intent`` — single
        source of truth shared with the home feed and (next sprint) the
        booking write path.
        """
        intent = resolve_booking_intent(
            technician=obj,
            service=self.context.get('resolved_service'),
            sub_service=self.context.get('resolved_subservice'),
            promotion=self.context.get('resolved_promo'),
        )
        return (
            intent.primary_price,
            intent.primary_price_raw,
            intent.price_context_label,
            intent.promo_tag_firewalled,
        )

    def get_primary_price(self, obj):
        price, _, _, _ = self._resolve_pricing(obj)
        return price

    def get_primary_price_raw(self, obj):
        _, raw, _, _ = self._resolve_pricing(obj)
        return raw

    def get_price_context(self, obj):
        _, _, context, _ = self._resolve_pricing(obj)
        return context

    def get_promo_tag(self, obj):
        _, _, _, promo_tag = self._resolve_pricing(obj)
        return promo_tag

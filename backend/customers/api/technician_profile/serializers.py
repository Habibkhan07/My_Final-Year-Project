# customers/api/technician_profile/serializers.py
from rest_framework import serializers
from technicians.models import TechnicianProfile, TechnicianSkill, Review


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
        Returns (primary_price: str, primary_price_raw: str, price_context: str, promo_tag: str | None).

        Scenario A — Fixed-Price Gig:
          sub_service_id passed AND SubService.is_fixed_price=True.
          promo_tag is ALWAYS None — discount stacking on fixed gigs is forbidden.

        Scenario B — Labor Gig (variable task):
          sub_service_id passed AND SubService.is_fixed_price=False.
          Price is the technician's own rate window (base..max).
          promo_tag allowed.

        Scenario C — Category Discovery:
          Only service_id provided.
          Price is the category's inspection fee.
          promo_tag allowed.
        """
        resolved_subservice = self.context.get('resolved_subservice')
        resolved_service = self.context.get('resolved_service')
        resolved_promo = self.context.get('resolved_promo')

        if resolved_subservice:
            # --- Scenario A: Fixed-Price Gig ---
            if resolved_subservice.is_fixed_price:
                price = f"Rs. {int(resolved_subservice.base_price):,}"
                raw_price = str(resolved_subservice.base_price)
                # ABSOLUTE RULE: promo_tag=None regardless of any passed promotion_id
                return price, raw_price, "Fixed Price", None

            # --- Scenario B: Labor Gig ---
            # prefetched_skill set by selector only when sub_service_id was passed
            prefetched_skill = getattr(obj, 'prefetched_skill', [])
            tech_skill = (
                prefetched_skill[0]
                if prefetched_skill
                else obj.technicianskill_set.filter(sub_service=resolved_subservice).first()
            )

            if tech_skill and tech_skill.base_rate:
                base = int(tech_skill.base_rate)
                raw_price = str(tech_skill.base_rate)
                max_r = int(tech_skill.max_rate) if tech_skill.max_rate else None
                if max_r and max_r != base:
                    price = f"Rs. {base:,} - {max_r:,}"
                else:
                    price = f"Rs. {base:,}"
            else:
                # Fallback to platform base_price when technician hasn't set their rate
                price = f"Rs. {int(resolved_subservice.base_price):,}"
                raw_price = str(resolved_subservice.base_price)

            promo_tag = resolved_promo.ui_description if resolved_promo else None
            return price, raw_price, "Labor Fee", promo_tag

        # --- Scenario C: Category Discovery ---
        if resolved_service:
            price = f"Rs. {int(resolved_service.base_inspection_fee):,}"
            raw_price = str(resolved_service.base_inspection_fee)
            promo_tag = resolved_promo.ui_description if resolved_promo else None
            return price, raw_price, "Inspection Fee", promo_tag

        # Default fallback (no context passed — global browse)
        return "Rs. 500", "500.00", "Inspection Fee", None

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

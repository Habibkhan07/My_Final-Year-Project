from rest_framework import serializers
from technicians.models import TechnicianProfile
from catalog.models import Service, SubService
from marketing.models import Promotion
from bookings.selectors import resolve_booking_intent

# 1. THE NESTED COMPONENT SERIALIZERS

class CategorySummarySerializer(serializers.ModelSerializer):
    """Data for the Category Grid"""
    class Meta:
        model = Service
        fields = ['id', 'name', 'icon_name']


class PromotionSummarySerializer(serializers.ModelSerializer):
    """Data for the top Carousel Banners"""
    title = serializers.CharField(source='name')
    banner_image_url = serializers.ImageField(source='image', read_only=True)
    promo_description = serializers.CharField(source='ui_description', read_only=True)
    button_text = serializers.SerializerMethodField()

    class Meta:
        model = Promotion
        fields = ['id', 'title', 'banner_image_url', 'promo_description', 'button_text']

    def get_button_text(self, obj):
        return "Claim Now"


class FixedGigSummarySerializer(serializers.ModelSerializer):
    """Data for the Horizontal Scrolling 'Fixed-Price Maintenance' list"""
    parent_category = serializers.CharField(source='service.name', read_only=True)
    image_url = serializers.URLField(source='card_image_url', read_only=True)
    # Ensure base_price is serialized as a string to match API contract
    base_price = serializers.DecimalField(max_digits=10, decimal_places=2, coerce_to_string=True)

    class Meta:
        model = SubService
        fields = ['id', 'name', 'base_price', 'parent_category', 'image_url']


class TopTechnicianSerializer(serializers.ModelSerializer):
    """
    Data for 'Top Rated Near You' and 'Discovery List'.
    Implements the 'Unified Money Corner' strategy for the Flutter Dumb UI.
    """
    full_name = serializers.SerializerMethodField()
    primary_category = serializers.SerializerMethodField()

    # Numeric Egress (Float)
    rating_average = serializers.FloatField(read_only=True)
    distance_km = serializers.FloatField(read_only=True, required=False)
    bayesian_score = serializers.FloatField(read_only=True, required=False)

    # Dumb UI Strings (The "Money Corner")
    ui_rating_text = serializers.SerializerMethodField()
    primary_price = serializers.SerializerMethodField()
    price_context = serializers.SerializerMethodField()
    promo_tag = serializers.SerializerMethodField()
    
    # Keeping subtitle for other context if needed
    ui_subtitle_text = serializers.SerializerMethodField()

    class Meta:
        model = TechnicianProfile
        fields = [
            'id',
            'full_name',
            'primary_category',
            'city',
            'profile_picture',
            'rating_average',
            'review_count',
            'distance_km',
            'bayesian_score',
            'is_active',
            'ui_rating_text',
            'primary_price',
            'price_context',
            'promo_tag',
            'ui_subtitle_text',
        ]

    def get_full_name(self, obj):
        return obj.user.get_full_name() or obj.user.username

    def get_primary_category(self, obj):
        skills_list = obj.skills.all()
        return skills_list[0].service.name if skills_list else "Professional"

    def get_ui_rating_text(self, obj):
        return f"{obj.rating_average} ({obj.review_count} jobs)"

    def _resolve_pricing_data(self, obj):
        """
        Returns (primary_price, price_context).

        Logic lives in ``bookings.selectors.resolve_booking_intent`` — single
        source of truth shared with the technician profile detail and (next
        sprint) the booking write path. The shared resolver formats with
        comma thousand-separators for all scenarios; that consistency is an
        intentional improvement over the prior in-place logic, which
        omitted commas for fixed-gig and inspection-fee displays.
        """
        intent = resolve_booking_intent(
            technician=obj,
            service=self.context.get('resolved_service'),
            sub_service=self.context.get('resolved_subservice'),
            promotion=self.context.get('resolved_promo'),
        )
        return intent.primary_price, intent.price_context_label

    def get_primary_price(self, obj):
        price, _ = self._resolve_pricing_data(obj)
        return price

    def get_price_context(self, obj):
        _, context = self._resolve_pricing_data(obj)
        return context

    def get_promo_tag(self, obj):
        # Short chip label — the card chip is a tight pill; the full
        # ``ui_description`` sentence overflows. See Promotion.ui_chip_label
        # docstring for the rationale.
        resolved_promo = self.context.get('resolved_promo')
        if resolved_promo:
            return resolved_promo.ui_chip_label
        return None

    def get_ui_subtitle_text(self, obj):
        # We can use this for distance or other secondary info
        if hasattr(obj, 'distance_km') and obj.distance_km:
            return f"{round(obj.distance_km, 1)} km away"
        return None

# 2. THE MASTER ENVELOPE SERIALIZER
class HomeFeedAggregatorSerializer(serializers.Serializer):
    """
    The Complete Data Contract for the Home Screen.
    Aggregates all components into a single JSON response.
    """
    categories = CategorySummarySerializer(many=True)
    promotions = PromotionSummarySerializer(many=True)
    fixed_gigs = FixedGigSummarySerializer(many=True)
    top_technicians = TopTechnicianSerializer(many=True)
# marketing/selectors/promotion_selector.py

from django.utils import timezone
from marketing.models import Promotion

def get_active_promotions(limit: int = 5):
    """
    Fetches active promotional banners for the Home Screen carousel.
    Only returns promotions where the current date falls between valid_from and valid_until.
    """
    now = timezone.now()
    
    return Promotion.objects.filter(
        is_active=True,
        is_featured_on_home=True,
        valid_from__lte=now,
        valid_until__gte=now
    ).select_related(
        'target_service'
    ).order_by('-valid_from')[:limit]
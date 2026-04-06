# catalog/selectors/gig_selector.py

from catalog.models import SubService

def get_featured_fixed_price_gigs(limit: int = 5):
    """
    Fetches services that are 'Instant Book' (Fixed Price) and 
    flagged as 'Featured' for the home screen horizontal scroll.
    """
    return SubService.objects.filter(
        is_fixed_price=True,
        is_featured=True,
        service__is_active=True
    ).select_related('service')[:limit]
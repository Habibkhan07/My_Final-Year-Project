# catalog/selectors/search_selector.py

from django.db.models import Q
from catalog.models import SubService # Explicitly import from the catalog app

def get_subservices_by_query(*, search_text: str, limit: int = 10):
    """
    Industry Standard Pattern Matching Engine.
    """
    if not search_text or len(search_text) < 2:
        return SubService.objects.none()

    query_filter = (
        Q(name__icontains=search_text) |           
        Q(service__name__icontains=search_text) |  
        Q(search_tags__icontains=search_text)      
    )

    return SubService.objects.filter(
        query_filter, 
        service__is_active=True
    ).select_related('service').distinct()[:limit]
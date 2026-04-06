# catalog/selectors/category_selector.py

from catalog.models import Service

def get_active_categories(limit: int = 8):
    """
    Fetches the top-level parent categories for the Home Screen 4x2 grid.
    Ordered by 'display_order' to give the admin control over the UI.
    """
    return Service.objects.filter(
        is_active=True
    ).order_by('display_order')[:limit]
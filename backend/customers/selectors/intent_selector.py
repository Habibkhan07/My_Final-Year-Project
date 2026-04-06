from typing import Tuple, Optional
from catalog.models import Service, SubService
from marketing.models import Promotion
from catalog.selectors.search_selectors import get_subservices_by_query

def resolve_discovery_intent(
    *, 
    q: Optional[str] = None, 
    service_id: Optional[str] = None, 
    sub_service_id: Optional[str] = None, 
    promotion_id: Optional[str] = None
) -> Tuple[Optional[Service], Optional[SubService], Optional[Promotion], Optional[int], Optional[int]]:
    """
    Resolves the user's search intent into concrete database models.
    Prevents business logic and DB queries from leaking into the view.
    
    Priority Logic:
    1. Search Query (q) matches a SubService -> Overrides all except promo metadata.
    2. Explicit Gig ID (sub_service_id) -> Overrides Category.
    3. Promo ID -> Provides target service and discount metadata.
    4. Explicit Category ID (service_id).
    """
    resolved_service = None
    resolved_subservice = None
    resolved_promo = None
    
    # Safely cast IDs to ints, preserving None
    final_service_id = int(service_id) if service_id and str(service_id).isdigit() else None
    final_sub_service_id = int(sub_service_id) if sub_service_id and str(sub_service_id).isdigit() else None
    parsed_promo_id = int(promotion_id) if promotion_id and str(promotion_id).isdigit() else None

    # 1. Resolve Search Intent (High Priority for results)
    if q:
        matched_subservices = get_subservices_by_query(search_text=q, limit=1)
        matched_list = list(matched_subservices)
        if matched_list:
            resolved_subservice = matched_list[0]
            final_sub_service_id = resolved_subservice.id

    # 2. Resolve Promo Metadata (Used for 'Dumb UI' strings)
    if parsed_promo_id:
        try:
            resolved_promo = Promotion.objects.get(id=parsed_promo_id, is_active=True)
            # Only set service if not already narrowed by a Search/Gig
            if resolved_promo.target_service and not resolved_subservice:
                resolved_service = resolved_promo.target_service
                final_service_id = resolved_service.id
        except Promotion.DoesNotExist:
            pass
    
    # 3. Resolve Explicit Gig if Search didn't find one
    if final_sub_service_id and not resolved_subservice:
        try:
            resolved_subservice = SubService.objects.get(id=final_sub_service_id)
        except SubService.DoesNotExist:
            final_sub_service_id = None # Reset if fake ID passed

    # 4. Infer Service from resolved SubService (Override Promo Service)
    if resolved_subservice:
        resolved_service = resolved_subservice.service
        final_service_id = resolved_service.id

    # 5. Resolve Explicit Category if nothing else set it
    if final_service_id and not resolved_service:
        try:
            resolved_service = Service.objects.get(id=final_service_id)
        except Service.DoesNotExist:
            final_service_id = None

    return resolved_service, resolved_subservice, resolved_promo, final_service_id, final_sub_service_id

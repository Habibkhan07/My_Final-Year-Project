from rest_framework.views import APIView
from rest_framework.pagination import PageNumberPagination

from technicians.selectors.matchmaking_selectors import get_top_nearby_technicians
from customers.api.home.serializers import TopTechnicianSerializer 
from customers.selectors.intent_selector import resolve_discovery_intent

class TechnicianDiscoveryListView(APIView):
    """
    Returns a Bayesian-sorted, paginated list of nearby technicians.
    Acts as a Smart Router, dynamically handling Category, Gig, Promo, and Search Intents.
    """
    def get(self, request, *args, **kwargs):
        # SECURITY: Public discovery endpoint, no object-level permissions required.

        # 1. Safely extract GPS
        try:
            lat = float(request.query_params.get('lat'))
            lng = float(request.query_params.get('lng'))
        except (TypeError, ValueError):
            lat, lng = None, None

        # 2. Extract and Resolve Intent Context via Selector
        q = request.query_params.get('q')
        service_id = request.query_params.get('service_id')
        sub_service_id = request.query_params.get('sub_service_id')
        promotion_id = request.query_params.get('promotion_id')

        resolved_service, resolved_subservice, resolved_promo, final_service_id, final_sub_service_id = resolve_discovery_intent(
            q=q,
            service_id=service_id,
            sub_service_id=sub_service_id,
            promotion_id=promotion_id
        )

        # 3. Call the Matchmaking Selector
        technicians = get_top_nearby_technicians(
            lat=lat,
            lng=lng,
            service_id=final_service_id if not final_sub_service_id else None,
            sub_service_id=final_sub_service_id,
            limit=None 
        )

        # 4. Paginate the Result
        paginator = PageNumberPagination()
        paginator.page_size = 20
        paginated_techs = paginator.paginate_queryset(technicians, request)

        # 5. Serialize and Return with "Dumb UI" Context
        serializer_context = {
            'resolved_service': resolved_service,
            'resolved_subservice': resolved_subservice,
            'resolved_promo': resolved_promo,
            'request': request, 
        }
        
        serializer = TopTechnicianSerializer(
            paginated_techs, 
            many=True, 
            context=serializer_context
        )
        response = paginator.get_paginated_response(serializer.data)
        if resolved_promo:
            response.data['ui_promo_banner_text'] = resolved_promo.ui_description
        return response
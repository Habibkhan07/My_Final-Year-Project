# customer/api/home/views.py

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

# --- Cross-Domain Selectors ---
from catalog.selectors.category_selector import get_active_categories
from catalog.selectors.gig_selector import get_featured_fixed_price_gigs
from marketing.selectors.promotion_selector import get_active_promotions
from technicians.selectors.matchmaking_selectors import get_top_nearby_technicians

# --- Serializers ---
from .serializers import HomeFeedAggregatorSerializer 


class CustomerHomeFeedAPIView(APIView):
    """
    BFF (Backend-For-Frontend) endpoint for the Customer Mobile App.
    Aggregates categories, active promotions, featured gigs, and nearby top technicians.
    """
    
    def get(self, request, *args, **kwargs):
        # 1. Extract raw GPS coordinates from the request
        raw_lat = request.query_params.get('lat')
        raw_lng = request.query_params.get('lng')
        
        # 2. Safely parse coordinates (Protection against bad mobile inputs)
        lat, lng = None, None
        if raw_lat and raw_lng:
            try:
                lat = float(raw_lat)
                lng = float(raw_lng)
            except (ValueError, TypeError):
                # If Flutter sends invalid data (e.g., text instead of numbers), 
                # we just treat it as missing GPS and fall back to global top technicians.
                pass 

        # 3. Call Domain Selectors (The heavy lifting happens here)
        categories = get_active_categories(limit=8)
        promotions = get_active_promotions(limit=5)
        fixed_gigs = get_featured_fixed_price_gigs(limit=5)
        
        # Matchmaking needs the validated lat/lng, but passes None for service_id 
        # to get the global platform score.
        top_technicians = get_top_nearby_technicians(
            lat=lat,
            lng=lng,
            service_id=None, 
            limit=5
        )
        
        # 4. Assemble the Aggregate Payload
        payload = {
            "categories": categories,
            "promotions": promotions,
            "fixed_gigs": fixed_gigs,
            "top_technicians": top_technicians,
        }
        
        # 5. Serialize and Return
        # PASSING CONTEXT: This is critical for generating absolute URLs for ImageFields
        serializer = HomeFeedAggregatorSerializer(instance=payload, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import SubServiceSearchSerializer
from catalog.selectors.search_selectors import get_subservices_by_query

class SearchAPIView(APIView):
    """
    Handles live keyword searches for services and sub-services .
    """
    def get(self, request):
        # 1. Extract the search keyword from the query parameters
        search_keyword = request.query_params.get('q', '').strip()

        # 2. Call the Selector (Your business logic from search_selectors.py)
        # If the keyword is too short, the selector safely returns an empty QuerySet.
        results = get_subservices_by_query(search_text=search_keyword)

        # 3. Serialize and Return
        serializer = SubServiceSearchSerializer(instance=results, many=True)
        
        # We wrap it in a 'results' key to keep the JSON predictable for Flutter
        return Response({"results": serializer.data}, status=status.HTTP_200_OK)
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from .serializers import SavedAddressSerializer
from ...models import SavedAddress

class SavedAddressListView(APIView):
    """
    GET /api/customers/addresses/
    Returns all saved addresses for the authenticated customer.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # We use select_related to join with CustomerProfile in one query
        addresses = SavedAddress.objects.filter(customer__user=request.user)
        serializer = SavedAddressSerializer(addresses, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

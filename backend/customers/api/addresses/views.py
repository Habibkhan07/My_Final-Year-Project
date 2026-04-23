from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from .serializers import CustomerAddressReadSerializer, CustomerAddressWriteSerializer
from customers.selectors.address_selectors import get_addresses_for_user
from customers.services.address_service import create_customer_address, delete_customer_address


class CustomerAddressListCreateView(APIView):
    # SECURITY: IsAuthenticated ensures addresses are always scoped to a real session token
    permission_classes = [IsAuthenticated]

    def get(self, request):
        addresses = get_addresses_for_user(user=request.user)
        serializer = CustomerAddressReadSerializer(addresses, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = CustomerAddressWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        address = create_customer_address(user=request.user, validated_data=serializer.validated_data)
        return Response(CustomerAddressReadSerializer(address).data, status=status.HTTP_201_CREATED)


class CustomerAddressDeleteView(APIView):
    # SECURITY: delete_customer_address scopes the lookup to request.user, preventing IDOR
    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        delete_customer_address(user=request.user, address_id=pk)
        return Response(status=status.HTTP_204_NO_CONTENT)

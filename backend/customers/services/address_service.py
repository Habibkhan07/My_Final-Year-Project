from django.contrib.auth.models import User
from django.db import transaction
from rest_framework.exceptions import NotFound

from customers.models import CustomerAddress, CustomerProfile
# This is comment.
#More there will be added more comments to improve the code readibilty



def create_customer_address(*, user: User, validated_data: dict) -> CustomerAddress:
    """
    Creates a CustomerAddress for the given user.
    If is_default=True, clears all other defaults atomically to prevent multiple
    defaults existing simultaneously (select_for_update prevents a race condition
    where two concurrent requests both set is_default=True).
    """
    try:
        profile = CustomerProfile.objects.get(user=user)
    except CustomerProfile.DoesNotExist:
        raise NotFound("Customer profile not found.")

    with transaction.atomic():
        if validated_data.get('is_default'):
            CustomerAddress.objects.select_for_update().filter(
                customer=profile, is_default=True
            ).update(is_default=False)

        return CustomerAddress.objects.create(customer=profile, **validated_data)


def update_customer_address(*, user: User, address_id: int, data: dict) -> CustomerAddress:
    """
    Updates a CustomerAddress owned by user.
    If is_default=True is passed, clears other defaults for this customer.
    """
    try:
        address = CustomerAddress.objects.get(id=address_id, customer__user=user)
    except CustomerAddress.DoesNotExist:
        raise NotFound("Address not found.")

    with transaction.atomic():
        if data.get('is_default'):
            # Clear existing defaults
            CustomerAddress.objects.select_for_update().filter(
                customer=address.customer, is_default=True
            ).exclude(id=address_id).update(is_default=False)

        for attr, value in data.items():
            setattr(address, attr, value)
        
        address.save()
        return address


def delete_customer_address(*, user: User, address_id: int) -> None:
    """
    Deletes a CustomerAddress owned by user.
    Scoping the lookup to customer__user prevents IDOR — a user cannot delete
    another user's address even if they know its ID.
    """
    try:
        address = CustomerAddress.objects.get(id=address_id, customer__user=user)
    except CustomerAddress.DoesNotExist:
        raise NotFound("Address not found.")

    address.delete()

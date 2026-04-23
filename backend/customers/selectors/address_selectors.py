from django.contrib.auth.models import User
from customers.models import CustomerAddress


def get_addresses_for_user(*, user: User):
    """
    Returns all saved addresses for a user, ordered by default-first.
    select_related avoids an extra query when serializing customer.user fields.
    """
    return CustomerAddress.objects.filter(customer__user=user).select_related('customer__user')

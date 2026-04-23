"""
Tests for customers/selectors/address_selectors.py

Coverage:
  get_addresses_for_user:
    - Returns correct addresses for a user
    - Returns empty queryset for a user with no addresses
    - Does not leak addresses belonging to other users
    - Ordering: is_default=True sorts before is_default=False
    - No N+1: executes in a fixed number of queries regardless of address count
"""
import pytest

from customers.selectors.address_selectors import get_addresses_for_user
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory

pytestmark = pytest.mark.django_db


class TestGetAddressesForUser:

    def test_returns_addresses_for_user(self, django_assert_num_queries):
        profile = CustomerProfileFactory()
        CustomerAddressFactory(customer=profile)
        CustomerAddressFactory(customer=profile)

        with django_assert_num_queries(1):
            result = list(get_addresses_for_user(user=profile.user))

        assert len(result) == 2

    def test_returns_empty_queryset_for_new_user(self):
        profile = CustomerProfileFactory()
        result = list(get_addresses_for_user(user=profile.user))
        assert result == []

    def test_does_not_leak_other_users_addresses(self):
        profile = CustomerProfileFactory()
        other_profile = CustomerProfileFactory()
        CustomerAddressFactory(customer=profile)
        CustomerAddressFactory(customer=profile)
        CustomerAddressFactory(customer=other_profile)
        CustomerAddressFactory(customer=other_profile)

        result = list(get_addresses_for_user(user=profile.user))
        assert len(result) == 2
        assert all(a.customer_id == profile.id for a in result)

    def test_ordering_default_first(self):
        profile = CustomerProfileFactory()
        non_default = CustomerAddressFactory(customer=profile, is_default=False, label='Office')
        default = CustomerAddressFactory(customer=profile, is_default=True, label='Home')

        result = list(get_addresses_for_user(user=profile.user))
        assert result[0].id == default.id
        assert result[1].id == non_default.id

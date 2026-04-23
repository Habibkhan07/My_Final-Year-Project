"""
Tests for customers/services/address_service.py

Coverage:
  create_customer_address:
    - Creates address with correct customer FK
    - is_default=True clears all existing defaults for that user atomically
    - is_default=False does not disturb existing defaults
    - Raises NotFound if user has no CustomerProfile

  update_customer_address:
    - Updates fields correctly
    - is_default=True clears all previous defaults atomically
    - Raises NotFound for other user's address (IDOR)

  delete_customer_address:
    - Deletes the record from DB
    - Raises NotFound for a nonexistent id
    - Raises NotFound for an address belonging to another user (IDOR: same error as nonexistent)
"""
import pytest
from rest_framework.exceptions import NotFound

from customers.models import CustomerAddress
from customers.services.address_service import (
    create_customer_address, 
    update_customer_address,
    delete_customer_address
)
from tests.factories.accounts import UserFactory
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory

pytestmark = pytest.mark.django_db


VALID_DATA = {
    'label': 'Home',
    'street_address': '123 Main St, Lahore',
    'latitude': '31.520400',
    'longitude': '74.358700',
    'is_default': False,
}


class TestCreateCustomerAddress:

    def test_creates_address_with_correct_profile(self):
        profile = CustomerProfileFactory()
        address = create_customer_address(user=profile.user, validated_data=VALID_DATA.copy())
        assert address.customer == profile
        assert address.street_address == '123 Main St, Lahore'

    def test_is_default_true_clears_all_previous_defaults(self):
        profile = CustomerProfileFactory()
        old1 = CustomerAddressFactory(customer=profile, is_default=True)
        old2 = CustomerAddressFactory(customer=profile, is_default=True)

        new_address = create_customer_address(
            user=profile.user,
            validated_data={**VALID_DATA, 'is_default': True},
        )

        old1.refresh_from_db()
        old2.refresh_from_db()
        assert old1.is_default is False
        assert old2.is_default is False
        assert new_address.is_default is True

    def test_is_default_false_does_not_touch_existing_defaults(self):
        profile = CustomerProfileFactory()
        existing_default = CustomerAddressFactory(customer=profile, is_default=True)

        create_customer_address(
            user=profile.user,
            validated_data={**VALID_DATA, 'is_default': False},
        )

        existing_default.refresh_from_db()
        assert existing_default.is_default is True

    def test_raises_not_found_if_profile_missing(self):
        user_without_profile = UserFactory()
        with pytest.raises(NotFound):
            create_customer_address(user=user_without_profile, validated_data=VALID_DATA.copy())


class TestUpdateCustomerAddress:

    def test_updates_fields_correctly(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile, label='Old Label')

        update_customer_address(
            user=profile.user,
            address_id=address.id,
            data={'label': 'New Label'}
        )

        address.refresh_from_db()
        assert address.label == 'New Label'

    def test_setting_default_clears_previous_default(self):
        profile = CustomerProfileFactory()
        old_default = CustomerAddressFactory(customer=profile, is_default=True)
        new_default = CustomerAddressFactory(customer=profile, is_default=False)

        update_customer_address(
            user=profile.user,
            address_id=new_default.id,
            data={'is_default': True}
        )

        old_default.refresh_from_db()
        new_default.refresh_from_db()
        assert old_default.is_default is False
        assert new_default.is_default is True

    def test_raises_not_found_for_other_users_address(self):
        other_profile = CustomerProfileFactory()
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        with pytest.raises(NotFound):
            update_customer_address(
                user=attacker_profile.user,
                address_id=other_address.id,
                data={'is_default': True}
            )


class TestDeleteCustomerAddress:

    def test_deletes_own_address(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)

        delete_customer_address(user=profile.user, address_id=address.id)

        assert not CustomerAddress.objects.filter(id=address.id).exists()

    def test_raises_not_found_for_nonexistent_id(self):
        profile = CustomerProfileFactory()
        with pytest.raises(NotFound):
            delete_customer_address(user=profile.user, address_id=999999)

    def test_raises_not_found_for_other_users_address(self):
        """
        address_id exists but belongs to a different profile.
        Must raise the same NotFound — caller cannot distinguish IDOR from nonexistent.
        """
        other_profile = CustomerProfileFactory()
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        with pytest.raises(NotFound):
            delete_customer_address(user=attacker_profile.user, address_id=other_address.id)

        # Confirm victim's record was untouched
        assert CustomerAddress.objects.filter(id=other_address.id).exists()

"""
Tests for GET/POST /api/customers/addresses/ and DELETE /api/customers/addresses/<id>/
customers/api/addresses/views.py

Coverage:
  GET  - 401 unauthenticated
       - 200 empty list for new user
       - 200 returns only the authenticated user's own addresses (no cross-user leakage)
       - 200 default address sorts first
       - 200 response shape has all required fields

  POST - 401 unauthenticated
       - 201 creates address, response shape matches read serializer
       - 201 address persisted in DB
       - 201 posting with is_default=true clears previous default
       - 400 missing street_address
       - 400 missing latitude
       - 400 missing longitude
       - 400 envelope matches contract (status, code, message, errors)

  PATCH - 401 unauthenticated
        - 200 update is_default=true clears old default
        - 404 nonexistent address id
        - 404 other user's address (IDOR opaque)

  DELETE - 401 unauthenticated
         - 204 deletes own address, record gone from DB
         - 404 nonexistent address id
         - 404 address belonging to another user returns same 404 (IDOR opaque)
"""
import pytest
from rest_framework.test import APIClient

from customers.models import CustomerAddress
from tests.factories.customers import CustomerProfileFactory, CustomerAddressFactory

pytestmark = pytest.mark.django_db

LIST_URL = '/api/customers/addresses/'


def _detail_url(pk):
    return f'/api/customers/addresses/{pk}/'


class TestGetAddresses:

    def setup_method(self):
        self.client = APIClient()

    def test_401_unauthenticated(self):
        response = self.client.get(LIST_URL)
        assert response.status_code == 401

    def test_200_empty_list_for_new_user(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)

        response = self.client.get(LIST_URL)
        assert response.status_code == 200
        assert response.json() == []

    def test_200_returns_only_own_addresses(self):
        profile = CustomerProfileFactory()
        other_profile = CustomerProfileFactory()
        CustomerAddressFactory(customer=profile)
        CustomerAddressFactory(customer=profile)
        CustomerAddressFactory(customer=other_profile)  # must not appear

        self.client.force_authenticate(user=profile.user)
        response = self.client.get(LIST_URL)

        assert response.status_code == 200
        assert len(response.json()) == 2

    def test_200_default_address_sorts_first(self):
        profile = CustomerProfileFactory()
        CustomerAddressFactory(customer=profile, is_default=False, label='Office')
        CustomerAddressFactory(customer=profile, is_default=True, label='Home')

        self.client.force_authenticate(user=profile.user)
        response = self.client.get(LIST_URL)

        assert response.status_code == 200
        data = response.json()
        assert data[0]['is_default'] is True
        assert data[0]['label'] == 'Home'

    def test_200_response_shape(self):
        profile = CustomerProfileFactory()
        CustomerAddressFactory(customer=profile)
        self.client.force_authenticate(user=profile.user)

        response = self.client.get(LIST_URL)
        assert response.status_code == 200
        item = response.json()[0]
        assert set(item.keys()) == {'id', 'label', 'street_address', 'latitude', 'longitude', 'is_default', 'created_at'}


class TestPostAddress:

    def setup_method(self):
        self.client = APIClient()

    def _valid_payload(self, **overrides):
        payload = {
            'label': 'Home',
            'street_address': '123 Main St, Lahore',
            'latitude': '31.520400',
            'longitude': '74.358700',
            'is_default': False,
        }
        payload.update(overrides)
        return payload

    def test_401_unauthenticated(self):
        response = self.client.post(LIST_URL, self._valid_payload(), format='json')
        assert response.status_code == 401

    def test_201_creates_address(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)

        response = self.client.post(LIST_URL, self._valid_payload(), format='json')
        assert response.status_code == 201
        data = response.json()
        assert set(data.keys()) == {'id', 'label', 'street_address', 'latitude', 'longitude', 'is_default', 'created_at'}
        assert data['label'] == 'Home'
        assert data['street_address'] == '123 Main St, Lahore'

    def test_201_address_persisted_in_db(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)

        response = self.client.post(LIST_URL, self._valid_payload(), format='json')
        assert response.status_code == 201
        assert CustomerAddress.objects.filter(
            customer=profile,
            street_address='123 Main St, Lahore',
        ).exists()

    def test_201_new_default_clears_old_default(self):
        profile = CustomerProfileFactory()
        old_default = CustomerAddressFactory(customer=profile, is_default=True)
        self.client.force_authenticate(user=profile.user)

        response = self.client.post(LIST_URL, self._valid_payload(is_default=True), format='json')
        assert response.status_code == 201

        old_default.refresh_from_db()
        assert old_default.is_default is False
        new_id = response.json()['id']
        assert CustomerAddress.objects.get(id=new_id).is_default is True

    def test_400_missing_street_address(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)
        payload = self._valid_payload()
        del payload['street_address']

        response = self.client.post(LIST_URL, payload, format='json')
        assert response.status_code == 400
        assert 'street_address' in response.json()['errors']

    def test_400_missing_latitude(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)
        payload = self._valid_payload()
        del payload['latitude']

        response = self.client.post(LIST_URL, payload, format='json')
        assert response.status_code == 400
        assert 'latitude' in response.json()['errors']

    def test_400_missing_longitude(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)
        payload = self._valid_payload()
        del payload['longitude']

        response = self.client.post(LIST_URL, payload, format='json')
        assert response.status_code == 400
        assert 'longitude' in response.json()['errors']

    def test_400_envelope_matches_contract(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)

        response = self.client.post(LIST_URL, {}, format='json')
        data = response.json()
        assert response.status_code == 400
        assert set(data.keys()) >= {'status', 'code', 'message', 'errors'}
        assert data['code'] == 'validation_error'
        assert data['status'] == 400


class TestUpdateAddress:

    def setup_method(self):
        self.client = APIClient()

    def test_401_unauthenticated(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        response = self.client.patch(_detail_url(address.id), {'is_default': True}, format='json')
        assert response.status_code == 401

    def test_200_update_is_default_clears_old_default(self):
        profile = CustomerProfileFactory()
        old_default = CustomerAddressFactory(customer=profile, is_default=True)
        new_default = CustomerAddressFactory(customer=profile, is_default=False)
        self.client.force_authenticate(user=profile.user)

        response = self.client.patch(_detail_url(new_default.id), {'is_default': True}, format='json')
        assert response.status_code == 200
        assert response.json()['is_default'] is True

        old_default.refresh_from_db()
        assert old_default.is_default is False
        new_default.refresh_from_db()
        assert new_default.is_default is True

    def test_404_cannot_update_other_users_address(self):
        other_profile = CustomerProfileFactory()
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        self.client.force_authenticate(user=attacker_profile.user)

        response = self.client.patch(_detail_url(other_address.id), {'is_default': True}, format='json')
        assert response.status_code == 404


class TestDeleteAddress:

    def setup_method(self):
        self.client = APIClient()

    def test_401_unauthenticated(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        response = self.client.delete(_detail_url(address.id))
        assert response.status_code == 401

    def test_204_deletes_own_address(self):
        profile = CustomerProfileFactory()
        address = CustomerAddressFactory(customer=profile)
        self.client.force_authenticate(user=profile.user)

        response = self.client.delete(_detail_url(address.id))
        assert response.status_code == 204
        assert not CustomerAddress.objects.filter(id=address.id).exists()

    def test_404_nonexistent_address(self):
        profile = CustomerProfileFactory()
        self.client.force_authenticate(user=profile.user)

        response = self.client.delete(_detail_url(999999))
        assert response.status_code == 404

    def test_404_cannot_delete_other_users_address(self):
        """
        Address exists but belongs to another user.
        Must return the same 404 as a nonexistent ID — caller cannot distinguish (IDOR opaque).
        """
        other_profile = CustomerProfileFactory()
        other_address = CustomerAddressFactory(customer=other_profile)

        attacker_profile = CustomerProfileFactory()
        self.client.force_authenticate(user=attacker_profile.user)

        response = self.client.delete(_detail_url(other_address.id))
        assert response.status_code == 404
        # Confirm the victim's address was NOT deleted
        assert CustomerAddress.objects.filter(id=other_address.id).exists()

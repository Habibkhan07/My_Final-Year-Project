"""
LogoutView contract tests.

Asserts the full security contract:
- 204 on success (no body)
- Server-side token is actually invalidated (the SAME token bytes return 401
  on the very next request)
- Anonymous calls bounce 401 with the standard envelope
- Idempotent: re-calling after the row is already gone still returns 204
  (the FE's retry-after-network-blip path must not flap)
"""
import pytest
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework.authtoken.models import Token

from tests.factories.accounts import UserFactory, UserProfileFactory


@pytest.fixture
def client():
    return APIClient()


@pytest.fixture
def logout_url():
    return reverse('logout')


@pytest.fixture
def authed_user_and_token(db):
    user = UserFactory()
    UserProfileFactory(user=user)
    token = Token.objects.create(user=user)
    return user, token


# ---------------------------------------------------------------------------
# POST /api/accounts/logout/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_logout_returns_204(client, logout_url, authed_user_and_token):
    _, token = authed_user_and_token
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    response = client.post(logout_url)

    assert response.status_code == 204
    # 204 No Content — response body MUST be empty per HTTP spec; the FE
    # parser does not try to JSON-decode this.
    assert response.content == b''


@pytest.mark.django_db
def test_logout_invalidates_token_server_side(client, logout_url, authed_user_and_token):
    """
    The defining property of logout: the token bytes that worked one call
    ago must not work on the next call.
    """
    user, token = authed_user_and_token
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')

    logout_response = client.post(logout_url)
    assert logout_response.status_code == 204

    # Same token, same client, fresh request — must now bounce 401.
    retry_response = client.post(logout_url)
    assert retry_response.status_code == 401
    assert retry_response.data['code'] == 'unauthorized'

    # And the Token row is actually gone from the DB.
    assert not Token.objects.filter(user=user).exists()


@pytest.mark.django_db
def test_logout_requires_auth_401(client, logout_url):
    """No Authorization header → standard 401 envelope."""
    response = client.post(logout_url)
    assert response.status_code == 401
    assert response.data['code'] == 'unauthorized'


@pytest.mark.django_db
def test_logout_with_invalid_token_returns_401(client, logout_url):
    """Bogus token bytes → 401, never a 500 or 204."""
    client.credentials(HTTP_AUTHORIZATION='Token not-a-real-token')
    response = client.post(logout_url)
    assert response.status_code == 401


@pytest.mark.django_db
def test_logout_is_idempotent_at_service_layer(authed_user_and_token):
    """
    The service itself must be idempotent: calling it after the row is
    already gone must not raise. The view layer can't expose this because
    permission_classes blocks the second call at 401, but the service is
    where retry-after-network-blip safety lives.
    """
    from accounts.services import auth_service
    user, token = authed_user_and_token

    auth_service.logout(user=user)
    assert not Token.objects.filter(user=user).exists()

    # Second call on the same user — no row to delete, no exception.
    auth_service.logout(user=user)
    assert not Token.objects.filter(user=user).exists()

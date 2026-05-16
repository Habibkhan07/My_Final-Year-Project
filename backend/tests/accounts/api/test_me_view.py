"""
MeView contract tests — `GET` and `PATCH /api/accounts/me/`.

Every test asserts the full error envelope shape so the Flutter error
pipeline never encounters a surprise field name.

Security focus:
- Auth required (401 envelope).
- Mass-assignment guards: PATCH cannot write through to phone,
  is_technician, is_staff, is_superuser, etc.
- N+1 guard on GET via django_assert_num_queries (joins userprofile).
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
def me_url():
    return reverse('me')


@pytest.fixture
def authed(db):
    """A user with profile + token, already attached to the client."""
    user = UserFactory(first_name='Ali', last_name='Raza')
    profile = UserProfileFactory(user=user, phone='+923001234567')
    token = Token.objects.create(user=user)
    return user, profile, token


def _auth(client, token):
    client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')


# ---------------------------------------------------------------------------
# GET /api/accounts/me/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_get_me_returns_expected_fields(client, me_url, authed):
    user, profile, token = authed
    _auth(client, token)

    response = client.get(me_url)

    assert response.status_code == 200
    assert response.data == {
        'id': user.id,
        'first_name': 'Ali',
        'last_name': 'Raza',
        'phone': '+923001234567',
        'is_technician': False,
    }


@pytest.mark.django_db
def test_get_me_reflects_is_technician_from_profile(client, me_url):
    """`is_technician` is sourced from UserProfile, not auth.User."""
    user = UserFactory()
    UserProfileFactory(user=user, is_technician=True)
    token = Token.objects.create(user=user)
    _auth(client, token)

    response = client.get(me_url)

    assert response.status_code == 200
    assert response.data['is_technician'] is True


@pytest.mark.django_db
def test_get_me_requires_auth_401(client, me_url):
    response = client.get(me_url)
    assert response.status_code == 401
    assert response.data['code'] == 'unauthorized'


@pytest.mark.django_db
def test_get_me_does_not_trigger_n_plus_one(
    client, me_url, authed, django_assert_num_queries
):
    """
    Exactly one SQL query: User JOIN UserProfile via `select_related`.
    The Token auth itself contributes one additional query (the
    Authorization header lookup), so the budget is 2 total. If this
    test fails at 3 queries, the serializer is fetching `userprofile`
    on demand — fix the selector, not the test.
    """
    _, _, token = authed
    _auth(client, token)

    with django_assert_num_queries(2):
        response = client.get(me_url)

    assert response.status_code == 200


# ---------------------------------------------------------------------------
# PATCH /api/accounts/me/
# ---------------------------------------------------------------------------

@pytest.mark.django_db
def test_patch_me_updates_names(client, me_url, authed):
    user, _, token = authed
    _auth(client, token)

    response = client.patch(
        me_url,
        {'first_name': 'Hamza', 'last_name': 'Khan'},
        format='json',
    )

    assert response.status_code == 200
    user.refresh_from_db()
    assert user.first_name == 'Hamza'
    assert user.last_name == 'Khan'


@pytest.mark.django_db
def test_patch_me_returns_fresh_state(client, me_url, authed):
    """
    The PATCH response body MUST be the freshly-updated profile so the
    FE notifier can swap its cached state without a second GET.
    """
    user, _, token = authed
    _auth(client, token)

    response = client.patch(
        me_url,
        {'first_name': 'Hamza', 'last_name': 'Khan'},
        format='json',
    )

    assert response.status_code == 200
    assert response.data['first_name'] == 'Hamza'
    assert response.data['last_name'] == 'Khan'
    # The unchanged fields must still be present (i.e. the response is
    # the FULL state, not a partial echo of just the patched fields).
    assert response.data['phone'] == '+923001234567'
    assert response.data['is_technician'] is False
    assert response.data['id'] == user.id


@pytest.mark.django_db
def test_patch_me_empty_first_name_returns_400(client, me_url, authed):
    _, _, token = authed
    _auth(client, token)

    response = client.patch(
        me_url,
        {'first_name': '', 'last_name': 'Khan'},
        format='json',
    )

    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'
    assert 'first_name' in response.data['errors']


@pytest.mark.django_db
def test_patch_me_missing_last_name_returns_400(client, me_url, authed):
    _, _, token = authed
    _auth(client, token)

    response = client.patch(
        me_url,
        {'first_name': 'Hamza'},
        format='json',
    )

    assert response.status_code == 400
    assert response.data['code'] == 'validation_error'
    assert 'last_name' in response.data['errors']


@pytest.mark.django_db
def test_patch_me_rejects_is_technician_field(client, me_url, authed):
    """
    Mass-assignment guard. The body contains valid required fields PLUS a
    sneaky `is_technician: true` — the serializer must drop it silently
    (extra fields are not declared, so DRF ignores them) and the DB row
    must remain unchanged.
    """
    user, profile, token = authed
    _auth(client, token)
    assert profile.is_technician is False  # baseline

    response = client.patch(
        me_url,
        {
            'first_name': 'Hamza',
            'last_name': 'Khan',
            'is_technician': True,  # ← should NOT flip
        },
        format='json',
    )

    assert response.status_code == 200  # legit fields succeeded
    profile.refresh_from_db()
    assert profile.is_technician is False  # ← attack neutralized
    assert response.data['is_technician'] is False


@pytest.mark.django_db
def test_patch_me_rejects_phone_field(client, me_url, authed):
    """
    Phone is the auth identity. PATCH must never let it move via this
    endpoint — changing phone requires a fresh OTP flow.

    Snapshots BOTH the `UserProfile.phone` field (what the FE reads)
    AND `User.username` (the auth identity — process_otp_verification
    sets them equal at signup). Any future change that exposes a
    writeable `phone` on `MeUpdateSerializer` must keep both invariants
    or fail this test.
    """
    user, profile, token = authed
    _auth(client, token)
    original_profile_phone = profile.phone
    original_username = user.username

    response = client.patch(
        me_url,
        {
            'first_name': 'Hamza',
            'last_name': 'Khan',
            'phone': '+923009999999',  # ← should NOT take effect
            'username': '+923009999999',  # ← belt-and-braces
        },
        format='json',
    )

    assert response.status_code == 200
    profile.refresh_from_db()
    user.refresh_from_db()
    assert profile.phone == original_profile_phone
    assert user.username == original_username


@pytest.mark.django_db
def test_patch_me_rejects_is_staff_field(client, me_url, authed):
    """Privilege-escalation guard."""
    user, _, token = authed
    _auth(client, token)
    assert user.is_staff is False

    response = client.patch(
        me_url,
        {
            'first_name': 'Hamza',
            'last_name': 'Khan',
            'is_staff': True,
            'is_superuser': True,
        },
        format='json',
    )

    assert response.status_code == 200
    user.refresh_from_db()
    assert user.is_staff is False
    assert user.is_superuser is False


@pytest.mark.django_db
def test_patch_me_requires_auth_401(client, me_url):
    response = client.patch(
        me_url,
        {'first_name': 'Hamza', 'last_name': 'Khan'},
        format='json',
    )
    assert response.status_code == 401
    assert response.data['code'] == 'unauthorized'


@pytest.mark.django_db
def test_patch_me_only_updates_caller_not_other_users(client, me_url, authed):
    """
    Two users in the DB. Caller PATCHes — only the caller's row moves.
    Belt-and-braces test for the request.user scoping; if someone ever
    accepts a `user_id` field, this test fails.
    """
    user, _, token = authed
    other_user = UserFactory(first_name='Other', last_name='Person')
    UserProfileFactory(user=other_user, phone='+923007777777')

    _auth(client, token)

    response = client.patch(
        me_url,
        {'first_name': 'Hamza', 'last_name': 'Khan'},
        format='json',
    )

    assert response.status_code == 200
    user.refresh_from_db()
    other_user.refresh_from_db()
    assert user.first_name == 'Hamza'
    # Other user untouched.
    assert other_user.first_name == 'Other'
    assert other_user.last_name == 'Person'

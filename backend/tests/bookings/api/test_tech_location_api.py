"""HTTP tests for the GPS ingress endpoint.

POST /api/bookings/<id>/tech-location/

Coverage:
  * 401 anonymous, 403 wrong role, 404 missing booking
  * 200 happy path → publishes stream + (sometimes) flips status
  * 429 throttle on second call within 4 s
  * Terminal-status booking is silent no-op (200 with published=false)
"""
from __future__ import annotations

from unittest.mock import patch

import pytest
from rest_framework.test import APIClient

from bookings.models import JobBooking
from tests.factories.bookings import (
    JobBookingCompletedFactory,
    JobBookingConfirmedFactory,
    JobBookingEnRouteFactory,
)
from tests.factories.customers import CustomerAddressFactory


pytestmark = pytest.mark.django_db


def _url(booking_id: int) -> str:
    return f"/api/bookings/{booking_id}/tech-location/"


def _reset_throttle():
    """Clear the process-local throttle bucket between tests."""
    from bookings.api.tech_location import views

    views._LAST_PUBLISH_TS.clear()


@pytest.fixture(autouse=True)
def clear_throttle():
    _reset_throttle()
    yield
    _reset_throttle()


class TestTechLocationIngressEndpoint:
    def setup_method(self):
        self.client = APIClient()

    def test_401_anonymous(self):
        booking = JobBookingConfirmedFactory()
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        assert response.status_code == 401

    def test_403_when_customer(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.customer)
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        assert response.status_code == 403
        assert response.json()["code"] == "not_a_technician"

    def test_404_when_booking_missing(self):
        from tests.factories.technicians import TechnicianProfileFactory

        tech_profile = TechnicianProfileFactory()
        self.client.force_authenticate(user=tech_profile.user)
        response = self.client.post(
            _url(999_999),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        assert response.status_code == 404
        assert response.json()["code"] == "booking_not_found"

    def test_403_when_other_tech(self):
        from tests.factories.technicians import TechnicianProfileFactory

        booking = JobBookingConfirmedFactory()
        other = TechnicianProfileFactory()
        self.client.force_authenticate(user=other.user)
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        assert response.status_code == 403
        assert response.json()["code"] == "not_assigned_to_you"

    def test_200_publishes_stream(self):
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingConfirmedFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        with patch("bookings.api.tech_location.views.publish_stream") as ps:
            # Far enough away to ensure CONFIRMED→EN_ROUTE auto-flip.
            response = self.client.post(
                _url(booking.id),
                {"lat": 31.6, "lng": 74.4, "accuracy_meters": 8.5},
                format="json",
            )
        assert response.status_code == 200
        body = response.json()
        assert body["published"] is True
        ps.assert_called_once()
        kwargs = ps.call_args.kwargs
        assert kwargs["group"] == f"tracking_job_{booking.id}"
        assert kwargs["stream_type"] == "tech_gps"
        assert kwargs["payload"]["lat"] == 31.6

    def test_200_auto_transition_fires_en_route(self, fake_finance, captured_broadcasts):
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingConfirmedFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        # ~10km away → triggers EN_ROUTE.
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.6, "lng": 74.4},
            format="json",
        )
        assert response.status_code == 200
        body = response.json()
        assert body["transition_fired"] == JobBooking.STATUS_EN_ROUTE
        booking.refresh_from_db()
        assert booking.status == JobBooking.STATUS_EN_ROUTE

    def test_200_auto_transition_fires_arrived(self, fake_finance, captured_broadcasts):
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingEnRouteFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        # ~10m off → triggers ARRIVED.
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.5205, "lng": 74.3588},
            format="json",
        )
        assert response.status_code == 200
        body = response.json()
        assert body["transition_fired"] == JobBooking.STATUS_ARRIVED

    def test_200_no_auto_transition_when_distance_unchanged(self, captured_broadcasts):
        addr = CustomerAddressFactory(latitude=31.5204, longitude=74.3587)
        booking = JobBookingConfirmedFactory(address=addr)
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"lat": 31.5205, "lng": 74.3588},  # within EN_ROUTE threshold
            format="json",
        )
        assert response.status_code == 200
        assert response.json()["transition_fired"] is None

    def test_429_throttle_on_second_call(self):
        booking = JobBookingConfirmedFactory(
            address=CustomerAddressFactory(),
        )
        self.client.force_authenticate(user=booking.technician.user)
        first = self.client.post(
            _url(booking.id),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        second = self.client.post(
            _url(booking.id),
            {"lat": 31.5, "lng": 74.3},
            format="json",
        )
        assert first.status_code == 200
        assert second.status_code == 429
        assert second.json()["code"] == "too_many_requests"

    def test_silent_noop_on_terminal_status(self):
        booking = JobBookingCompletedFactory(
            address=CustomerAddressFactory(),
        )
        self.client.force_authenticate(user=booking.technician.user)
        with patch("bookings.api.tech_location.views.publish_stream") as ps:
            response = self.client.post(
                _url(booking.id),
                {"lat": 31.5, "lng": 74.3},
                format="json",
            )
        assert response.status_code == 200
        body = response.json()
        assert body["published"] is False
        assert body["transition_fired"] is None
        ps.assert_not_called()

    def test_400_invalid_coords(self):
        booking = JobBookingConfirmedFactory()
        self.client.force_authenticate(user=booking.technician.user)
        response = self.client.post(
            _url(booking.id),
            {"lat": 91.0, "lng": 74.3},  # lat > 90 → reject
            format="json",
        )
        assert response.status_code == 400

    def test_terminal_flip_between_idor_and_publish_does_not_leak(self):
        """Regression for the H4 audit finding (Pass 2).

        Pre-fix the booking status was read once unlocked at the IDOR
        stage, then re-used for the terminal-status guard before
        ``publish_stream``. A concurrent transition to a terminal
        status between the read and the publish would leak GPS to the
        ``tracking_job_<id>`` group AFTER the job had ended.

        Post-fix the terminal-status guard re-reads the booking under
        ``select_for_update`` inside an ``transaction.atomic`` block so
        any concurrent terminal flip either happened before our lock
        (we observe it and silently no-op) or after our publish (the
        publish was authorized at the moment it fired).

        We simulate the race by monkey-patching the locked re-read to
        return a terminal-status row even though the unlocked IDOR
        read saw a non-terminal one.
        """
        from bookings.api.tech_location import views as views_mod

        booking = JobBookingConfirmedFactory(address=CustomerAddressFactory())
        self.client.force_authenticate(user=booking.technician.user)

        # Force the locked re-read to look terminal even though the
        # initial unlocked fetch is CONFIRMED. If the view trusted the
        # earlier fetch, the publish would still fire.
        original_get = views_mod.JobBooking.objects.select_for_update

        class _StubQS:
            def only(self, *args, **kwargs):
                return self

            def get(self, **kwargs):
                row = views_mod.JobBooking.objects.get(id=kwargs["id"])
                row.status = views_mod.JobBooking.STATUS_COMPLETED
                return row

        with patch.object(
            views_mod.JobBooking.objects,
            "select_for_update",
            return_value=_StubQS(),
        ):
            with patch("bookings.api.tech_location.views.publish_stream") as ps:
                response = self.client.post(
                    _url(booking.id),
                    {"lat": 31.6, "lng": 74.4},
                    format="json",
                )
        assert response.status_code == 200, response.json()
        body = response.json()
        # The locked re-read saw COMPLETED → silent no-op, no leak.
        assert body["published"] is False
        assert body["transition_fired"] is None
        ps.assert_not_called()

    def test_idor_check_runs_before_throttle(self):
        """Regression for the H5 audit finding.

        A non-assigned tech who hammers the endpoint with a booking id
        they don't own must NOT pollute ``_LAST_PUBLISH_TS``. Pre-fix
        the throttle ran before the IDOR check, which let an attacker
        evict legitimate (assigned-tech, booking) entries by spamming
        random booking ids until the cache cap was hit. After the fix
        the IDOR check returns 403 before the throttle key is even
        considered.
        """
        from bookings.api.tech_location import views as views_mod
        from tests.factories.technicians import TechnicianProfileFactory

        booking = JobBookingConfirmedFactory()
        other = TechnicianProfileFactory()
        self.client.force_authenticate(user=other.user)

        assert views_mod._LAST_PUBLISH_TS == {}, (
            "throttle bucket must start empty (autouse fixture cleared it)"
        )
        # Two back-to-back calls from a non-assigned tech.
        for _ in range(2):
            response = self.client.post(
                _url(booking.id),
                {"lat": 31.5, "lng": 74.3},
                format="json",
            )
            # Both must be 403 — neither must roll over to 429.
            assert response.status_code == 403
            assert response.json()["code"] == "not_assigned_to_you"

        # Crucial assertion: the throttle bucket is still empty. If the
        # IDOR check ever moves back to AFTER the throttle, the second
        # call would have stored a key, breaking this assertion.
        assert (other.user.id, booking.id) not in views_mod._LAST_PUBLISH_TS
        assert views_mod._LAST_PUBLISH_TS == {}

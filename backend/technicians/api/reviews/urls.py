"""URL surface for customer reviews.

Two URL families:

* ``/api/bookings/<booking_id>/review/`` — the per-booking review
  surface. Mounted from ``bookings.api.urls`` (not here) so the URL
  reads as a booking-scoped resource, matching the consumer's mental
  model. This module exports the view; the include path lives in
  ``bookings/api/urls.py``.
* ``/api/technicians/<technician_id>/reviews/`` — the per-tech
  paginated list. Mounted from ``technicians.api.urls``.

Why split: the booking endpoint is "review for a specific job I
booked" — booking is the parent resource. The technician list is
"all reviews for this tech, regardless of booking" — technician is
the parent resource. Each lives under its semantic parent.
"""
from __future__ import annotations

from django.urls import path

from .views import BookingReviewView, TechnicianReviewsListView

# Mounted by ``technicians.api.urls`` under ``/api/technicians/``.
technician_review_urlpatterns = [
    path(
        "<int:technician_id>/reviews/",
        TechnicianReviewsListView.as_view(),
        name="technician-reviews-list",
    ),
]

# Mounted by ``bookings.api.urls`` under ``/api/bookings/``.
booking_review_urlpatterns = [
    path(
        "<int:booking_id>/review/",
        BookingReviewView.as_view(),
        name="booking-review",
    ),
]

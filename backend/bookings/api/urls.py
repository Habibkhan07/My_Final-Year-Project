from django.urls import path
from bookings.api.instant_book.views import InstantBookView
from bookings.api.job_actions.views import (
    AcceptJobBookingView,
    DeclineJobBookingView,
)

urlpatterns = [
    # URL: /api/bookings/instant-book/
    path('instant-book/', InstantBookView.as_view(), name='instant-book'),
    # URL: /api/bookings/<id>/accept/
    path(
        '<int:booking_id>/accept/',
        AcceptJobBookingView.as_view(),
        name='accept-job-booking',
    ),
    # URL: /api/bookings/<id>/decline/
    path(
        '<int:booking_id>/decline/',
        DeclineJobBookingView.as_view(),
        name='decline-job-booking',
    ),
]

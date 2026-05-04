from django.urls import path
from bookings.api.customer_list.views import (
    CustomerBookingsCountsView,
    CustomerBookingsListView,
)
from bookings.api.instant_book.views import InstantBookView
from bookings.api.job_actions.views import (
    AcceptJobBookingView,
    DeclineJobBookingView,
)

urlpatterns = [
    # URL: /api/bookings/  — customer-side paginated list
    # Routed BEFORE the instant-book / action paths so the bare-root GET
    # is not caught by a more permissive pattern. See CUSTOMER_BOOKINGS_API.md.
    path('', CustomerBookingsListView.as_view(), name='customer-bookings-list'),
    # URL: /api/bookings/counts/  — segmented-control badge counts
    path('counts/', CustomerBookingsCountsView.as_view(), name='customer-bookings-counts'),
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

"""URL routing for the bookings app.

Audit P1-13 — order matters. Django resolves URLs in declaration
order; literal-prefix paths (``counts/``, ``instant-book/``) must
come BEFORE the typed ``<int:booking_id>/`` catch-all. The ``<int:>``
converter rejects non-numeric segments so "counts" wouldn't match
the typed route anyway, but explicit ordering avoids future
regressions.

The booking-detail GET (``<int:booking_id>/``) shares its prefix
with every transition POST below — Django picks the most-specific
match (longer trailing segment wins), so the detail GET is never
shadowed by the verb-suffixed POSTs.
"""
from __future__ import annotations

from django.urls import path

# Existing endpoints (untouched by this session)
from bookings.api.customer_list.views import (
    CustomerBookingsCountsView,
    CustomerBookingsListView,
)
from bookings.api.instant_book.views import InstantBookView
from bookings.api.job_actions.views import (
    AcceptJobBookingView,
    DeclineJobBookingView,
)

# Sprint v1 (session 2) — orchestrator HTTP surface
from bookings.api.booking_detail.views import BookingDetailView
from bookings.api.completion.views import ConfirmCashReceivedView
from bookings.api.customer_arriving.views import CustomerArrivingView
from bookings.api.quotes.views import (
    ApproveQuoteView,
    DeclineQuoteView,
    RequestRevisionView,
    SubmitQuoteView,
)
from bookings.api.tech_location.views import TechLocationIngressView
from bookings.api.terminations.views import (
    CustomerCancelView,
    MarkNoShowView,
    OpenDisputeView,
    RescheduleView,
    TechCancelView,
)
from bookings.api.transitions.views import (
    ArrivedView,
    EnRouteView,
    StartInspectionView,
)


urlpatterns = [
    # 1. Bare-root + literal-prefix (existing, must come first)
    path('', CustomerBookingsListView.as_view(), name='customer-bookings-list'),
    path('counts/', CustomerBookingsCountsView.as_view(), name='customer-bookings-counts'),
    path('instant-book/', InstantBookView.as_view(), name='instant-book'),

    # 2. Booking-detail GET — typed-int prefix that the transitions below
    #    extend with longer suffixes. Django's longest-prefix-match
    #    means a POST to /<id>/accept/ never reaches this view.
    path('<int:booking_id>/', BookingDetailView.as_view(), name='booking-detail'),

    # 3. Pre-existing tech accept / decline
    path(
        '<int:booking_id>/accept/',
        AcceptJobBookingView.as_view(),
        name='accept-job-booking',
    ),
    path(
        '<int:booking_id>/decline/',
        DeclineJobBookingView.as_view(),
        name='decline-job-booking',
    ),

    # 4. Sprint v1 — phase markers (manual override; auto path is via tech-location)
    path('<int:booking_id>/start-inspection/', StartInspectionView.as_view(), name='start-inspection'),
    path('<int:booking_id>/en-route/', EnRouteView.as_view(), name='en-route'),
    path('<int:booking_id>/arrived/', ArrivedView.as_view(), name='arrived'),
    # InDrive-style customer ACK on the ARRIVED screen.
    path(
        '<int:booking_id>/customer-arriving/',
        CustomerArrivingView.as_view(),
        name='customer-arriving',
    ),

    # 5. Sprint v1 — quotes
    path('<int:booking_id>/quotes/', SubmitQuoteView.as_view(), name='submit-quote'),
    path(
        '<int:booking_id>/quotes/<int:quote_id>/approve/',
        ApproveQuoteView.as_view(),
        name='approve-quote',
    ),
    path(
        '<int:booking_id>/quotes/<int:quote_id>/decline/',
        DeclineQuoteView.as_view(),
        name='decline-quote',
    ),
    path(
        '<int:booking_id>/quotes/<int:quote_id>/request-revision/',
        RequestRevisionView.as_view(),
        name='request-revision',
    ),

    # 6. Sprint v1 — completion (combined complete + cash collection)
    path(
        '<int:booking_id>/confirm-cash-received/',
        ConfirmCashReceivedView.as_view(),
        name='confirm-cash-received',
    ),

    # 7. Sprint v1 — terminations
    path('<int:booking_id>/cancel/', CustomerCancelView.as_view(), name='customer-cancel'),
    path('<int:booking_id>/tech-cancel/', TechCancelView.as_view(), name='tech-cancel'),
    path('<int:booking_id>/no-show/', MarkNoShowView.as_view(), name='no-show'),
    path('<int:booking_id>/disputes/', OpenDisputeView.as_view(), name='open-dispute'),
    path('<int:booking_id>/reschedule/', RescheduleView.as_view(), name='reschedule'),

    # 8. Sprint v1 — GPS ingress (publishes tech_gps stream + auto-transition)
    path(
        '<int:booking_id>/tech-location/',
        TechLocationIngressView.as_view(),
        name='tech-location',
    ),
]

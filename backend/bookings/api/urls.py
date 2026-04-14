from django.urls import path
from bookings.api.instant_book.views import InstantBookView

urlpatterns = [
    # URL: /api/bookings/instant-book/
    path('instant-book/', InstantBookView.as_view(), name='instant-book'),
]

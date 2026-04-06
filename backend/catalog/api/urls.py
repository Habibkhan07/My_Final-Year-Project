from django.urls import path
from .search.views import SearchAPIView

urlpatterns = [
    # GET /api/catalog/search/?q={keyword}
    path('search/', SearchAPIView.as_view(), name='catalog-search'),
]
# customers/api/urls.py
from django.urls import path
# Import from the specific views file
from customers.api.home.views import CustomerHomeFeedAPIView
from customers.api.nearby_technicians.views import TechnicianDiscoveryListView

urlpatterns = [
    # URL: /api/customers/home/
    path('home/', CustomerHomeFeedAPIView.as_view(), name='customer-home-feed'),

    # URL: /api/customers/nearby-technicians/
    path('nearby-technicians/', TechnicianDiscoveryListView.as_view(), name='nearby-technicians-list'),
]
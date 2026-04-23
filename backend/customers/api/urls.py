# customers/api/urls.py
from django.urls import path
# Import from the specific views file
from customers.api.home.views import CustomerHomeFeedAPIView
from customers.api.nearby_technicians.views import TechnicianDiscoveryListView
from customers.api.technician_profile.views import TechnicianProfileDetailView
from customers.api.availability.views import TechnicianAvailabilityView
from customers.api.addresses.views import CustomerAddressListCreateView, CustomerAddressDeleteView

urlpatterns = [
    # URL: /api/customers/home/
    path('home/', CustomerHomeFeedAPIView.as_view(), name='customer-home-feed'),

    # URL: /api/customers/nearby-technicians/
    path('nearby-technicians/', TechnicianDiscoveryListView.as_view(), name='nearby-technicians-list'),

    # URL: /api/customers/technician-profile/<pk>/
    path('technician-profile/<int:pk>/', TechnicianProfileDetailView.as_view(), name='technician-profile-detail'),

    # URL: /api/customers/technicians/<pk>/availability/
    path('technicians/<int:pk>/availability/', TechnicianAvailabilityView.as_view(), name='technician-availability'),

    path('addresses/', CustomerAddressListCreateView.as_view(), name='customer-address-list'),
    path('addresses/<int:pk>/', CustomerAddressDeleteView.as_view(), name='customer-address-detail'),
]

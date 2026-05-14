"""
URL configuration for core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""# core/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings # Add this
from django.conf.urls.static import static # Add this

from wallet.api.views import JazzCashReturnView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.api.urls')),
    path('api/technicians/', include('technicians.api.urls')),
    path('api/customers/', include('customers.api.urls')),
    path('api/catalog/', include('catalog.api.urls')),
    path('api/bookings/', include('bookings.api.urls')),
    # AI chatbot framework — dispute persona v1 (more personas land here
    # as folder-adds under chatbot/personas/<key>/, no URLConf edits).
    path('api/chat/', include('chatbot.urls')),
    # Realtime Dispatch Hub (Events & Devices)
    path('api/realtime/', include('realtime.api.urls')),
    # JazzCash gateway return URL — unauthenticated, hash-verified.
    # Mounted at the root URLconf (NOT under /api/technicians/) because
    # JazzCash POSTs cross-origin to it; conceptually it belongs to the
    # gateway surface, not the tech-facing API.
    path(
        'api/wallet/gateway/jazzcash/return/',
        JazzCashReturnView.as_view(),
        name='wallet-jazzcash-return',
    ),
]


# This allows Django to serve the Profile/CNIC pictures during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
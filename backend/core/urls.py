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

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/accounts/', include('accounts.api.urls')),
    path('api/technicians/', include('technicians.api.urls')),
    path('api/customers/', include('customers.api.urls')),
    path('api/catalog/', include('catalog.api.urls')),
    ]


# This allows Django to serve the Profile/CNIC pictures during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
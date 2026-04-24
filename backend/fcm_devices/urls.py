from django.urls import path

from fcm_devices.views import RegisterDeviceView, UnregisterDeviceView

app_name = "fcm_devices"

urlpatterns = [
    path("register/", RegisterDeviceView.as_view(), name="register"),
    path("unregister/", UnregisterDeviceView.as_view(), name="unregister"),
]

from django.contrib import admin

from fcm_devices.models import FCMDevice


@admin.register(FCMDevice)
class FCMDeviceAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "device_type", "is_active", "updated_at")
    list_filter = ("device_type", "is_active")
    search_fields = ("user__username", "user__email", "device_token")
    readonly_fields = ("created_at", "updated_at")

from catalog.models import Service

def get_services_with_subservices():
    """
    Fetches the service tree for the onboarding form and the Profile-tab
    Add Skill picker. Returns a list of dictionaries shaped for direct
    Flutter consumption.

    ``service.icon_name`` and ``sub.is_fixed_price`` are additive fields
    consumed by the Add Skill picker — the existing onboarding flow's
    Freezed models drop unknown keys, so adding them is back-compat.
    """
    services = Service.objects.prefetch_related('sub_services').all()
    return [
        {
            "id": s.id,
            "name": s.name,
            "icon_name": s.icon_name,
            "sub_services": [
                {
                    "id": sub.id,
                    "name": sub.name,
                    "base_price": str(sub.base_price),
                    "max_price": str(sub.max_price) if sub.max_price else None,
                    "icon_name": sub.icon_name,
                    "is_fixed_price": sub.is_fixed_price,
                }
                for sub in s.sub_services.all()
            ]
        } for s in services
    ]

from catalog.models import Service

def get_services_with_subservices():
    """
    Fetches the service tree for the onboarding form.
    Returns a list of dictionaries formatted for easy Flutter consumption.
    """
    services = Service.objects.prefetch_related('sub_services').all()
    return [
        {
            "id": s.id,
            "name": s.name,
            "sub_services": [
                {
                    "id": sub.id,
                    "name": sub.name,
                    "base_price": str(sub.base_price),
                    "max_price": str(sub.max_price) if sub.max_price else None,
                    "icon_name": sub.icon_name,
                }
                for sub in s.sub_services.all()
            ]
        } for s in services
    ]
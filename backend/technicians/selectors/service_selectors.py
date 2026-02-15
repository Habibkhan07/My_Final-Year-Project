from ..models import Service

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
                {"id": sub.id, "name": sub.name, "base_price": str(sub.base_price)} 
                for sub in s.sub_services.all()
            ]
        } for s in services
    ]
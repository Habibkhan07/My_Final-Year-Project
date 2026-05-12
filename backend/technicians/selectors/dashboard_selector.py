from django.utils import timezone
from bookings.models import JobBooking
from technicians.models import TechnicianProfile


def get_technician_dashboard(technician: TechnicianProfile, request=None) -> dict:
    """Returns the technician's daily scheduling overview.

    Metrics (activity + earnings history) are served by a separate selector
    (metrics_selector.get_technician_metrics) and endpoint (GET /api/technicians/metrics/).
    """
    now = timezone.now()
    today = now.date()

    # Base query for today's jobs for this technician
    today_jobs = JobBooking.objects.filter(
        technician=technician,
        scheduled_start__date=today,
    ).select_related('customer', 'customer__userprofile', 'address').order_by('scheduled_start')

    # Upcoming Jobs: CONFIRMED jobs scheduled for now or later today
    upcoming_jobs = list(today_jobs.filter(
        status=JobBooking.STATUS_CONFIRMED,
        scheduled_start__gte=now
    ))
    
    up_next_job_dict = None
    later_today_jobs_list = []
    
    def format_time(dt):
        if not dt: return None
        res = dt.isoformat()
        if res.endswith('+00:00'):
            return res.replace('+00:00', 'Z')
        return res

    if upcoming_jobs:
        up_next = upcoming_jobs[0]
        
        customer_name = up_next.customer.get_full_name()
        if not customer_name:
            customer_name = up_next.customer.username
            
        up_next_job_dict = {
            "job_id": up_next.id,
            "service_title": up_next.price_context,
            "scheduled_time": format_time(up_next.scheduled_start),
            "customer_name": customer_name,
            "customer_phone": getattr(getattr(up_next.customer, 'userprofile', None), 'phone', None) or None,
            "address_text": up_next.address.street_address if up_next.address else "",
            "lat": float(up_next.address.latitude) if up_next.address and up_next.address.latitude else 0.0,
            "lng": float(up_next.address.longitude) if up_next.address and up_next.address.longitude else 0.0,
        }
        
        for job in upcoming_jobs[1:]:
            later_today_jobs_list.append({
                "job_id": job.id,
                "service_title": job.price_context,
                "scheduled_time": format_time(job.scheduled_start),
                "address_text": job.address.street_address if job.address else ""
            })
            
    profile_picture_url = None
    if technician.profile_picture:
        profile_picture_url = technician.profile_picture.url
        if request:
            profile_picture_url = request.build_absolute_uri(profile_picture_url)

    return {
        "wallet_balance": float(technician.current_wallet_balance),
        "is_online": technician.is_online,
        "profile_picture": profile_picture_url,
        "up_next_job": up_next_job_dict,
        "later_today_jobs": later_today_jobs_list,
    }

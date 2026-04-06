# technicians/selectors/matchmaking_selectors.py
import math
from django.db.models import Avg, Prefetch
from catalog.models import SubService
from technicians.models import TechnicianProfile, TechnicianSkill, TechnicianServicePerformance

# --- PURE MATH HELPER FUNCTIONS ---

def _calculate_bayesian_score(v: float, R: float, C: float, m: float = 10.0) -> float:
    """
    Calculates the true weight of a rating using Bayesian logic.
    m=10.0 ensures high-volume professionals outrank lucky beginners.
    """
    return ((v / (v + m)) * R) + ((m / (v + m)) * C)

def _calculate_haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculates the great-circle distance between two GPS points in kilometers."""
    R_earth = 6371.0 
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R_earth * c

# --- THE MAIN ORCHESTRATOR ---

def get_top_nearby_technicians(*, lat: float, lng: float, service_id: int = None, sub_service_id: int = None, radius_km: float = 10.0, limit: int = 5):
    """
    Production-grade selector: Uses geographic bounding boxes, 
    O(1) database queries via select_related/prefetch_related, and Bayesian ranking.
    """
    # 0. Base Queryset (The N+1 Fix is the select_related('user') here)
    base_qs = TechnicianProfile.objects.select_related('user').prefetch_related('skills__service').filter(
        is_active=True,
        is_onboarding_complete=True
    )

    # Failsafe: No GPS? Return global top.
    if not lat or not lng:
        qs = base_qs.order_by('-rating_average', '-review_count')
        return qs[:limit] if limit is not None else qs
        
    lat, lng = float(lat), float(lng)

    # 1. THE BOUNDING BOX: Let SQL drop 99% of irrelevant rows instantly
    lat_delta = radius_km / 111.0
    
    # Prevent division by zero at the poles
    cos_lat = math.cos(math.radians(lat))
    if cos_lat == 0:
        cos_lat = 0.00001
    lng_delta = radius_km / (111.0 * cos_lat)
    
    nearby_techs = base_qs.filter(
        base_latitude__range=(lat - lat_delta, lat + lat_delta),
        base_longitude__range=(lng - lng_delta, lng + lng_delta)
    )

    # 2. DOMAIN FILTERING (Category vs Specific Gig)
    target_service_id = None

    if sub_service_id:
        nearby_techs = nearby_techs.filter(skills__id=sub_service_id).distinct()
        target_service_id = SubService.objects.filter(id=sub_service_id).values_list('service_id', flat=True).first()
        
        # NEW: Prefetch the specific technician skill for the target sub-service
        # This allows Scenario #3 pricing calculation in O(1) inside the Serializer
        skill_prefetch = Prefetch(
            'technicianskill_set',
            queryset=TechnicianSkill.objects.filter(sub_service_id=sub_service_id),
            to_attr='prefetched_skill'
        )
        nearby_techs = nearby_techs.prefetch_related(skill_prefetch)
        
    elif service_id:
        nearby_techs = nearby_techs.filter(skills__service_id=service_id).distinct()
        target_service_id = service_id

    # 3. CONTEXTUAL PERFORMANCE (O(1) Prefetch Fix)
    if target_service_id:
        performance_prefetch = Prefetch(
            'service_performances', 
            queryset=TechnicianServicePerformance.objects.filter(service_id=target_service_id),
            to_attr='prefetched_performance'
        )
        nearby_techs = nearby_techs.prefetch_related(performance_prefetch)
        platform_avg = TechnicianServicePerformance.objects.filter(service_id=target_service_id).aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0
    else:
        platform_avg = nearby_techs.aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0

    # 4. MEMORY PROCESSING (Zero DB hits inside this loop)
    scored_techs = []
    
    for tech in nearby_techs:
        if not tech.base_latitude or not tech.base_longitude:
            continue

        # Distance precise check (Filtering out corners of the bounding box)
        distance = _calculate_haversine_distance(lat, lng, float(tech.base_latitude), float(tech.base_longitude))
        if distance > radius_km:
            continue

        # Context-aware ranking
        if target_service_id:
            performance_list = tech.prefetched_performance
            performance = performance_list[0] if performance_list else None
            v = float(performance.review_count) if performance else 0.0
            R = float(performance.rating_average) if performance else 0.0
        else:
            v = float(tech.review_count)
            R = float(tech.rating_average)
            
        # Bind the dynamic values for the Serializer
        tech.bayesian_score = _calculate_bayesian_score(v=v, R=R, C=float(platform_avg))
        tech.distance_km = distance
        
        scored_techs.append(tech)

    # 5. SORT & YIELD
    scored_techs.sort(key=lambda x: (-x.bayesian_score, x.distance_km))
    return scored_techs[:limit]
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

    CRITICAL: Domain filters (service/sub-service) are applied BEFORE the GPS check
    so that promo/category/gig filtering always works, even when coordinates are absent.
    """
    # 0. Base Queryset (The N+1 Fix is the select_related('user') here)
    #
    # ``is_online=True`` is the discovery-side counterpart to the auto-offline
    # behavior in ``wallet.services.ledger.record_transaction``: when a tech's
    # wallet drops into lockout territory (balance < 0) the ledger flips them
    # offline in the same atomic. This filter then removes them from the
    # customer's discovery list, completing the "tech goes offline → not
    # bookable" loop. Manual offline toggles get the same treatment, which is
    # the universal pattern across Uber / Careem / TaskRabbit / Foodpanda:
    # offline = not visible to dispatch.
    base_qs = TechnicianProfile.objects.select_related('user').prefetch_related('skills__service').filter(
        is_active=True,
        is_onboarding_complete=True,
        is_online=True,
    )

    # --- STEP 1: DOMAIN FILTERING (always applied, GPS-independent) ---
    # This must happen before the GPS failsafe so that promo/category/gig contexts
    # are always respected, even when the device has no location data.
    target_service_id = None

    if sub_service_id:
        # Filter: technicians who have this specific skill (e.g., "AC Gas Refill")
        base_qs = base_qs.filter(skills__id=sub_service_id).distinct()
        target_service_id = SubService.objects.filter(id=sub_service_id).values_list('service_id', flat=True).first()

        # Prefetch the specific skill row for this sub-service (used for labor-rate pricing in serializer, O(1))
        skill_prefetch = Prefetch(
            'technicianskill_set',
            queryset=TechnicianSkill.objects.filter(sub_service_id=sub_service_id),
            to_attr='prefetched_skill'
        )
        base_qs = base_qs.prefetch_related(skill_prefetch)

    elif service_id:
        # Filter: technicians who have ANY skill under this parent category (e.g., all AC technicians)
        base_qs = base_qs.filter(skills__service_id=service_id).distinct()
        target_service_id = service_id

    # --- STEP 2: CONTEXTUAL PERFORMANCE PREFETCH (O(1), always applied when scoped) ---
    if target_service_id:
        performance_prefetch = Prefetch(
            'service_performances',
            queryset=TechnicianServicePerformance.objects.filter(service_id=target_service_id),
            to_attr='prefetched_performance'
        )
        base_qs = base_qs.prefetch_related(performance_prefetch)
        platform_avg = TechnicianServicePerformance.objects.filter(service_id=target_service_id).aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0
    else:
        platform_avg = base_qs.aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0

    # --- STEP 3: GPS FALLBACK — no location means global ranking, but filters already applied above ---
    if not lat or not lng:
        qs = base_qs.order_by('-rating_average', '-review_count')
        return qs[:limit] if limit is not None else qs

    lat, lng = float(lat), float(lng)

    # --- STEP 4: THE BOUNDING BOX — let SQL drop 99% of geographically irrelevant rows ---
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

    # --- STEP 5: MEMORY PROCESSING (zero DB hits inside this loop) ---
    scored_techs = []

    for tech in nearby_techs:
        if not tech.base_latitude or not tech.base_longitude:
            continue

        # Precise distance check (filters out corners of the bounding box)
        distance = _calculate_haversine_distance(lat, lng, float(tech.base_latitude), float(tech.base_longitude))
        if distance > radius_km:
            continue

        # Context-aware Bayesian ranking
        if target_service_id:
            performance_list = tech.prefetched_performance
            performance = performance_list[0] if performance_list else None
            v = float(performance.review_count) if performance else 0.0
            R = float(performance.rating_average) if performance else 0.0
        else:
            v = float(tech.review_count)
            R = float(tech.rating_average)

        # Attach dynamic values for the Serializer
        tech.bayesian_score = _calculate_bayesian_score(v=v, R=R, C=float(platform_avg))
        tech.distance_km = distance

        scored_techs.append(tech)

    # --- STEP 6: SORT & YIELD ---
    scored_techs.sort(key=lambda x: (-x.bayesian_score, x.distance_km))
    return scored_techs[:limit]

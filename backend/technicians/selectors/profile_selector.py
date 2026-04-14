# technicians/selectors/profile_selector.py
from typing import Optional, Tuple
from django.db.models import Avg, Prefetch

from catalog.models import Service, SubService
from marketing.models import Promotion
from technicians.models import TechnicianProfile, TechnicianSkill, TechnicianServicePerformance, Review
from technicians.selectors.matchmaking_selectors import (
    _calculate_haversine_distance,
    _calculate_bayesian_score,
)
from django.utils import timezone


def _resolve_promo(
    *,
    promotion_id: Optional[int],
    resolved_service: Optional[Service],
) -> Optional[Promotion]:
    """
    Resolves a single active Promotion object from either an explicit ID
    or by checking if the target service has any active promo.
    Returns None when neither source yields an active promo.
    """
    now = timezone.now()

    if promotion_id:
        try:
            return Promotion.objects.get(id=promotion_id, is_active=True, valid_from__lte=now, valid_until__gte=now)
        except Promotion.DoesNotExist:
            pass

    if resolved_service:
        return (
            Promotion.objects.filter(
                target_service=resolved_service,
                is_active=True,
                valid_from__lte=now,
                valid_until__gte=now,
            )
            .order_by('-valid_from')
            .first()
        )

    return None


def get_technician_profile_detail(
    *,
    tech_id: int,
    lat: Optional[float] = None,
    lng: Optional[float] = None,
    service_id: Optional[int] = None,
    sub_service_id: Optional[int] = None,
    promotion_id: Optional[int] = None,
) -> Tuple[TechnicianProfile, Optional[Service], Optional[SubService], Optional[Promotion]]:
    """
    Fetches a single approved TechnicianProfile and enriches it with contextual
    pricing data (distance, Bayesian score) computed in memory — zero extra DB hits
    after the initial fetch.

    Raises TechnicianProfile.DoesNotExist when the profile is not found or not approved,
    which the view maps to a 404.

    Resolution priority (mirrors resolve_discovery_intent):
      1. sub_service_id → resolves SubService + its parent Service
      2. service_id → resolves Service only
      3. promotion_id → resolves active Promo (and its target service if nothing else set it)
    """
    # --- STEP 1: RESOLVE CONTEXT OBJECTS ---
    resolved_subservice: Optional[SubService] = None
    resolved_service: Optional[Service] = None

    if sub_service_id:
        try:
            resolved_subservice = SubService.objects.select_related('service').get(id=sub_service_id)
            resolved_service = resolved_subservice.service
        except SubService.DoesNotExist:
            pass

    if not resolved_service and service_id:
        try:
            resolved_service = Service.objects.get(id=service_id)
        except Service.DoesNotExist:
            pass

    resolved_promo = _resolve_promo(promotion_id=promotion_id, resolved_service=resolved_service)

    # --- STEP 2: BUILD QUERYSET WITH ALL PREFETCHES (no N+1) ---
    qs = TechnicianProfile.objects.select_related('user').prefetch_related(
        # Skills list for the profile page
        Prefetch(
            'technicianskill_set',
            queryset=TechnicianSkill.objects.select_related('sub_service__service'),
            to_attr='all_skills',
        ),
        # Top 2 recent reviews
        Prefetch(
            'reviews',
            queryset=Review.objects.select_related('reviewer').order_by('-created_at')[:2],
            to_attr='recent_reviews_list',
        ),
    )

    # Conditionally prefetch the specific skill row for labor-rate pricing (O(1))
    if resolved_subservice:
        qs = qs.prefetch_related(
            Prefetch(
                'technicianskill_set',
                queryset=TechnicianSkill.objects.filter(sub_service=resolved_subservice),
                to_attr='prefetched_skill',
            )
        )

    # --- STEP 3: FETCH — raises DoesNotExist (→ 404) if not found or not approved ---
    tech = qs.get(id=tech_id, status='APPROVED')

    # --- STEP 4: CONTEXTUAL BAYESIAN SCORING (in memory, zero DB hits) ---
    if resolved_service:
        platform_avg = (
            TechnicianServicePerformance.objects.filter(service=resolved_service)
            .aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0
        )
        # Try context-specific performance first, fall back to global profile rating
        try:
            perf = TechnicianServicePerformance.objects.get(technician=tech, service=resolved_service)
            v = float(perf.review_count)
            R = float(perf.rating_average)
        except TechnicianServicePerformance.DoesNotExist:
            v = float(tech.review_count)
            R = float(tech.rating_average)
    else:
        platform_avg = (
            TechnicianProfile.objects.filter(is_active=True, is_onboarding_complete=True)
            .aggregate(Avg('rating_average'))['rating_average__avg'] or 4.0
        )
        v = float(tech.review_count)
        R = float(tech.rating_average)

    # m=10 trust constant: prevents lucky 5-star beginners from outranking veterans
    tech.bayesian_score = _calculate_bayesian_score(v=v, R=R, C=float(platform_avg))

    # --- STEP 5: DISTANCE CALCULATION (in memory via Haversine) ---
    if lat is not None and lng is not None and tech.base_latitude and tech.base_longitude:
        tech.distance_km = _calculate_haversine_distance(
            lat, lng, float(tech.base_latitude), float(tech.base_longitude)
        )
    else:
        tech.distance_km = None

    return tech, resolved_service, resolved_subservice, resolved_promo

"""
Single source of truth for resolving a customer's discovery intent
(service / sub_service / promotion) plus a target technician into the
catalog references and pricing primitives used by both customer-facing
read paths (technician profile, home feed) and — in a later step — the
booking write path.

Read paths consume the formatted display strings (``primary_price``,
``price_context_label``, ``promo_tag_firewalled``). The booking write
path consumes the raw ``primary_amount`` plus ``booking_type`` for
validation and persistence.

Discovery intent is never user-typed at booking time — it carries
through from the URL the customer arrived on (search bar match, gig
tile, category tile, promo banner). See ``BOOKINGS_API.md`` and
``customers/selectors/intent_selector.py``.
"""
from __future__ import annotations

from dataclasses import dataclass
from decimal import Decimal
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from catalog.models import Service, SubService
    from marketing.models import Promotion
    from technicians.models import TechnicianProfile


# Booking-type discriminator — drives the technician's on-site UX
# (Complete vs. Build Quote screen) and the write-side validation
# strategy. Stable string values — wire-format compatible.
BOOKING_TYPE_INSPECTION = "INSPECTION"
BOOKING_TYPE_FIXED_GIG = "FIXED_GIG"
BOOKING_TYPE_LABOR_GIG = "LABOR_GIG"
# Sentinel for global-browse / no-context callers. Read paths fall back
# to a flat "Rs. 500 / Inspection Fee" display; the write path will
# never see this value (booking creation requires a resolved Service).
BOOKING_TYPE_UNKNOWN = "UNKNOWN"


@dataclass(frozen=True)
class ResolvedIntent:
    """
    Outcome of :func:`resolve_booking_intent`. Stable contract.

    ``primary_amount`` is the raw figure the write path validates
    against (exact equality across all booking types).

    ``promo_tag_firewalled`` honours the absolute product rule: discount
    stacking on a fixed-price gig is forbidden, so the field is ``None``
    for ``FIXED_GIG`` even when a promotion is in the discovery context.
    The ``promotion`` instance itself is also nulled in that case so the
    booking write path won't persist a phantom FK.
    """
    service: Optional["Service"]
    sub_service: Optional["SubService"]
    promotion: Optional["Promotion"]

    booking_type: str  # one of the BOOKING_TYPE_* constants above

    primary_amount: Decimal

    # Pre-formatted display strings. Comma thousand-separators are
    # applied uniformly across all scenarios; read consumers render
    # these verbatim (Dumb-UI principle, see CLAUDE.md).
    primary_price: str
    primary_price_raw: str
    price_context_label: str

    promo_tag_firewalled: Optional[str]


# Default fallback used when neither service nor sub_service is in
# context (global browse / no discovery intent). Matches the platform's
# baseline inspection fee.
_DEFAULT_PRICE = Decimal("500.00")
_DEFAULT_PRICE_DISPLAY = "Rs. 500"
_DEFAULT_PRICE_RAW = "500.00"


def resolve_booking_intent(
    *,
    technician: "TechnicianProfile",
    service: Optional["Service"],
    sub_service: Optional["SubService"],
    promotion: Optional["Promotion"],
) -> ResolvedIntent:
    """
    Resolve the customer's discovery intent into a :class:`ResolvedIntent`.

    Mirrors the three pricing scenarios documented in
    ``customers/api/DISCOVERY_API.md``:

    * **A — Fixed-Price Gig** (``sub_service.is_fixed_price=True``):
      promo firewalled to ``None``; promotion FK also nulled.
    * **B — Labor Gig** (``sub_service.is_fixed_price=False``): price
      is the technician's ``TechnicianSkill.labor_rate``; falls back to
      the sub-service's platform base price when the technician hasn't
      set a custom rate.
    * **C — Category / Promo on parent service** (only ``service``
      provided): price is the service's inspection fee.

    A "Rs. 500 / Inspection Fee / no promo" fallback is returned when
    neither ``service`` nor ``sub_service`` is in context.

    Performance contract: at most ONE DB hit — the
    ``TechnicianSkill`` fallback lookup in Scenario B when
    ``technician.prefetched_skill`` is empty. Production matchmaking
    selectors prefetch this; the lookup is a safety net.
    """
    # SECURITY: pure read; consumes already-validated catalog instances
    # resolved upstream by ``resolve_discovery_intent``. No client-
    # supplied IDs reach this function unverified.

    # --- Scenario A: Fixed-Price Gig ----------------------------------
    if sub_service is not None and sub_service.is_fixed_price:
        amount = Decimal(sub_service.base_price)
        return ResolvedIntent(
            service=service or sub_service.service,
            sub_service=sub_service,
            # FIREWALL: promotion stripped entirely on fixed gigs.
            # Discount stacking is forbidden by product rule; we null
            # the FK here so a future write-path consumer cannot
            # accidentally persist a phantom promotion on the booking.
            promotion=None,
            booking_type=BOOKING_TYPE_FIXED_GIG,
            primary_amount=amount,
            primary_price=f"Rs. {int(amount):,}",
            primary_price_raw=str(sub_service.base_price),
            price_context_label="Fixed Price",
            promo_tag_firewalled=None,
        )

    # --- Scenario B: Labor Gig ----------------------------------------
    if sub_service is not None:
        prefetched = getattr(technician, "prefetched_skill", []) or []
        tech_skill = (
            prefetched[0]
            if prefetched
            else technician.technicianskill_set.filter(sub_service=sub_service).first()
        )

        if tech_skill is not None and tech_skill.labor_rate:
            primary_amount = Decimal(tech_skill.labor_rate)
            primary_price_raw = str(tech_skill.labor_rate)
        else:
            # Tech hasn't set a custom rate — fall back to the platform
            # per-sub-service default.
            primary_amount = Decimal(sub_service.base_price)
            primary_price_raw = str(sub_service.base_price)

        return ResolvedIntent(
            service=service or sub_service.service,
            sub_service=sub_service,
            promotion=promotion,
            booking_type=BOOKING_TYPE_LABOR_GIG,
            primary_amount=primary_amount,
            primary_price=f"Rs. {int(primary_amount):,}",
            primary_price_raw=primary_price_raw,
            price_context_label="Labor Fee",
            promo_tag_firewalled=promotion.ui_description if promotion else None,
        )

    # --- Scenario C: Category Discovery / Promo on parent service ----
    if service is not None:
        amount = Decimal(service.base_inspection_fee)
        return ResolvedIntent(
            service=service,
            sub_service=None,
            promotion=promotion,
            booking_type=BOOKING_TYPE_INSPECTION,
            primary_amount=amount,
            primary_price=f"Rs. {int(amount):,}",
            primary_price_raw=str(service.base_inspection_fee),
            price_context_label="Inspection Fee",
            promo_tag_firewalled=promotion.ui_description if promotion else None,
        )

    # --- Fallback: no discovery context (global browse) --------------
    return ResolvedIntent(
        service=None,
        sub_service=None,
        promotion=None,
        booking_type=BOOKING_TYPE_UNKNOWN,
        primary_amount=_DEFAULT_PRICE,
        primary_price=_DEFAULT_PRICE_DISPLAY,
        primary_price_raw=_DEFAULT_PRICE_RAW,
        price_context_label="Inspection Fee",
        promo_tag_firewalled=None,
    )
